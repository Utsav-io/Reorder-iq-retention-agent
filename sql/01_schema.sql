-- ReOrder IQ: database schema (PostgreSQL 16)
-- All data in this project is SYNTHETIC and illustrative.

CREATE TABLE IF NOT EXISTS customers (
  customer_id    SERIAL PRIMARY KEY,
  signup_date    DATE NOT NULL,
  market         TEXT NOT NULL,
  consent_status TEXT NOT NULL CHECK (consent_status IN ('opted_in','opted_out')),
  loyalty_tier   TEXT NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
  order_id                 SERIAL PRIMARY KEY,
  customer_id              INT NOT NULL REFERENCES customers(customer_id),
  order_timestamp          TIMESTAMPTZ NOT NULL,
  restaurant_id            INT NOT NULL,
  gross_order_value        NUMERIC(8,2) NOT NULL,
  discount_amount          NUMERIC(8,2) NOT NULL DEFAULT 0,
  platform_funded_discount NUMERIC(8,2) NOT NULL DEFAULT 0,
  merchant_funded_discount NUMERIC(8,2) NOT NULL DEFAULT 0,
  variable_cost            NUMERIC(8,2) NOT NULL,
  order_status             TEXT NOT NULL CHECK (order_status IN ('completed','cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_orders_customer_ts ON orders(customer_id, order_timestamp);

CREATE TABLE IF NOT EXISTS action_recommendations (
  recommendation_id     SERIAL PRIMARY KEY,
  customer_id           INT NOT NULL REFERENCES customers(customer_id),
  segment               TEXT,
  next_action           TEXT NOT NULL,
  reason                TEXT,
  discount_pct          NUMERIC(5,2) DEFAULT 0,
  expected_discount_cost NUMERIC(8,2) DEFAULT 0,
  explanation           TEXT,
  policy_version        TEXT DEFAULT 'v1',
  approval_status       TEXT NOT NULL DEFAULT 'pending_approval',
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS experiment_assignments (
  assignment_id        SERIAL PRIMARY KEY,
  experiment_id        TEXT NOT NULL,
  customer_id          INT NOT NULL REFERENCES customers(customer_id),
  variant              TEXT NOT NULL CHECK (variant IN ('treatment','control')),
  assigned_at          TIMESTAMPTZ DEFAULT now(),
  eligibility_snapshot JSONB,
  assignment_key       TEXT NOT NULL,
  UNIQUE (experiment_id, customer_id)
);

CREATE TABLE IF NOT EXISTS campaigns (
  campaign_id  TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  channel      TEXT NOT NULL,
  segment_rule TEXT,
  offer_type   TEXT,
  offer_value  NUMERIC(8,2) DEFAULT 0,
  max_budget   NUMERIC(10,2) DEFAULT 0,
  start_at     TIMESTAMPTZ,
  end_at       TIMESTAMPTZ,
  status       TEXT DEFAULT 'sandbox'
);

CREATE TABLE IF NOT EXISTS campaign_events (
  event_id        SERIAL PRIMARY KEY,
  campaign_id     TEXT REFERENCES campaigns(campaign_id),
  experiment_id   TEXT NOT NULL,
  customer_id     INT REFERENCES customers(customer_id),
  event_type      TEXT NOT NULL CHECK (event_type IN ('sent','delivered','opened','clicked','opted_out')),
  event_timestamp TIMESTAMPTZ DEFAULT now(),
  message_variant TEXT,
  UNIQUE (experiment_id, customer_id, event_type)
);

CREATE TABLE IF NOT EXISTS experiment_results (
  result_id                       SERIAL PRIMARY KEY,
  experiment_id                   TEXT NOT NULL,
  run_at                          TIMESTAMPTZ DEFAULT now(),
  n_treatment                     INT,
  n_control                       INT,
  reorder_rate_treatment_pct      NUMERIC(6,2),
  reorder_rate_control_pct        NUMERIC(6,2),
  lift_pp                         NUMERIC(6,2),
  lift_ci_low_pp                  NUMERIC(6,2),
  lift_ci_high_pp                 NUMERIC(6,2),
  incremental_orders              NUMERIC(8,2),
  contrib_per_customer_treatment  NUMERIC(8,2),
  contrib_per_customer_control    NUMERIC(8,2),
  incr_contrib_per_customer       NUMERIC(8,2),
  incr_contrib_ci_low             NUMERIC(8,2),
  incr_contrib_ci_high            NUMERIC(8,2),
  campaign_cost                   NUMERIC(10,2),
  net_incremental_contribution    NUMERIC(10,2),
  note                            TEXT
);

CREATE TABLE IF NOT EXISTS ai_briefs (
  brief_id        SERIAL PRIMARY KEY,
  experiment_id   TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  brief           JSONB,
  parse_ok        BOOLEAN,
  approval_status TEXT DEFAULT 'pending_approval'
);
