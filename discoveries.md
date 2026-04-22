# Discoveries

A running log of nuances, gotchas, and non-obvious facts collected while
building this demo. Each entry answers two questions: **what did we find?**
and **why does it matter for someone building a similar demo?**

The format is deliberately blunt so future readers (including future me) get
both the conclusion and the reasoning behind it, not just polished marketing
prose.

---

## Kilo custom agents

### 1. `.kilocodemodes` is outdated. The current path is `.kilo/agents/<name>.md`.

**What we thought:** based on older Kilo and Roo Code conventions, agents
were defined in a single JSON file called `.kilocodemodes` at the project
root.

**What we found:** the current format is one markdown file per agent, at
`.kilo/agents/<name>.md` for project-level agents or
`~/.config/kilo/agent/<name>.md` for global ones. Verified against the
official docs at [kilo.ai/docs/customize/custom-modes](https://kilo.ai/docs/customize/custom-modes)
and against `packages/opencode/src/config/config.ts` in the kilocode source.

**Why it matters:** writing a config in the old format means Kilo either
skips it silently or errors on startup. Either way the demo agent does not
show up in the picker, which is a bad surprise during a recording. Always
verify the loader path before writing the config file.

### 2. The markdown body *is* the system prompt.

**What we thought:** the prompt would live in a `prompt` field in the
frontmatter, the way most agent frameworks do it.

**What we found:** the `prompt` field exists in the schema but is ignored
by the loader in practice. The markdown body of the file (everything after
the closing `---` of the frontmatter) is what the agent uses as its system
prompt.

**Why it matters:** this actually makes writing good prompts easier. You get
real headings, bullet lists, code blocks, and inline examples with no JSON
escaping or `\n` noise. It also means you should not try to "configure" the
agent through frontmatter fields that do not exist.

### 3. Permissions are per-tool, not per-group.

**What we thought:** following older Roo-style conventions, permissions
would be groups like `read`, `edit`, `bash`, `browser`, `mcp`, assigned as
a flat list: `groups: ["read", "bash"]`.

**What we found:** Kilo models permissions per individual tool name, with
`allow` / `deny` / `ask` actions and optional glob-pattern scoping. The
schema lives in `packages/opencode/src/config/config.ts` around lines 504
to 534.

Example of what the current shape looks like:

```yaml
permission:
  read: allow
  bash:
    "./scripts/repro-*.sh": "allow"
    "*": "deny"
  edit:
    "artifacts/*": "allow"
    "*": "deny"
```

**Why it matters:** per-tool scoping is more precise than groups. A Triager
can have bash access for specific repro scripts only, without opening up
arbitrary command execution. That precision is what makes the
agent-level permission story credible rather than hand-wavy, and it's a
selling point worth calling out in the demo.

### 4. The `mode` field is an enum with meaningful semantics.

The `mode` frontmatter field takes one of three values:

- `primary`: user-selectable from the agent picker in the UI.
- `subagent`: only reachable via delegation from another agent (through
  the `task` tool).
- `all`: both of the above.

**Why it matters:** for v1 both Triager and Scribe are `primary` because
the user manually switches between them. If a later version had Triager
invoke Scribe automatically, Scribe would become `subagent` (or `all`),
and Triager would need `task: allow` in its permissions.

---

## Prompts

### 1. Format does not fix prompt quality.

Moving from `.kilocodemodes` (JSON) to `.kilo/agents/<name>.md` (markdown
body) made prompts **easier to write**, not **easier to get right**. The
container changed; the words that shape agent behavior did not.

**Why it matters:** do not mistake "the file loads successfully" for "the
agent behaves well." A Triager with a vague prompt will produce a vague
repro note regardless of whether it's stored in JSON or markdown. Test
the prompt by running the agent against the seeded bug, then iterate on
wording, not on config.

### 2. Prompt failure modes we're watching for

For the **Triager**:

- If the prompt does not enforce "trace to source before hypothesizing,"
  the agent will guess from the symptom and write a plausible-sounding
  but wrong repro note.
- If the prompt does not require `file:line` citations for every claim in
  the trace section, the trace becomes vibes.
- Without explicit confidence language, the agent will not flag when it
  is unsure, which makes the repro note unreliable.

For the **Scribe**:

- If the prompt does not clearly separate audiences, the customer
  workaround reads like an engineering memo and the escalation ticket
  gets diluted with customer-friendly hedges.
- Without an explicit "do not propose or implement a code fix in v1"
  instruction, the agent tries to edit code, fails against the permission
  system, and produces a confusing session for the viewer.
- Without a tone guide, the customer message lands either too chirpy or
  too defensive.

These failure modes are why we're iterating on prompt bodies in chat
before baking them into files.

---

## The seeded bug

### 1. `dotenv.config({ override: true })` silently clobbers the shell env.

The bug in `app/server/src/config.ts` calls `dotenv.config({ override: true })`
for `.env.local` after loading `.env`. Default dotenv behavior does **not**
override existing environment variables, so values set in the shell
normally win. With `override: true`, the file value wins, which breaks the
common "shell env overrides defaults" mental model that most developers
carry.

**Why it matters for the demo:** this is a real mistake that shows up in
production codebases. It is also a bug that a read-only Triager can
diagnose by reading three files in order (`.env.local`, `config.ts`,
`server.ts`), which makes it an ideal first bug for showcasing an agent's
trace work. Too trivial and the agent looks unimpressive; too subtle and
the recording becomes a patience exercise.

---

## Artifacts and their scope

### 1. Not every artifact has the same scope.

**What we thought initially:** all five output artifacts (repro note,
root cause, customer workaround, escalation ticket, runbook) would be
written once per bug into a flat `artifacts/` folder.

**What we found by thinking about repeat reports:** artifacts fall into
two categories, and the difference matters for file organization.

- **Per-bug artifacts** describe the underlying issue. They live once
  per bug and accumulate ticket references as new customers report the
  same problem: `repro-note.md`, `root-cause.md`,
  `escalation-ticket.md`, `runbook.md`.
- **Per-ticket artifacts** are one-to-one with a specific customer
  interaction. `customer-workaround.md` belongs here: each customer
  gets their own version, named by them, quoting their ticket.

**Why it matters:** a flat `artifacts/` folder with generic filenames
breaks the moment a second ticket lands for the same bug. Our v1
organizes artifacts in a per-bug subdirectory
(`artifacts/01-auth-config/`) and reserves per-ticket filenames
(`customer-workaround-<ticket>.md`) for the one artifact that needs
them. The Triager's prompt explicitly handles the "repro note already
exists, this is a repeat report" case: append the new ticket ID, do
not rewrite the trace.

### 2. The runbook-as-output path leaves room for runbook-as-input later.

**What we considered:** should the runbook be an *input* to the Triager
(a library of past resolutions it checks before investigating), rather
than just an output of the Scribe?

**What we decided:** for v1, runbooks are outputs only. The input path
(a runbook library that accelerates future Triager runs) only pays off
when at least one runbook is already on the shelf before a new bug
arrives. Building the input plumbing in v1 means zero matches and zero
payoff in the first recording.

**Why it matters:** this keeps the architecture open. Each resolved bug
produces a runbook. When bug 02 lands in a follow-up post, the
Triager's prompt can start checking `.kilo/runbooks/` (or
`artifacts/*/runbook.md`) for pattern matches. When bug 03 matches an
existing runbook, the demo gets its compounding-value moment:
resolution time drops from minutes to seconds, and the LinkedIn story
shifts from "agent solves a bug" to "agent + accumulated runbooks
reduce support MTTR over time."

---

## Agent behavior gotchas

### 1. Silent tool failures get rationalized into fabricated success.

**What we observed:** during the first Triager dry-run, the agent
produced a high-quality repro note as chat output, declared high
confidence, and stated that the note had been written to
`artifacts/01-auth-config/repro-note.md`. The file was never written.
Behind the scenes the edit-tool call kept erroring with "File not
found", the Read tool errored with "offset must be greater than or
equal to 1", and the agent retried a few times before producing a
final summary that spoke about the work as if it had landed.

**Why it happened:** two factors compounded.

1. The agent chose the wrong tool for the job. It reached for `edit`
   (which assumes an existing file) instead of `write` (which creates
   one). Nothing in our prompt distinguished the two.
2. The prompt did not tell the agent what to do when a tool failed.
   Without an explicit "stop and report" rule, the LLM's default
   behavior is to produce a satisfying final response, even if that
   means papering over the failure in chat.

A third, more pedestrian factor contributed: the parent directory
`artifacts/01-auth-config/` did not exist yet. We pre-create per-bug
subfolders now so the happy path is unobstructed.

**Why it matters:** this is the most dangerous class of failure in
agent workflows. The human operator sees a confident summary and
assumes the work landed. Unless you read the full tool-call trace or
open the expected output file manually, you will not notice. Any agent
prompt that does real file I/O needs three rules that we added after
this run:

- **Tool-selection:** use `write` for new files, `edit` for existing
  ones; do not call `edit` on a path that does not yet exist.
- **Fail loud:** if a tool call errors, stop and surface the exact
  error; do not retry silently, do not fabricate success.
- **Verify after writing:** before declaring done, list the output
  directory and confirm the expected files are on disk.

These rules are now baked into both `triager.md` and `scribe.md` in a
dedicated "File I/O rules" section.

### 3. Agents will fabricate work through any channel you give them.

**What we observed:** after the first dry-run failure, we added rules
telling the Triager to "fail loud, never fabricate" around file writes.
The next run's failure was the same shape, but wearing a different
costume. The agent created a todowrite list that included "Run the
repro script", then marked that todo as **completed** without ever
calling the bash tool. The chat summary spoke about the reproduction
in confident past tense; the execution trace showed zero bash
invocations.

**Why it matters:** "fail loud" is not a single-channel rule. Agents
have multiple ways to claim work is done: file writes, chat summaries,
todo checkmarks, self-reported progress, even their own final
responses. Guarding one channel just displaces the failure onto the
next. The rule has to be channel-agnostic: *if you did not call the
underlying tool, the work is not done, regardless of how you are
reporting it.* Both agents' prompts now say this explicitly.

### 4. Unlisted tools default to allowed, inviting scope creep.

**What we observed:** mid-investigation, the Triager decided to look
up Kilo's own configuration schema. It invoked a `skill` call for
`kilo-config`, followed by a `webfetch` to an external JSON-schema
URL. None of that had anything to do with the bug it was triaging.
Our permission block for the Triager never mentioned `skill`,
`webfetch`, or `websearch`, so Kilo's default behavior (permissive)
let the agent wander.

**Why it matters:** agent permissions must be modeled as
*deny-by-default*, not *allow-by-default*. Every tool the agent can
reach but should not needs an explicit `deny`. Listing only the tools
you want is not enough; Kilo (and most agent frameworks) will give
the agent whatever you did not explicitly close off. We now
`deny: webfetch, websearch, skill, task` on both Triager and Scribe,
and should keep adding explicit denies as new tools surface.

### 5. Convention mismatches cost the agent a few turns.

**What we observed:** the Triager prompt advertised a convention of
`scripts/repro-<bug-id>.sh`, which resolves to
`scripts/repro-01-auth-config.sh`. The actual file was named
`scripts/repro-01.sh`. The agent tried the prompt's convention, got a
"File not found", then eventually found the real path via the bug
symptom file, which named it explicitly.

**Why it matters:** even a small naming mismatch between what the
prompt promises and what the filesystem provides causes the agent to
burn turns and emit confusing errors. The fix is cheap: either match
the convention or write only one place that names paths (not both).
We renamed the script to follow the bug-id convention so filenames
scale to future bugs consistently (`repro-02-<slug>.sh`, etc.), and
the bash permission glob `./scripts/repro-*.sh` still matches.

---

## Permissions

### 1. Permission rules are evaluated in order, and the LAST match wins.

**What we thought initially:** glob rules in a permission block worked
like most allow-lists we've seen, where a specific allow beats a broad
deny, or where "most specific wins" is the tiebreaker.

**What we found (from Kilo's custom-modes docs):** *"Rules are
evaluated in order, with the last matching rule winning."* That means
the block

```yaml
bash:
  "./scripts/repro-*.sh": "allow"
  "*": "deny"
```

denies the repro script, because `*` matches too and is last. The
correct ordering is deny-first, allow-last:

```yaml
bash:
  "*": "deny"
  "./scripts/repro-*.sh": "allow"
```

**Why it matters:** this was the likely root cause of our earlier
"silent write failures" and the agent's refusal to run the repro
script. The `edit` block had the same inverted ordering for
`artifacts/**` vs `*`, so every write the Triager attempted was being
denied at the permission layer but surfaced through the toolchain as
misleading errors ("file not found", "offset must be..."). Fixed on
both agents. This is the single most dangerous permission gotcha we
have hit so far, because the failures do not look like permission
failures.

### 2. Three actions (`allow`, `ask`, `deny`), and `ask` is underused.

Kilo exposes three permission actions, not two. `ask` prompts the
user for approval at runtime. We have been writing `allow`/`deny`
everywhere, but `ask` is a useful middle ground, e.g. for bash
commands that are occasionally needed but shouldn't be silent. Worth
reaching for on any future agent that does potentially destructive
work.

### 3. Adjacent hardening mechanisms worth remembering.

From Kilo's docs, two mechanisms we have not used in v1 but should
know about:

- **`.kilocodeignore`** is a project-wide file-restriction mechanism
  that both file writes and bash commands are validated against.
  Useful for protecting secrets or build outputs. Note that our v1
  *needs* the Triager to read `.env.local` to find the bug, so we
  would not apply this indiscriminately.
- **Namespaced permission patterns for MCP tools**, e.g.
  `"github_create_pull_request": "ask"` alongside `"github_*": "deny"`.
  Will matter when we add the docs-lookup MCP server in a follow-up
  post.

### 4. Principle of least privilege is the explicit recommendation.

Kilo's own docs call out the principle of least privilege: start with
the minimum permissions the agent actually needs and widen only as
required. That is the operating posture we adopted from the start,
but it is worth logging that the framework authors agree, rather than
us picking it up from general security instincts. Deny-by-default,
explicit allow-lists, per-tool scoping, last-match-wins ordering.

---

## Process

### 1. Verify schema against source before writing config.

Docs can lag the code, especially for tools that ship new features on a
weekly cadence. For anything non-trivial (agent config, permission
system, MCP setup), the correct workflow is: check the docs for the
shape, then read the actual Zod schema or parser in the source, then
write the file. Skipping the source-verification step cost us the
`.kilocodemodes` detour.

### 2. Smoke-test the bug before recording.

Before writing agent prompts, confirm the bug actually reproduces
end-to-end with a single command. If the repro is flaky, the agent's
Triager output will be flaky too, and you will not know whether the
agent or the setup is at fault. The `scripts/repro-01-auth-config.sh` script exits
non-zero if the bug does not manifest, which gives us a binary signal.

---

*This is a living document. Each meaningful nuance hit while building
the demo should be added here, keeping the "what we thought / what we
found / why it matters" pattern so future readers get both the
conclusion and the reasoning.*
