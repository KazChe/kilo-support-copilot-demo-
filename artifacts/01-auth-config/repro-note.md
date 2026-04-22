# Repro Note: 01-auth-config

## Reported in tickets

- SUPPORT-4815 (first report) — logged in via the web UI and via curl, both indicate 'authentication failed'.

*(This list is append-only. New tickets reporting the same underlying bug add a line here instead of creating a new repro note.)*

## Symptom (as reported)
"I followed the README. I set `API_KEY=my-shell-key` in my shell, started the server, and tried to log in via the web UI and via curl. Both say 'authentication failed'. The key I'm sending matches what I set in the shell. What am I doing wrong?"

## Environment
- Server: `app/server/` on this repo, latest commit
- Node: as determined by repro script
- Shell: bash or zsh
- OS: macOS or Linux

## Steps to reproduce
1. Execute `export API_KEY=my-shell-key`
2. Start the server: `cd app/server && npm start`
3. Attempt login via web UI or use curl with `Authorization: Bearer my-shell-key`

## Observed
- HTTP 401
- Server log: "auth: API key mismatch"

## Expected
- HTTP 200 with successful authentication message

## Evidence / trace
- `/Users/kam/development/KILO/app/server/src/server.ts:13` — Warning log 'auth: API key mismatch' when API key does not match.
- `/Users/kam/development/KILO/app/server/src/server.ts:14` — Responds with 401 if API key does not match.
- `/Users/kam/development/KILO/app/server/src/config.ts:8` — API key is fetched from environment variable `API_KEY`.

## Hypothesis
The API key comparison is failing because the shell's environment variable `API_KEY` is not being honored properly by the server or incorrectly fetched.

## Confidence
High — The direct comparison shows the mismatch as per server logs and response.