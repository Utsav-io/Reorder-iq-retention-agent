-- WF-03, node "Assign Treatment/Control".
-- Stable, mutually exclusive assignment: the MD5 hash of 'EXP-001:<customer_id>' decides
-- the group; UNIQUE(experiment_id, customer_id) + ON CONFLICT DO NOTHING make reruns safe.
INSERT INTO experiment_assignments (experiment_id, customer_id, variant, eligibility_snapshot, assignment_key)
SELECT 'EXP-001', r.customer_id,
       CASE WHEN get_byte(decode(md5('EXP-001:' || r.customer_id), 'hex'), 0) % 2 = 0 THEN 'treatment' ELSE 'control' END,
       jsonb_build_object('next_action', r.next_action, 'segment', r.segment,
                          'policy_version', r.policy_version, 'consent_status', c.consent_status),
       md5('EXP-001:' || r.customer_id)
FROM action_recommendations r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.approval_status = 'approved'
  AND r.next_action = 'personalized_reminder'
  AND c.consent_status = 'opted_in'
ON CONFLICT (experiment_id, customer_id) DO NOTHING
RETURNING customer_id, variant, assignment_key;
