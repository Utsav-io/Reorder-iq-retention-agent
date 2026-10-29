-- Human approval step (done manually for this project).
-- Recommendation: replace with an n8n approval form so a named person approves.
UPDATE action_recommendations
SET approval_status = 'approved'
WHERE next_action = 'personalized_reminder'
  AND approval_status = 'pending_approval';
