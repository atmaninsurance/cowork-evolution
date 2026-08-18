# Prompt for codex-me — independent view on the pre-build design review (ACI-260029)

**Filed by:** Claude Code session `38ff89fa` on David's direction, 2026-08-17.
**Run as:** an interactive codex-me session started in `~/Documents/Agent_Workflow` (David
launches it; this is a consultation, not a machinery-spawned task — no worker, no deadline
block). Paste everything below the line into the session as the first message.

---

David has asked for your independent view on a proposal, and specifically for **how you
would structure it** before you read how we did. Please do the parts **in order** — Part A
before you read Part C — so your structure is yours and not an echo of ours. Say plainly
where you disagree; agreement is not the deliverable.

## Part A — the problem, cold (design it yourself first)

**Context you need (read these, they are short):**
- `~/Documents/The_Estate/action-items/ACI-260029-260817-Open.md` — the item; read only
  its **Context** section for now, stop before "Design questions" and skip the last
  Progress bullet until Part C.
- `~/Documents/Agent_Workflow/README.md` §"Roles" and §"Orchestrator lane" — how work
  flows today: front door → V/D judgment → executor lane → reviewer → delivery.
- `~/Documents/Agent_Workflow/designer/designer.sh` header comment (the first ~80 lines) —
  the Designer lane's two duties and the role invariant (the pen never writes a verdict).
- `~/Documents/Projects/cowork-evolution/Design/executor-pm-design-v2-20260816.md` §1–§6
  and §9 — the Project Manager design (ratified as DEC-260132): a Designer decomposes a
  brief into a **sequence sidecar** carrying every step; the front door **ratifies the
  whole sidecar once**; the PM releases steps one at a time on a fast path (mechanical
  screen only) as long as they match the ratified copy.
- `~/Documents/Agent_Workflow/executor/artifacts/NNN-executor-pm-design/report.md` §5 —
  the fourteen-row intake checklist, with its "machine-checkable?" column. Nine rows are
  being built as a mechanical lint (P-2). Five are marked *judged* and are built nowhere.

**The gap:** once the PM exists, a whole multi-step sequence gets ratified in one act and
then runs on a fast path. Nothing today reviews the **quality and risk of the design
itself** before that act — is this the right decomposition, in the right order, with real
verification and a rollback? Today's checks are: provenance (does the record substantiate
it?), a one-question intent judge (does this serve the verified intent?), mechanical
screens, and — *after* the build — the executor's reviewer. Execution is the test of the
design. For routine work that is fine. For high-stakes sequences (control-plane changes,
governance surfaces, launchd, anything hard to reverse) David wants a **pre-build design
review**.

**Constraints that are settled and not up for redesign:**
- Findings only. The review never routes work, never authors a decision, never claims
  authority. Authority-shaped questions go to David through the existing escalation path.
- Role invariant: whoever reviews is neither the pen that drafted the sidecar nor the
  Verifier that ratifies it.
- No lane writes into a folder another lane watches; the OI's tracking record has a
  single writer (the orchestrator).
- Fail closed: an absent or unreadable verdict is never a pass.
- Narrow trigger — most sequences must not pay for this.
- David's ruling (2026-08-17): it should **not** be a single judge invoked inside the
  orchestrator's wake; it should be **a team of agents with different areas of focus,
  stress-testing the design**, and **a Codex session should be one of them**.

**Your Part A deliverable — design it as you would build it:**
1. The shape: how many reviewers, what each one is for, parallel or sequential, and why.
2. The inputs each reviewer gets (and deliberately does *not* get).
3. The output schema: what one reviewer returns, and how the set becomes one verdict
   without a further model judgment.
4. The plumbing: who hands the sidecar to the panel, who consumes the verdict, where files
   live, what state the OI holds meanwhile — under the constraints above.
5. The trigger: what mechanical fact(s) decide a sequence gets reviewed.
6. The loop: what happens on a failing verdict, how many rounds, what ages out to David.
7. Where in the PM build order it must land, and what it costs per reviewed sequence.
8. **The questions.** The list you would put to the Designer to decide whether the proposed
   design is the *best* option — not merely a valid one. Group them however you like.

## Part B — the Codex seat, specifically

David wants you on the panel because your failure modes are independent of ours. Tell us
how you would want to be used:
- What should you be given — the sidecar alone, with no chat context? the brief? the live
  code tree? — and what should you *not* be given, so that you stay independent?
- What can you catch that a second Claude reviewer cannot? Be concrete about the mechanism,
  not the brand.
- Two roles we are considering for you: (i) *the adversarial implementer* — "build this
  from the spec alone; where do you stall, guess, or do the wrong thing confidently?" and
  (ii) *the laziest-passing-implementation test* — "for step k's verification, write the
  minimal implementation that passes it; if you can, the verification is vacuous." Are
  those the right roles for you? What would you add or replace?
- Your sandbox is default-deny (`-C` + `--add-dir`). What is the minimum you need mounted
  read-only to do this job, and what output path should be your only write?

## Part C — now read our proposal, and critique it

Read the **last Progress bullet** of `ACI-260029-260817-Open.md` (dated 2026-08-17 ~16:5x)
and its "Design questions" section. Our current proposal, in brief: placement between
P-2 and P-3b of the PM build order; a panel where each seat holds one lens
(alternatives / intent / failure-modes / verification / sequencing / boundary / cost /
operability / Codex-adversarial), findings consolidated mechanically into
`proceed / return-to-designer (numbered mandate list) / escalate`; borrow the executor
reviewer's discipline (session judges, deterministic code moves; three-outcome
vocabulary; mandate list; return bound; version-controlled templates) but fail closed;
trigger = the P-2 checklist's `control-plane` class, or affected designs docs named, or
requester flag; loop bound reused from DEC-0093 (cap 3, progress judgment, ~24h age-out).
Open: seat roster and count (a four-seat compression is under consideration — one of them
Codex, always), whether the top tier goes to David supervised, the exact trigger set.

Then:
1. Where does your Part A structure differ from ours, and which is better, and why?
2. What would you **cut** from ours? (Be specific — a review that costs more than the
   mistake it prevents is a mistake.)
3. What would you **add**?
4. Which of our questions-to-the-Designer are weak (answerable by boilerplate) and what
   sharper question replaces each?
5. What is the single most likely way this review, as we have drawn it, fails to catch a
   bad design? Name the blind spot.
6. Anything in the proposal that violates a settled constraint above, or a rule in your own
   bootstrap, that we missed.

## Ground rules for this session

- **Read only**, except for one file: write your memo to
  `~/Documents/Agent_Workflow/Design/ACI-260029-codex-review-20260817.md`. Nothing else is
  created, moved, or edited. No estate IDs minted, no governance files touched, no git
  operation (the nightly sweep owns commits).
- Tag every claim about how the system works today with the file and section you read it
  from; tag opinion as opinion. If you could not open a file, say "not read" — do not
  reconstruct it from context.
- Length: as long as it needs to be, no longer. Headings matching Parts A / B / C. Lead
  each part with the plain-English answer, then the detail — David reads this first.
- Do not soften disagreement. If you think the panel is over-built, say so and show the
  smaller shape.

When the memo is written, reply in-chat with a five-line summary: your recommended shape in
one sentence, the top thing you would cut, the top thing you would add, the blind spot, and
the one question you would put to the Designer above all others.
