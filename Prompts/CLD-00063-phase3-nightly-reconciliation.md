# Code Session Prompt — Nightly-Chain Reconciliation (CLD-00063 Phase 3 + CLD-00062 Phase 4)

**Authored:** 2026-07-11 (Cowork chat `remote_5fbe34b8-8763-5946-8a82-8d4fe5621f3f`, memory-design-action-items-review)
**Execute in:** Claude Code on the Mac Studio, David supervising (⛔ gates below)
**Timing note:** intended to run before the Fable 5 window closes (Sun 2026-07-12, 11:59 PM PT). Tonight's 23:00 nightly (night-3) then serves as the live verification of these changes.

---

## Who you are / context load

You are Claude Code working in David's memory-automation estate. Before touching anything, read:

1. `~/Claude/memory/action-items/CLD-00063-260710-Open.md` — the converter/true-up item; Phase 3 is this session.
2. `~/Claude/memory/action-items/CLD-00062-260709-Open.md` — the nightly-chain item; Phase 4 remainder is this session.
3. `~/Claude/Scheduled/nightly/README.md` + the assets in that directory (wrapper `cowork-nightly.sh`, exporters, `lint-transcripts.py`, `_transcript_common.py`, `export-remote-transcript.py`, EOD + sweep prompts, plist).
4. `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md` — DEC-0069 (nightly chain), DEC-0070 (remote transcript protocol), DEC-0071 (decision-capture + no-stub deprecation), DEC-0073/0074 (lifecycle triggers).
5. `~/Claude/memory/reference/remote-cowork-platform.md` — platform mechanics.
6. `~/Claude/memory/processes/live-transcribe.md` §Remote capture mode — the format/ownership context for remote transcripts.

Standing constraints: Pacific dates read from the clock (`TZ=America/Los_Angeles date`), never estimated. No PHI anywhere in this estate. Git IS sanctioned for you (DEC-0024) — but commit at the end with David's go-ahead, not incrementally. Work on copies when testing destructive paths.

---

## Part A — CLD-00063 Phase 3 (converter/lint reconciliation)

### A1. Lint full-UUID sentinel fix

`_transcript_common.py`'s `SENTINEL_RE` requires an 8-hex-char prefix (`APPEND_([0-9a-fA-F]{8})_AFTER_TURN_`), but remote transcripts embed the **full UUID** in their sentinels. The 2026-07-11 lint run produced 3 "no sentinel at foot" FALSE POSITIVES on remote files. Fix: accept both forms (see `ANY_SENTINEL_RE` in `export-remote-transcript.py` — `([0-9a-fA-F-]+)` — for the working pattern). Make the change once in the shared lib if the lint reads through it; verify no other consumer depends on the 8-char capture group's exact width.

**Acceptance:** re-run `lint-transcripts.py` over the corpus → the 3 remote false positives clear; zero new findings on legacy `local_`/`code/` files.

### A2. Ownership mode for remote transcripts

The tooling knows two file classes: hand-authored (never rewrite) and `TOOL_OWNED_MARK` (free to fully regenerate). Remote converter-maintained files are neither. Define a third mode — working name `live-deterministic` — detected from the Capture-mode header line (remote files say "Remote deterministic converter…"). Semantics: **append-only true-up is legitimate; full regeneration is not; hand `[note:]` blocks and the header are preserved.** The nightly exporter must NOT treat `remote_` files as its targets (no Mac-side source exists for them; the nightly is verifier-only per DEC-0070 item 5). Encode the detection in `_transcript_common.py`, apply in lint + both exporters.

**Acceptance:** lint classifies remote files as live-deterministic (not hand, not tool-owned); exporters skip them; a doc line lands in the nightly README.

### A3. Enable legacy `--backfill-closing`

Ratified by David 2026-07-10 ("automation owns transcript fixes — I will not review transcripts"), paused pending night-2 validation, which PASSED 2026-07-11. Enable the flag in the Stage-1 exporter invocation for legacy surfaces: fill **both** gap types — missing closing turns AND unresolved `<pending>` assistant bodies (~57 corpus-wide) — each stamped with an inline backfill provenance marker.

⛔ **Gate A:** before the live enable, run once in `--dry-run` (or equivalent) and show David the counts (files touched, closing turns filled, `<pending>` blocks resolved, any file where no source JSONL exists). Proceed on his OK. Files with no recoverable source are left untouched and listed, not guessed at.

**Acceptance:** flag live in the wrapper's Stage-1 line; dry-run counts reviewed; spot-check 2–3 backfilled files for marker presence and untouched hand prose.

### A4. ATTENTION trim

Alerting drops to hard-FAIL only. FLAG-level findings stay in the ledger/lint report but no longer generate the ATTENTION surface; triage of FLAGs becomes the agent's duty at next session start (note this in the nightly README and in the ATTENTION file format doc if one exists). Ledger and logs unchanged.

**Acceptance:** a FLAG-only run produces no ATTENTION file; a simulated FAIL still does (test the branch, don't just read it).

### A5. MCP write/edit semantic summaries in the converter

`_transcript_common.summarize_input()` gives native `Write`/`Edit` a semantic summary (path + size, content omitted) but MCP equivalents render at full size — so transcript-push payloads re-embed transcript content inside the transcript. Extend the name matching to at least: `mcp__remote-devices__Filesystem__write_file`, `mcp__remote-devices__Filesystem__edit_file`, `mcp__remote-devices__Desktop_Commander__write_file`, `mcp__remote-devices__Desktop_Commander__edit_block` (match on suffix so proxy-prefix changes don't break it; extract `path` and content-size where the schema provides them). Canonical copy at `~/Claude/Scheduled/nightly/` is what future chats bootstrap-copy — already-running chats keep their old container copies, which is fine.

**Acceptance:** unit-style spot test: feed a synthetic `tool_use` record for each mapped name through `summarize_input` → summary, not full content.

---

## Part B — CLD-00062 Phase 4 remainder (docs / governance / closures)

### B1. Doc updates

- `~/Claude/memory/processes/live-transcribe.md`: fix stale EOD/Storage references (the Storage section's "outside any git repo" note and the Related-artifacts EOD pointers) to match the DEC-0069/0070 reality.
- `COWORK-ARCHITECTURE.md` / `COWORK-ROADMAP.md` (in `~/Documents/Projects/cowork-evolution/`): record the nightly chain as live (DEC-0069) and the remote transcript protocol (DEC-0070).
- Reconcile the design-annex deviations noted in CLD-00062 Phase 4: stage order (export-before-EOD), content-date discovery, Cowork-exporter scope addition — annex gets a "as-built deviations" note, not a rewrite.
- Rule-amendment proposal file: verify nothing remains to propose — most of DEC-0069's deferred amendments landed via CLD-00064/DEC-0070. If anything is genuinely still un-proposed, list it for David rather than applying.

### B2. Legacy EOD SKILL retirement + double-fire decision

⛔ **Gate B (David decision, ask before acting):** the legacy desktop Cowork EOD scheduled task still exists and was still functional as of 2026-07-10. Night-2 ran clean, so the chain is trusted. Ask David: disable the legacy scheduled task now? On his YES: disable it, then retire the legacy EOD SKILL per the **DEC-0071 no-stub convention** — move to `_deprecated/` with a banner pointing at `~/Claude/Scheduled/nightly/` + `processes/end-of-day-compaction.md`, no stub left at the old path, and run the reference sweep (grep the estate incl. automation surfaces for pointers to the SKILL/scheduled task; update or flag each). On his NO: leave both, note the deferral in CLD-00062.

### B3. Action-item closures and updates (with `_index.md` maintained inline, per the always-load rule)

- **CLD-00051** — close (Code-driven git sweep is live: night-2 committed AND pushed all rosters). Move to `closed-items/2026/` with closure note; remove index line.
- **CLD-00045** — update: nightly EOD is now the transcript-capture verifier; the multi-space question is restated against the new architecture (remote chats self-flush per DEC-0070/0073/0074; EOD synthesizes from flushed transcripts). Close it if David agrees the original concern is structurally moot; otherwise annotate.
- **CLD-00046** — update: EOD thin-launcher applied (eod-prompt.md → process doc); note the SKILL outcome from Gate B; the "codify as convention" remainder either closes (if you and David judge DEC-0071 + the applied instances sufficient) or stays with a narrowed scope.
- **CLD-00062** — mark Phase 4 complete; if nothing else remains, close it (night-3 verification note: tomorrow morning's check is the standing verifier now).
- **CLD-00063** — mark Phase 3 complete. Remaining open unknowns (reclaimed-container wake, resumed-chat JSONL rehydration — the hard recoverability boundary) are NOT Phase 3 scope: ask David whether to keep CLD-00063 open to hold them or close it and open a slim successor item. Either way the index reflects it.

### B4. Decision-capture check (DEC-0071 standing duty)

Before finishing, run the threshold test on this session's changes. Likely DEC-worthy candidate: **"automation owns transcript fixes"** (A3+A4 together — backfill-with-markers + FAIL-only alerting + agent-side FLAG triage) as a ratified standing posture; it was David-directed 2026-07-10 but never captured as a DEC. Flag it to David; on his OK author the DEC per `processes/decision-capture.md` (relate to DEC-0069/0070, DEC-0059 ruling b; no supersessions expected). The ownership-mode addition (A2) is probably an implementation detail under DEC-0070 — note it in DEC-0070's item trail, don't mint a new DEC unless David wants one.

---

## Close-out

1. Re-run the full lint; paste the summary for David.
2. Summarize every file changed (tooling, docs, action items, index) in a short table for David's review.
3. ⛔ **Final gate:** on David's OK, commit per repo roster conventions (sensible messages, no force-push; `~/Claude` and `cowork-evolution` are the expected repos) and push.
4. Write the session's daily-log section per the Code-surface convention, and note in it that **night-3 (tonight 23:00)** is the live verification of A1–A4 — tomorrow-morning check: ledger clean, no false-positive sentinel FLAGs, ATTENTION absent unless hard FAIL, backfill markers present in touched legacy files.
