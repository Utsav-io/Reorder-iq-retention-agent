// WF-05, Code node "Parse Brief" (Run Once for All Items).
// Turns Gemini's text into JSON; if parsing fails the pipeline still saves the raw text.
const item = $input.first().json;
let raw = item.content?.parts?.[0]?.text ?? item.text ?? item.output ?? JSON.stringify(item);
raw = String(raw).replace(/```json|```/g, '').trim();
let ok = true, brief;
try { brief = JSON.parse(raw); } catch (e) { ok = false; brief = { error: 'parse_failed', raw: raw }; }
return [{ json: { experiment_id: 'EXP-001', brief: JSON.stringify(brief), parse_ok: ok } }];
