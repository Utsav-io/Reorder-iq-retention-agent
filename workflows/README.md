# n8n workflow exports

Put the exported workflow JSON files here:

- `WF-01_data_and_opportunity_detection.json`
- `WF-03_approval_and_assignment.json`
- `WF-04_measure_results.json`
- `WF-05_ai_brief.json`

In n8n: open the workflow, click the three dots (top right), choose **Download**. Import with **Import from File**.

Before committing, open each file in a text editor and search for `key`, `password`, `token` and `AIza` to confirm no secrets are inside. n8n exports reference credentials by name but do not normally include the secret itself.
