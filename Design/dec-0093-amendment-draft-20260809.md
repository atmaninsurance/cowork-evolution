# DEC-0093 amendment — draft for ratification

**Date:** 2026-08-09 · **Author:** Claude Code session `8aea2d2f` (David-directed: "Draft the DEC-0093 amendment")
**Status:** DRAFT — working paper. On David's ratification this mints as an estate DEC
(`The_Estate/decisions/2026/`, via `mint.py dec`) carrying **Amends: DEC-0093**; the frozen
legacy entry gains a back-pointer tag only on David's explicit word (protected file).
**Build home:** CLD-00094 (the existing DEC-0093 build item — no new ACI). Build increments
route as ordinary front-door intakes anchored there.

## What this amends, in one paragraph

DEC-0093 (2026-07-29) created the clarification tier: claim-side questions return to the
consulting surface instead of pinging David, bounded to ONE round, with a 24-hour age-out.
Eleven days of live running — capped this morning by a thirteen-round rewrite loop on
OI-000037 and a David-directed process experiment at round 13 — showed the one-round bound is
the wrong governor: the rounds were productive (every find real, none denied, zero drift from
purpose) but partially serializable, increasingly narrow, and ungoverned by any severity
notion. This amendment replaces the flat bound with four coordinated mechanisms. **Nothing
here touches DEC-0093's authority invariant (item 3): a clarification round still may only
align the claim with the record, never the gate; the mechanical screen, red-line, capability
check, and done-checks are untouched and unwaived.**

## The four parts

### Part 1 — Round cap 1 → 3–5, governed by a per-round progress test

*(The shape David directed 2026-08-02, recorded on CLD-00094. **Written against the
DEC-260119 END-STATE roles (David's clarifying question, 2026-08-09)** so this does not go
stale when increment I-4 retires the legacy full-judgment pass: in the end-state the
Verifier asks two closed questions OF THE RECORD — the attester's "does the record authorize
this, at this capability and scope?" and the intent judge's "does what would run accomplish
what was authorized?" — and converses with nobody. The loops this part governs are the two
places genuine rounds exist:)*

- **(a) The Designer's clarify loop** — the Designer asking the REQUESTER bounded
  clarification questions — and **(b) the rewrite re-check cycle** — each corrected filing
  re-facing the intent judge (on the legacy pass until I-4, on the intent judge after).
  The round bound for both rises from 1 to a cap in the 3–5 range (**recommendation: 4**).
  The cap is the backstop, not the mechanism.
- **The mechanism is the progress judgment**, each round: is the exchange progressing, or
  rehashing? A no-progress verdict ends the loop immediately and promotes everything to
  David. **Recommendation on placement: the existing progress judge** — DEC-260119 D3's
  minimal-context sonnet judge, already live in the design loop (both question sets inlined
  in its prompt, no record inputs, preserving the two-readers property). This amendment
  extends that same judge to both loops, rather than inventing a second mechanism or
  letting any judging pass grade its own rounds.
- **Class-aware, not uniform:** the raised cap applies to claim-side (design/specification)
  rounds only. Anything authority-shaped still ends the loop at once and goes to David —
  unchanged from DEC-0093 item 1's test.
- The 24-hour age-out per held round stands unchanged.

### Part 2 — Mechanical clarify-question extraction (prerequisite to Part 1)

*(The second 2026-08-02 shape; "(2) is arguably (1)'s prerequisite" — raising the cap is only
safe if the routing that decides WHO gets a question is trustworthy.)*

**Vocabulary note (David's questions, 2026-08-09):** the tagged questions in this part are
emitted by the **legacy full-judgment pass** (the pre-I-4 "V/D") — NOT the Designer, and
not the slim end-state Verifier, which asks its two closed questions of the record and
converses with nobody. **End-state framing:** after I-4, model-authored question text
transits a re-typing pass only on the ESCALATION PACKAGING path (David-bound packages), and
that is where this fix permanently applies: whatever judging pass produces routed or
escalated question text, the router and the package carry it byte-verbatim from the
orchestrator's transcription — no model rewrite between the judge and the reader. The
`questions=N` cross-check and the fail directions (untagged → David, unparseable → David)
apply identically in both eras. *(That the roles needed asking is a second datapoint for
the role-vocabulary cleanup David flagged 2026-08-07 — recorded for the naming pass.)*

- Today a sonnet escalation-packaging pass RE-TYPES V/D's tagged questions, and the clarify
  gate reads that copy — a mis-copied tag silently demotes a David-class question to
  `[clarification]`, guarded only by prompt discipline. Since the CLD-00109 build, the
  orchestrator itself transcribes V/D's findings byte-verbatim, so trusted code already holds
  the exact question text.
- **The clarify gate extracts questions mechanically from the orchestrator-transcribed
  section.** No model-written text anywhere between V/D and the router. The verdict's
  `questions=N` becomes a free cross-check — a count mismatch is a contract violation and
  promotes everything to David. The gate runs BEFORE the escalation-packaging pass, so an
  all-clarification item skips the sonnet pass entirely.
- Fail directions unchanged: untagged → David; unparseable → David.

### Part 3 — The severity ratchet (proven live 2026-08-09)

*(David's experiment, OI-000037 round 13: ruled bar carried in the decision document;
verifier honored it faithfully — verdict cited the ruled bar, filed four findings as NOTED
FOR FUTURE CONSIDERATION, returned variation=none, routed. First live evidence.)*

- **From round 3 onward (recommendation; David may rule it earlier or later per item), a
  rewrite re-verification blocks ONLY on serious defects that prevent safe proceeding** — a
  defect that would damage the live estate, violate a ruled property, or leave work in an
  unrecoverable or half-applied state. Improvement-class findings — hardening, wording
  alignments, fixture additions, residual documentation — are recorded in the verdict as
  **NOTED FOR FUTURE CONSIDERATION** and do not block routing.
- **No note is dropped:** noted items are appended to the item's governance anchor (the
  auth-echo pattern — small build) with disposition owed at item close. The severity bar
  governs the VARIATION judgment only; a damage-class find still blocks at any round
  (checked against today's history: the rounds 9–10 orphan-cutover finds would still have
  blocked under the ratchet; only the fixture-mechanics tail would have been noted).
- **David retains the per-item override in both directions** — rule the bar earlier (as
  today's experiment did, via the decision document) or suspend it for an item where he
  wants exhaustive per-round review.
- **End-state native:** the ratchet is a bar on the VARIATION verdict — the intent judge's
  question in the DEC-260119 end-state — so unlike Parts 1–2 it needs no translation when
  I-4 lands; today's experiment exercised exactly the verdict that survives.

### Part 4 — The exhaustive adversarial pass (catch it up front, not serially)

*(From the 2026-08-09 assessment: two finding-families across thirteen rounds were one
analysis arriving in installments — the fresh-context verifier optimizes per-round soundness
and cannot hold a running enumeration.)*

- **A commissioned deep-review pass whose charter is ENUMERATE EVERYTHING, not block-first:**
  one headless task (design-pass shape, the task-067/076 precedent), run against the authored
  task document, reporting an exhaustive findings enumeration organized by lens —
  state-machine completeness, testability/vacuous-green, artifact lifecycle and retention,
  concurrency and re-entry, environment mechanics. The author folds all findings in ONE
  rewrite; the per-round gate then resumes as the safety net.
- **Placement (David's question, ruled framing 2026-08-09): the FINAL pass of the DESIGN
  phase — never the executor's first step.** Its findings go to the AUTHOR for the fold,
  which is design-phase work by definition; by the time an executor holds a task the gate
  has judged it, and changing it there would bypass the gate. It is also structurally
  SEPARATE from the Verifier — a fresh enumerate-everything reviewer, not the block-first
  judge grading its own future workload. Mechanically it runs as a commissioned headless
  task (the worker executes it; the product is design material). Flow: authoring →
  exhaustive pass → author folds once → Verifier gate as safety net → route → executor.
  The round-3 auto-trigger is the loop-back form: the item steps OUT of the gate, back into
  the design phase, receives the enumeration, folds once, re-enters.
- **Triggers (both recommended):** (a) up front, for high-stakes classes — any task whose
  fence touches service definitions or the live control plane; (b) automatically, when any
  item reaches round 3 without routing — the round count itself is the evidence that serial
  discovery is losing.
- Deliberately NOT category-per-round rotation inside the gate: prescribing where the
  verifier looks narrows what it can catch (the CLD-00124 watch-the-symptom lesson).
  Category coverage grows via the DEC-260120 self-growing checklist feeding the AUTHORING
  side instead — the exhaustive pass's lens list and the checklist share one taxonomy.

### Part 5 — Mixed-set binding fix (folded housekeeping)

*(The 2026-07-30 design gap on CLD-00094: a mixed question set lands `escalated`, so a
corrected refile carrying `related: [open-OI]` mints a NEW OI instead of consuming the round
— duplicate spines per defect, observed live on OI-000018/19 → 20/21.)*

- **A corrected intake carrying `related:` to an open OI binds to that spine regardless of
  whether it sits `clarifying` or `escalated`** — consuming the round through the DEC-0082
  rewrite path as designed. No duplicate mint. (ACI-260007's auto-supersession covers the
  historical duplicates; this prevents new ones.)

## Evidence base

- **The thirteen-round OI-000037 history (2026-08-03 → 2026-08-09)** — rounds productive
  (zero denials, zero drift), partially serializable (the orphan-window family: rounds 9,
  10, 12; the vacuous-green family: rounds 8, 11, 12), tail improvement-class.
- **The round-13 experiment** — ruled severity bar honored faithfully by the gate; routed
  with four notes, none dropped, all transcribed to CLD-00119 same sitting.
- **The progress judge precedent** — DEC-260119 D3's minimal-context judge, live in the
  design loop (PROG-VERDICT lines on OI-000061, 2026-08-08).
- **The 2026-08-02 CLD-00109 build report** (§Ratification items) — source of Parts 1–2.

## What stays unchanged (stated for the record)

DEC-0093 items 1 (classification test), 2 (sidecar/`clarifying` mechanism), 3 (authority
invariant — verbatim in force), 5 (progress-check chain); the 24h age-out; one decision
channel per OI (DEC-0095 §5); the mechanical screen, red-line, capability check and
done-checks; DEC-0106's never-weakened done-check principle.

## Decision list for ratification

- **D-A:** Cap number — 3, 4, or 5? *(Recommend 4.)*
- **D-B:** Progress-judge placement — extend the existing DEC-260119 D3 judge *(recommend)*,
  or a distinct pass?
- **D-C:** Ratchet default engagement — round 3 *(recommend)*, or another round?
- **D-D:** Exhaustive-pass triggers — both (a) high-stakes classes up front and (b) round-3
  auto-commission *(recommend both)*, or one?
- **D-E:** Part 5 fold — include the mixed-set binding fix in this DEC *(recommend)*, or
  leave it to a separate ruling?
- **D-F:** On minting, add the back-pointer tag to the frozen DEC-0093 entry
  (governance-protected file — your explicit word required)?

## Build sketch (all anchored CLD-00094, front-door intakes, sequenced)

B-1: mechanical extraction (Part 2 — prerequisite). B-2: cap raise + progress-judge
extension (Part 1; `CLARIFY_ROUND_MAX` already parameterizes the bound). B-3: severity
ratchet + noted-items append path (Part 3). B-4: exhaustive-pass task template + triggers
(Part 4). B-5: mixed-set binding (Part 5). Fixture lock across all paths per DEC-0089.
