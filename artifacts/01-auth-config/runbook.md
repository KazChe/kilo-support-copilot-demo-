## Runbook: API Key Login Issue

### Fingerprint
- **Log Message:** "auth: API key mismatch"
- **HTTP Status:** 401
- **Customer:** Acme Devtools Inc.

### Resolution Steps
1. Validate that `.env.local` does not override the expected `API_KEY` from the shell.
2. If necessary, update the `.env.local` to match the credentials required or remove conflicting entries.
3. Restart the server to apply changes.

### Notes
- Ensure engineering handles priority work on the variable precedence mechanism.
- Monitor for further reports of similar issues.