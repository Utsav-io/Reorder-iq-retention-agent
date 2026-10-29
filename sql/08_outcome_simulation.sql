-- SIMULATED post-campaign reorders (SYNTHETIC). Run ONCE.
-- Assumption built into the simulation: control reorders 12% naturally; treatment customers
-- whose message was delivered reorder 17% (a 5-point lift). Real results would differ.
-- Each new order uses the customer's own average order value, restaurant and cost ratio, no discount.
INSERT INTO orders (customer_id, order_timestamp, restaurant_id, gross_order_value,
                    discount_amount, platform_funded_discount, merchant_funded_discount,
                    variable_cost, order_status)
SELECT a.customer_id,
       now() + (1 + random() * 13) * interval '1 day',
       h.rest, h.aov, 0, 0, 0,
       round(h.aov * h.cost_ratio, 2),
       'completed'
FROM experiment_assignments a
JOIN (
  SELECT customer_id,
         max(restaurant_id) AS rest,
         round(avg(gross_order_value), 2) AS aov,
         avg(variable_cost / NULLIF(gross_order_value, 0)) AS cost_ratio
  FROM orders WHERE order_status = 'completed' GROUP BY customer_id
) h USING (customer_id)
LEFT JOIN campaign_events e
  ON e.customer_id = a.customer_id AND e.experiment_id = a.experiment_id AND e.event_type = 'delivered'
WHERE a.experiment_id = 'EXP-001'
  AND random() < CASE WHEN a.variant = 'treatment' AND e.event_id IS NOT NULL THEN 0.17 ELSE 0.12 END
  AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = a.customer_id AND o.order_timestamp > now());
