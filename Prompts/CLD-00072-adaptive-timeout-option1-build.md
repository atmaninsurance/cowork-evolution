# Prompt: Adaptive task timeouts — Option 1 build (deadline-aware execution + soft-landing handoff)

**Action item:** CLD-00072
**Project:** cowork-evolution
**Scope:** business
**Date written:** 2026-07-16
**Author:** Cowork-me
**Executor:** Claude Code
**Status:** Executed 2026-07-16 (Code session `99580b8f`) — Option-1 mechanics + the folded-in
done-check shipped and tested (26/26 stub assertions + 4 live runs on the real CLI); three
implementation bugs found and fixed during testing, incl. one visible only under live testing
(a soft landing exits 0 and was being recorded `done`). Outcome notes in CLD-00072 §Progress.
`needs-review`/analyst/autonomy-gating deliberately not built — seam left at the writer's verdict.

---

## Context

The CLD-00068 exit-137 investigation exposed a second, quieter failure mode in the Agent Workflow queue: a task whose `timeout_minutes` is systematically undersized fails identically on every attempt — each fresh session grinds the same first N minutes, is guillotined at the same point, burns the whole `max_attempts` budget re-doing identical work, and litters `artifacts/` with unreliable partials. The 010 re-run (2026-07-16) added a sibling hole: the worker's success check trusts exit code + non-empty stdout only, so an exit-0-but-empty run is silently recorded `done`.

The full Option-1 design — deadline-aware execution, flat 1-minute landing grace, SIGKILL-only watchdog, the three-rung handoff ladder, the handoff-writer role with a progress verdict, and continuation-vs-failure accounting — was settled with David on 2026-07-16 and is written up in the action item. **This prompt executes that build. The design is decided; do not re-litigate it.**

## Task

1. Read `~/Claude/memory/action-items/CLD-00072-260716-Open.md` in full — especially §"Option 1 — design detail (decided 2026-07-16)" and §"Implementation kickoff (start here — fresh session)". That kickoff section is the authoritative build spec for this session.
2. Execute the kickoff exactly as written: work through its read-first list (7 files, in the given order), then its task sequence 1–6 (deadline injection → JSONL-path capture → handoff-writer role → resume preamble → continuation accounting → bidirectional testing).
3. Folded-in fix (per the kickoff's 010 datapoint, in scope for this build): the worker's done-check must require the prompt's declared deliverable/artifact path to exist on disk before accepting `done`; an exit-0-but-empty run dead-letters instead of passing.
4. Post-change verification: `bash -n` + source-check on `_lib/run_claude.sh` and `worker.sh`; confirm the nightly (`com.cowork.nightly`) still sources `run_claude.sh` cleanly (same verification pattern as the DEC-0078 extraction); reload the worker and reviewer launchd jobs after the changes.
5. Executor handoff duty: append outcome notes to CLD-00072's Progress section, and flip this prompt file's Status to `Executed 2026-07-16` (or the actual date) when done.

## Acceptance Criteria

- A deliberately-overrun test task lands softly (or is reconstructed by the handoff-writer), resumes from `HANDOFF.md` on the next attempt, and finishes — exercising rung 1 and rung 2 of the handoff ladder where feasible.
- A genuinely stuck / no-progress test task dead-letters once the continuation cap (or the verdict's no-progress ruling) is hit.
- An exit-0-but-empty run (declared artifact missing) dead-letters; it is never recorded `done`.
- The watchdog remains **SIGKILL-only**, with the hard kill at `E + 1 min` relative to the deadline Code is told; Code receives the deadline as an absolute wall-clock time.
- The `needs-review`/analyst/autonomy-gating path is **not** built; a clean seam is left at the handoff-writer's verdict for the future design pass.
- `run_claude.sh`/`worker.sh` pass syntax + source checks; worker and reviewer reloaded; nightly unaffected.
- CLD-00072 Progress updated with what shipped, test outcomes, and any residuals.

## Notes for executor

- David is present and supervising, but this run has **no formal ⛔ gates** — surface questions or surprises to him in-session rather than guessing, and keep moving otherwise.
- `_lib/run_claude.sh` is shared live machinery: the nightly chain sources the same file. Treat every edit there as a change to the nightly too.
- Handoff-writer sessions: own fresh `claude -p` session, short bounded budget (~180s, like the preflight probe), cheap model, `max_attempts = 1`, and a DEC-0078-style delegated-execution marker/hygiene tag so lint and the EOD daily-log discovery exclude them.
- Continuation accounting: a `continuations` counter distinct from `attempts`, plus an absolute continuation cap; the optional deterministic cross-check (did `artifacts/` grow?) is cheap — include it.
- Do not hand-seed `_meta/cli-version.last` (DEC-0079 lesson — only the preflight writes it, only after a PASS).
- Prompt lifecycle: this file stays in `Prompts/` after execution as historical record (DEC-0047).
