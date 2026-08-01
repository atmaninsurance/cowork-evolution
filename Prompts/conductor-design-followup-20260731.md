# Follow-up design pass — the review surface, and the venture pipeline under machinery-selects

**Authored:** 2026-07-31 by Cowork chat `remote_77a9151d-8ecd-52ee-91b7-dab678f0ac21`
**Run as:** David-supervised terminal session, **Opus** (per DEC-0102 ruling 3 — not Fable; Fable is prompted on demand for a more exhaustive pass, and David has not asked for one here)
**Anchor:** **CLD-00109**. Authorized by **DEC-0102 item 10**.
**Predecessor:** `Prompts/conductor-design-pass-20260731.md` → `Design/conductor-orchestration-design-20260731.md` (the main pass, complete and adjudicated).

---

## Mode

A **narrow** design pass. Same rules as the main pass:

- **Read-only** on all code and records. The only file you create is the deliverable named at the bottom. No script edits, no `inbox/` writes, no git, no action items, no DECs.
- **Run autonomously to completion. Do not stop to ask questions.** Mark anything that belongs to David inline as `[DECISION REQUIRED]` with options and a recommendation, and keep going.
- Every claim about current behaviour cites `file:line`, a DEC id, or a CLD id. Anything you could not verify is labelled and collected at the end.

**This pass does NOT reopen stages 3–5, or any of the main design's other conclusions.** They are decided (DEC-0102). If your work here surfaces something that genuinely contradicts one of them, say so prominently in a single flagged section — do not quietly redesign around it.

---

## Why this pass exists

The main pass completed at 14:44 PT on 2026-07-31. Two things changed afterward that it could not have known:

1. **The weekly digest it relies on does not exist**, and its build was withdrawn at 14:58 (DEC-0101). The main design made the digest the surface at which David personally approves each idea for promotion (design §Q19). Both halves of that are now different: the digest must be *built* as part of stage 1 (David's instruction), and it is no longer an approval gate.
2. **The notification-surface question was answered**, in a direction none of the main pass's material anticipated. See DEC-0102 ruling 2.

Everything else in the main design stands.

---

## The two rulings that drive this pass

Read DEC-0102 in full before starting. The two that shape the work:

**Ruling 1 — the machinery selects; David reviews the selection.** Verbatim: *"I prefer a method of learning what interests me rather than getting approvals as we go. Let's see what gets selected. If I think it was a poor choice I'll say so and we can discuss why. Use those sessions to fine tune what is important and what is not."* Scoped to **anything reversible**; the machinery stops only for material spend above a ceiling and for irreversible acts. Existing red-line classes are unchanged and sit above this.

**Ruling 2 — the review surface is the session start, not a push channel.** *"Can we use the Claude iphone app as a communication vehicle? Every startup includes a look at open items, so questions can be posed in chat."* The startup protocol's open-items read IS the surface. A question reaches David with its context around it rather than as a line in a chat app.

**Platform correction — David, 2026-07-31, later the same chat. This narrows ruling 2 and DEC-0102's
description of it; design from THIS, not from the DEC's phrasing.** Verbatim: *"It depends on the
chat session. If I started a chat from the Mac connected to a local project, then I can chat with
you through that interface and you can take action locally. It doesn't look like I can initiate a
chat from the phone and connect it to a local project."*

So the surface is a **Mac-initiated session with a connected local project** — not the phone. The
phone can continue a session but cannot start one with local access, which means anything requiring
the machinery's state to be read or acted on happens at a desk. **Do not design a phone-first
surface.** Design for the Mac session, and note separately what (if anything) a phone-continued
session can still usefully show.

**Push is deferred, not declined.** David: *"Chatting will suffice for now, but once you're up and
running and I can focus on other things I'll need a more proactive method for you to reach me. That
might be email, text, Telegram (very limited pointing me to check status). We'll see."* Read this as
a **forward requirement**: the surface you design must not foreclose a later push channel bolted
onto it. Concretely — the thing that decides *what would be worth pushing* should be a property of
the surface's own classification (question 2), so that adding a channel later is a delivery change,
not a redesign. His own framing of the likely shape is a **pointer, not content**: "very limited,
pointing me to check status." Design question 4 with that in mind.

**The consequence that makes this a design problem rather than a config change:** since promotion is no longer David's act, the weekly digest's job becomes *"here is what I selected and why"* — which is exactly the calibration instrument ruling 1 depends on. **The digest and the session-start review are therefore one surface, not two.** Designing them as two would give David two places to look and a reason to look at neither, which is the failure mode he just described about Telegram.

---

## Required reading

**1. What was decided.** `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md` — **DEC-0102** (this pass's charter; all eleven adjudications and the three rulings), **DEC-0101** (the withdrawal; its item 5 is what ruling 2 answers), **DEC-0099** (the consulting surface as decision channel — still standing), **DEC-0089** (fail loud, bounded — ruling 2 reinterprets it; read the original before relying on the reinterpretation), **DEC-0090** items 5, 7, 8 (P3 grant, ledger-vs-alert traffic separation, the separate bot identity), **DEC-0100**, **DEC-0097** (close criteria and self-close).

**2. The main design.** `~/Documents/Projects/cowork-evolution/Design/conductor-orchestration-design-20260731.md`. Read **Part 7 (staged rollout)** and **Part 8 (the venture pipeline)** closely — those are what you are revising. Read Parts 1–6 once for context; you are not changing them. Note its §Could-not-verify list so you do not re-derive what it already flagged.

**3. The anchor.** `~/Claude/memory/action-items/CLD-00109-260731-Open.md` — read the whole file including the Progress log; the last two entries are today's.

**4. The notification machinery as it actually is.** Do not take the summaries below on trust — verify each:
- `~/Documents/Agent_Workflow/_lib/notify.sh` — the whole file. Note `:156`: an unreadable token file degrades to desktop-only plus a ledger FLAG and there is **no fallback** to another lane's bot.
- `~/Documents/Agent_Workflow/orchestrator/orchestrator.sh` — every `notify_david` call site. **Enumerate them**: this pass needs the actual list of things the machinery currently tells David, not a plausible one. Note CLD-00105's edge-triggering fix landed 2026-07-31 — read what it changed.
- `~/Documents/Agent_Workflow/librarian/librarian-cycle.sh` — note `:144`, the token filename it expects, and compare against `ls ~/.config/cowork-workflow/`. They do not match; confirm the direction yourself.
- `~/Documents/Agent_Workflow/_meta/check_staleness.sh` and the README's staleness section — the other current source of David-facing noise.

**5. What the session-start surface is today.** `~/Claude/memory/MEMORY.md` — the startup protocol, especially steps 4 (action-items index), 6 (nightly-ledger FLAG triage) and 7 (the greeting). **This is the existing surface you are extending.** Also `~/Claude/memory/action-items/_index.md` — its size and shape are the practical constraint: whatever you design has to survive being read at every session start without becoming the thing David skims past.

**6. The venture pipeline's substrate.** `~/Documents/Agent_Workflow/librarian/topics.md` (the David-owned register and rubric — note the ownership header) and `librarian/ideas-ledger.md` (the entry schema; **empty of entries** — verify).

---

## The questions

**A. The unified review surface**

1. **What is the surface, concretely?** One artifact, or a generated view assembled at session start from several? Where does it live, who writes it, when? Constraints it must satisfy: readable in the time David actually gives it at a session start; assembled from state the machinery already maintains rather than from a new parallel record; produced by the local machinery (the nightly chain or a lane wake), not by the chat session that reads it — so it exists whether or not a session ever opens; and structured so that a later push channel could carry a *pointer* to it without redesign (see the platform correction above).

2. **Which classes of thing surface there, and what must each carry?** Enumerate the classes the machinery actually produces (from your reading of item 4 above — the real list, not a plausible one): decisions genuinely needing David, escalations, holds and stale conditions, completions, FAILs, FLAGs, nightly-chain results, venture selections, wiki candidates. For each: does it surface at all, in which section, and **what must the entry contain so David can react without opening another file?** David's complaint about the retired channel was *"not enough information"* as much as volume — an entry that only says something happened is a design failure under this bar. Note his standing preference: for anything the Library surfaces he wants the **topic, the category (problem / efficiency / revenue), and the plain gist — not the mechanics**; and **wiki candidates are not to be surfaced to him at all** (they are evaluated against The_Wiki and general criteria and handled without him).

3. **How does fail-loud survive?** DEC-0089 requires the machinery to fail loud. With no push channel, "loud" means *impossible to miss at the next session start*. Design that: what makes a genuine failure structurally unskippable in a surface David reads quickly, and what stops the loud tier from inflating until it is the whole page? State plainly whether anything gets quieter than it is today, and what the cost is if David does not open a session for three days.

4. **Is there any residual push case at all?** Argue it either way and recommend. If yes, name the classes and the mechanism; if no, say what the machinery does instead when it is stuck (wait, and be first in the queue at next session start, is a legitimate answer).

5. **The platform question — verify, do not assume.** Cowork scheduled tasks fire in the cloud with no device bridge (CLD-00061 Datapoint 4, 2026-07-09), so a scheduled task cannot read the Mac and would have nothing substantive to say. **One candidate route exists and is unverified:** the nightly Stage-5 sweep pushes every repo to private GitHub remotes, so a cloud-side task could in principle read machine state from there. Assess feasibility — what would it need (credentials, and where they could live given DEC-0091 item 2's structural class), what it could and could not see, what it would cost, and whether it is worth building at all given ruling 2. **A clean "not worth it" is a good answer.** Do not design the implementation.
   Also flag as untested (do not attempt to test): whether the device bridge reaches the Mac when a session is viewed from the phone with the desktop app running.

**B. The digest, inside stage 1**

6. **What is the digest now?** It is a report, not a gate. Specify: contents, cadence, generator, destination, and its relationship to the surface in question 1 — if they are one thing, say what that one thing is; if they are not, justify two.

7. **What does it have to show for the calibration loop to work?** Ruling 1's whole premise is that David corrects the selection criteria by reacting to real selections. That requires the digest to show not just *what* was selected but *why* — enough of the scoring and the near-misses that a wrong pick is diagnosable. Design the entry shape. Include what a **rejected** idea's visibility should be: a selection is only judgeable against what it beat.

8. **Stage 1's close criteria are now different** — the main design's set assumed a human promotion gate (Part 7, stage 1). Restate them mechanically checkable under machinery-selects, including the digest.

**B2. The client-data rule, and what the lane may know about the book of business**

**Both of these are settled by DEC-0103 — read it. Your job is the mechanism, not the policy.**

David's correction, verbatim: *"I don't and won't sell client data. If an idea involves selling or
giving client data then it is not worth pursuing. That is different than targeting clients for a new
service. I can contact them through email or direct mail to share information. That is what I'll be
doing with the Wellness Program."*

So `topics.md` item 6 stops being a flag-for-human-read and becomes a **mechanical disqualifier**:
an idea whose business model involves selling, sharing or transferring client data to a third party
is **rejected**, not escalated. Marketing Atman's own services to Atman's own clients through Atman's
own channels is ordinary business and trips nothing. Note what this dissolves: item 6 as written
penalised the same thing scored criterion 5 (*fit-with-existing-assets*) rewards, and it was the
pipeline's only human gate under machinery-selects. **The pipeline now has zero human gates** —
address that squarely in your answer to question 12.

`topics.md` is David-owned and machinery-read-only; the edit is his to make and may not have landed
when you run. **Design against DEC-0103's statement of the rule, and note the file's state as you
found it.**

12. **Mechanise the disqualifier, and defend zero gates.** How is "the business model involves
    selling or transferring client data" detected reliably enough to auto-reject, given the judge is
    a model reading a one-paragraph stub? A false negative wastes a dive; a false positive silently
    kills a good idea, which is worse and invisible. Recommend the mechanism (a required declared
    field on every stub? a screen-side check? the Analyst re-testing it before diving?), and say what
    makes a wrongly-rejected idea *recoverable* — a rejected stub should still be visible somewhere
    David could overturn it. Then state plainly why a pipeline with no human gate is acceptable here,
    or what single gate you would keep.

13. **Design the aggregate book-of-business profile.** David: *"Agreed on never reading actual client
    data. What they could read is compiled reports that are non specific. such as david has X number
    of Medicare Advantage clients, X number of MedSupp, X number of IFP. This is information that
    Alfred might compile."*

    Without this, *fit-with-existing-assets* is scored against a guess — so this is not a nicety, it
    is what makes criterion 5 meaningful. Settle: where the file lives and its ownership contract
    (the `topics.md` shape — one writer, read-only to the lane); **that Alfred compiles it**, since he
    is the HIPAA-covered local actor with legitimate access and that keeps the boundary structural
    rather than a matter of the venture lane exercising restraint; the **permitted schema**
    (counts and distributions — product-line counts, tenure, renewal timing) and the **prohibited**
    content (names, dates, addresses, policy numbers, conditions, and any cell small enough to
    identify an individual — say how small-cell suppression is enforced); the **refresh cadence**,
    since a stale profile degrades every score derived from it silently; and how the venture lane is
    mechanically prevented from reading anything else (the `work_scope:` / post-run-audit pattern is
    the existing precedent).

    Flag as a dependency, not a design: this needs something on Alfred's side to produce it. Name
    what, and whether stage 1 can start without it (scoring criterion 5 on a stated assumption until
    the profile exists) or must wait.

**C. The fold-through**

9. **Restate stages 1 and 2** with: promotion as the machinery's act within the caps; the compliance-adjacency flag as the pipeline's **only** human gate (never machine-promotable at any score); research requests auto-routed from stage 2 on the enumerable condition the main design specified for stage 4 (DEC-0102 D6); and the digest built in stage 1. Keep the main design's cap numbers unless something you find contradicts them — they are ratified. Flag any place the inversion breaks something the main design was relying on.

10. **Design the scoring feedback loop — David's proposal, and it supersedes the "cheapest detector"
    framing this pass was originally going to ask for.** Verbatim: *"How about a scoring loop? Scout
    grades its own idea and sends it to the Analyst. The Analyst also grades the idea (maybe sending
    it to three models for grading) then provides feedback to the Scout. Feedback includes not only
    how well did you score yourself, but by extension what was important or not important, and what
    direction should be considered for future ideas."*

    This is the right instrument and it closes the loop rather than merely measuring drift — design
    it properly. Five constraints it has to satisfy, each of which is a real design problem:

    - **The Scout has no memory, and David asked directly where it should live.** Every night is a
      fresh session with no continuity (`_meta/schema.md:86–88`). Feedback is therefore **a file the
      Scout reads**, not a message it receives. David: *"Are you thinking a slim memory.md file or
      something like it, that provides those key learnings or do we point it to The_Wiki or some
      other memory layer? The Scout and Analyst must learn, so there must be some form of memory."*

      **Settle this explicitly — it is one of the two or three load-bearing answers of this pass.**
      The consulting surface's read, offered as a starting position to accept or beat: **three
      different things are being called memory here and they want three homes.** (1) The **ledger** —
      what was proposed and what happened; raw, append-mostly; exists today. (2) **Calibration** —
      how to score, what David valued, which directions died; operational, changes weekly, must stay
      small enough to sit in a prompt every night; a slim curated file in the venture lane. (3)
      **Durable knowledge** — what a dive actually learned about a market or a business model;
      encyclopedic and general; **The_Wiki, authored through The_Librarian**, which preserves the
      authorship boundary (DEC-0090 item 6) rather than giving the venture lane a second door into
      the commons. The argument against putting calibration in The_Wiki: the Wiki is a shared
      encyclopedia of durable general knowledge, and tuning state is local, operational and stale
      within a month — mixing them pollutes the commons and re-breaks the authorship boundary.
      Against the private memory store: that is David's memory, not the lane's.

      Note the structural parallel, and say whether it holds: this is the same three-tier shape
      David's own memory system already uses — raw daily logs, curated decisions, encyclopedic wiki.
      If it holds, **the curation discipline should be borrowed too**, because that is the part that
      actually keeps the middle tier usable: define the compaction rule that keeps the calibration
      file bounded (what gets promoted into it, what ages out, who runs the compaction and when).
      A learnings file that only accumulates becomes the whole prompt and then stops being read.
    - **David must be the anchor, or the loop drifts.** If the Scout tunes to the Analyst and the
      Analyst is also a model, the pair converges on machine consensus — two models agreeing is not
      calibration. **David's reactions at the digest must enter the same record and outrank the
      Analyst's**, and the schema should make that precedence explicit rather than implicit in
      ordering. State how a human correction is represented and how it wins.
    - **Coverage: the Analyst only sees what got promoted.** At ~35 stubs and ~2 promotions a week,
      an Analyst-only loop trains the Scout on 2 of 35 — it never learns why the other 33 lost.
      Consider a cheap tier that costs nothing: the gate already computes every stub's scores, so it
      can record *which criterion held each non-promoted stub back* mechanically, with no model call.
      Recommend the tiering (free / deep / anchor) or a better one.
    - **Three graders should ask three different questions, not vote three times.** The main design
      settled that lens diversity beats vote redundancy (Settled 6; design §Q11–Q12), and David's own
      stated preference is *"is there a better way to do this?"* / *"provide three alternative ways"*
      over *"is this good?"*. If the Analyst fans out, design it as distinct lenses — e.g. one
      re-scoring against the rubric, one asked for a materially better version of the idea, one asked
      what kills it — with a synthesis that preserves disagreement. Cost this against the budget:
      say what it adds per dive and whether it fits inside the one-opus-night-slot bound or needs a
      revised bound.
    - **"What direction should be considered for future ideas" is a first-class output, not an
      overflow — and exploring is explicitly NOT to be treated as a risk.** David, correcting this
      brief's earlier framing (DEC-0103 item 3): *"I don't know what I don't know. I need you to
      evolve and expand your ideas over time. I do not consider it a dangerous thing for you to
      explore new ideas. Taking action is constrained, resource allocation can be a limiter.
      Exploring new ideas is desired."*
      The distinction that survives is narrow: the Scout **proposing** a direction is wanted and
      should have a standing invitation, including directions outside the register entirely — those
      surface in the digest as proposals. What stays David's is **where sustained effort goes**,
      because that is resource allocation: the register governs what gets dives, and `topics.md`
      remains his edit (machinery never writes it). Design the proposal channel as a real output with
      its own section, and enforce only the write boundary mechanically.

    Deliver: the record's schema, who writes what and when, how it enters the Scout's prompt, how it
    is bounded, and how you would tell after four weeks whether the loop is working at all.

11. **Two carried findings that belong in the stage-1 build**, verified in OI-000027's clarification package (`~/Documents/Agent_Workflow/orchestrator/archive/2026/OI-000027.clarify.md`) — confirm both against the live tree and say what stage 1 must do about each: (a) no lane outside the machinery lanes pins `CLAUDE_BIN`, so a new venture lane's first model call would use the floating symlink — and its launchd plist needs fencing, `launchd` being an unowned capability (DEC-0100 names none; GRANT-0001 was one-shot and consumed); (b) the Librarian's bot-token filename is transposed between `librarian-cycle.sh:144` and disk.

---

## Explicitly out of scope

- Stages 3, 4 and 5, and every Part 1–6 conclusion of the main design.
- CLD-00106's implementation; the semantic-layer question (CLD-00096); Alfred/Azure; anything PHI-adjacent.
- Redesigning Telegram. It is being retired as the default surface, not fixed.
- Filing intakes, opening items, writing DECs, touching code.

---

## Deliverable

`~/Documents/Projects/cowork-evolution/Design/conductor-orchestration-design-followup-20260731.md`

An **addendum** — it does not restate the main design, it revises named parts of it. Same audience rules: plain-English shape before mechanics, define terms of art on first use, concrete over abstract, Mermaid where a topology is easier seen than read. Assume a technically literate reader who is not a programmer.

Must contain, clearly marked:

- a standalone executive summary
- a **per-class table** for question 2 — every class the machinery produces, its disposition, its surface, its payload
- the revised stages 1–2 with mechanically checkable close criteria
- a `[DECISION REQUIRED]` section, each item with options and your recommendation
- an explicit **could-not-verify** list
- a self-contained section on the **scoring feedback loop** (question 10), readable on its own
- a short section naming anything in the main design this pass **contradicts**, if anything

**Verification bar** — check your own document before finishing:

1. Every current-behaviour claim cites `file:line`, a DEC id, or a CLD id.
2. Question 2's class list came from **reading the call sites**, not from this brief's examples. If a class in this brief does not exist in the code, say so; if the code produces one this brief omits, add it.
3. The fail-loud answer (question 3) states plainly whether anything gets quieter than today, and what three days of no sessions costs.
4. Question 5 reaches a recommendation, including "not worth it" if that is where the evidence lands, and does not design an implementation.
5. Stage 1's close criteria are checkable by grep, diff or fixture — no criterion requiring judgment to evaluate.
6. Nothing out of scope is designed. Stages 3–5 are untouched.
7. The digest/session-start relationship is stated explicitly as one surface or two, with the reason.
8. Question 10's loop names its record's schema, its growth bound, and the mechanism by which a
   David correction outranks an Analyst one — not just the principle that it should.
9. Question 12 states plainly whether the pipeline ends with zero human gates, defends it, and says
   how a wrongly auto-rejected idea stays recoverable.
9b. Question 10's memory answer names the compaction rule that bounds the calibration file — not
    just its schema. An unbounded learnings file is a failed answer.
9c. Question 13's profile schema is aggregate by construction, with small-cell suppression stated as
    a mechanism, and names what Alfred must produce.
10. Nothing in the document assumes a phone-initiated session can reach local state, or that a push
    channel exists today.
11. No file other than the deliverable was created or modified.

Length follows content. Do not pad; do not compress away the reasoning David would need in order to disagree with you.
