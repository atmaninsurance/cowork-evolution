# Code session — make the judging roles structurally unable to write the evidence base

**Authority:** David-directed, 2026-08-02, from Cowork chat `remote_f184a039`. Supervised terminal
session, David present (DEC-0081 supervised exception — deliberately not routed, because this work
changes the gate an intake would have to pass through).

**Read first:** `~/Documents/Agent_Workflow/Design/unified-authorization-gate.md` — §3 is this task,
§9 shows where it sits, §11 lists open questions including the one below. Anchor: CLD-00109.

---

## The end state

V/D and the attester decide whether work is authorized. They judge against records they can
currently rewrite, and their write-nothing behaviour is a sentence in a prompt.

When you are done:

1. **The attester cannot write. Anywhere.** Enforced by the machine, not by its prompt.
2. **V/D cannot write the evidence base** — `~/Claude/memory/decisions/`,
   `~/Claude/memory/action-items/`, `~/Documents/Agent_Workflow/_meta/grants/`,
   `~/Claude/transcripts/`.
3. **A restriction that is incomplete or malformed fails loudly**, rather than silently running
   unprotected.

Diagnose and choose the mechanism yourself. You can run the live code and probe the tooling; the
authoring surface cannot.

**Standard: grant parity** (CLD-00100). Prevention for the accidental and incidental, detection for
the deliberate. Everything runs as one user — do not chase OS-level unforgeability, and do not stall
if you cannot reach it. Report the assurance level you actually reach, and what it leaves open.

---

## The question this task owns

V/D writes its findings to the OI spine, and the spine is partly evidence — the red-line check reads
it. So property 2 cannot be satisfied without deciding where V/D's findings land instead. That is
yours to settle; say what you chose and what you rejected.

---

## Fence

- **May modify:** `orchestrator/orchestrator.sh`, `_lib/run_claude.sh`, `_meta/test_orchestrator.sh`.
- **Must not change:** what the judging passes are asked to judge, their inputs, their fail-closed
  behaviour, or the auto-route logic. This changes what they *can do*, not what they decide.
- **Must not restrict** the worker, the reviewer, or the nightly stages — they legitimately write.
  Everything currently launches through one shared function, so a naive change reaches all of them.
- **Out of scope, separate increments:** the deny-list and class table, and the commit-and-push step.
- Fixtures stay inside the sandbox task 039 built. Its closing assertions prove the suite cannot
  touch the live tree; they must still pass.

## Bar

Baseline before you start: `bash _meta/test_orchestrator.sh` → **ALL PASS (260)**, ~90s as of
2026-08-02. Keep it green.

Then, fixture-proven:

- A judging pass **instructed by its own input** to write into the evidence base does not write.
  The adversarial case, not the happy path.
- **The guard is shown to be load-bearing** — the same fixture writes when the restriction is
  removed. Without that pair you have shown nothing.
- A malformed restriction fails loudly.
- The worker and nightly stages still write what they legitimately write.

## Deliverable

`~/Documents/Agent_Workflow/code/artifacts/cld00109-judges-cannot-write/report.md` — the mechanism
and what you rejected; where V/D's findings land and why; the assurance level in grant-parity terms
(prevented / merely detectable / neither); and **anything in the design record that is wrong.** That
document was written from reading the code, not running it. It is a design record, not a decision —
if implementation shows a position in it is mistaken, that finding is worth more than compliance.

Supervised close-out per `_meta/supervised-build-guardrails.md` §5. Git is available in a terminal
session; confirm with David before committing.

---

*Prior work, unverified: a Cowork session probed tool-restriction behaviour on this machine and left
raw artifacts at `/tmp/probe*-out.txt`. Four data points, deliberately not summarised here — treat
them as a lead, not a finding.*
