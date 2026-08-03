# Code session — the clarification flow: remove the model rewrite, then let the loop run longer

**Authority:** David-directed, 2026-08-02, Cowork chat `remote_f184a039`. Supervised terminal session
(DEC-0081 supervised exception). **Anchor:** CLD-00094 — its 2026-08-02 entry holds both items and
David's framing. **Amends:** DEC-0093's clarification flow. **Context:** DEC-0104 (the gate this
serves), and `code/artifacts/cld00109-judges-cannot-write/report.md`, whose §Ratification items you
wrote.

---

## Two changes, and they are sequenced — (1) before (2)

### 1. V/D's questions must reach the clarify gate without passing through a model rewrite

Today the escalation-packaging pass reproduces V/D's tagged questions under a verbatim-copy prompt
instruction, and the clarify gate extracts from *that* copy. The tags decide whether a question goes
to David or to the authoring surface, so a mis-copied tag is DEC-0093's worst case — **a David-class
question silently becoming a clarification the machinery answers itself** — guarded today by prompt
discipline alone.

Since CLD-00109 the orchestrator already holds V/D's findings byte-verbatim, so the trustworthy text
exists before the packaging pass runs.

**End state:** no model-written text anywhere between V/D and the clarify gate.

### 2. The clarification loop can run longer than one round, and ends when it stops progressing

Under the attester-fronted gate, V/D's residual questions become predominantly design-side, where a
real multi-round exchange with the authoring surface earns its cost.

**End state:** the cap rises into the 3–5 range, and a **per-round progress judgment** ends the loop
early when the exchange is rehashing rather than moving — promoting to David. The cap is the
backstop; the progress judgment is the mechanism.

**Why this order:** raising the cap multiplies how often a question gets routed. Doing that before
(1) multiplies exposure to exactly the failure that matters most.

---

## Two questions David has NOT settled — answer them, with reasoning, in the report

- **Where the progress judgment runs.** A cheap minimal-context pass in the attester's spirit, or a
  question V/D answers about its own round? DEC-0104 item 2 records why two readers with different
  inputs are harder to steer than one; that property is what is at stake.
- **Whether the wider cap is uniform or class-aware** — design-side rounds only, with anything
  authority-shaped still ending the loop at once.

Propose and justify. Do not decide either silently, and do not treat a choice you make here as
ratified — the DEC amendment follows this work, as DEC-0104 followed the last one.

---

## Fence

- **Must not change** the fail directions: untagged → David; unparseable → David; anything
  authority-shaped → David. Every failure mode still promotes rather than absorbs.
- **Must not** weaken any per-round protection that applies today — they must hold identically at
  the higher cap.
- The escalation-packaging pass keeps its real job: the David-bound synthesis and draft task block.
- **Out of scope:** the attester-fronted gate itself, the deny-list and class table, and the
  commit-at-quarantine step. Separate increments.
- Judging-pass write restrictions shipped 2026-08-02 — do not loosen them to make anything easier.
- Fixtures stay inside the sandbox; the suite's closing assertions must keep passing.

## Bar

Baseline: `bash _meta/test_orchestrator.sh` → **ALL PASS (286)** as of 2026-08-02. Keep it green.

Fixture-proven:

- **Adversarial, and shown load-bearing both ways:** a compromised packaging pass that alters a
  question's tag **cannot** demote a David-class question under the new path — and **can** under the
  old one. Without the second half you have not shown the fix does anything.
- An exchange that rehashes ends **before** the cap.
- An exchange that is genuinely progressing still stops **at** the cap.
- Each fail direction preserved, proven per failure mode rather than in aggregate.

## Deliverable

`~/Documents/Agent_Workflow/code/artifacts/cld00094-clarify-flow/report.md` — what you built; your
answers to the two open questions and why; what you rejected; and **anything in CLD-00094, DEC-0093
or DEC-0104 that the running code contradicts.** The last session found the design record wrong about
the red-line check and a live stale-verdict defect nobody knew about; that kind of finding is worth
more than compliance.

Supervised close-out per `_meta/supervised-build-guardrails.md` §5 — **including §3 as written this
time** (copy → verify → atomic move, not in-place edits; last session's deviation is acknowledged in
its own report). Git is available in a terminal session; confirm with David before committing, and
note that the CLD-00109 work is also still uncommitted.
