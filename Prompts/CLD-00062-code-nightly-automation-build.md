# CLD-00062 — Build Prompt: Code-Scheduled Nightly Automation

**Run in:** Claude Code (local CLI) on the Mac Studio, interactive session with David present for Phases 2–3.
**Authored:** 2026-07-09, chat `remote_4bd6fe76-e364-5844-90b3-ad9cc6777f4b` (platform-test-fresh-session).
**Design annex (read first):** `~/Documents/Projects/cowork-evolution/Design/code-scheduled-automation-architecture.md`
**Decision:** DEC-0069. **Tracking:** CLD-00062.

You are building the nightly automation chain that replaces Cowork's dead scheduled-EOD path: EOD compaction → transcript tooling → graph refresh → reviewed git sweep + push → ledger/alerting, orchestrated by one launchd-driven wrapper. The design annex is authoritative on scope and stances; this prompt is the execution order.

## Standing constraints (apply to every phase)

1. **Pacific dates everywhere** — read the clock with `TZ=America/Los_Angeles date`; never carry a date forward.
2. **Do NOT modify** `~/Claude/memory/rules/*`, MEMORY.md's startup protocol, or the Cowork Global Instruction. Where the design implies changes there, write a proposal file to `~/Documents/Projects/cowork-evolution/Design/proposed-rule-amendments-CLD-00062.md` for the pending joint review.
3. **Alfred's domain is out of bounds:** no writes under `~/.openclaw/` or to `alfred-workspace`; do not touch Alfred's cron/daily-close.
4. **Git discipline:** no force-push; The_Wiki commits must pass `~/Documents/The_Wiki/_meta/lint.py` (blocking); commit messages follow the existing repo conventions; author attribution per DEC-0061 item 5.
5. **Stop-and-ask gates** are marked ⛔ — get David's explicit OK in-session before proceeding past one.
6. Keep a running work log; at the end of each phase append a summary to today's daily log under `## Chat: CLD-00062-build` (create the section on first write).

## Phase 0 — Inventory (read-only)

1. **Existing LaunchAgents/daemons for this user:** list `~/Library/LaunchAgents/` (+ `launchctl list` filtered to non-Apple). Identify the graph-refresh agent (23:25 PT, runs `refresh.py`, commits corpus — DEC-0027/0029). Record its label, plist path, exact program arguments, and what it commits.
2. **Claude Code local session records:** confirm where this machine's Code sessions persist (expect JSONL under `~/.claude/projects/<encoded-cwd>/`). Record path pattern, one sample's structure (roles, tool calls, timestamps), and whether historical sessions back to ~2026-05 survive.
3. **Desktop-app Cowork cache investigation:** under `~/Library/Application Support/Claude/`, determine whether remote-architecture Cowork sessions leave any local record (old `local-agent-mode-sessions/` path or successor). Read-only; report what exists and its freshness. This decides whether a Cowork transcript compare-and-fix is ever buildable.
4. **Repo roster verification:** for each repo in the design's table, confirm path, remote, branch, cleanliness, and any existing hooks (esp. The_Wiki pre-commit PHI lint). Flag any repo with uncommitted work older than 7 days.
5. **Runtime preflight:** `claude --version`; confirm `claude -p "echo test"`-style headless invocation works unattended (note auth source + model used + approximate cost signal); check pmset/sleep schedule; confirm Ollama availability for `refresh.py`.

⛔ **Gate 0:** present the inventory to David — especially (a) the existing graph agent's commit behavior, (b) whether Cowork local cache exists, (c) repo roster confirmation, (d) the headless-auth result. Get sign-off on the roster and on absorbing the graph agent's commit step.

## Phase 1 — Build (assets only; nothing scheduled yet)

Create `~/Claude/Scheduled/nightly/` containing:

1. `cowork-nightly.sh` — orchestrating wrapper: lock file (abort with FAIL line if held); per-stage invocation in design order; per-stage ledger line (`<date> <stage> OK|FLAG|FAIL — <one clause>`) written even on crash (trap); wrapper start/end lines; `ATTENTION-<date>.md` flag file on any FLAG/FAIL.
2. `eod-prompt.md` — the Stage 1 EOD prompt for `claude -p`. Thin launcher per CLD-00046: it points at `~/Claude/memory/processes/end-of-day-compaction.md` (which you will update in Phase 4) and enumerates only the environment deltas: local filesystem access, no session_info (skip closing-turn backfill; leave `<pending>` intact), no git, own transcript to `code/`, exclude own session from discovery, idempotency tags.
3. `export-code-transcripts.py` — deterministic Code-session JSONL → `~/Claude/transcripts/code/<UUID>.md` exporter/true-up (create missing, append missed turns, never rewrite existing content; follow the live-transcribe file format incl. sentinel). Model on the CLD-00040 tool-suite approach; no LLM in the loop.
4. `lint-transcripts.py` — integrity lint per the design (sentinel continuity, headers, `<pending>` census, daily-log ↔ transcript cross-check). Output: machine-readable summary + ledger line; violations also produce a `[COMPACTION-ISSUE]` line in today's daily log.
5. `git-sweep-prompt.md` — Stage 4 prompt for `claude -p`: per-repo reviewed commit per the design's anomaly rules and hard gates, then push + verify remote ref; per-repo ledger detail.
6. `com.cowork.nightly.plist` — LaunchAgent (23:00 PT), pointing at the wrapper, with stdout/stderr captured to `~/Claude/Scheduled/nightly/logs/`. Write it in the folder; do NOT load it yet.
7. `README.md` — one page: what runs, when, where the ledger is, how to run each stage manually, how to disable (launchctl unload), failure-mode table from the design.

Unit-test the two Python tools against copies in a temp dir before touching real transcripts.

⛔ **Gate 1:** walk David through the assets (esp. one sample reviewed-commit plan and one exporter output diff).

## Phase 2 — Supervised dry run (David present)

1. Run `export-code-transcripts.py --dry-run` then live on real data; verify `code/` outputs.
2. Run `lint-transcripts.py`; review findings together (expect `<pending>` census + any CLD-00049-class gaps).
3. Run the EOD stage manually via `claude -p` in **dry-run mode** (add a DRY-RUN preamble: report intended writes, write nothing). Review its plan.
4. Run the git sweep prompt in dry-run (show would-commit diffs per repo; do not commit).
5. Fix what the dry run surfaces; repeat until clean.

⛔ **Gate 2:** David approves going live.

## Phase 3 — First live night

1. Load the LaunchAgent; if the graph agent's commit step is being absorbed (per Gate 0 decision), disable that step the same evening — never both live on one night.
2. Let the 23:00 run execute unattended.
3. **Next morning verification (with David or solo):** ledger complete, daily log finalized + tomorrow-skeleton present, transcripts exported/linted, repos committed AND pushed (verify remote refs), no ATTENTION file — or triage it.

## Phase 4 — Documentation and governance closure

1. Update `~/Claude/memory/processes/end-of-day-compaction.md` (Code environment: discovery, no session_info, no commit, tooling stages) and `processes/live-transcribe.md` (EOD-backfill references → new reality; Storage note).
2. Retire `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` to a pointer stub → `nightly/README.md` (CLD-00046 applied).
3. Update `~/Documents/Projects/cowork-evolution/COWORK-ARCHITECTURE.md` (nightly-automation section; graph-agent change) and COWORK-ROADMAP.md if stage-relevant.
4. Action items: **close CLD-00051** (commit automation live); update **CLD-00045** (EOD moved local; note what the new EOD does/doesn't capture cross-space); update **CLD-00046** (first applied instance); update **CLD-00062** phases as completed; reconcile `_index.md` per the always-inline rule.
5. Write the proposal file for rule/startup-protocol amendments (constraint 2) if not already written.
6. Final commit of all the above through the new Stage-4 sweep itself (its first real workload), then report: assets built, first-night results, docs updated, proposals pending joint review.

## Success criteria

- Two consecutive unattended nights with a complete ledger, finalized daily logs, exported/linted transcripts, and pushed repos.
- No writes to rules/, no Alfred-domain touches, no force-pushes, no PHI-lint bypass.
- CLD-00051 closed; proposals for the joint review delivered.
