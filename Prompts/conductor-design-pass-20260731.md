# Design pass — deterministic multi-model orchestration for Agent Workflow

**Authored:** 2026-07-31 by Cowork chat `remote_44bd64f7-d5c2-55c4-a4cb-74c3f6ee14fe`
**Run as:** David-supervised terminal session, `claude --model fable`
**Anchor:** **CLD-00109** (Conductor-like deterministic multi-model orchestration — the design
workstream this pass serves). Inherits three threads from CLD-00073: the analyst role,
reviewer=judge separation, and SME role packages.

---

## Mode

You are running a **design pass**. This is not a build.

- **Read-only** on all code and records. The **only** file you create is the deliverable named at
  the bottom. Do not modify any script, do not write into any `inbox/`, do not run the machinery,
  do not run git commands, do not create action items or DECs.
- **Run autonomously to completion. Do not stop to ask questions.** Where the record is silent, or
  where a choice belongs to David, make your best recommendation, mark it inline as
  `[DECISION REQUIRED]` with the options and a recommendation, and keep going. Surfacing open
  questions **in the document** is the goal. Halting the session on one is a failure.
- Where you are uncertain about a fact, say so explicitly in the document rather than asserting.
  Every claim about how the system behaves today must cite its evidence — `file:line`, a DEC id, or
  a CLD id. Claims you could not verify must be labelled as unverified.

---

## Objective

Design how **deterministic multi-model orchestration** should work inside Agent Workflow.

The capability is the one the open-source `microsoft/conductor` project demonstrates. **Do not
treat that project as the specification and do not propose adopting it as a dependency** — the
decision already taken is to take the *properties* and build the equivalent into this system.
Those properties are:

- routing between steps is **declared and deterministic** — a model does not decide what happens
  next; the topology is data, evaluated by code
- the topology is **inspectable and version-controlled before it runs**, so it can be reviewed in a
  diff rather than inferred from logs
- **per-step model selection**, including across vendors
- steps exchange **structured typed outputs**, not shared conversation state
- **parallel fan-out** and **sequential pipelines** are both first-class
- **explicit human gates**
- **deterministic script steps** sit alongside model steps as equals

After this pass, David should be able to read one document and know: what the shape is, what it
changes about the current system, what it costs, in what order it would be built, and what he
personally has to decide.

**There is a concrete worked example — read §F before you start answering A–E.** The Scout →
Analyst venture pipeline (questions 18–21) is a real pending change, not an illustration invented
for this brief. It is the first instance of the department framing in §Settled item 2, and it is
the cheapest place to make the abstract parts of this design concrete. Ground A–E in it wherever
you can rather than reasoning only in the abstract.

**There is also a live problem the design must solve — read §G before you start answering A–E.**
The notification surface (questions 22–25) is not a detail of escalation; it is the reason
escalation currently under-delivers. David has stopped reading the channel the machinery notifies
him on. Question 9's escalation predicate and §G's surface question are two halves of one answer —
design them together, not in separate places.

---

## Required reading

Read these in this order. **Do not explore beyond this list** unless a specific question forces it
— budget is real and this is a large repository.

**1. The conversation that produced this brief — the primary substrate.**
`~/Claude/transcripts/cowork/remote_44bd64f7-d5c2-55c4-a4cb-74c3f6ee14fe.md`

This is a long consultation between David and Cowork on 2026-07-31. It contains the framing,
David's own words on what he wants, several conclusions already reached, and one place where Cowork
was wrong and corrected itself. Read it fully and carefully. **Where this document and the
transcript disagree, the transcript's later statements win.**

**Scope limit on that precedence rule — important.** That transcript covers the consultation that
produced sections A–E only. **§F (the Scout → Analyst pipeline) was decided later the same day in a
different chat and is NOT in it.** Do not treat §F as unsupported because this transcript is silent
on it.

**1b. The second consultation — the substrate for §F.**
`~/Claude/transcripts/cowork/remote_815d6db1-eaff-58d4-88cb-0c9ab2912f1f.md`

The chat in which David reviewed The_Librarian's cycle reports, split the Build C gate (DEC-0100),
and then proposed and ruled the Scout → Analyst pipeline. Read it when you reach §F. The same
precedence rule applies within §F's scope: where this brief and that transcript disagree, the
transcript's later statements win.

**State of this file.** It was opened as a header-only bootstrap and backfilled from the container
session record on 2026-07-31 at 21:15Z — **turns 1–7 are present**, each stamped with an
`export-remote-transcript.py` provenance line. The foot sentinel reads `AFTER_TURN_7`. The chat's
final turn is **not** captured (the converter always excludes the in-flight turn); it contains only
the backfill itself and the edits to this prompt file, so nothing of substance is missing.

**Sanity check before relying on it.** If the file instead ends at `AFTER_TURN_0` with no turn
blocks, the backfill was lost — say so in your "could not verify" list and fall back to the records
below, which are authoritative regardless:

- the **"First worked example"** section of CLD-00109
- the 2026-07-31 Progress entries on CLD-00089

Those two are sufficient to answer questions 18–21 on their own. The transcript adds David's own
phrasing and his reasoning in the moment; it is corroboration, not the foundation. Do not block on
it either way.

**2. The machinery as it is today.**
- `~/Documents/Agent_Workflow/README.md` — lanes, roles, conservative defaults
- `~/Documents/Agent_Workflow/_meta/schema.md` — prompt-file and intake formats, OI status
  vocabulary, screen behaviour
- `~/Documents/Agent_Workflow/orchestrator/orchestrator.sh` — read the V/D invocation region
  (~`:840–930`), the adjudication/auto-route region (~`:1990–2230`), the escalation composer
  (~`:960–1000`), and the model settings at `:49–53`. You do not need to read all of it.
- `~/Documents/Agent_Workflow/code/worker.sh` — the claim/execute/outcome path, especially the
  model handling at `:707` and `:815`, and `append_result` at `:263–300`
- `~/Documents/Agent_Workflow/_lib/run_claude.sh` — the anti-hang runner; note the 4th-argument
  model parameter and the CLD-00072 budget model
- `~/Documents/Agent_Workflow/_meta/screen.py` — the mechanical screen; note `MODELS` at `:59`
- `~/Documents/Agent_Workflow/_meta/intake-consultation-template.md` and
  `_meta/authoring-contract.md`

**3. The governing decisions.** From
`~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`: **DEC-0082** (auto-route, exact-copy),
**DEC-0089** (fail loud, bounded), **DEC-0091** (capability grants; record-verified authorization),
**DEC-0093** (escalation tier 1, clarification vs interview vs consultation), **DEC-0094** (project
tag, spine-to-index pattern), **DEC-0095** (authoring contract), **DEC-0097** (close criteria and
self-close), **DEC-0098** (objective-level intakes), **DEC-0099** (decisions route through the
consulting surface; Telegram notification-only).

**4. The open items that own adjacent territory.** From `~/Claude/memory/action-items/`:
**CLD-00109** (this pass's own anchor — read it first; it states the settled inputs and the
inherited threads), **CLD-00043** (agent coordination layer), **CLD-00073** (coordinator role +
role separation — the parent; read its role-architecture, role-packages, and human-gating-v2
sections, not its full Progress log), **CLD-00072** (adaptive timeouts; options 2 and 3 unbuilt),
**CLD-00065** (ChatGPT Evolution; the OpenAI BAA findings), **CLD-00096** (single semantic layer),
**CLD-00106** (per-task model field — opened today; read it, several of its findings are load-
bearing here).

**5. The Scout → Analyst worked example (§F).** These are the evidence base for questions 18–21.
Read them only when you reach §F — they are not needed for A–E.
- `~/Claude/memory/action-items/CLD-00109-260731-Open.md` — the **"First worked example"** section.
  This is the authoritative statement of what David agreed to.
- `~/Claude/memory/action-items/CLD-00089-260727-Open.md` — The_Librarian's anchor. Read the
  **Vision** block (her content-only charter), **settled point 5** (the P3 autonomy grant and its
  bounds, which §F inherits), **settled point 2** (the P2 deep-research trio — the path the
  Analyst's research requests would reuse), and the **2026-07-31 Progress entries**. Skip the rest
  of the Progress log.
- `~/Documents/Agent_Workflow/librarian/topics.md` — the David-owned focus register and the
  five-criterion rubric plus the compliance-adjacency hard flag. Note the header comment: David
  edits it, machinery only reads it.
- `~/Documents/Agent_Workflow/librarian/ideas-ledger.md` — the entry schema and field rules. Note
  it is **empty of entries**; verify that before relying on the claim.
- `~/Claude/memory/action-items/CLD-00108-260731-Open.md` — context on why the P1 half is held.
  Background only; §F does not touch P1.
- From `COWORK-DECISIONS-2026.md`: **DEC-0090** (The_Librarian architecture; item 5 is the P3 grant
  §F would supersede, item 6 slug parity) and **DEC-0100** (the gate split — note the
  **amended-in-part banner at its head**: its release of P3 was suspended the same day by DEC-0101,
  which is on reading list 6. Read the banner before reading item 1).

**6. The notification surface (§G).** Evidence base for questions 22–25. Read when you reach §G.

**Precedence note — the same shape as §F's, and read it carefully.** §G was decided in a **third**
chat (`remote_77a9151d`, 2026-07-31 afternoon), later than both transcripts above. **Neither
transcript contains it.** Do not treat §G as unsupported because they are silent on it, and do not
let the "transcript's later statements win" rule pull you back to a superseded position on P3 — the
transcripts predate DEC-0101. **Do not go looking for that third transcript.** It is a live chat and
may be incomplete at the time you read; the records below are the authoritative statement and are
sufficient on their own.

- From `COWORK-DECISIONS-2026.md`: **DEC-0101** (the withdrawal of the Build C intake, the
  suspension of DEC-0100 item 1, and the Telegram pullback as a design input). Its item 5 is the
  authoritative statement of what §G asks you to design. Read **DEC-0100** with the
  amended-in-part banner now at its head.
- `~/Claude/memory/action-items/CLD-00109-260731-Open.md` — the **"Notification surface"** section
  and the **"Update 2026-07-31 … DEC-0101"** block inside "First worked example". Both are new;
  re-read this item even if you read it for §F.
- `~/Claude/memory/action-items/CLD-00089-260727-Open.md` — the **final** 2026-07-31 Progress entry
  (the withdrawal). It supersedes the two entries above it on P3's status.
- `~/Documents/Agent_Workflow/_lib/notify.sh` — the notification path. Note `:156`: an unreadable
  token file degrades to desktop-only plus a ledger FLAG, and there is **no fallback to the
  machinery bot**. Verify this before relying on it.
- `~/Documents/Agent_Workflow/librarian/librarian-cycle.sh` — note `:144`, the token filename it
  expects. Compare against what exists on disk (`ls ~/.config/cowork-workflow/`). The two do not
  match; confirm the direction of the mismatch yourself rather than taking this brief's word.
- From `COWORK-DECISIONS-2026.md`: **DEC-0090** item 8 (the separate-bot-identity requirement) and
  item 7 (why ledger traffic was separated from alert traffic in the first place) — the two
  decisions §G may need to amend.

*(DEC-0099 and DEC-0089 are already on list 3 above; both are load-bearing for §G.)*

---

## Settled — do not relitigate these

These were decided in the consultation or in the record. Treat them as given; note it prominently
if you believe one is wrong, but design *from* them.

1. **Not adopting `microsoft/conductor` as a dependency.** Build the equivalent.
2. **Planning decides which approach; implementation decides how to carry it out.** The split is
   real and the design should honour it.
3. **Resident vs reviewer.** Actors with continuity (Cowork, Alfred) have their own memory.
   Models invoked as reviewers do not, and are arguably better without it — an adversarial reviewer
   that shares your accumulated context shares your assumptions. N models does **not** mean N
   memory systems.
4. **Program stages vs execution phases.** Program stages are decision boundaries and get human
   off-ramps. Execution phases are dependency ordering inside one objective and do **not** involve
   David. Both are real and they nest.
5. **Escalation is trigger-driven, not schedule-driven.** David is pulled in when a named condition
   is crossed — typically impact on another system — not at periodic checkpoints.
6. **Lens diversity beats vote redundancy.** Asking three models "is this good?" buys one opinion
   three times. The useful questions are "is there a better way", "give three alternatives",
   "what fails here that nobody named".
7. **Anything Atman-adjacent stays out of non-BAA-covered vendors.** The OpenAI gate is closed
   (CLD-00065). Non-PHI project work (`cowork-evolution`, `wiki-redesign`) is unconstrained.
8. **The existing OI lifecycle stays.** Intake → screen → OI → V/D → route → execute → review →
   deliver → close, with escalation to the consulting surface, is the frame. Design *within* it.
9. **Revenue-idea work leaves The_Librarian and is designed here, not as a parallel workstream.**
   David ruled this on 2026-07-31 (see §F). The two-department Scout → Analyst shape, the Analyst's
   output being a formal business proposal rather than a third department, The_Librarian's reduction
   to research supplier, and the requirement that **both stages be capped** are all David's rulings
   — design from them. The specific cap *numbers* are open and are yours to propose (question 19).
   What is **not** settled: the lane topology, where the ledger lives, whether promotion is
   automatic or human-gated, and the request channel — those are questions 18–21.

   **Status correction (DEC-0101, later the same day — this is the current state):** the intake that
   would have built P3 inside The_Librarian's lane (OI-000027) was **withdrawn and archived** before
   it executed, and **DEC-0100 item 1's release is suspended, not revoked.** Nothing was built. P3's
   disposition is therefore settled as **MOVED** — the close criterion asking you to state "moved,
   retained, or split" is answered; what remains yours is *how*. Sources written before ~14:00 PT on
   2026-07-31, including both transcripts on the reading list, describe P3 as released and a build as
   pending. They are stale on that point. The weekly digest moves with P3 for the same reason (it
   summarizes P3 output and has nothing to report without it) — design it as the pipeline's
   reporting surface.

10. **The notification surface is folded into this pass** — David's explicit choice, offered four
    dispositions and picking "settle it in the design pass" (DEC-0101 item 5). What is settled is
    only that *this pass owns the question*. Everything about the answer is open, including whether
    Telegram survives at all and whether per-lane bot identities are still the right shape.
    **DEC-0099 and DEC-0090 item 8 stand until this pass proposes otherwise** — you may recommend
    amending either, prominently, but do not assume either is already dead.

11. **Model tier is a per-lane, per-task choice. There is no global default to set.** David,
    2026-07-31: *"I expect to use different models depending on what is required."* Propose tiers per
    department with reasoning; do not propose a single system-wide model setting.

---

## The questions the design must answer

Answer each explicitly. Where you defer one, say so and say why.

**A. Shape of the orchestration primitive**

1. What is the declarative unit — what does a "workflow definition" look like in this system, where
   does it live, and what reads it? Justify the format choice against the fact that `screen.py`,
   `oilib.py`, and the worker are already the parsers of record.
2. How do the two geometries differ concretely: the **deliberative fan-out** (parallel, divergent,
   several lenses on one question, converging to a recommendation) versus the **productive
   pipeline** (sequential, convergent — author → adversary → revise → test → verify)? What does
   each need that the other does not?
3. How does a step's structured output get carried to the next step in a system whose state
   substrate is files, not a runtime? What is the durable record of a fan-out?

**B. V/D and the planning department**

4. David's proposal, arrived at in the consultation: **treat V/D like the Code worker — its own
   lane with its own queue — rather than an agent spun up inline inside the orchestrator wake.**
   Assess this. It is the central architectural question of this pass. Cover at minimum: what it
   buys (per-item model selection for free, the CLD-00072 budget model, natural fan-out, artifacts,
   a reviewer), what it costs (V/D becomes asynchronous — `verifying` turns from an in-flight
   moment into a real waiting state; a third launchd daemon or contention on the serial drain), and
   the recursion question it raises — *what screens the V/D task, given "screen at every promotion"
   is a standing invariant (CLD-00043)?*
5. V/D today runs on **every** intake and is cheap by design. If it also becomes the planning
   department, what triage decides whether the expensive planning fan-out is convened at all?
   David's framing: *"it starts with 'is this a well formed request', then it moves to 'how should
   we do this'."* Design that router — its inputs, its three-or-more outcomes, and where the
   decision is recorded.
6. Should a **study** (a pass whose deliverable is a recommendation rather than a change) be a
   distinct work type alongside the current executable task? If yes: its close criteria, its
   verification bar (you verify *reasoning* — were alternatives genuinely considered, is the
   evidence cited, does the conclusion follow — not that code works), its destination, and how it
   differs from an ordinary task in the schema. If no: what carries that work instead?

**C. Departments, loops and off-ramps**

7. David's model is organisational: a **Planning Division** and an **Implementation Division**, each
   with departments focused on specific areas, sequenced under stated circumstances, forming loops
   with off-ramps when something real needs his input. A department in an organisation has five
   things — a charter, an input contract, an output contract, an escalation rule, and a budget.
   Show whether that maps cleanly onto a step definition in your design. If it does, use David's
   vocabulary in the document.
8. **Loop termination.** Planning and implementation can ping-pong. Every loop needs a termination
   criterion and a round budget. DEC-0093's one-round clarification bound is existing prior art —
   reuse the pattern rather than deriving a second one, or justify diverging.
9. **The escalation predicate.** What makes an issue "real" enough to pull David in? Design the
   predicate — how impacted systems get named up front, how it is re-evaluated when implementation
   strategy reveals impacts planning missed, and where it is recorded.

**D. Multi-vendor**

10. How do non-Anthropic models participate? Cover the mechanics (invocation, credentials, failure
    handling, timeout, cost accounting) and the **authorization** question: a non-Anthropic step
    must sit behind the existing screen, not beside it, or it becomes a second front door.
11. **Cold lenses versus anchored lenses.** A cold lens sees only the objective and constraints and
    never sees the proposal, so it produces an independent answer to compare. An anchored lens sees
    the proposal and attacks it. Both were judged useful. How does the design express each, and
    what does the synthesizer do with the difference?
12. **The synthesizer must not be one of the lenses** — otherwise its view wins by construction.
    Design around that. Consider whether the synthesizer's job should be *"where did they disagree
    and what does each disagreement imply"* rather than *"what is the answer"*.
13. Constraint to respect: model choice today is gated by `screen.py`'s `MODELS = {"sonnet",
    "opus"}` allowlist, and there is currently **no path at all** from a request to V/D's model
    (`VD_MODEL` is a launch-time env var). CLD-00106 holds this. State what your design needs from
    it, but do not design CLD-00106's fix here.

**E. Cost, risk and sequencing**

14. Every actor draws from **one shared weekly subscription pool**. A fan-out multiplies cost by
    the number of lenses. What governs spend, and what happens when a fan-out would exceed budget —
    degrade, queue, or refuse?
15. What breaks if this is built? Name the specific existing behaviours at risk.
16. **Propose a staged rollout** — the smallest first increment that delivers real value and is
    independently useful if nothing after it is built, then subsequent stages with what each
    unlocks. For each stage: the objective, the close criteria, and whether it needs a DEC before
    it can be built.
17. What should be built **last or never**? Say plainly which parts are speculative.

**F. The first worked example — the Scout → Analyst venture pipeline**

Added 2026-07-31 by David after the prompt was first written. Use this as the **concrete worked
example** throughout your answer rather than reasoning only in the abstract — it is the first real
instance of the Planning Division / departments framing.

Background: The_Librarian currently owns P3 — self-directed revenue-idea dives inside a David-owned
focus register (`~/Documents/Agent_Workflow/librarian/topics.md`, single active topic *recurring
revenue streams using AI*), scored on a five-criterion rubric with a compliance-adjacency hard flag.
P3 was released under DEC-0100 on 2026-07-31 and then **suspended the same day under DEC-0101**,
with the build intake withdrawn before it executed; `librarian/ideas-ledger.md` is still **empty** —
no ideas have ever been generated, and none will be in her lane. David ruled that this work moves out
of The_Librarian and into this design, on two grounds: it costs nothing to move now, and revenue
ideation does not fit her charter (she works content — The_Library and The_Wiki — never machinery).

The shape he agreed to:

- **Scout** — generates high-level ideas inside the focus areas, scores them, and stops. Cheap,
  shallow, high volume. Output is an **idea stub**.
- **Analyst** — takes one promoted stub and tests viability and monetization. Output is a **formal
  business proposal**; the document is the Analyst's output format, not a third department.
- **The_Librarian becomes the research supplier** — the Analyst raises specific research requests,
  she finds sources and makes Library deposits. Effectively the existing P2 path with a machine
  requester.

Answer these:

18. Are Scout and Analyst **two lanes, or one lane with two step types**? Recommend, with the
    operational consequences of each (services, drains, ledgers, failure isolation).
19. **The gate.** David explicitly requires limits on how many stubs reach the Analyst and how many
    the Analyst works in a day. Proposed defaults to react to — adjust and justify: Scout ~5 stubs
    per night; promotion requires a score threshold **and** a rank cut, at most 2 per week; Analyst
    one active dive at a time, one per day, one opus night slot per dive. Is promotion automatic,
    or a human gate? How does the compliance-adjacency hard flag survive the split?
20. **Where does the ideas ledger live** once it is no longer The_Librarian's file, and who may
    write to it? Note that `topics.md` is a David-owned, machinery-read-only file and that property
    must be preserved wherever it lands.
21. **How does the Analyst request research from The_Librarian** — through the orchestrator front
    door (audited, slower) or a direct lane-to-lane channel (faster, less visible)? Recommend, and
    say what the screen-at-every-promotion invariant (CLD-00043) requires of your answer.

Also fold this example into your answers to questions 14 (shared weekly pool — a gated pipeline is
the concrete cost case) and 16 (staged rollout — is Scout-alone a viable stage 1?).

**G. The notification surface — how the machinery reaches David at all**

Added 2026-07-31 by David, later than §F and in a different chat (see reading list section 6). This
is a live failure, not a hypothetical. **Do not treat it as a subsection of §F** — it applies to
every lane, existing and proposed.

Background, in David's words: *"I've noticed that almost all communications run through the
Orchestrator token. Both exist, but at this point I'm pulling back on using Telegram for most
things. Too much noise with not enough information and lost responses at times means I'm ignoring
now."*

Three separate defects are bundled in that sentence and the design should treat them separately:
**volume** (too many notices), **payload** (a notice that does not carry enough to act on), and
**reliability** (replies that are sometimes lost — which matters more than volume, because a
channel that drops responses cannot be a decision channel at all). CLD-00105's edge-triggered fix
(delivered 2026-07-31) addressed volume only.

Note the standing tension: DEC-0089 requires the machinery to **fail loud**. A quieter notification
surface must not become a quieter *failure* surface. Reconciling those is the substance of this
section.

Answer these:

22. **Which classes of event should reach David at all, and on what surface?** Enumerate the classes
    the machinery actually produces today (blocking decisions, escalations, hold/stale conditions,
    completions, digests, FAILs, FLAGs) and assign each a disposition: push to a channel, wait in
    the record for the next session, or neither. Recommend a specific surface per class. Options
    David was offered and did not choose *are still on your table* — he deferred, he did not rule
    them out: stop pushing entirely and rely on the record; email restricted to blocking items;
    Telegram at a much higher bar. Consider also whether the daily log / session-start read is
    itself the primary surface, with push reserved for what cannot wait.
23. **What must a notice contain to be worth sending?** David's complaint is *"not enough
    information"* as much as volume. Specify a payload contract per class — what a notice must
    carry so he can act or triage without opening another file, and what it must link to. A notice
    that only says something happened is a design failure under this bar.
24. **Reliability.** Replies are sometimes lost today. If any class of notice invites a *response*
    (a decision, an approval), what makes the response path trustworthy — acknowledgement,
    idempotent re-delivery, a durable record written before the notice is sent, or moving that class
    off push entirely and onto the consulting surface where DEC-0099 already routes decisions?
    Recommend, and be explicit about what your recommendation gives up.
25. **Per-lane identities.** DEC-0090 item 8 requires The_Librarian to have her own bot identity,
    and DEC-0090 item 7 separated ledger traffic from alert traffic. On disk that separation is
    configured; in code it is broken (see reading list section 6). With every lane you are proposing
    in this design — Scout, Analyst, a V/D lane — does per-lane identity still scale, or does the
    surface want a single addressed channel with a `from:` field? Say what your answer means for
    DEC-0090 items 7 and 8: upheld, amended, or superseded.

Fold §G into question 9 (the escalation predicate) explicitly — the predicate decides *when* David
is pulled in and §G decides *how he finds out*; an answer to one that ignores the other is
incomplete. Fold it into question 16 as well: if the notification surface needs work before any
fan-out is trustworthy, say which stage owns it.

---

## Explicitly out of scope

- The semantic-layer placement question (which knowledge lives in The_Wiki vs a system practice
  layer vs actor memory). CLD-00096 owns it; a consultation is pending. Note dependencies, do not
  design it.
- CLD-00106's implementation.
- The Alfred / Azure OpenAI provider question — deferred to the Alfred workstream.
- Anything requiring PHI-covered vendors.
- Filing intakes, opening action items, writing DECs, or touching code.

---

## Deliverable

One document at:

`~/Documents/Projects/cowork-evolution/Design/conductor-orchestration-design-20260731.md`

Structure it for a reader who is technically literate but not a programmer: lead with the
plain-English shape before the mechanics, define any term of art on first use, and prefer concrete
examples over abstractions. Diagrams in Mermaid are welcome where a sequence or topology is easier
seen than read.

It must contain, clearly marked and easy to find:

- an executive summary that stands alone
- your answers to the questions above, in a structure you choose
- a `[DECISION REQUIRED]` section collecting every point that needs David, each with options and
  your recommendation
- an explicit list of what you could **not** verify
- the staged rollout
- a self-contained section on the **Scout → Analyst worked example**, written so David can read it
  without reading the rest of the document, and stating explicitly what happens to The_Librarian's
  existing P3 grant (DEC-0090 item 5) — superseded, narrowed, or left standing
- a self-contained section on the **notification surface**, also readable on its own, containing
  the per-class table asked for in question 22 and stating explicitly what happens to DEC-0099 and
  to DEC-0090 items 7 and 8 — upheld, amended, or superseded

**Verification bar** — before you finish, check your own document against these and fix what fails:

1. Every claim about current system behaviour cites `file:line`, a DEC id, or a CLD id.
2. Every question in section "The questions the design must answer" is either answered or
   explicitly deferred with a reason.
3. Nothing in the "Settled" list is contradicted without a prominent flag.
4. Each proposed stage has close criteria that could be mechanically checked.
5. Nothing in "Out of scope" has been designed.
6. No file other than the deliverable was created or modified.
7. The Scout → Analyst example is used as a concrete illustration in at least the cost (14) and
   staged-rollout (16) answers, not quarantined in §F.
8. Both throughput caps in question 19 are answered with **specific numbers and a justification**,
   not deferred to David — he asked for limits and expects proposed values to react to.
9. Question 22 is answered as a **table with a row per event class**, each with a surface and a
   payload — not as prose about principles. Every class the machinery produces today appears in it.
10. The §G answer states plainly whether the design **quiets the failure surface**, and if it does,
    how DEC-0089's fail-loud requirement is still met. An answer that reduces noise without
    addressing this fails the bar.
11. Nothing in the document treats The_Librarian's P3 as buildable in her lane or its build as
    pending. DEC-0100 released it in principle; DEC-0101 suspended that release and the intake was
    withdrawn before it executed. Saying "released but suspended pending this design" is correct;
    saying "released, build pending" is not. If a source you read says otherwise, name the source and
    its date rather than following it.

Length should follow content. Do not pad, and do not compress away reasoning David would need in
order to disagree with you.
