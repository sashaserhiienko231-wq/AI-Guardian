# Gmail message scanning add-on

AI Guardian includes an optional Google Apps Script add-on for scanning the
message currently open in Gmail. Opening a message only displays the add-on
card. The add-on does not read or send message content until the user clicks
**Analyze this email**. It does not poll the inbox, scan unopened mail, or send
push notifications.

## What is sent and stored

After the user clicks the scan button, the add-on sends the sender, subject,
plain-text body (up to 100,000 characters), and the `Authentication-Results`,
`Reply-To`, and `Return-Path` headers to the configured AI Guardian backend over
HTTPS. The backend currently saves scan findings and a summary, not the email
body, subject, sender, or headers. The add-on displays the result inside
Gmail. It does not send scan results to the Flutter app.

Only configure a backend you control and trust. Use an HTTPS endpoint, protect
it against abuse, and review its database access and retention before sending
real messages.

## Create a test add-on

1. Deploy the AI Guardian FastAPI backend at a reachable HTTPS URL. The URL
   should be the API base, such as `https://guardian.example.com`, not the
   `/api/v1/scanner/email` endpoint. A local `localhost` backend is not
   reachable from Apps Script.
2. Create a standalone project at [script.google.com](https://script.google.com).
3. In **Project Settings**, enable **Show "appsscript.json" manifest file in
   editor**. Replace the generated `appsscript.json` with the file in
   `integrations/gmail-addon/`, and add `Code.gs` with the other file from that
   directory.
4. In the Apps Script project settings, link the script to your standard Google
   Cloud project by its project number. Configure Google Auth Platform
   branding/audience there. For personal Gmail testing, set the audience to
   **External** and add your account as a test user. No separate OAuth client
   ID or client secret is needed for this Apps Script add-on.
5. In **Project Settings → Script Properties**, add:
   - Property: `AI_GUARDIAN_API_BASE_URL`
   - Value: your backend's HTTPS base URL
6. Save the project. In **Deploy → Test deployments**, select **Install** and
   authorize the requested Gmail current-message and external-request scopes.
7. Open Gmail, open a message, launch the AI Guardian add-on, and click
   **Analyze this email**. The first authorization or add-on refresh may require
   reopening the message.

The add-on requests `gmail.addons.current.message.readonly`, which limits
message access to the current Gmail context rather than requesting full
`gmail.readonly` inbox access. Google classifies add-on scopes and app
verification requirements; review Google's current
[Gmail add-on scopes](https://developers.google.com/workspace/add-ons/concepts/workspace-scopes#gmail_add-on_scopes)
and [Gmail API scope guidance](https://developers.google.com/workspace/gmail/api/auth/scopes)
before distributing it beyond test users.

This is a user-triggered scan, not automatic inbox monitoring. Automatically
scanning new mail would require broader Gmail access and a separately secured
notification backend. It is intentionally not enabled here.
