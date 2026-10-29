-- WF-04, node "Measure Incremental Results".
-- Outcome window = completed orders after the campaign start date (CMP-001.start_at).
-- 95% intervals use the normal approximation. Message cost 0.05 AED/send is an ASSUMPTION.
WITH w AS (
  SELECT start_at FROM campaigns WHERE campaign_id = 'CMP-001'
),
cust AS (
  SELECT a.customer_id, a.variant,
         COUNT(o.order_id) AS orders,
         COALESCE(SUM(o.gross_order_value - o.discount_amount - o.variable_cost), 0) AS contribution
  FROM experiment_assignments a
  CROSS JOIN w
  LEFT JOIN orders o
    ON o.customer_id = a.customer_id AND o.order_status = 'completed' AND o.order_timestamp > w.start_at
  WHERE a.experiment_id = 'EXP-001'
  GROUP BY a.customer_id, a.variant
),
g AS (
  SELECT variant, COUNT(*)::numeric AS n, AVG((orders > 0)::int)::numeric AS p,
         AVG(contribution)::numeric AS m, COALESCE(STDDEV_SAMP(contribution), 0)::numeric AS sd
  FROM cust GROUP BY variant
),
t AS (SELECT * FROM g WHERE variant = 'treatment'),
c AS (SELECT * FROM g WHERE variant = 'control'),
cost AS (
  SELECT COUNT(*) * 0.05 AS campaign_cost
  FROM campaign_events WHERE experiment_id = 'EXP-001' AND event_type = 'sent'
)
INSERT INTO experiment_results
 (experiment_id, n_treatment, n_control,
  reorder_rate_treatment_pct, reorder_rate_control_pct,
  lift_pp, lift_ci_low_pp, lift_ci_high_pp, incremental_orders,
  contrib_per_customer_treatment, contrib_per_customer_control,
  incr_contrib_per_customer, incr_contrib_ci_low, incr_contrib_ci_high,
  campaign_cost, net_incremental_contribution, note)
SELECT 'EXP-001', t.n, c.n,
  ROUND(100*t.p, 2), ROUND(100*c.p, 2),
  ROUND(100*(t.p - c.p), 2),
  ROUND(100*((t.p - c.p) - 1.96*SQRT(t.p*(1-t.p)/t.n + c.p*(1-c.p)/c.n)), 2),
  ROUND(100*((t.p - c.p) + 1.96*SQRT(t.p*(1-t.p)/t.n + c.p*(1-c.p)/c.n)), 2),
  ROUND((t.p - c.p) * t.n, 2),
  ROUND(t.m, 2), ROUND(c.m, 2),
  ROUND(t.m - c.m, 2),
  ROUND((t.m - c.m) - 1.96*SQRT(t.sd^2/t.n + c.sd^2/c.n), 2),
  ROUND((t.m - c.m) + 1.96*SQRT(t.sd^2/t.n + c.sd^2/c.n), 2),
  ROUND(cost.campaign_cost, 2),
  ROUND((t.m - c.m) * t.n - cost.campaign_cost, 2),
  'SYNTHETIC illustrative data. Simulated outcomes. 14-day window. Message cost 0.05 AED/send is an assumption.'
FROM t, c, cost
RETURNING *;
