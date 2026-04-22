# kilo-support-copilot-demo

A small demo repo that showcases [Kilo Code](https://kilo.ai/) driving a support-engineering
workflow: reproduce a seeded bug, diagnose it, and produce the artifacts a
real support team would hand off (repro note, root-cause summary,
customer-facing workaround, escalation ticket).

This is **lean v1**: one bug, two Kilo modes, no MCP. Bugs 2 and 3, a Fixer
mode with a regression test, and an MCP docs-lookup server are planned as
follow-ups.

## Layout

```
.
├── app/
│   ├── server/        Express + TypeScript API with one seeded bug
│   └── web/           Single static HTML login page (no build step)
├── .kilo/
│   ├── bugs/          Symptom descriptions (no cause hints), input for the Triager
│   └── templates/     Markdown templates for each support artifact
├── scripts/
│   └── repro-01.sh    Deterministic reproduction for bug 01
├── artifacts/         Where the Triager and Scribe write their output
└── .kilocodemodes     (coming next) Kilo custom modes: triager, scribe
```

## Running the app manually

```
cd app/server
npm install
API_KEY=my-shell-key npm start
```

Then open http://localhost:3000 and try logging in with `my-shell-key`.

(Expected outcome for v1: you see `authentication failed`. That's the bug.)

## Reproducing bug 01

```
./scripts/repro-01.sh
```

The script starts the server with an API key set in the shell, POSTs a login
request using the same key, and exits non-zero if the bug doesn't reproduce.

## The demo workflow

1. **Triager** (read-only) reads `.kilo/bugs/01-auth-config.md`, runs the
   repro script, traces the cause by reading source, and writes
   `artifacts/repro-note.md`.
2. **Scribe** (read + write scoped to `artifacts/`) reads the repro note and
   the code, then writes `artifacts/root-cause.md`,
   `artifacts/customer-workaround.md`, and `artifacts/escalation-ticket.md`.

Both modes will be defined in `.kilocodemodes` once we've verified the schema
against Kilo's source.

## Status

- [x] Buggy server
- [x] Static login page
- [x] Repro script
- [x] Bug symptom file
- [x] Artifact templates
- [ ] `.kilocodemodes` (pending schema check)
- [ ] Demo recording

## Follow-ups (not in v1)

- Fixer mode + regression test for bug 01
- Bug 02 (API/backend race) and Bug 03 (UI stale closure)
- MCP docs-lookup server used by the Scribe for citations
