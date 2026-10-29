// WF-01, Code node "Decide Next Best Action" (Run Once for All Items). Policy v1.
// Deterministic rules only: consent is a hard stop, no discount by default.
return $input.all().map(item => {
  const c = item.json;
  const days = Number(c.days_since_last_order);
  let action, reason;
  if (c.consent_status !== 'opted_in') {
    action = 'no_action';
    reason = 'Consent missing - hard stop';
  } else if (days <= 7) {
    action = 'no_action';
    reason = 'Ordered recently - suppress from win-back';
  } else {
    action = 'personalized_reminder';
    reason = 'Previously frequent, order rate declining';
  }
  return { json: { ...c, next_action: action, reason: reason, discount_pct: 0,
                   expected_discount_cost: 0, policy_version: 'v1', approval_status: 'pending_approval' } };
});
