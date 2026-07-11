# CLD-00062 — Kickoff prompt for Claude Code (paste as-is)

CLD-00062 build kickoff — Code-scheduled nightly automation.

Read these two files, in order, before doing anything:

1. `~/Documents/Projects/cowork-evolution/Design/code-scheduled-automation-architecture.md` — the design annex; authoritative on scope, stances, and failure modes.
2. `~/Documents/Projects/cowork-evolution/Prompts/CLD-00062-code-nightly-automation-build.md` — the execution order; follow it exactly, including the standing constraints at the top.

Then execute the build prompt starting at Phase 0 (read-only inventory). I am at the keyboard: stop at every ⛔ gate and get my explicit OK before proceeding. Do not modify anything under ~/Claude/memory/rules/, MEMORY.md's startup protocol, or anything in Alfred's domain (~/.openclaw/, alfred-workspace) — where the design implies such changes, write proposals as the build prompt directs.

Housekeeping as you go: check off completed phases in `~/Claude/memory/action-items/CLD-00062-260709-Open.md`, and append a phase summary to today's daily log (`~/Claude/memory/daily/<Pacific date>.md` — read the clock with TZ=America/Los_Angeles) under `## Chat: CLD-00062-build`.

Background if needed: DEC-0069 in `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`, platform mechanics in `~/Claude/memory/reference/remote-cowork-platform.md`, empirical basis in CLD-00061 (Datapoints 3–4, daily log 2026-07-09).
