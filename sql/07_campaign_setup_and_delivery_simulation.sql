-- Campaign definition (sandbox: no real messages are sent).
INSERT INTO campaigns
  (campaign_id, name, channel, segment_rule, offer_type, offer_value, max_budget, start_at, end_at, status)
VALUES
  ('CMP-001', 'Personalized reminder - declining frequent customers', 'email_sandbox',
   'prior_60 >= 6 AND recent_60 <= 50% of prior_60', 'none', 0, 0,
   now(), now() + interval '30 days', 'sandbox')
ON CONFLICT (campaign_id) DO NOTHING;

-- WF-03, node "Log Sandbox Delivery": treatment customers only. Control gets nothing.
-- Delivery/open/click rates (97% / 40% / 25%) are ASSUMPTIONS for the simulation.
WITH t AS (
  SELECT customer_id FROM experiment_assignments
  WHERE experiment_id = 'EXP-001' AND variant = 'treatment'
),
s AS (
  INSERT INTO campaign_events (campaign_id, experiment_id, customer_id, event_type, message_variant)
  SELECT 'CMP-001', 'EXP-001', customer_id, 'sent', 'reminder_v1' FROM t
  ON CONFLICT DO NOTHING RETURNING customer_id
),
d AS (
  INSERT INTO campaign_events (campaign_id, experiment_id, customer_id, event_type, message_variant)
  SELECT 'CMP-001', 'EXP-001', customer_id, 'delivered', 'reminder_v1' FROM s WHERE random() < 0.97
  ON CONFLICT DO NOTHING RETURNING customer_id
),
o AS (
  INSERT INTO campaign_events (campaign_id, experiment_id, customer_id, event_type, message_variant)
  SELECT 'CMP-001', 'EXP-001', customer_id, 'opened', 'reminder_v1' FROM d WHERE random() < 0.40
  ON CONFLICT DO NOTHING RETURNING customer_id
),
c AS (
  INSERT INTO campaign_events (campaign_id, experiment_id, customer_id, event_type, message_variant)
  SELECT 'CMP-001', 'EXP-001', customer_id, 'clicked', 'reminder_v1' FROM o WHERE random() < 0.25
  ON CONFLICT DO NOTHING RETURNING customer_id
)
SELECT (SELECT COUNT(*) FROM s) AS sent, (SELECT COUNT(*) FROM d) AS delivered,
       (SELECT COUNT(*) FROM o) AS opened, (SELECT COUNT(*) FROM c) AS clicked;
