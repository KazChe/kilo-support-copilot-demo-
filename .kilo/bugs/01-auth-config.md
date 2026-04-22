# Bug 01 — login fails when API_KEY is set in the shell

## Reported by
Pretend-customer "Acme Devtools Inc." — support ticket #SUPPORT-4815

## Symptom (as reported)
> "I followed the README. I set `API_KEY=my-shell-key` in my shell, started
> the server, and tried to log in via the web UI and via curl. Both say
> 'authentication failed'. The key I'm sending matches what I set in the shell.
> What am I doing wrong?"

## Environment
- Server: `app/server/` on this repo, latest commit
- Node: whatever the repro script picks up
- Shell: bash or zsh
- OS: macOS or Linux

## What the customer tried
1. `export API_KEY=my-shell-key`
2. `cd app/server && npm start`
3. Open http://localhost:3000, paste `my-shell-key` into the API Key field, click Log In
4. Sees **authentication failed**

## Reproduction
`scripts/repro-01.sh` reproduces the failure deterministically. It starts the
server with `API_KEY=my-shell-key` exported in the environment, then POSTs
`Authorization: Bearer my-shell-key` to `/login`. Expected 200, observed 401.

## Ask of the Triager
1. Run the repro script and confirm the failure.
2. Trace the cause by reading the codebase (do not modify any files outside
   `artifacts/`).
3. Produce `artifacts/repro-note.md` following `.kilo/templates/repro-note.md`.
4. Do **not** implement a fix in v1. The fix lives in a later artifact.
