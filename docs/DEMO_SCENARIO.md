# 5–7 Minute Demo Scenario

## 1. Introduction — 30 seconds

Explain that AI Guardian helps users understand phishing links, QR codes,
password risks, and security reports.

## 2. Dashboard — 45 seconds

Open the dashboard and explain that values come from stored scan results.
Do not invent example statistics.

## 3. URL scanning — 1 minute

Enter `https://example.com/login`.
Explain that HTTPS alone is not proof of safety.
Show rule-based indicators and any ML disclosure.

## 4. QR Scanner — 1 minute

Upload a harmless QR image or decode plain text in the preview.
Show that plain or unknown content receives `UNKNOWN`, not `SAFE`.
Explain that no URL is opened automatically.

## 5. Password security — 45 seconds

Enter a sample password locally.
Explain that it is not sent to the backend or AI provider.

## 6. AI Assistant — 45 seconds

Ask "How can I recognize phishing?"
If no external provider is configured, demonstrate the local educational assistant.
Explain that answers are not verified findings.

## 7. Threat history — 45 seconds

Open history and demonstrate search/filter, detail, delete, or CSV export.
No password or email body is stored.

## 8. ML — 45 seconds

Explain that the model was trained on UCI PhiUSIIL.
State the test metrics and that probabilities are not confirmed threats.

## 9. Security mechanisms — 30 seconds

Mention private-IP and SSRF rejection, 1 MiB request limit, rate limiting,
production bearer configuration, and loopback Docker binding.

## 10. Conclusion — 30 seconds

Summarize tested builds and clearly state hardware and external provider limitations.
