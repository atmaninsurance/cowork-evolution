# Prompt: Agent Workflow — Stage A build (Code worker + reviewer on a file queue)

**For:** a local Claude Code session on the Mac Studio, David-supervised (this build loads
launchd jobs — do NOT run unattended).
**Authored:** 2026-07-13, Cowork chat `remote_e98d7863`. **Parent item:** CLD-00043 (agent
coordination layer — this executes its Stage A as designed in that chat; v1 design pass of
2026-07-05 governs the folder-set/ACL/ledger shape). **Style:** CLD-00062 (phased, ⛔-gated,
supervised dry run before anything runs unattended).

**First act:** open a new action item (next free CLD ID — expected CLD-00069) titled
"Agent Workflow Stage A — Code worker + reviewer queue", **Project:** cowork-evolution,
**Scope:** business, **Related:** CLD-00043, CLD-00068, DEC-0069. Track this build there.

---

## Home and naming (David-ratified direction)

Root: **`~/Documents/Agent_Workflow/`** — sibling to The_Library / The_Wiki (the established
`~/Documents` commons pattern), because this becomes multi-agent in Stage B and must NOT live
inside any one agent's home (`~/Claude` is Cowork's; `~/.openclaw` is Alfred's). Names are
deliberately plain-English:

```
~/Documents/Agent_Workflow/
  README.md          ← the rules of the road (Phase 0 writes it; spec below)
  ledger.md          ← append-only run history, human-readable one-liners
  collected/         ← reviewer-gathered final outputs (the single orchestrator-side
                        collection point, per CLD-00043 v1 — David's prior decision)
  code/              ← the Stage-A consumer (Claude Code)
    inbox/           ← prompts waiting (anyone authorized may drop here)
    processing/      ← at most ONE claimed prompt (claim = atomic rename into here)
    outbox/          ← finished prompts with a ## Result section appended
    artifacts/       ← files a task produces (referenced from its Result)
  alfred/            ← created empty now, activated in Stage B (same subfolder shape)
  _meta/
    schema.md        ← prompt-file format (below)
    screen.py        ← safety screen (below)
    prompt-template.md
```

Git: init as a **private repo `agent-workflow`** (nightly author identity; David creates the
GitHub remote or authorizes `gh repo create`). Add to the nightly Stage-5 sweep roster so
history is pushed nightly. **PHI-free by construction** — this repo syncs; prompts must never
carry client data (screen.py enforces a lint).

## Prompt-file schema (`_meta/schema.md`)

Filename: `NNN-<slug>.md` (zero-padded queue number + slug, e.g. `001-wiki-authoring-session.md`).

```markdown
---
id: NNN-<slug>
status: queued | processing | done | failed | dead-letter
priority: 1-5            (1 highest; ties broken by NNN)
depends_on: []           (list of ids that must be status:done in outbox/)
timeout_minutes: 30      (default; hard cap 120)
max_attempts: 2
attempts: 0
model: sonnet            (default sonnet; opus only when the task warrants it)
requested_by: david | cowork | code
created: YYYY-MM-DD
---
# <Task title>

<The prompt body — complete, standalone instructions, exactly as if typed into claude -p.
Must state its deliverable and where artifacts go (artifacts/<id>/).>
```

Worker appends `## Result` (summary, artifact paths, exit status) on completion; reviewer
appends `## Review` (assessment, follow-ups) before moving to `collected/` awareness.

## Phase 0 — Scaffold (no automation yet)

1. Create the tree above; write `README.md` covering: purpose (Stage A of CLD-00043), the
   lifecycle (inbox → processing → outbox → reviewed), write ACL (ONLY David, Cowork chats,
   and Code sessions may create inbox files; Alfred neither reads nor writes anything here
   until Stage B is formally activated), the schema pointer, and the safety rules (below).
2. Write `_meta/schema.md` + `_meta/prompt-template.md` per the schema above.
3. git init + first commit; wire the remote; add the repo to the Stage-5 sweep roster
   (edit the roster the same way prior roster additions were made; note it in the ledger).

⛔ **GATE A: show David the tree + README before Phase 1.**

## Phase 1 — Safety screen (`_meta/screen.py`)

Mechanical, no-LLM checks run by the worker BEFORE executing any claimed prompt (and available
standalone). Reject → status `failed`, reason in ledger, file back to inbox with `screen_failed`
note. Checks:

- Frontmatter parses; required fields present; timeout ≤ 120; model in {sonnet, opus}.
- `requested_by` present and in the allowlist (david | cowork | code).
- **Task-type allowlist v1:** body must not instruct git push/force-push outside sweep
  conventions, must not touch `~/.openclaw/`, Alfred's constitutional docs (AGENTS/IDENTITY/
  SOUL), `~/Claude/memory/MEMORY.md` startup protocol, launchd plists, or credentials/secrets.
  Implement as deny-pattern grep list in screen.py — conservative, expandable.
- **PHI lint:** reuse The_Wiki's `_meta/lint.py --phi` pattern (names/DOB/policy-number
  regexes + keyword screen) against the whole prompt file.
- Size cap: prompt body ≤ 32KB (decomposition discipline — CLD-00039's lesson applies to
  Code too).

Unit-test screen.py (accept-case, each reject-case) before Phase 2.

## Phase 2 — Worker

`worker.sh` + `com.cowork.agent-worker` LaunchAgent:

- **Trigger:** launchd `WatchPaths` on `~/Documents/Agent_Workflow/code/inbox` +
  `StartCalendarInterval` hourly fallback + `ThrottleInterval` ≥ 300s.
- **Mutual exclusion:** `worker.lock` (mkdir-style, like `nightly.lock`); additionally
  **stand down without retry between 22:30–00:30 PT** so the worker never competes with the
  23:00 nightly chain.
- **Claim + drain loop:** oldest eligible file (all `depends_on` done; priority order;
  `processing/` must be empty — serial v1, one prompt in flight globally) atomically `mv`
  into `processing/`, bump `attempts`, set `status: processing`. On completion the worker
  IMMEDIATELY attempts the next eligible claim and repeats — draining the queue serially in
  one wake — stopping only when no eligible prompt remains, the daily cap is reached, or the
  stand-down window begins. Delivery is decoupled from execution: the inbox may be loaded
  with an entire batch at once; `priority`/`NNN`/`depends_on` encode the order.
- **Screen:** run `screen.py`; reject path per Phase 1.
- **Execute:** reuse the `run_claude` machinery from `cowork-nightly.sh` — startup-grace
  early-kill (`CLAUDE_STARTUP_GRACE=240`), retry-once semantics driven by the prompt's
  `max_attempts`, kill-time JSONL forensics, per-run log in `~/Claude/Scheduled/nightly/logs/`
  namespace or a local `Agent_Workflow/logs/` (prefer local logs/ + gitignore). Extract
  `run_claude` into a shared `_lib/run_claude.sh` sourced by both cowork-nightly.sh and
  worker.sh rather than copy-pasting — keep one implementation (refactor cowork-nightly.sh to
  source it; verify the nightly still passes its preflight after the refactor).
- **Timeout:** hard kill at `timeout_minutes`; heartbeat = the session's JSONL mtime (no
  output growth for >grace ⇒ silent-hang class ⇒ early kill; same CLD-00068 logic).
- **Outcome:** append `## Result`; set status done/failed; `mv` to `outbox/`; failed with
  attempts remaining → back to `inbox/` (retains NNN, keeps queue position); attempts
  exhausted → `status: dead-letter`, stays in `outbox/`, ledger line flags it.
- **Ledger:** one line per event (claim, screen-reject, done, failed, dead-letter) in the
  run-ledger.md style.

⛔ **GATE B: David reviews worker.sh + plist BEFORE `launchctl load`. Load with the worker
pointing at an EMPTY inbox first; verify a clean no-op ledger line.**

## Phase 3 — Reviewer

`reviewer.sh` + `com.cowork.agent-reviewer` LaunchAgent (twice daily, e.g. 08:00 + 16:00 PT —
outside the worker's stand-down window):

- Reads `outbox/` entries lacking `## Review` + the ledger since its last mark.
- For each: audit result vs the prompt's stated deliverable (claude -p, sonnet, its own
  timeout via the shared run_claude); append `## Review` (assessment; follow-up
  recommendations). Follow-ups it recommends are written as NEW inbox prompt files with
  `requested_by: code` — they pass the same screen; the loop closes but always through the
  screen.
- Housekeeping: stale `processing/` claim past timeout+grace → mark failed/requeue per
  attempts (this is the backstop if the worker died mid-claim); `done`+reviewed outputs'
  artifacts referenced into `collected/` (copy or index — reviewer's judgment, note in README).
- Escalation: hard failures (dead-letter, repeated screen rejects, worker absent >24h) →
  `ATTENTION-<date>.md` at the Agent_Workflow root, FAIL-only (DEC-0075 philosophy); FLAG-level
  goes in the ledger for session-start triage.

v1 restraint: reviewer RECOMMENDS requeues in its Review notes but only performs the stale-claim
cleanup mechanically; broader autonomy graduates later.

⛔ **GATE C: David reviews reviewer.sh + plist before load.**

## Phase 4 — Supervised dry run (David present)

Seed three test prompts:
1. `001-hello-artifact` — trivial: write a one-line artifact file. Expect: claim → done →
   outbox with Result → reviewer Review → collected.
2. `002-timeout-probe` — a prompt engineered to exceed a 2-minute timeout_minutes. Expect:
   kill at timeout, forensics logged, retry once, dead-letter at attempts=2, ATTENTION only if
   the spec says dead-letters raise one (they do: first dead-letter per day raises ATTENTION).
3. `003-screen-reject` — a prompt violating the deny-list. Expect: screen reject, never
   executed, ledger line.

All three behave → ⛔ **GATE D: David approves unattended operation** → leave both agents
loaded. Record the whole build as a DEC (extends DEC-0069; executes CLD-00043 Stage A;
threshold test per DEC-0071 — this alters standing automation, it clearly rises to a DEC).
Update CLD-00043 (Stage A live; Stage B criteria: CLD-00058 + CLD-00023 landed + CLD-00039
rule in place) and close the new build item.

## First real queue load (after Gate D)

Seed from the 2026-07-13 sequencing assessment, in order: wiki authoring session prep
(inventory + drafts for David's [WIKI-QUESTION]s), stale-item sweep (report-only:
recommend close/keep for the ~14 legacy ALF/CLD items, David triages), OpenAI BAA/HIPAA
research pass (CLD-00065 gate), Google Gemini BAA verification research (CLD-00058 sub-gate).
All research/report tasks — no state mutations — the right risk profile for week one.

## Session model + transcript/EOD hygiene

**One fresh `claude -p` session per prompt** — the worker script persists across a drain, but
every task executes in its own headless Code session (own context, own JSONL). No context
carries between tasks; continuity comes from the filesystem (outbox Results, artifacts/, the
memory store), never from session memory — files-canonical, and it keeps any one task's
context bounded (the CLD-00020/00039 accumulation class can't occur across tasks).

Consequences to wire in:
- The SessionEnd hook (DEC-0076) will auto-reconstruct a `code/` transcript per task session —
  fine and free. But these are DELEGATED-WORK sessions, not user chats: extend the
  chain-internal exclusion (`CHAIN_INTERNAL_RE` in `lint-transcripts.py` + the EOD discovery
  exclusions) so queue worker/reviewer sessions are excluded from daily-log chat discovery.
  Give every worker-launched prompt a recognizable first line ("Agent Workflow queue task
  <id> — delegated execution, not a user chat") that the regex can key on.
- Queue activity reaches the daily log as ONE summary line synthesized from the ledger (EOD
  can do this from run-ledger-style entries), not as per-session `## Chat:` sections.
- Each retry is a FRESH session (attempt 2 never inherits attempt 1's poisoned context); the
  prior attempt's JSONL stays on disk for forensics.

## Cost note

Each prompt is one `claude -p` session. Default model sonnet keeps routine queue work cheap;
reserve opus via the frontmatter for genuinely hard tasks. The reviewer runs sonnet always.
David can cap daily throughput by simply not queueing more prompts; a mechanical daily cap
(e.g. worker refuses >6 runs/day) is a one-line guard worth including.
