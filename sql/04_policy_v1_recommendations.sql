-- SQL equivalent of WF-01 (metrics + Filter + "Decide Next Best Action" + save).
-- Use this to reproduce recommendations without n8n. In the project itself
-- this logic runs inside the n8n workflow (see n8n_code/decide_next_best_action.js).
-- Policy v1: consent hard stop; suppress if ordered in last 7 days; otherwise a
-- personalized reminder with 0% discount. Everything starts as pending_approval.
INSERT INTO action_recommendations
  (customer_id, segment, next_action, reason, discount_pct, expected_discount_cost, policy_version, approval_status)
WITH m AS (
  SELECT c.customer_id, c.consent_status,
         COUNT(o.order_id) FILTER (WHERE o.order_timestamp >= now() - interval '60 days')  AS recent_60,
         COUNT(o.order_id) FILTER (WHERE o.order_timestamp <  now() - interval '60 days'
                                    AND  o.order_timestamp >= now() - interval '120 days') AS prior_60,
         EXTRACT(DAY FROM now() - MAX(o.order_timestamp))::int AS days_since_last_order
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'completed'
  GROUP BY c.customer_id, c.consent_status
)
SELECT customer_id, 'at_risk',
       CASE WHEN consent_status <> 'opted_in' OR days_since_last_order <= 7 THEN 'no_action'
            ELSE 'personalized_reminder' END,
       CASE WHEN consent_status <> 'opted_in' THEN 'Consent missing - hard stop'
            WHEN days_since_last_order <= 7   THEN 'Ordered recently - suppress from win-back'
            ELSE 'Previously frequent, order rate declining' END,
       0, 0, 'v1', 'pending_approval'
FROM m
WHERE consent_status = 'opted_in' AND prior_60 >= 6 AND recent_60 <= prior_60 * 0.5;
