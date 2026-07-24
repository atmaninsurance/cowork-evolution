---
id: decision-20260723-oi-000001
status: queued
priority: 2
origin: david-decision
requested_by: cowork              # filed on David's behalf by consultation chat remote_62d4de81
created: 2026-07-23
related: [OI-000001, CLD-00073, DEC-0082, DEC-0083]
decision: rewrite
execution: supervised
---
# Decision — OI-000001: approved with modifications; supervised execution

David's rulings on the escalation of `consult-20260723-cld00073-ratification-deltas`
(chat `remote_62d4de81`, 2026-07-23):

## Rulings

1. **Deltas 1–7 approved as filed** (V/D sidecar overflow; verified-consultation
   auto-route with `variation` slot; agent-proposal deeper analysis; rewrite
   re-verification; deliver_to when-present + create-if-missing; intake-template line;
   EOD Stage-3.6 outcome-append to anchored CLDs).
2. **Open question 1 — attester: BUILD NOW** (DEC-0082 finalization). The narrow
   provenance-attester pre-step ships with the auto-route implementation: a bounded,
   minimal-context check answering only "does the anchored record substantiate this
   work?", independent of the rich-context V/D read. Auto-route requires BOTH clean.
3. **Open question 2 — destination-root allowlist CONFIRMED:**
   `~/Documents/Projects/` and `~/Documents/Agent_Workflow/`.
4. **Open question 3 — execution mode: SUPERVISED**, and the scope is REWRITTEN to add
   **delta 8: the supervised execution lane (DEC-0083)** — `execution: headless |
   supervised` field on intakes and decision documents (screen-validated); route-supervised
   instantiates into `code/supervised/` with the orchestrator-appended supervised-mode
   bookkeeping block and a Telegram pointer carrying the copy-paste launch line;
   staleness exemption + 7-day FLAG reminder + artifacts-complete-but-never-moved nudge;
   decision-enactment honors the execution field.

## Rewritten task (pointer — supervised bootstrap)

Because the supervised lane does not exist until this build creates it, this decision is
enacted under the DEC-0083 §6 one-time bootstrap: the rewritten routable task is
materialized as a David-supervised build prompt at
`~/Documents/Projects/cowork-evolution/Prompts/OI-000001-deltas-build.md` (DEC-0081
supervised-work exception) rather than instantiated by the orchestrator. The supervised
session executes it and performs the OI-000001 bookkeeping itself with the machinery it
builds: quarantine THIS document as `items/OI-000001.decision-01.md`, append the decision
to the spine Progress, set `task:` to its own task record, write the task record +
`## Result` to `code/outbox/`, output document to
`artifacts/consult-20260723-cld00073-ratification-deltas/report.md`. The standard
reviewer → completion round then closes OI-000001 normally.

## deliver_to

daily-log
