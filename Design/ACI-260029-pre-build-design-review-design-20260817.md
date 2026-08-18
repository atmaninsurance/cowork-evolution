# The pre-build design review — design of record (ACI-260029)

**Status:** settled 2026-08-17 in one sitting (Code session `38ff89fa`, David present), on
three inputs: the session's first-pass proposal, codex-me's independent memo
(`~/Documents/Agent_Workflow/Design/ACI-260029-codex-review-20260817.md`), and David's
rulings. Ratified as **DEC-260134** (same day). Build increment **R-1** in the PM program
(DEC-260132 Effect 6, as amended), filed at the front door 2026-08-17 with C-1.
**Project:** cowork-evolution. **Anchors:** ACI-260029, DEC-260132, DEC-260133, DEC-260114 A1.

## 0 · In one paragraph

Once the Project Manager exists, a whole multi-step sequence is ratified in one act and then
runs on a fast path. Nothing today reviews the *quality and risk of the design itself*
before that act. The pre-build design review is a **panel of three agent sessions, each
with a different attack method — a counterfactual challenger, an adversarial implementer
(codex-me), and an assurance/operations attacker — run in parallel, inside the design lane,
as a subroutine of `designer.sh`**, on the Designer's sequence sidecar before it is filed at
the front door. Their schema-valid findings are consolidated by deterministic code into
`proceed / return-to-designer / escalate`; the Designer revises on a return (cap 2 rounds);
the filing at the front door carries the aggregate; the front door's ratification (P-3b)
is interlocked on a fresh, hash-matched `proceed`. The orchestrator is not involved until
the front door — **unless a panel recommendation changes the *what* rather than the *how*,
in which case it is an authority question and routes to David.** Triggered narrowly and
mechanically; most sequences never pay for it.

## 1 · Why (the gap, in systems terms)

Today's checks on a design are: provenance (does the record substantiate it? — V/D), a
one-question intent judge (does this serve the verified intent?), mechanical screens
(designcheck; the P-2 checklist's nine machine-checkable rows), and — after the build — the
executor's Reviewer. **Execution is the test of the design.** Adequate for routine work.
For a high-stakes sequence (control plane, governance surfaces, launchd, anything hard to
reverse), ratifying the whole thing once and then fast-pathing its steps means a confident
wrong decomposition runs to completion before anyone judges it. The v1 PM design had a
*judged* practicality pass; v2 (DEC-260132 Effect 5) cut it and kept only the mechanical
rows. Five checklist rows are marked *judged* and built nowhere: C-2 standalone steps, C-6
real evidence, C-7 not satisfiable by an empty implementation, C-10 fence coherence, C-14
rollback per control-plane step. The review is where those live — plus the design-quality
questions no checklist row covers.

## 2 · David's rulings (verbatim, dated 2026-08-17)

1. *"I don't think the design reviewer should route back through the orchestrator. It
   should be a team of agents with different areas of focus. Stress testing the design as
   it were. I'd like to pull in a codex session as part of the review process."*
2. *"I agree with codex on this one. If we are dealing with the design and design review
   we're still in the design lane just pulling in the resources (other agents) to check the
   work and perhaps recommend alternatives. None of that needs the orchestrator unless the
   new recommended design moves beyond the authorized scope. If the designer changes the
   'how', but doesn't change the 'what', then it should be fine. I could see a
   recommendation from the panel saying if we're doing 'this' we should do 'that' as well in
   which case a new authorization would be required and it would route to me."*
3. On operations: a subroutine within the designer lane; a handoff of the design file
   between actors is acceptable if a separate folder is necessary. (Paraphrase; the
   session's answer — staged immutable copies, not moves — is §5.)

## 3 · Shape: three seats by method (codex-me's design, adopted)

Parallel, independent, no seat sees another's findings before submitting. Each seat has
one falsifiable job:

| Seat | Method | Owns |
|---|---|---|
| **Counterfactual challenger** | "Is there a smaller, safer, more reversible design that meets the brief?" | alternatives, proportionality, architectural sequencing, unnecessary machinery |
| **Adversarial implementer — codex-me** | "Build this from the spec alone. Where do you stall, guess, exceed the fence, or confidently do the wrong thing?" | spec self-containment (authoring contract §7), **verification mutation testing** (empty / stale / partial / wrong-target / reordered / skipped-cleanup / non-idempotent implementations that still pass), and the **state/authority composition attack** (locally valid steps that compose into an early close, widened authority, a race, or an unrecoverable intermediate state) |
| **Assurance & operations attacker** | "Break it: state transitions, permissions, concurrency, recovery, observability, handoffs. Does verification detect the break? Does rollback restore a known state?" | failure scenarios, rollback reality, operability, cost as a required field |

**Not a seat:** intent (owned by the intent judge), provenance (V/D), the screen (C-11),
per-step authority (the front door). Cost is a required field on the challenger and
assurance outputs, not a seat. There is no David seat: authority questions and loop
failures reach him; nothing else does.

## 4 · Inputs — and deliberate exclusions

Every seat gets an **immutable review manifest**: the candidate sidecar + its sha256; the
verified brief; the mechanically derived touched-path/risk manifest; the applicable schema,
fence, permission and lane-interface contracts; revision + round numbers.

- Challenger: brief, candidate, constraints, risk manifest. **Not** the author's rationale,
  claimed alternatives, chat transcript, prior findings, or seat identities.
- Codex: **phase 1** — sidecar, interface contracts, the minimum relevant read-only code
  slice (touched paths + their direct callers/consumers), **no brief, no rationale**; it
  records what it would build and where it hesitates. **Phase 2, same session** — the brief
  is revealed; it checks whether its plausible implementation satisfies the words while
  missing the purpose. Never other seats' findings.
- Assurance: sidecar, read-only runtime topology + operating contracts, state formats,
  mechanically selected failure records for the touched components. Not the author's
  reassurance or a suggested verdict.

No seat receives a conversational summary in place of a source; no seat receives another
agent's memory, secrets, live queues, or writable state. Independence means independent
*evidence formation*, not ignorance of the verified brief or the real tree.

## 5 · Where it runs: inside the design lane, as a subroutine of `designer.sh`

From the orchestrator's hand-off (OI held `designing`) to the Designer's filing at the
front door, the whole loop is **design-lane state**. No OI status change, no orchestrator
wake, no escalation per round. No new lane, no new launchd agent, no new lock: the design
lane's own agent, cadence, model tier and stand-down window host the panel.

`run_review_panel()` in `designer.sh`:

1. **Freeze the object.** Copy the sidecar into `designer/review/<OI>/v<NN>/r<NN>/manifest/`
   with its hash, the verified brief and the risk manifest. Immutable for the round.
2. **Fan out.** Per seat: stage read-only inputs (§4), launch the session **from the
   seat's own folder** (`seats/<seat>/` — its cwd, its only write area; also what keeps
   `run_claude`'s per-cwd transcript attribution correct under parallelism), write-
   restricted by the same staging + deny-write helpers the design session already uses.
   Claude seats via `run_claude`; the Codex seat via **`_lib/run_codex.sh` (DEC-260133 C-1)**
   — same signature, exit codes and guard contract, `codex exec` under Codex's default-deny
   sandbox with the seat folder as `-C` and the read-only slice as `--add-dir`. Three in
   parallel; `wait`.
3. **Validate + consolidate — code, not a model** (§6) → `aggregate.yaml` beside the seats.
4. **Loop or exit.** `return` → re-run the design session with the numbered mandate list →
   sidecar v+1 → new round folder, new hash (an unchanged hash is not a new round). Cap 2
   rounds. `proceed` → the Designer files at the front door as today, aggregate attached.
   Any authority-question → the filing carries it; it routes to David.

**The design file is never handed hand-to-hand and edited in place.** Each round's sidecar
is an immutable versioned file; every seat gets a staged read-only copy; the Designer's
revision writes a new version. This is the orchestrator's own DEC-260119 I-6 rule (inputs
frozen at call start, hash recorded) applied inside the design lane.

Layout (codex-me's, adopted, under the design lane's tree):

```
designer/review/OI-NNNNNN/v01/r01/
  manifest/        sidecar.sequence.md  sidecar.sha256  brief.md  risk-manifest.yaml
  seats/challenger/   seats/codex/   seats/assurance/     (cwd + only write area, each)
  aggregate.yaml
```

## 6 · Output schema and deterministic consolidation

Each seat returns exactly one schema-valid record (`design-review-seat/v1`): `oi`,
`sidecar_sha256`, `round`, `seat`, `template_version`, `input_manifest_sha256`,
`completion`, and `findings[]` each with `id`, `class` (`blocker | advisory |
authority-question`), `area` (controlled vocabulary), `step_refs`, `evidence`,
`failure_scenario`, `required_property`, `reproducer_or_test`, `confidence`. A blocker names
evidence, a concrete failure scenario, and the property a revision must make true — never
a mandated implementation unless only one safe one exists.

The runner validates seat count, hashes, schema, template versions, completion, freshness,
then applies fixed rules — **no fourth model interprets the panel**:

1. Missing / unreadable / stale / hash-mismatched / schema-invalid seat output → **return**
   with a system-failure mandate. Never a pass. (Fail closed — the executor Reviewer's
   default-approve on an unreadable verdict is the wrong default here.)
2. Any `authority-question` → **escalate**: listed verbatim, unranked.
3. Otherwise any `blocker` → **return-to-designer**: one consolidated mandate list, sorted
   by area/step/seat/id, exact duplicates collapsed by key only.
4. Otherwise **proceed**, advisories carried, not conditions.

The aggregate says `recommended_disposition`. Inside the design lane that is what the
Designer acts on (revise / file). It never changes an OI status.

## 7 · The how/what test — the one place the orchestrator re-enters

The front-door-verified brief defines the **what**: done-criteria, deliverable, fence,
budget, the surfaces it may touch. The sidecar is the **how**. A finding that changes the
how — split a step, add a rollback, verify with a real fixture, reorder — is the Designer's
to adopt on its own authority. A finding that changes the what — a new component, a wider
fence, a new surface, spend, a launchd act, "if we do this we should also do that" — is
beyond the authorized scope: the Designer cannot adopt it; it becomes an
`authority-question`, the filing carries it through the front door, and it routes to David
on the existing [consultation] path.

**Made mechanical:** the risk manifest is regenerated per revision; its touched surfaces are
diffed against the brief's authorized surfaces by code. Inside → how. Outside → what →
authority-question. A Designer that omits paths to stay inside trips **omission fails into
review** (§8). Nobody judges whether something is a scope change; the diff says.

## 8 · Trigger — mechanical facts, narrow

Review a sequence if any of: (a) a touched path or declared operation intersects a
**version-controlled protected-surface table** (control-plane code, service definitions /
launchd, governance and authority surfaces, identity/permission/secrets boundaries,
cross-actor and PHI-boundary controls, outward-facing actions, material-spend controls);
(b) it declares a destructive, migratory, non-idempotent, data-shape-changing or
hard-to-reverse operation; (c) rollback is declared impossible or manual; (d) the requester
sets `review: pre-build`; (e) required risk / touched-path declarations are **absent or
conflict** with mechanically extracted paths — unknown risk fails *into* review. The P-2
checklist's C-13 extractor is reused with its table widened to the settled classes. "A
design doc is named" is **not** a trigger (over-inclusive and evadable).

## 9 · Loop bound

Two panel rounds total (original + one re-review of a materially revised sidecar; unchanged
hash ≠ new round). The re-review sees the original findings and a mechanical
finding-to-change map only *after* each seat has read the new candidate cold. Any blocker
after round two, any authority-question, or no complete aggregate within ~24h → the
Designer files at the front door and it escalates to David. **No model progress judge.**
Hash change, mandate closure, round count and elapsed time route; the panel reports.

## 10 · Placement in the PM program and the P-3b interlock

**R-1 lands after P-2 and before P-3b.** It consumes P-2's C-13 class and C-11 dry-screen;
it must exist before P-3b's fast path makes whole-sequence ratification consequential;
P-3b's own sidecar (control-plane class) is its first customer. **Interlock (P-3b's spec
gains one line):** a triggered candidate cannot be ratified without a complete, fresh,
hash-matched `proceed` aggregate. Ratified order becomes P-1 → P-2 → P-3a → **R-1** → P-3b
→ P-3c → P-5 → P-6, with **DEC-260133 C-1** (`run_codex.sh`) as R-1's dependency for the
Codex seat.

## 11 · Verification bar for R-1 (what "built" means)

- A **mutation corpus**: one deliberately bad sidecar per blocker class (a fictional
  interface; an omitted consumer; a vacuous verification; a widened fence; a missing
  rollback on a control-plane step; a step sequence that closes its OI early), each passing
  every mechanical check, each caught by the designated seat with a schema-valid blocker,
  the aggregate reaching the intended outcome with no model in the loop.
- Fail-closed proofs: a missing seat, a malformed record, a stale hash, a mid-run candidate
  change → `return`, never `proceed`.
- The how/what diff: a revision inside the baseline → no authority-question; one step
  touching a surface outside it → `authority-question`, and the filing carries it.
- Parallel-launch proof: three seats from three cwds; transcript attribution correct per
  seat; no seat wrote outside its folder (fingerprint).
- Per-seat measures recorded from the first run: tokens, elapsed, malformed outputs, unique
  findings, false returns — the measurement layer (`_meta/usagelib.py`, DEC-260131 build
  iii, landed 2026-08-17) already records every session's tokens by lane and phase; the
  seats label their phase.
- Codex seat: proven against the `run_codex.sh` contract; live if C-1 has landed, else the
  contract stub with the live run named "not done" and re-verified when C-1 lands.

## 12 · What this design does not do

No standing human seat; no intent verdict; no routing; no OI status writes; no new lane or
agent; no review of routine sequences; no dollar figures (tokens only, DEC-260131 build iii
posture); no third panel round; no model judging the judges. Historical replay is a
nice-to-have (no live sequences exist yet); the mutation corpus is the practical ablation.

## 13 · Questions the panel puts to the Designer (the templates' spine)

Replay/ablation form, codex-me's sharpening adopted: *name the three strongest alternatives
and the defect class each misses; remove each seat and show the unique loss; supply one bad
sidecar per blocker class that passes every mechanical check; what is the first irreversible
transition and what invariant blocks it without a fresh hash-matched review; can a Designer
evade review by omitting paths, and what makes the omission itself a trigger; which claim
must be grounded in the live tree, and how is that slice selected without letting the
Designer hide a dependency; what closes a mandate without a progress judge; what happens if
Codex is unavailable, a seat times out, output is malformed, or the candidate changes
mid-run; what measured threshold removes a seat or retires the panel.* The full nine-lens
question set from the session's first pass is retained as **prompt coverage** inside the
three seats' templates, not as seats.

## Records

- ACI-260029 (this item; David's rulings verbatim in Progress).
- codex-me memo: `~/Documents/Agent_Workflow/Design/ACI-260029-codex-review-20260817.md`.
- Consultation prompt: `~/Documents/Projects/cowork-evolution/Prompts/ACI-260029-codex-design-review-prompt-20260817.md`.
- DEC-260134 (ratification); DEC-260132 (PM, amended build order); DEC-260133 (C-1);
  DEC-260114 A1 (Designer lane, taxonomy amended); DEC-0093 (loop shape); DEC-260119 I-6
  (frozen inputs); DEC-260131 (measurement).
