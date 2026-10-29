-- WF-01, node "Calculate customer metrics".
-- Per customer: orders in the last 60 days vs the prior 60 days, and a segment.
-- at_risk = >= 6 orders in days 61-120 AND last-60-day orders <= half of that.
WITH m AS (
  SELECT c.customer_id, c.consent_status, c.market, c.loyalty_tier,
         COUNT(o.order_id) FILTER (WHERE o.order_timestamp >= now() - interval '60 days')  AS orders_recent_60,
         COUNT(o.order_id) FILTER (WHERE o.order_timestamp <  now() - interval '60 days'
                                    AND  o.order_timestamp >= now() - interval '120 days') AS orders_prior_60,
         ROUND(AVG(o.gross_order_value), 2) AS avg_order_value,
         EXTRACT(DAY FROM now() - MAX(o.order_timestamp))::int AS days_since_last_order
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.order_status = 'completed'
  GROUP BY c.customer_id, c.consent_status, c.market, c.loyalty_tier
)
SELECT m.*,
       CASE WHEN consent_status <> 'opted_in'                                  THEN 'excluded_no_consent'
            WHEN orders_prior_60 >= 6 AND orders_recent_60 <= orders_prior_60 * 0.5 THEN 'at_risk'
            WHEN orders_prior_60 >= 6                                          THEN 'healthy'
            ELSE 'low_history' END AS segment
FROM m;
