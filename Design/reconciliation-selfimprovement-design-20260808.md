# The reconciliation and self-improvement layer — design

**Task:** 076-design-the-reconciliation-and-self-impro · **Written:** 2026-08-08, headless worker session
**Anchor:** ACI-260011 (the six rulings and David's refinement to ruling 2)
**Status of this document:** a design pass. No machinery was changed, no record was opened, amended or
authored, nothing was published. Every path written by this run is under
`code/artifacts/076-design-the-reconciliation-and-self-impro/`.

---

## 0 · How to read this, and how its claims are sourced

This document designs four components and sequences them into build increments. It does not build
any of them and it does not decide anything that needs David — everything of that kind is collected
once, in §9.

**Record resolution.** Every anchored record was resolved by id through the resolver named in the
task, run from the repository root:

```
python3 _meta/screen.py --resolve ACI-260011 ACI-260008 CLD-00119 DEC-260119 DEC-0106
```

All five ids resolved; none was reported unresolved. The resolver returned:

| id | resolved to |
|----|-------------|
| ACI-260011 | `~/Documents/The_Estate/action-items/ACI-260011-260808-Open.md` |
| ACI-260008 | `~/Documents/The_Estate/action-items/ACI-260008-260807-Open.md` |
| CLD-00119 | `~/Documents/The_Estate/action-items/CLD-00119-260803-Open.md` |
| DEC-260119 | `~/Documents/The_Estate/decisions/2026/DEC-260119.md` |
| DEC-0106 | `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md` (the frozen legacy decisions file; DEC-0106 is the section beginning at its line 187) |

**Provenance convention used throughout.** Because the difference matters to whether a reader can
trust a sentence, every factual claim about the machinery carries one of two marks:

- **[live]** — checked against the running tree during this run, and cited by file (and line where a
  line is the point). This is the default; most claims are of this kind.
- **[record]** — taken from a governance record and *not* re-checked against the tree in this run.
  Treat it as evidence of what was true when it was written.

**One governing precedence.** ACI-260011's Progress section carries David's same-sitting refinement
to ruling 2. Where the refinement and the original ruling text differ, **the refinement governs**,
and this document follows the refinement: the generalization step's answer set is **two-armed**, not
three-categoried.

---

## 1 · What the machinery actually does today (the ground the design stands on)

Everything in this section was read from the live tree during this run.

### 1.1 The lanes that exist

- **Orchestrator** — `orchestrator/orchestrator.sh`, 5202 lines [live]. Hourly plus event-driven on
  any inbox drop. Owns the OI spine, the front door, the judging passes, routing, the completion
  round, the diagnostic-ticket lane, and notifications.
- **Worker** — `code/worker.sh`, 1105 lines [live]. Claims queued tasks, runs them headless, lands
  results in `code/outbox/`.
- **Reviewer** — `code/reviewer.sh`, 418 lines [live]. Runs hourly at :30. Does **two unrelated
  jobs on one clock**: an LLM audit of finished work (§2 of that file, lines 156–241) and mechanical
  housekeeping — stale-claim cleanup (§1, lines 113–155), log retention (§4, from line 267), outbox
  archiving and artifacts retention (§5, from line 329), and the staleness watchdog (from line 404).
- **Designer** — `designer/designer.sh`, 444 lines [live], with `_meta/designcheck.py` as the
  deterministic half of the front door's second pass.
- **Librarian**, **venture** — adjacent lanes, out of scope here.
- **The Cowork nightly chain** — `~/Claude/Scheduled/nightly/cowork-nightly.sh` [live], six stages
  (transcript export, EOD compaction, transcript lint, graph refresh, git sweep + push, ledger +
  alerting). It lives outside this repository.

### 1.2 There is no Housekeeper yet

**This is the single most consequential fact for sequencing.** CLD-00119 designs the split of the
reviewer into an event-driven reviewer and a timed housekeeper, and ruling 1 names the Housekeeper
as reconciliation's home. It does not exist [live]:

- No `housekeeper` script anywhere in the tree; the only matches are prose in records and in the
  design sidecars for OI-000037 [live].
- No `code/reviewed/` folder — `code/` holds `artifacts, auth-healthcheck.sh, dead-letter, inbox,
  logs, outbox, processing, reviewer.sh, supervised, worker.sh` [live].
- No housekeeper launch agent — `~/Library/LaunchAgents/` carries
  `com.cowork.agent-{orchestrator,reviewer,worker}.plist`, `com.cowork.designer.plist`,
  `com.cowork.librarian.plist`, `com.cowork.venture.plist`, `com.cowork.nightly.plist` — and no
  housekeeper [live].
- **OI-000037, the item that would build it, is escalated and sitting on David's board** —
  `REVIEW.md` §1 NEEDS YOU lists it as "escalated 5d ago", and `orchestrator/_index.md` row
  OI-000037 reads `escalated | david-consultation | verified` [live].

So reconciliation's ruled home is a surface that has been designed but not built, and whose build is
itself waiting on David. §8 sequences around this honestly rather than designing against a surface
that cannot be read.

### 1.3 The ledger is a usable event history

`ledger.md` is a flat append-only text log, 787,505 bytes at the start of this run [live]. Line
shape, verified from the live tail [live]:

```
2026-08-08 17:45 designed-route OK   — OI-000062 routed after the second pass -> 076-…md [execution=headless, stamp=designer/OI-000062@r1]
2026-08-08 17:45 completion     OK   — no reviewed results awaiting delivery
```

That is `DATE TIME EVENT STATUS — clause`. The event vocabulary is wide but finite; over the last
3000 lines the distinct events include `wake, completion, orchestrator-end, telegram-poll,
clarify-ageout, adjudication-retry, intake, reviewboard, staleness, review-start, review-end,
retention, audit, claim, done, mint, clarify-out, delivered, escalate, route, stage-inputs, reverify,
auth-echo, parked, notice, design-claim, clarify-in, adjudication-fail, model-lane, readjudicate,
no-deliverable, stage-breach, notify-edge, cap` and others [live].

Two properties matter for reconciliation. First, **the clause names the OI id** for every
item-scoped event, so an item's history is greppable. Second, **the events are transitions**, not
level reports: `route`, `parked`, `delivered`, `escalate`, `clarify-out`, `clarify-in` each mark a
moment. That is what makes state re-derivable from history rather than merely cross-checkable.

The weakness, also live: the clause is **prose**, not fields. Re-derivation therefore needs a parser
with a per-event grammar, and a clause whose wording changes silently breaks it. §3.4 designs
against that.

### 1.4 The state machine is already incomplete, demonstrably

`_meta/oilib.py:82` declares the vocabulary [live]:

```python
STATUS_VOCAB = ("received", "verifying", "evaluated", "clarifying", "escalated",
                "routed", "executing", "reviewed", "delivered", "closed",
                "disposed", "superseded")
```

Two live findings, both checked this run:

1. **`STATUS_VOCAB` is declared and never used.** `grep -n STATUS_VOCAB _meta/oilib.py` returns
   exactly one hit — its own definition [live]. Nothing validates a status against it. Its own
   comment calls it "documentation + the spelling authority for callers", which is accurate: it is
   a comment with a variable name.
2. **`parked` is a live status that is not in the vocabulary.** The diagnostic-ticket lane sets it —
   `orchestrator.sh` `park_and_ticket()` writes `status=parked` alongside `parked_reason`,
   `parked_check`, `parked_at`, `parked_task` [live] — and `parked` appears nowhere in
   `_meta/oilib.py`, nowhere in `_meta/reviewboard.py`, and nowhere in the status-vocabulary
   paragraph of `orchestrator/_index.md`'s header [live].

That is exactly the shape ruling 3's completeness audit exists to find, and it was found in one
grep. It is strong evidence that the audit will pay.

### 1.5 The diagnostic-ticket lane (DEC-0106) is built and running

OI-000048, "Build the diagnostic-ticket lane ratified by DEC-0106", is `delivered` 2026-08-06, and
OI-000050 / OI-000051 are two real machine-raised tickets, both delivered [live, from
`orchestrator/_index.md`]. In the live code [live]:

- `park_and_ticket()` implements the four outcomes: recursion bound (a ticket that fails its own
  done-check escalates, never spawns), per-item bound (`TICKET_PER_ITEM_MAX`, default **1**, at
  `orchestrator.sh:129`), volume bound (`TICKET_OPEN_MAX`, default **5**, at `orchestrator.sh:130`),
  and the ordinary mint into the front door.
- `parked_pass()` runs every wake before the completion round and, for an unchanged parked state,
  "does NOTHING and says nothing" — its own comment, and the mechanism is structural (the item is in
  a status the sweep does not read) rather than a dedup filter [live].
- `is_ticket()` / `ticket_diagnoses()` (`orchestrator.sh:4815`, `:4823`) identify a ticket by the
  item it diagnoses [live].

This matters twice over: it is the lane ruling 2's generalization step attaches to, and it is a
working precedent for a bounded self-repair loop that this design copies rather than reinvents.

### 1.6 Notification is already edge-triggered, with one deliberate exception

`orchestrator.sh:817–920` is a level-to-edge converter, built under CLD-00105 [live]. Its own header
records the defect it fixed: "40+ notices for one unchanged finding … the observed 2026-07-31 burst
was self-inflicted, three extra notices in 35 minutes because filing a decision document woke the
orchestrator" [live].

- `notify_on_change <oid> <kind> <fingerprint> …` (`:890`) pushes only when the fingerprint is new
  or different for that `(item, condition-kind)` pair [live].
- State lives at `_meta/notify-state/<OI-id>.state`, one line per condition kind, tab-separated
  `kind, fingerprint, first-epoch, last-epoch` [live]. Verified content of a live file:
  `park  released:OI-000050  1786074301  1786074301` [live].
- It **fails open** by construction and pushes before it records, so a crash between the two
  re-notifies rather than going silent [live].
- **`NOTIFY_BACKSTOP_SECS` defaults to 86400** (`orchestrator.sh:857`) — one reminder per day per
  unchanged condition, textually marked `STILL OPEN Nh (daily reminder, nothing new)` [live].

Eleven call sites use `notify_on_change`, covering the hold, deliver-library, deliver-roots,
ticket-bound and park condition kinds [live]. **Five call sites still call `notify_david` directly**
— `orchestrator.sh:1612` (infrastructure-fault escalation), `:1724` (supervised handoff), `:2435`
(clarify age-out), `:2756` (interview complete but decision document could not be composed), `:3450`
(design-round age-out) [live].

### 1.7 The honest-labeling defect, measured

This is ruling 4(b), and the task asks for the count and the placement, verified live. Both were.

**How many distinct causes share one return code.** `_lib/run_claude.sh:96–99` declares four
returns [live]:

```
CLAUDE_RC_ERROR_OUTPUT=64   # wrote an API/CLI error and nothing else
CLAUDE_RC_NO_OUTPUT=63      # wrote nothing at all
CLAUDE_RC_BAD_RESTRICTION=62 # write-restriction requested but malformed/unappliable
CLAUDE_RC_NO_AUTH=61        # could not authenticate — retrying cannot clear it
```

**`rc=62` is returned from four textually distinct sites, carrying four different meanings** [live]:

| site | meaning |
|------|---------|
| `run_claude.sh:783` | the write-restriction profile is **malformed** |
| `run_claude.sh:788` | the restriction is **unappliable** — no `sandbox-exec` on this host |
| `run_claude.sh:793` | the profile **failed preflight** |
| `run_claude.sh:932` | the restriction was **BREACHED during the call** — deny-write path changed; call refused, output discarded, nothing deleted |

The first three are refusals *before anything launched*. The fourth is a guard firing *after* a call
that may have been perfectly healthy. They are not the same event in any sense a triaging reader
cares about, and they share one integer.

**Where the code becomes a reader-facing label.** `orchestrator.sh:1160` [live]:

```sh
VD_OK=0; VD_FAIL_CAUSE="model-call-error(rc=$rc)"
```

This is a **second, wider collapse**: *every* nonzero rc from `run_claude` — 61, 62, 63, 64, or any
other — becomes the words "model-call-error". The escalation-packaging path does the same at
`orchestrator.sh:1397` [live]. `VD_FAIL_CAUSE` is passed to `record_pass_failure` at five call sites
(`:3635, :3944, :4270, :4480, :4573`) [live], which writes the ledger line; `_meta/reviewboard.py:443`
lifts ledger FAIL lines into the board; and the result reaches David's eyes. Live, in `REVIEW.md:30`
at the start of this run [live]:

> **ledger FAIL** `adjudication-fail` 2026-08-07 13:55 — OI-000054 vd pass failed
> (cause=model-call-error(rc=62)); no verdict recorded — a failed call is never an adjudication;
> retry-eligible (1/3) at a later wake

That line is on the board today. Its cause label is wrong: ACI-260008 records that the 2026-08-07
rc=62 events were the write-guard destroying a concurrent writer's files, not a model failure
[record], and the live code above shows how a guard breach acquires the word "model".

**What already holds, and must not be re-designed.** The *verdict* half of the property is already
true and is written into the line itself: "no verdict recorded — a failed call is never an
adjudication". `run_vd_pass` sets `VD_OK=0` and records no verdict on any failure path [live], and
DEC-260119 increment I-6 added a genuinely distinguishable class — `staging-defect` at
`orchestrator.sh:1009/1015/1021/1028`, and the `stage-breach` FLAG class visible live at
`REVIEW.md:58` [live]. So I-6 has already proved the pattern this design generalizes.

**The residue is the cause label alone**, and ACI-260008 says so in its own words: "the ledger
cause-label wording (rc=62 renders as 'model-call-error') — fix where callers render the rc, own
pass" [record]. §6.2 designs it; §8 makes it increment R-6 and states which half is design and which
half is build.

### 1.8 What does not exist at all today

- **No reconciliation of any kind.** Nothing compares an item's spine against the ledger's account
  of it, or against `_index.md`, or against the board. `oilib.py index-sync` *writes* the index row
  from the spine [live]; it never asks whether the spine is right.
- **No re-derivation of state from event history.** Nothing reads `ledger.md` as an authority.
  `check_staleness.sh` reads it for exactly one thing — the last worker `wake` line, to detect a
  dead worker [live].
- **No repair capability.** Every recovery in the record was performed by a human-attended session
  [record: ACI-260008, ACI-260011].
- **No generalization step.** The reviewer's `## Review` schema is fixed at four fields — `verdict`,
  `assessment`, `follow-ups`, `reviewed` (`reviewer.sh:193–197`) [live] — and asks nothing about
  wider application.
- **No Designer pre-flight checklist artifact.** The nearest thing is `_meta/authoring-contract.md`,
  seven hand-maintained sections whose §4 and later carry dated lessons folded in by hand [live].
- **No status-vocabulary enforcement, no per-status owner/exit/watchdog map** — §1.4.

### 1.9 The watchdog that does exist, and the precedent it sets

`_meta/check_staleness.sh` is the only thing in the tree with a reconciliation flavour. Its header
[live] states a principle this design adopts wholesale:

> Invoked by BOTH the reviewer pass and the nightly chain — two independent hosts, no new launchd
> job — so the queue is audited from OUTSIDE the machinery it reports on. It self-escalates: desktop
> notification + a ledger FAIL line, NEVER through the machinery being audited (it does not write an
> orchestrator/inbox attention item, because that inbox is one of the things it checks).

It covers five conditions: a queued-but-unclaimed executor inbox entry (3h), a rotting orchestrator
intake (24h), an orphaned `processing/` claim with no live lock, a silent worker (24h), and — as a
softer reminder class — an escalated OI with no Progress movement past 7 days [live].

Note what it checks: **queue-shaped staleness**, never item-state coherence. It would not notice a
spine that contradicts its own history. That is precisely the gap ruling 1 fills, and the two are
complements, not competitors — §3.7 keeps them apart deliberately.

---

## 2 · The four components, and the one sentence each exists for

| # | Component | Ruling | One sentence |
|---|-----------|--------|--------------|
| A | **Reconciliation** (with recovery folded in) | 1, 6 | Notice and repair wrong *states*, in a machinery that is excellent at preventing wrong *actions*. |
| B | **The generalization step** | 2 (as refined) | Make every fix answer, once, what its systemic answer is — and never let the absence of a fitting shape drop the answer. |
| C | **The self-growing pre-flight checklist** + the state-machine completeness audit | 3 | Turn each verification finding into a checked-next-time entry, and find the states that have no owner, no exit or no watchdog. |
| D | **Notifications**, in two halves | 4 | (a) tell a human when something *enters* a state that needs them, never for standing state; (b) never let a guard failure wear a judge's or a model's name. |

Ruling 5 is an explicit non-goal — §7. Ruling 6 has no component of its own by David's direction;
it is folded into A — §3.6.

---

## 3 · Component A — Reconciliation (ruling 1, with recovery-as-capability folded in)

### 3.1 Where it runs

**The Housekeeper**, per ruling 1 — with the hard qualification of §1.2: the Housekeeper does not
exist, and the item that would build it is on David's board. Three consequences, all designed for:

1. **The reconciler is written as a standalone script, `_meta/reconcile.py`, not as inline
   Housekeeper code.** It takes its inputs as paths and its cadence as a flag (`--light` /
   `--deep`), writes findings to stdout and the ledger, and knows nothing about who invoked it. Its
   host is then a one-line call from whatever timed job exists.
2. **Its first host is the existing hourly reviewer pass** (`code/reviewer.sh`, which already runs
   hourly at :30 and already hosts mechanical sweeps and invokes `check_staleness.sh` [live]) —
   *only if* CLD-00119 has not landed by the time increment R-3 is ready. This is a deliberately
   temporary tenancy, and it is the same tenancy `check_staleness.sh` already has.
3. **On the Housekeeper's landing, the host line moves** — one line deleted from `reviewer.sh`, one
   added to the housekeeper. That is the whole migration, and it is why the standalone shape is
   worth the small extra structure.

**The deep variant runs from the Cowork nightly chain**, not from the Housekeeper, and the reason is
`check_staleness.sh`'s own precedent (§1.9): the deep pass is the one that adjudicates whether the
Agent Workflow machinery's own bookkeeping is coherent, and it should run from a host that is not
that machinery. The Housekeeper may *also* invoke it; the nightly invocation is the one that must
exist. **This is a departure from a literal reading of ruling 1** ("a deeper NIGHTLY variant in the
chain"), except that "in the chain" most plausibly *means* the nightly chain — so this is a reading,
not a departure. It is put to David as decision **D-2** rather than assumed.

### 3.2 Cadence and the settle threshold

- **Light pass: hourly**, on the host's ordinary wake.
- **Deep pass: nightly**, from the nightly chain.
- **Settle threshold: 15 minutes** (`RECONCILE_SETTLE_SECS`, default 900), per ruling 1.

The threshold is defined as: **an item is examined only if its most recent `ledger.md` event naming
it is older than the threshold.** Two points of care, both learned from the live tree:

- **The clock is the ledger's, not the filesystem's.** A spine's mtime moves for reasons that are
  not transitions (an index-sync, a Progress append). The ledger event is the transition record, so
  it is the right clock. `check_staleness.sh` uses file mtimes [live] and is right to, because it is
  asking a different question — "has this sat too long?" not "is this mid-move?".
- **An item with no ledger events at all is not examined and is not silently skipped.** It is
  reported once as `no-history`, because an OI with no event history is itself a finding (it means
  either a brand-new mint inside the settle window, or bookkeeping that never happened).

The threshold is a *floor on staleness*, not a rate limit: an item that has been quiet for six days
is examined every hour, cheaply, and its finding is deduplicated by §3.5 rather than by not looking.

### 3.3 What it compares

Six comparisons. The first four are the light pass; all six are the deep pass.

| # | Comparison | Light | Deep | The wrong state it catches |
|---|-----------|:-----:|:----:|---------------------------|
| C1 | **Spine ↔ its own ledger history** — the re-derivation of §3.4 | ✓ | ✓ | "decision consumed, no retry pending, not routed" — ruling 1's named example; the OI-000054 / OI-000037 class [record] |
| C2 | **Spine ↔ `orchestrator/_index.md` row** — status, summary, task, closed | ✓ | ✓ | A stale board row; an index-sync that did not run or ran against a half-written spine |
| C3 | **Spine ↔ its sidecars** — an `escalated` spine with no `.escalation.md`; a `clarifying` spine with no `.clarify.md`; a `parked` spine with no `ticket_arrival` and no `ticket_deferred` | ✓ | ✓ | An escalation David is told about with no package to read; the class `REVIEW.md:57`'s live `auth-echo` FLAG is adjacent to |
| C4 | **Status legality** — the status is in `STATUS_VOCAB`, and its required companion fields are present | ✓ | ✓ | The live `parked` finding of §1.4; any future status introduced without registration |
| C5 | **Spine ↔ queue reality** — a `routed`/`executing` item whose named task file is in none of `inbox/`, `processing/`, `outbox/`, `dead-letter/`; and the converse, a queue file naming an OI whose spine does not know it | | ✓ | Work that fell out of the pipeline between two lanes |
| C6 | **Archive consistency** — a terminal spine still in `items/` past the archive threshold, an archived spine still carrying an open-status index row, an `_index.md` row whose spine file is absent | | ✓ | Ruling 1's named "archive consistency" |

The board (`REVIEW.md`) is deliberately **not** compared. It is a generated view that is rebuilt
identically at every wake and says so in its own header [live] — reconciling against it would be
reconciling against a function of the things already being reconciled. What the board *does* get is
the findings, through §3.5.

### 3.4 How item state is re-derived from the event history

This is C1, and it is the part with real teeth, so it is specified concretely.

**The model.** A small event→state transition table, one entry per ledger event that changes an
item's status, expressed as `(event, status-clause-pattern) → implied status + implied obligations`.
Replaying an item's events in order yields a **derived state**: a status, plus a set of *open
obligations* — things the history says are owed and not yet discharged.

Obligations are what make the ruled example detectable. Worked through, using live event names
(§1.3):

| History fragment | Derived obligation | Discharged by |
|---|---|---|
| `clarify-out` for OI-N | a clarification round is outstanding | `clarify-in` for OI-N, or `clarify-ageout` naming OI-N |
| `escalate` for OI-N | a decision is awaited | consumption of a `david-decision` (the `auth-echo` event, or a `decision` event naming OI-N) |
| a decision consumed for OI-N | the decision must be enacted | `route`, `disposed`, `superseded`, or an explicit re-escalation |
| `parked` for OI-N | a ticket is owed or deferred | `ticket` OK for OI-N, or a later `parked` line naming the volume bound |
| `route` for OI-N | a result is owed | `delivered`, `dead-letter`, or a `parked` line |
| `adjudication-fail` for OI-N | a retry is owed within the bound | `adjudication-retry`, or the bound firing into `escalate` |

**The finding shape.** A discrepancy is reported as a triple: *what the spine says*, *what the
history implies*, *the ledger lines that imply it* (date, time, event, and the clause verbatim). The
third element is not decoration — it is what lets a human adjudicate the finding in ten seconds
without re-deriving anything, and it is what lets a wrong transition table be diagnosed rather than
trusted.

**Precedence: the spine is the record; the ledger is the witness.** Where they disagree, the
reconciler **reports** and, for the mechanical subset of §3.6, **repairs the spine toward the
history** — because the history is append-only and the spine is mutable, so the history is the
harder thing to corrupt. It is not a proof: a missing ledger line makes the history wrong too.
Hence §3.6's narrow repair list and its announce-everything rule.

**The known fragility, stated rather than hidden.** The clause is prose (§1.3), so the transition
table matches on patterns and *will* drift when a clause is reworded. Two defences, both cheap and
both part of increment R-2:

1. **An unrecognized event for an item is a finding, not a silence** (`unparsed-event`), reported at
   most once per event *class* per pass. A parser that has gone blind announces itself.
2. **The transition table ships with fixtures built from real ledger excerpts**, so a reword that
   breaks a pattern breaks a test rather than a night's reconciliation.

### 3.5 How findings stay bounded

Ruling 1 sets the bound as DEC-0089's: **one finding per item, not one per wake** [record:
ACI-260011]. That is implemented with the mechanism the tree already has and has already proved —
the edge-trigger of §1.6 — rather than a new one.

1. **Fingerprint per (item, finding-class).** A finding is reduced to `<class>:<digest of the
   discrepancy>`. Identical discrepancy next hour → identical fingerprint.
2. **The ledger records every finding, every pass, unconditionally.** Loudness in the record is not
   bounded; only the *push* and the *board row* are. This is `notify_on_change`'s own discipline —
   "STILL EVALUATED, STILL LOGGED — only the push is withheld" [live] — and it is what keeps the
   ledger a complete history rather than a deduplicated one.
3. **One board row per (item, finding-class)**, carrying a first-seen age and an occurrence count,
   never one row per occurrence.
4. **A per-pass cap, `RECONCILE_MAX_NEW_FINDINGS`, default 20.** On overflow the pass emits the 20
   and one aggregate line naming the total and the classes suppressed. This is the anti-flood
   backstop for the case the ruling names — one standing fault touching many items — and it is
   *loud about its own truncation*, which is the difference between a bound and a silence.
5. **A standing finding older than 7 days becomes a single `standing-fault` line** naming the class,
   the count of items and the age, and its per-item rows collapse into it. One board row for one
   fault, however many items it touches.

**What is never bounded:** a finding that the reconciler *repaired* is announced every time it
repairs, with no dedupe at all. Repairs are rare and are actions taken on David's estate; a repair
that stopped being announced because it kept happening would be the worst possible failure of this
component.

### 3.6 Repair: which findings are mechanical, and recovery-as-capability (ruling 6)

Ruling 1: "where the healing is mechanical, heal + FLAG rather than just FLAG." Ruling 6 folds
recovery in here — same inputs, same pass, not a separate component. The dividing line proposed is
**reversibility and derivability**: a repair is performed only when the correct value is *derivable
from a record the reconciler already read*, and the repair is *reversible from the announcement
alone*.

**Perform-and-announce (the `heal` list) — four repairs, and no more at R-4:**

| Repair | What it does | Why it is safe |
|---|---|---|
| H1 · **Index row resync** | Re-runs `oilib.py index-sync` for an item whose `_index.md` row disagrees with its spine | The index is already declared "maintained mechanically … do not edit by hand" [live, `orchestrator/_index.md` header]; the spine is its source; this is the existing operation, invoked from a new place |
| H2 · **Notify-state repair** | Removes a `_meta/notify-state/<id>.state` line whose condition no longer holds | Fails toward *more* notification, never less — the same fail-open direction the module already chose [live] |
| H3 · **Archive relocation** | Moves a terminal spine past the threshold from `items/` to `archive/YYYY/`, and fixes an index row that points at the old path | Pure relocation of an immutable-by-convention file; the destination is deterministic |
| H4 · **Obligation re-arm** | Where the history shows an owed retry that no longer has a pending marker on the spine, restores the marker so the ordinary retry path picks it up next wake | It restores the machinery's *own* prior intent, recorded in its *own* ledger. This is the OI-000054 / OI-000037 class — the two ruled decisions that went silently dead [record] — and it is the one repair that turns this component from a reporter into a recoverer |

H4 is the load-bearing one and the riskiest, so three constraints ride on it: it re-arms **only**
where the ledger shows the retry was owed and never spent; it re-arms **once** per item per
discrepancy fingerprint (a re-armed obligation that dies again is a finding, not a second re-arm);
and it **never** re-arms across a status the machinery treats as terminal.

**Announce-only (everything else).** Anything touching a governance record; anything that would
route, complete, dispose or escalate an item; anything whose correct value requires a judgment;
anything involving a queue file's contents. In particular the reconciler **never** writes to
`orchestrator/inbox/`, for `check_staleness.sh`'s stated reason — that inbox is one of the things it
checks [live].

**Recovery-as-capability, concretely.** Folding ruling 6 in means the reconciler is where a recovery
*procedure* lives, so that the next incident is not improvised. Beyond H1–H4 it produces, for each
finding it will not repair, a **recovery note**: the item, the discrepancy, the evidence lines, and
the *named* next action drawn from a fixed list — `re-arm`, `re-route`, `re-escalate`,
`restore-from-quarantine`, `restore-from-git`, `human-adjudication`. The record's own evidence is
that the raw materials were always excellent and only the procedure was missing [record:
ACI-260011]; this is that procedure, written where the evidence is already assembled.

**The escape hatch, per the task's own instruction to ruling 2 and applied here too:** a discrepancy
the transition table cannot classify is reported as `unclassified` with its evidence, and reaches a
human through the ordinary escalation path. It is never forced into a class and never dropped.

### 3.7 Why this does not duplicate `check_staleness.sh`

They ask different questions and must stay separate: the watchdog asks **"has this sat too long?"**
(queue-shaped, mtime-based, five conditions, no notion of item state); the reconciler asks **"is
this coherent?"** (state-shaped, ledger-based, no notion of duration). Merging them would give one
job two clocks and two vocabularies — the exact fault CLD-00119 exists to fix in the reviewer
[record]. They should share only their host and their reporting discipline.

---

## 4 · Component B — The generalization step (ruling 2, as refined)

### 4.1 The step

**A mandatory terminal question on two lanes**, asked once per fix:

> **What is the systemic answer to this? What is the wider class of which this fix is one instance,
> and what should change so the class is handled rather than this instance?**

**Lane 1 — the diagnostic-ticket lane (DEC-0106).** The step is the last thing a ticket does before
its resolution returns to the parked original. A ticket's whole purpose is diagnosis of an unknown
cause [record: DEC-0106 item 3; CLD-00119's adjacency note], which makes it the single highest-yield
place in the machinery to ask this question: something has just been understood that was not
understood before.

**Lane 2 — the Reviewer's audit of fix-class work.** The reviewer already writes a structured
`## Review` per outbox entry with `verdict`, `assessment`, `follow-ups`, `reviewed`
[live, `reviewer.sh:193–197`]. The step adds one field to that schema, on fix-class work only.

**"Fix-class" is a determination, and it must be mechanical, not a judgment.** Proposed rule: an
outbox entry is fix-class if **any** of — its task frontmatter carries an OI whose spine records a
`parked` transition (i.e. it is or descends from a diagnostic ticket); its `related:` names a
defect-class item; the task was raised by the machinery rather than by David (`origin=system-alert`
or a machine-raised intake). Each is checkable in code from files the reviewer already reads. Where
the rule is *not* met, the step is simply not asked — a false negative here costs one missed
generalization; a false positive costs a model-authored generalization about a green-field build,
which is noise on David's board. Bias to the false negative.

### 4.2 The two arms (David's refinement governs)

Exactly two legal outcomes. This is the refinement's whole point — the original three-category form
risked a fix whose systemic answer fit no category, and David's stated concern was "I'd hate to have
something fail because the solution didn't fit in the rule, checklist or detector categories"
[record: ACI-260011 Progress].

**Arm 1 — a systemic solution is proposed, in whatever form fits.**
The **universal container is a machine-raised intake** through the ordinary front door. Whatever the
systemic answer is — a rule, a check, a detector, a refactor, a retirement, a convention, a design
pass, something with no name — it can be stated as an objective in an intake. There is no shape it
can fail to fit, because an intake's content is prose bounded by the authoring contract, not an
enumeration.

Inside this arm, the two lightweight shapes survive **only as a fast path**, for the narrow case
where the propose→ratify→land machinery can enact the answer directly without a task:

- a **checklist candidate** → appended to the Component C candidate list (§5);
- a **detector candidate** → appended to the same list, tagged as detector-class.

The fast path is a *convenience*, and the design states its own precedence: **if the fast path does
not obviously fit, the intake is used.** An author who is unsure takes the intake. The fast path may
never be the reason an answer is compressed.

**Arm 2 — an explicit recorded decline, with its reason.**
"No wider application, because …" recorded on the ticket (lane 1) or in the `## Review` (lane 2). A
decline is a legitimate, common and *valuable* answer — many fixes are genuinely one-off — and
recording the reason is what makes a wrong decline auditable later. **A decline with no reason is
not a decline**; it is treated as an unclassifiable resolution and takes the escape hatch below.

**Neither arm reached → the escape hatch.** A resolution the machinery cannot classify goes to a
human **through the normal escalation path** — the same path, the same package shape, the same
board. It is never forced into an arm and it is never dropped. Concretely, the step is unclassifiable
when: the generalization field is absent or empty; it declines with no reason; or it proposes a
systemic solution the fast path cannot enact and the intake author cannot state as an objective
(e.g. it would require an authority the machinery does not have). This last case is the important
one — it is exactly where a system without an escape hatch would quietly do nothing.

### 4.3 One question per fix — the anti-recursion bound

Ruling 2 says one generalization question per fix, no meta-recursion. Mechanically:

- **An item raised BY the generalization step is exempt from the step.** It is marked at mint
  (`origin` carries a generalization marker), the reviewer's fix-class rule excludes it, and the
  ticket lane's terminal step skips it. A generalization of a generalization is not asked.
- **One question per fix, not per finding.** A ticket that fixed three things asks once, about the
  fix as a whole.
- **The DEC-0106 bounds already in force apply unchanged** — `TICKET_PER_ITEM_MAX=1`,
  `TICKET_OPEN_MAX=5` [live] — so the step cannot manufacture tickets, only intakes, and intakes go
  through the ordinary front door with its ordinary screen and gate.

This mirrors the recursion bound the ticket lane already implements and proves in live code
(`park_and_ticket()`'s first branch, §1.5) — the same shape, in a new place.

### 4.4 Where the answer lands, and who ratifies

- **Arm 1, intake path:** the intake goes through the ordinary front door. Nothing is special-cased.
  The screen, the deterministic checks, the attester and the intent judge all apply as they do to
  any filing. **David ratifies by the ordinary route** — this design proposes no new authority and
  claims none.
- **Arm 1, fast path:** the entry is a *candidate*, advisory only, until promoted — §5.3.
- **Arm 2:** recorded, and read by nothing but a human and the periodic review of §5.4.

### 4.5 The honest risk

The step is asked by a model, and a model asked "what is the systemic answer?" will very often
produce a plausible one. The two defences are structural, not exhortative: **Arm 2 must be as easy
to take as Arm 1** (a decline is one sentence, an intake is a whole document — the gradient already
points the right way), and **every Arm 1 output goes through the full front door**, which is
precisely the machinery built to refuse plausible-but-unsubstantiated work [record: DEC-260119].
The step's failure mode is therefore queue noise, caught at the gate, not enacted defects. That is
the acceptable failure direction, and it is worth stating that the alternative — a step whose output
bypasses the gate for being "small" — would not be.

---

## 5 · Component C — The self-growing pre-flight checklist, and the state-machine audit (ruling 3)

### 5.1 The problem in one sentence, from the evidence

"The reviewer/housekeeper build took six verification rounds because findings classes are discovered
serially and never harvested" [record: ACI-260011]. Each round found a real defect; nothing carried
round N's lesson into round N+1's pre-flight. The checklist is the carrier.

### 5.2 Classification, and how a finding becomes a candidate entry

**Where the findings come from.** Three live sources, all already writing structured text: the V/D
pass's `## V/D Findings` section on a spine [live], the Reviewer's `## Review` block
[live, `reviewer.sh:193–197`], and `_meta/designcheck.py`'s check results [live].

**The classifier is a deterministic post-step, per ruling 3** — not a model pass. It runs after the
finding is written and does three things:

1. **Class.** Assign one of a small fixed set: `authoring` (the document was wrong),
   `substantiation` (the record did not authorize it), `well-formedness`, `red-line`, `scope`,
   `state-machine`, `evidence` (a claim was not checked), `other`. `other` is legal and is not a
   failure — it is the honest bucket, and a rising `other` count is itself a signal that the class
   set needs extending.
2. **Deduplicate.** A candidate is keyed by `(class, normalized finding text)`. A duplicate does not
   create a second entry; it **increments the entry's occurrence count and appends its citation**.
   Occurrence count is the promotion signal of §5.3, so dedupe is load-bearing, not tidiness.
3. **Cite.** Ruling 3 is explicit that the citation *is* the finding. Each entry carries, for every
   occurrence: the item id, the pass that raised it, the date, and the finding text verbatim. An
   entry with no citation cannot exist — the writer refuses it.

**Where it lives.** A new `_meta/preflight-candidates.md`, machine-maintained, never hand-edited,
with a header saying so in the same voice as `orchestrator/_index.md`'s [live]. It is deliberately
*not* `_meta/authoring-contract.md`: that file is a governance-adjacent document maintained by hand
and cited by the gate, and a machine appending to it would put automatic writes on a surface humans
reason about. The candidate list is the machine's; the contract is David's.

### 5.3 Candidate → required, and who ratifies

The loop shape is the one ruling 2 names as precedent — propose → ratify → land [record:
ACI-260011].

- **Propose (automatic).** The classifier appends the candidate. It is **advisory to the Designer
  immediately**: the Designer's pre-flight reads both the required list and the candidate list, and
  candidates are presented as "seen N times, most recently on <item>" — informative, never blocking.
- **Ratify (human).** A candidate becomes **required** only by David's word. Nothing in this design
  promotes anything automatically, and the design claims no authority to. The mechanical part is
  only the *proposal*: when a candidate crosses a threshold (proposed: 3 occurrences across 2
  distinct items, `PREFLIGHT_PROMOTE_MIN`), the machinery raises it as an ordinary front-door
  intake — one intake per promotion, subject to the same gate as anything else. **Who ratifies, and
  whether a lighter ratification is acceptable, is decision D-5.**
- **Land (mechanical).** On ratification the entry moves from the candidate list to a required list
  the Designer's pre-flight treats as blocking, and the promoting decision is cited on the entry.

**Required means "must be answered", not "must pass".** A required entry is a question the Designer
must explicitly address in its design record; it is not a veto. This keeps the checklist from
becoming an unratified gate that grows itself — which is the one way this component could do harm.

### 5.4 Ageing

An entry with no new occurrence in 90 days is marked `dormant` and stops being shown, without being
deleted (its citations are evidence). A dormant entry re-activates on its next occurrence. This
keeps the advisory list readable, which is the only thing that keeps it read.

### 5.5 The one-time state-machine completeness audit

Ruling 3's second half, specified as *work* rather than as machinery — it is a one-time pass whose
output is a document plus items.

**The deliverable: a table with one row per status, and four columns.**

| column | what it must state |
|---|---|
| **Status** | the exact string as written to a spine |
| **Owner** | the single component responsible for moving an item out of it |
| **Exit paths** | every legal next status, and the event that causes each |
| **Watchdog** | what notices an item that has been in this status too long, at what threshold, and where it reports — or `NONE` |

**Scope: every status actually written to a spine**, discovered by grepping the tree for status
writes, **not** by reading `STATUS_VOCAB` — because §1.4 proves the vocabulary is already out of
date. The audit's starting set is the twelve declared statuses plus `parked`, plus whatever else the
grep finds.

**Evidence the audit will pay, gathered in this run:** `STATUS_VOCAB` is never referenced (§1.4);
`parked` is undeclared and undocumented (§1.4); `check_staleness.sh` watchdogs five queue conditions
and `escalated` softly, which leaves most statuses with no watchdog at all (§1.9); and the record
reports tasks 042/047 sitting six days in a state with no exit and no watchdog [record: ACI-260011].

**Gaps become items**, one per gap, through the ordinary front door. The audit itself decides
nothing and fixes nothing — its output is the table, the gap list, and the intakes.

**A note on `STATUS_VOCAB` itself.** Making it enforcing (validate on write, refuse an unknown
status) is the obvious follow-on and is *not* folded into the audit, because it is a behaviour change
to a live gate: today an unknown status is written silently, and making it refuse could park a live
item. It is named as its own increment (R-8) behind the audit that tells us what the legal set
actually is.

---

## 6 · Component D — Notifications (ruling 4), in two halves

The ruling has two halves and they are genuinely different problems with different fixes. They are
kept visibly apart here because a design that addressed only the first would look complete and would
not be.

### 6.1 Half (a) — transitions-only

**The property:** a human is notified when an item **enters** a state that needs them, and is never
re-notified for standing state.

**How much is already true.** Most of it. §1.6 documents `notify_on_change` as a live, working
level-to-edge converter with per-item, per-condition-kind fingerprints, fail-open behaviour, and a
push-before-record ordering [live]. This design does not rebuild it. Three residues remain:

**(a1) Five call sites bypass the converter.** `orchestrator.sh:1612, :1724, :2435, :2756, :3450`
call `notify_david` directly [live]. Each must be assessed and either routed through
`notify_on_change` with a proper fingerprint, or documented in place as a genuine one-shot. From
reading them: `:2435` (clarify age-out) and `:3450` (design-round age-out) are one-shot by
construction — the age-out fires once and changes the status. `:1724` (supervised handoff) is a
transition. `:1612` (infrastructure fault, N failures in a row) and `:2756` (decision document could
not be composed) are **not** obviously one-shot and are the two to convert. The increment's work is
the assessment; the design's requirement is that **every push site is either edge-triggered or
carries a comment stating why it is inherently one-shot.** No silent third case.

**(a2) The 24-hour backstop is a deliberate exception to the ruling, and needs David's word.**
`NOTIFY_BACKSTOP_SECS=86400` re-pushes an unchanged condition once a day, marked
`STILL OPEN Nh (daily reminder, nothing new)` [live]. Its rationale is written into the code: "Total
silence on a long-lived hold is its own failure mode … 'no news' and 'forgotten' look identical from
the outside" [live]. That is a good argument, and it is nonetheless a **re-notification for standing
state**, which is the thing ruling 4 forbids. This design does not resolve the tension by picking a
side. It is decision **D-4**.

**(a3) Reconciliation's own findings must obey this half.** Component A pushes through
`notify_on_change` with the fingerprints of §3.5, never through `notify_david`. A reconciler that
flooded the board would discredit the whole layer on its first day — which is why §3.5 was written
before this section rather than after it.

**Deliberately unchanged:** the count-only Telegram notice (`notify_count_only`), which is telegram-
only, carries no desktop notification, sends nothing at zero, and exists specifically so the desktop
channel stays reserved for failure classes [live]. It is already a transition-shaped signal about
the board as a whole and needs nothing from this design.

### 6.2 Half (b) — the honest-labeling residue

**The two properties that must hold:**

> **(P1)** A failure of the guard around a judging call must never be presented as that judge's
> verdict.
> **(P2)** The cause label a triaging reader sees must name **which kind** of failure actually
> happened.

**Status of P1: already true, live-verified, and this design must not disturb it.** On every failure
path `run_vd_pass` sets `VD_OK=0` and records no verdict [live], and the emitted line says so in
words a reader sees: "no verdict recorded — a failed call is never an adjudication"
[live, `REVIEW.md:30`]. Nothing here changes that; the increment must carry a fixture pinning it, so
that fixing P2 cannot regress P1.

**Status of P2: false today, at two places, both measured in §1.7.**

- **Collapse 1, in `_lib/run_claude.sh`:** four distinct causes return `rc=62` — malformed profile
  (`:783`), unappliable/no `sandbox-exec` (`:788`), failed preflight (`:793`), and **breach detected
  after the call** (`:932`) [live]. The first three are pre-launch refusals; the fourth is a guard
  firing on a call that may have been healthy. They are not the same event.
- **Collapse 2, in `orchestrator/orchestrator.sh:1160`:** `VD_FAIL_CAUSE="model-call-error(rc=$rc)"`
  maps **every** nonzero rc — 61, 62, 63, 64 — to the words "model-call-error" [live]. `:1397` does
  the same for escalation packaging [live].

**The placement diagnosis — the fix belongs at both, and the reason is which information exists
where.** `run_claude` is the only place that knows *which* of the four rc=62 conditions occurred;
the orchestrator is the only place that turns an rc into words a human reads. Fixing only the caller
would make it guess; fixing only the callee would leave the guess in place downstream. Concretely:

1. **`run_claude` exports a cause string alongside its rc** — a shell variable
   (`CLAUDE_FAIL_CAUSE`) set on every failure path to a short stable token:
   `restriction-malformed`, `restriction-unappliable`, `restriction-preflight-failed`,
   `restriction-breached`, `auth-failure`, `no-output`, `error-output`. The rc values do **not**
   change — no caller branches on them today (`run_claude.sh:958` says so explicitly [live]) and
   changing them would be a behaviour change this design has no mandate for. The cause string is
   purely additive.
2. **The orchestrator renders the cause it was given**, falling back to `model-call-error(rc=N)`
   only when no cause string is present. So an unconverted path degrades to today's behaviour rather
   than to a blank.
3. **`restriction-breached` renders distinctly** wherever it surfaces, because it is the one that is
   not a model failure at all — it is the guard, and ACI-260008 is the record of what mislabelling
   it costs [record]. The precedent already exists: I-6's `stage-breach` FLAG class is live and
   correctly named on the board today [live, `REVIEW.md:58`].
4. **No board-generator change.** `reviewboard.py:443` lifts the ledger line verbatim [live]; fixing
   the label at its source fixes it everywhere it is read, which is the reason this placement is
   preferable to a rendering fix.

**The design-versus-build statement property 4 requires, stated plainly:**

> **Designed here:** the two properties (P1, P2); the measurement of both collapses, by file and
> line, from the live tree; the diagnosis that the fix belongs at both the producing and the
> rendering site and why; the specific mechanism (an additive cause string, unchanged rc values, a
> degrade-to-today fallback); and the requirement that P1 be pinned by fixture so that fixing P2
> cannot regress it.
>
> **Reserved for a separate build pass:** the edit itself. ACI-260008 reserves it in its own words —
> "the ledger cause-label wording (rc=62 renders as 'model-call-error') — **fix where callers render
> the rc, own pass**" [record: ACI-260008, "Fix (ruled 2026-08-07)"]. **The increment this design
> names for that build is R-6** (§8). It is named, sequenced and given its verification here; it is
> not performed here, and this run changed no machinery.

---

## 7 · The non-goal (ruling 5)

**Ruling 5 — a fast slot for short tasks — is an explicit NON-GOAL of this layer.** It is deferred,
by David's ruling, and nothing in this design assumes it, prepares for it, or is blocked by it.

**The trigger its anchor names for revisiting it**, recorded here verbatim from ACI-260011:

> **Fast slot for short tasks: DEFERRED with a named trigger** — revisit when queue delay demonstrably
> costs something (the observed case: a 45-min fix behind a 90-min build).

So: the trigger is *demonstrated cost from queue delay*, and the anchor records the observed instance
that motivated it. Until such a case is measured and recorded, the ruling stands as deferred. Two
notes worth carrying forward for whoever revisits it:

- CLD-00119's reviewer/housekeeper split will change queueing latency on its own [record], so any
  measurement taken before that lands measures a system that is about to change.
- Nothing in this design lengthens the queue: Component B's output is intakes through the ordinary
  front door, and Component A's output is findings, not tasks.

---

## 8 · The build increments, sequenced

Each increment names its **precondition** (what must be true before it starts), its **deliverable**,
and its **verification** (how a reader knows it landed). Each is small enough to land alone and is
independently verifiable. Increments that depend on work in flight say so and why.

### 8.0 The work in flight this must be weighed against

**CLD-00119 — the reviewer/housekeeper split.** Not landed; OI-000037 is escalated on David's board
[live, §1.2]. It creates the Housekeeper (reconciliation's ruled home), a `code/reviewed/` folder,
and moves the Orchestrator's completion trigger from `outbox` to `reviewed/` — "a behaviour change,
not a detail, and it is the intended one" [record: CLD-00119].

**DEC-260119 (as amended 2026-08-08) — the Verifier rework.** Amended dependency order [record]:
`I-1 → I-6 → I-2 → I-3 (needs D1) → I-4 → { I-5 → I-9 (needs D8), I-7 (needs D4 evidence + David),
I-8 (needs D3) }`. Live status: **I-1 and I-6 have landed** — OI-000059 ("increment I-1") and
OI-000060 ("increment I-6 (as amended)") are both `delivered` in `orchestrator/_index.md` [live], and
I-6's effects are visible in the running ledger (`stage-inputs` lines with per-input sha256 digests
at 17:45 today [live]). **I-2, I-3 and I-4 are ahead**, and **I-4 retires the full-judgment V/D
pass** [record: DEC-260119].

**The interaction that governs sequencing.** I-4 will retire the V/D pass, whose failure path is
exactly where §6.2's `VD_FAIL_CAUSE` lives (`orchestrator.sh:1160`) — the surface R-6 must edit. And
CLD-00119 will move the reviewer's audit, which is where §4's Lane 2 attaches. **Two increments are
therefore sequenced behind work in flight, explicitly:**

- **R-6** (honest labeling) — *can* land before I-4 and is cheap either way, but its edit site is
  I-4's demolition zone. Recommendation and rationale in D-3.
- **R-7** (generalization on the Reviewer's audit) — **must wait on CLD-00119.** The reviewer's audit
  is being moved to a new event-driven job with a new folder topology. Designing the attach point
  now against `reviewer.sh:156–241` would be designing against a surface that is being reshaped.
  **This is an honest gap, stated as the objective requires:** §4 designs the *step*, its arms, its
  bound and its escape hatch — all of which are host-independent — and deliberately does **not**
  specify where in the reviewer the field is written, because that file's replacement has not been
  built. R-7's first task is to read the landed reviewer and place it.

### 8.1 The sequence

```
  R-1 ─→ R-2 ─→ R-3 ─→ R-4 ─→ R-5
                  │
  R-6 (independent; see D-3 re: I-4)
  R-8 ────────────────────────────→ (needs R-1)
  R-9 ─→ R-10 ─→ R-11
  R-7 ──────────────────────────── (needs CLD-00119 landed)
```

---

**R-1 · The state-machine completeness audit** *(Component C, §5.5)*
- **Precondition:** none. This is the entry point and it deliberately depends on nothing.
- **Deliverable:** the status × (owner, exit paths, watchdog) table; the gap list; one intake per gap
  through the ordinary front door.
- **Verification:** every status found by grepping status writes across the tree appears as a row;
  every row's four cells are filled or explicitly `NONE`; the `parked` finding of §1.4 appears as a
  gap; each gap has a filed intake.
- **Why first:** it is pure reading, it changes nothing, and its table is the input to R-2's
  transition model. The reconciler cannot re-derive state without knowing what the states are.

**R-2 · The reconciler core, report-only, light pass** *(Component A, §3.3 C1–C4, §3.4)*
- **Precondition:** R-1's table exists.
- **Deliverable:** `_meta/reconcile.py --light`, comparisons C1–C4, the event→state transition table
  with its `unparsed-event` finding, and fixtures built from real ledger excerpts. **Report-only —
  it repairs nothing.** Invoked manually.
- **Verification:** run against the live tree, read-only, and diff the tree before and after — byte
  identical. Fixtures cover each C1–C4 class and the ruled example ("decision consumed, no retry
  pending, not routed") reproduced from a real ledger excerpt. Every finding carries its evidence
  lines.

**R-3 · Host it on the hourly clock, with the settle threshold and the bound** *(§3.1, §3.2, §3.5)*
- **Precondition:** R-2 clean against the live tree; R-2's findings triaged, so a known-noisy
  reconciler is not put on a clock.
- **Deliverable:** the one-line invocation from the hourly host (the Housekeeper if CLD-00119 has
  landed by now; otherwise `reviewer.sh`, as a stated temporary tenancy), the settle threshold, the
  fingerprint dedupe, `RECONCILE_MAX_NEW_FINDINGS`, and the board rows.
- **Verification:** an injected standing discrepancy produces exactly one board row across ≥3
  consecutive passes while appearing in the ledger on every pass; an item whose last ledger event is
  under 15 minutes old is not examined; an over-cap pass emits the cap line naming what it suppressed.

**R-4 · Repairs H1–H4** *(§3.6)*
- **Precondition:** R-3 has run on the clock for a stated observation period with its findings
  triaged, so the repairs act on a finding set that has been read by a human at least once. **This
  is the increment that first writes to the tree, and it should not be the increment that first
  discovers the reconciler was wrong.**
- **Deliverable:** H1–H4, each announced unconditionally with no dedupe, each with a fixture; plus
  the recovery notes for the announce-only findings.
- **Verification:** each of H1–H4 has a fixture proving the repair *and* its announcement; H4 has a
  fixture proving it re-arms once and never twice for the same fingerprint; a fixture proves no
  repair writes to `orchestrator/inbox/` or to any governance record.

**R-5 · The deep nightly pass** *(§3.3 C5–C6, §3.1)*
- **Precondition:** R-4 landed; **D-2 answered** (which host runs the deep pass).
- **Deliverable:** `--deep`, comparisons C5 and C6, invoked from the host D-2 names.
- **Verification:** a fixture per comparison; the deep pass's findings obey the same bound; a night's
  run against the live tree is read and triaged before the invocation becomes standing.

**R-6 · Honest cause labels** *(Component D half (b), §6.2 — the build ACI-260008 reserves)*
- **Precondition:** none technically. **See D-3** on whether it lands before or after DEC-260119 I-4.
- **Deliverable:** `CLAUDE_FAIL_CAUSE` set on every failure path in `run_claude.sh` with the seven
  tokens of §6.2; the orchestrator rendering it at `:1160` and `:1397` with the degrade-to-today
  fallback; rc values unchanged.
- **Verification:** a fixture per cause token proving the emitted ledger line names it; **a fixture
  pinning P1** — that no failure path records a verdict — proving the P2 fix did not regress the
  property that already holds; a fixture proving an unconverted path still emits
  `model-call-error(rc=N)` rather than an empty cause.

**R-7 · The generalization step** *(Component B, §4)*
- **Precondition:** **CLD-00119 landed** (§8.0). Lane 1 (the ticket lane) could technically be built
  earlier, but the two lanes share the step's schema, its arms and its escape hatch, and building
  them apart would fork that schema.
- **Deliverable:** the terminal question on both lanes; the two arms; the mechanical fix-class rule;
  the exemption marker preventing meta-recursion; the escape hatch to the ordinary escalation path.
- **Verification:** a fixture per arm; a fixture proving an unclassifiable resolution escalates
  rather than being coerced or dropped; a fixture proving an item raised by the step is not itself
  asked the question; a fixture proving a decline with no reason takes the escape hatch.

**R-8 · Make `STATUS_VOCAB` enforcing** *(§5.5, closing note)*
- **Precondition:** R-1 landed (it defines the legal set), and its gap intakes resolved — otherwise
  enforcement refuses statuses the machinery legitimately writes today.
- **Deliverable:** validation on status write; refusal is loud and names the offending status.
- **Verification:** a fixture proving `parked` (or whatever R-1 legitimizes) is accepted and an
  invented status is refused loudly; a live-tree dry run showing zero refusals before it is armed.

**R-9 · The finding classifier and the candidate list** *(Component C, §5.2)*
- **Precondition:** none.
- **Deliverable:** the deterministic classifier over the three finding sources; the dedupe key; the
  citation requirement; `_meta/preflight-candidates.md`.
- **Verification:** a fixture proving an entry cannot be written without a citation; a fixture
  proving a repeat finding increments an occurrence and appends a citation rather than creating a
  second entry; a backfill over the last 30 days of real findings, read for plausibility.

**R-10 · The candidate list becomes advisory to the Designer** *(§5.3)*
- **Precondition:** R-9 landed with a non-trivial backfilled list.
- **Deliverable:** the Designer's pre-flight reads and presents candidates, with occurrence counts.
  **Advisory only — nothing blocks.**
- **Verification:** a design pass's own record shows the candidates it was shown; a fixture proves a
  candidate never blocks.

**R-11 · The promotion proposal path** *(§5.3)*
- **Precondition:** R-10 landed; **D-5 answered** (who ratifies a promotion).
- **Deliverable:** the threshold; the machine-raised promotion intake through the ordinary front
  door; the required-list mechanics; the "must be answered, not must pass" semantics.
- **Verification:** a fixture proving nothing is promoted without a ratifying record; a fixture
  proving a required entry blocks only on being unaddressed, never on its answer.

---

## 9 · The decision list — everything that needs David

Nothing in §8 assumes an answer to any of these. Each has its options and a recommendation.

**D-1 · OI-000037 (the reviewer/housekeeper split) is on your board and is blocking.**
It has been escalated 5 days [live, `REVIEW.md:17`]. Reconciliation's ruled home is the Housekeeper,
and R-7 (the generalization step) waits on the split outright.
*Options:* (a) rule on OI-000037 and let this layer sequence behind it; (b) let R-1→R-4 proceed with
the reconciler temporarily hosted on the existing hourly reviewer pass, migrating one line later;
(c) hold this layer entirely until the split lands.
**Recommendation: (b).** The reconciler is designed host-agnostic precisely so this is a one-line
move, `check_staleness.sh` already has exactly that tenancy, and holding the whole layer on one
escalation would repeat the pattern the layer exists to fix. But (a) is worth doing on its own
merits — the split is blocking more than this.

**D-2 · Which host runs the deep nightly reconciliation pass?**
Ruling 1 says "a deeper NIGHTLY variant in the chain".
*Options:* (a) the Cowork nightly chain (`~/Claude/Scheduled/nightly/cowork-nightly.sh`), so the
machinery is audited from outside itself; (b) a nightly invocation from the Housekeeper, keeping all
Agent Workflow machinery in one repository; (c) both.
**Recommendation: (a), with (c) acceptable.** `check_staleness.sh` already runs from both hosts for
exactly this stated reason [live], and the deep pass is the one adjudicating the machinery's own
bookkeeping. Note the cost of (a): a cross-repository dependency, and a nightly chain that grows a
seventh concern.

**D-3 · Does R-6 (honest cause labels) land before or after DEC-260119 I-4?**
I-4 retires the full-judgment V/D pass, whose failure path is R-6's principal edit site
(`orchestrator.sh:1160`) [live/record].
*Options:* (a) land R-6 now — the wrong label is on your board today (`REVIEW.md:30` [live]) and the
`run_claude.sh` half is untouched by I-4 either way; (b) wait for I-4 and edit once.
**Recommendation: (a), split.** Land the `run_claude.sh` half (the cause string) immediately — it is
additive, it is where the information actually is, and I-4 does not touch it. Land the orchestrator
rendering half at whichever site survives I-4. This gets the honest cause into the ledger soonest and
edits the volatile surface once.

**D-4 · The 24-hour notification backstop: keep, drop, or lengthen?**
Ruling 4 says never re-notify for standing state. The live code re-pushes an unchanged condition once
a day, marked as a reminder, on the argument that total silence and being forgotten look identical
[live, §1.6].
*Options:* (a) keep 86400s as-is and record it as a ruled exception to "transitions-only"; (b) drop
the backstop entirely — strict transitions-only, with the board as the only standing-state surface;
(c) lengthen it (e.g. weekly) as a compromise.
**Recommendation: (a).** The code's argument is good and was written in response to a real failure
mode; the reminder is textually marked so it cannot be mistaken for a new event; and `REVIEW.md`'s
NEEDS-YOU section already carries standing state continuously. What matters is that the exception is
*ruled* rather than left as an undiscussed contradiction of ruling 4. If you prefer (b), note that
`check_staleness.sh`'s 7-day escalated-OI reminder [live] is a second, independent nag on the same
condition and would need the same ruling.

**D-5 · Who ratifies a checklist candidate's promotion to required?**
§5.3 puts the proposal in the machinery and the ratification with a human, and claims no authority.
*Options:* (a) David only, via an ordinary front-door intake per promotion; (b) David, but batched —
one intake per week carrying all candidates that crossed the threshold; (c) a lighter standing
authorization: promotion is automatic above the threshold, with David notified and able to demote.
**Recommendation: (b).** (a) is correct in principle but will put a steady drip of small intakes on
your board, which is the pattern this layer is meant to reduce. (c) lets a list grow itself into a
gate, which §5.3 argues against. Batching keeps the authority exactly where (a) puts it while
costing one decision a week.

**D-6 · Is `restriction-breached` a FAIL or a FLAG on the board?**
Today it renders as an `adjudication-fail` FAIL [live, `REVIEW.md:30`], because it wears the model's
name. Once correctly labelled it is a guard event on a call that may have been healthy — and the
call is retried.
*Options:* (a) FAIL, as today; (b) FLAG, matching the existing `stage-breach` class which is live and
renders as a FLAG [live, `REVIEW.md:58`]; (c) FAIL only when the retry bound is exhausted.
**Recommendation: (c).** A single breach is a bounded, self-recovering event; an exhausted bound is a
standing fault that needs you. This is also the shape `record_pass_failure` already implements for
the retry count [live].

**D-7 · The reconciler's per-pass finding cap (`RECONCILE_MAX_NEW_FINDINGS`, proposed 20).**
A number worth your word because it trades board flooding against silent truncation.
*Options:* (a) 20 with a loud truncation line, as designed; (b) uncapped for the first observation
period, so the true finding volume is measured before a cap is chosen; (c) lower (5–10).
**Recommendation: (b) then (a).** R-2 is report-only and manually invoked, which is exactly the safe
place to measure real volume. Choose the cap from that measurement rather than from this estimate.

---

## 10 · What this document could not settle, and why

Stated plainly, as the verification bar requires.

1. **Where in the reviewer the generalization field is written.** The reviewer's audit is being moved
   by CLD-00119 and the split is not built (§1.2). §4 designs the step host-independently and R-7
   sequences behind the landing. This is a deliberate gap, not an omission.

2. **The exact edit site for the orchestrator half of R-6.** `orchestrator.sh:1160` is correct today
   [live] and is inside the code DEC-260119 I-4 retires [record]. D-3 splits the increment rather
   than guessing which site survives.

3. **The full transition table for §3.4 is not enumerated here.** It cannot honestly be, before R-1
   produces the status × exit-path table — and the live evidence that the declared vocabulary is
   already wrong (§1.4) is precisely why enumerating it from `STATUS_VOCAB` would produce a
   confident, wrong table. §3.4 specifies the table's *shape*, its failure behaviour and its
   fixtures; R-1 supplies its contents.

4. **Whether the `_index.md` ↔ spine comparison (C2) will be noisy.** `index-sync` writes the row
   from the spine [live], so in the steady state they should agree by construction and disagreements
   should be rare and meaningful. But nothing today measures that, and a comparison that fires
   constantly would swamp the bound. R-2 is report-only and manually invoked specifically so this is
   measured before it reaches a clock.

5. **The observation period before R-4 arms the repairs** is left unnumbered. It should be chosen
   from R-3's actual finding volume, not guessed here — the same reasoning DEC-260119's D4 applies to
   its own observation period [record].

6. **Whether `check_staleness.sh`'s 7-day escalated-OI reminder and the notification backstop
   double-nag** the same condition. Both are live [live, §1.6 and §1.9]; whether they fire on the
   same items in practice was not measured in this run. It is folded into D-4 rather than asserted.

---

## 11 · Traceability — every component to its ruling

| Ruling (ACI-260011) | Component | Section | Increments |
|---|---|---|---|
| 1 · Reconciliation, hourly on the Housekeeper, 15-min settle, deep nightly, re-derivable state, heal-where-mechanical, bounded findings | A | §3 | R-2, R-3, R-4, R-5 |
| 2 · The generalization step, mandatory terminal, **two-armed per the refinement**, one per fix, escape hatch | B | §4 | R-7 |
| 3 · Self-growing pre-flight checklist (classify → dedupe → cite → candidate → ratify) **and** the one-time state-machine completeness audit | C | §5.2–5.4, §5.5 | R-9, R-10, R-11 · R-1, R-8 |
| 4(a) · Notifications, transitions-only | D(a) | §6.1 | folded into R-3; residues a1/a2 in D-4 and R-3 |
| 4(b) · The honest-labeling residue | D(b) | §6.2 | **R-6** |
| 5 · Fast slot for short tasks | **NON-GOAL** | §7 | none, by ruling |
| 6 · Recovery-as-capability | folded into A, as directed | §3.6 | R-4 (H1–H4 + recovery notes) |

---

*End of design. Supporting material — the live-code evidence extract behind §1 — is in
`evidence-live-tree-20260808.md` in this directory.*
