-- One-row summary of the latest result and the latest AI brief.
CREATE OR REPLACE VIEW v_reorderiq_summary AS
SELECT
  r.experiment_id, r.n_treatment, r.n_control,
  r.reorder_rate_treatment_pct AS treatment_reorder_pct,
  r.reorder_rate_control_pct   AS control_reorder_pct,
  r.lift_pp, r.lift_ci_low_pp, r.lift_ci_high_pp, r.incremental_orders,
  r.incr_contrib_per_customer, r.incr_contrib_ci_low, r.incr_contrib_ci_high,
  r.campaign_cost, r.net_incremental_contribution,
  b.brief->>'recommended_action' AS ai_recommended_action,
  b.brief->>'confidence_level'   AS ai_confidence,
  b.approval_status              AS brief_approval_status,
  'SYNTHETIC illustrative data' AS data_label
FROM (SELECT * FROM experiment_results ORDER BY result_id DESC LIMIT 1) r
CROSS JOIN (SELECT * FROM ai_briefs ORDER BY brief_id DESC LIMIT 1) b;
