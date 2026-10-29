-- Synthetic data generator. Fully random: rerunning gives different numbers.
-- 5,000 customers; ~10% opted out; ~20% pro tier; three UAE markets.
-- About 20% of customers have their order rate cut by 75% in the last 60 days
-- (this is the "declining frequent customer" signal the agent looks for).
-- Run ONCE on an empty database.

INSERT INTO customers (signup_date, market, consent_status, loyalty_tier)
SELECT (current_date - (30 + floor(random() * 700))::int),
       (ARRAY['Dubai','Abu Dhabi','Sharjah'])[1 + floor(random() * 3)::int],
       CASE WHEN random() < 0.10 THEN 'opted_out' ELSE 'opted_in' END,
       CASE WHEN random() < 0.20 THEN 'pro' ELSE 'standard' END
FROM generate_series(1, 5000);

INSERT INTO orders (customer_id, order_timestamp, restaurant_id, gross_order_value,
                    discount_amount, platform_funded_discount, merchant_funded_discount,
                    variable_cost, order_status)
WITH cust AS MATERIALIZED (
  SELECT customer_id,
         0.02 + random() * 0.10 AS daily_rate,
         (customer_id % 5 = 0)  AS declining
  FROM customers
),
picked AS (
  SELECT c.customer_id,
         d.d AS days_ago,
         round((40 + random() * 80)::numeric, 2) AS gross,
         round((0.55 + random() * 0.20)::numeric, 3) AS cost_ratio
  FROM cust c
  CROSS JOIN generate_series(0, 179) AS d(d)
  WHERE random() < CASE WHEN c.declining AND d.d < 60 THEN c.daily_rate * 0.25 ELSE c.daily_rate END
)
SELECT customer_id,
       now() - (days_ago * interval '1 day') - (random() * interval '20 hours'),
       1 + floor(random() * 200)::int,
       gross, 0, 0, 0,
       round(gross * cost_ratio, 2),
       CASE WHEN random() < 0.03 THEN 'cancelled' ELSE 'completed' END
FROM picked;
