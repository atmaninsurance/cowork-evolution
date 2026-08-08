# Reworking the Verifier — slimming the front door to the ratified end-state

**Design pass, 2026-08-07.** Produced by the headless executor session for queue task
`067-design-the-verifier-rework-slim-the-fron` (OI-000056), which the Designer lane drafted and
the orchestrator routed at 16:26 PT after its second pass cleared.

**This document changes no machinery.** It specifies a rework, weighs three shapes, recommends
one, lists what retires and what replaces it, orders the build into increments, and ends with a
single list of the questions that need David. Nothing here is enacted, no governance record is
authored, and the write-restriction guard stack is untouched — the design proposes changes to it
and does not make them.

**Supporting material:** `evidence-live-code-20260807.md` in this same directory carries the
verbatim code citations, the live ledger/log extracts, and the resolver output this document
rests on.

---

## In one page

**The problem.** When a request arrives, one long review pass currently answers five questions:
does the record authorize this, is it a good idea, can it be done as written, what deviates, and
what needs asking. Four of those five now belong to the Designer — the lane that landed
2026-08-06 and holds the pen. The old pass never stopped doing them, and it is still the thing the
machinery routes on.

**What it costs, measured today.** That pass runs on a 15-minute leash. While it runs, a
protective mechanism watches the record files for changes, and if *anyone else* writes to them —
a consulting session, a decision filing, an estate update — it deletes what they wrote and refuses
the call. That fired **seven times today** and destroyed **ten files**, including the action item
that documents this very defect (`ACI-260008`, now unrecoverable) and what appears to be your own
decision document for the fix (`decision-20260807-oi-000055.md`). Separately, the front door is
still asking claim-side drafting questions the Designer exists to answer — OI-000047's rounds
were three requests for exact paths and fence wording, and they still ended on your board.

**The recommendation.** Slim the pass in place. Keep every check code can prove — screen, red-line
tripwires, well-formedness, stamp provenance, byte-identity — and keep exactly **two** short model
questions: *does the record authorize this?* and, for a filing that already carries a design,
*is what would run what was authorized?* Everything else moves to the Designer. The longest
permitted window at the front door goes from 15 minutes to 6, and the exposure that caused today's
losses shrinks with it.

**Not recommended, and why.** Making the Verifier its own lane (the option you raised on
2026-07-31) is deferred, not refused — it fixes none of today's measured harm, it adds a real
waiting state and a daemon, and its central question ("who checks the checker's own task?") has no
answer in the record yet. Folding verification into the Designer is refused outright: it would put
the author and the checker in one lane, which is the one property the record consistently protects.

**What you need to decide:** nine items in §10. Three are urgent — the two destroyed records
(**D5**), what the one remaining authorization question must cover (**D1**), and whether the
"is this exchange going anywhere" check moves with the work it guards (**D3**).

---

## Where each required property is answered

| # | property the task requires | section |
| --- | --- | --- |
| 1 | The slim pass, specified check by check, with the boundary in one place | **§2** (checks §2.2; boundary table §2.3) |
| 2 | Three shapes weighed, one recommended, each rejection reasoned | **§3** |
| 3 | Clarification-round machinery: destination, and each bound upheld or named for amendment | **§4** (bounds §4.3) |
| 4 | Both flows drawn end to end | **§5** (designed §5.1; objective-level §5.2) |
| 5 | Retirement list — nothing retires without a named replacement and an observable transition | **§6** |
| 6 | Design input (a): copies, not originals, with its constraint intact | **§7** |
| 7 | Design input (b): role vocabulary as input, not a verdict | **§8** |
| 8 | Sequenced build increments, total order, named first step | **§9** |
| 9 | Everything needing David, in one place | **§10** |
| — | What could not be settled, and why | **§11** |
| — | Claims taken from the record and not re-checked | **Appendix** |

---

## 0 · Reading the record: what resolved, what did not

Run from the repository root at the start of this pass, exactly as the task specifies:

```
python3 _meta/screen.py --resolve ACI-260001 CLD-00109 ACI-260008 DEC-260114 OI-000055 OI-000037 OI-000047
```

| id | resolved to | read |
| --- | --- | --- |
| **ACI-260001** | `The_Estate/action-items/ACI-260001-260805-Open.md` | yes, in full |
| **CLD-00109** | `The_Estate/action-items/CLD-00109-260731-Open.md` | yes, in full |
| **DEC-260114** | `The_Estate/decisions/2026/DEC-260114.md` (+ `DIGEST.md`) | yes, in full — original + Amendments 1 and 2 |
| **ACI-260008** | **NOTHING — see below** | could not be read; it does not exist |
| **OI-000055** | **`unresolved-ref: OI-000055` on stderr** | read directly from the orchestrator tree (`orchestrator/items/OI-000055.*`) |
| **OI-000037** | five candidate estate files (fuzzy match, not the item) | read directly from `orchestrator/items/OI-000037.*` |
| **OI-000047** | five candidate estate files (fuzzy match, not the item) | read directly from `orchestrator/items/OI-000047.*` |

Three findings about the resolver itself, all checked against the live code and the live tree
during this run:

1. **The resolver does not resolve OI ids.** `screen.py --resolve` searches the estate registries
   (`The_Estate/action-items/`, `The_Estate/decisions/`) and the frozen legacy decisions file. OI
   ids are orchestrator-tree ids and are not in its index. `OI-000055` was correctly named
   `unresolved-ref:` on stderr. `OI-000037` and `OI-000047` were **not** named unresolved — they
   returned a list of estate files matched on tokens. That is a **quiet false positive**: a
   consumer that treats stdout as "the record this id names" is handed five unrelated documents
   and no signal that the id was never found. The attester pass (`orchestrator.sh:1120`) is
   exactly such a consumer — it inlines the resolved paths as "the anchored record(s) — read
   these". *(Named here as a defect for the record; it is not this design's to fix and it does not
   appear in the increments below, because it is not part of the Verifier rework. It is raised for
   routing as decision **D9**.)*

2. **ACI-260008 does not exist and was never committed.** The id is cited by ACI-260001's
   2026-08-07 progress entry, by CLD-00109's 2026-08-07 entry, by OI-000055's `related:` field and
   by OI-000056's `related:` field. There is no such file in `The_Estate/action-items/` (the
   directory holds ACI-260001 through ACI-260007 and no 260008), and `git log --all
   --diff-filter=A` in that repository shows the path was never added. It is unrecoverable from
   git.

3. **The record was destroyed by the guard this design is about.** Today's orchestrator log
   records `ACI-260008-260807-Open.md` as an *offending path* in two separate write-restriction
   breach refusals — 14:55 (during OI-000047's V/D pass) and 16:03 (during OI-000056's attester
   pass) — and the guard `rm -f`s every offending path before refusing the call
   (`_lib/run_claude.sh`, the breach branch inside the attempt loop). The file is absent now. The
   inferential step, labelled as such: *that the deletions are what removed it* is inference from
   (a) the path appearing as an offending path twice, (b) the cleanup being an unconditional
   `rm -f`, and (c) the file being absent and never committed. Everything else is direct
   observation. **This is the item recording the data-destruction defect, destroyed by the defect
   it records, twice.** It goes to David in §10 as decision **D5**; this pass does not re-mint or
   reconstruct governance records.

A fourth observation from the same log is worse and belongs with it: at 16:06 the breach cleanup's
offending-path list included `orchestrator/inbox/decision-20260807-oi-000055.md`. That inbox is
empty of it now, no ledger line records it being consumed, and OI-000055 still sits `escalated` on
David's board with its two `[interview]` questions unanswered. On the same evidence standard as
above: **a decision document filed for OI-000055 appears to have been destroyed before the
orchestrator could read it, so the fix for the destruction defect is itself blocked by the
destruction defect.** Also in §10 as **D5**.

---

## 1 · What the front door does today (checked against the live code, this run)

Every claim in this section was read out of the running tree during this pass. File and function
are cited inline; the fuller extracts are in `evidence-live-code-20260807.md`.

### 1.1 The intake path, hop by hop

`orchestrator/orchestrator.sh:3227 intake_pass()` walks `orchestrator/inbox/*.md` at every wake
and sorts each arrival into one of three paths: a `david-decision` continuing an open OI
(`handle_decision_reentry`, :3879), a `cowork`-authored correction of an OI held `clarifying` **or
`designing`** (`handle_clarification_reentry`, :3572), or a fresh intake
(`handle_fresh_intake`, :3280).

For a fresh intake `handle_fresh_intake()` does, in order:

| # | step | code | kind |
| --- | --- | --- | --- |
| 1 | mint the OI, quarantine the arrival as `OI-NNNNNN.intake.md` | `:3282` via `oilib mint` | code |
| 2 | mechanical provenance/PHI/injection/size screen | `:3298` `screen.py --intake` | code |
| 3 | **the V/D pass** — opus, 900 s, class a or b | `:3317` `run_vd_pass()` (:925) | model |
| 4 | adjudicate | `:3339` `finish_fresh_adjudication()` | code, on the model's verdict |

`finish_fresh_adjudication()` then, in order: parses the verdict line; bounds the findings onto
the spine; **autonomously disposes** if `recommend=dispose` + class resolved/duplicate + origin
`system-alert` + no red line (:3364); takes **branch 2** if the filing carries a `Designed-by:`
stamp — the second pass, then route (:3382–3427); tries **auto-route** for a verified
consultation with `variation=none`, gated by the attester (:3436–3481); runs the **clarify gate**
(:3491); takes **branch 1** — hand to the Designer — on a clean-but-blockless verdict
(:3520–3532); and otherwise **escalates** to David (:3534–3564).

### 1.2 The four model passes at the front door

| pass | function | model | timeout | what it decides |
| --- | --- | --- | --- | --- |
| **V/D** | `run_vd_pass` :925 | `opus` (:72) | **900 s** (:74) | provenance, viability/impact with a ≥3-alternatives discipline, the DEC-0091 semantic capability check, recommendation (route/dispose/needs-input), variation (none/significant), and the authoring **and classification** of every question |
| **attester** | `run_attester_pass` :1120 | `sonnet` (:73) | 360 s (:75) | one question: does the anchored record substantiate this work |
| **clarify progress judge** | `run_clarify_progress_pass` :1981 | `sonnet` (:90) | 300 s (:91) | one question: is the clarification exchange moving or rehashing |
| **intent judge** | `run_design_intent_pass` :3046 | `sonnet` (:2896) | 360 s (:2897) | one question: does this implementation serve the verified intent |

All four launch write-restricted through the same shared guard: `RUN_CLAUDE_TOOLS=Read,Glob,Grep`
(:327) and `RUN_CLAUDE_DENY_WRITE` over `~/Claude/memory/decisions`, `~/Documents/The_Estate`,
`~/Claude/transcripts`, the grants registry and the whole orchestrator tree (:328).

The **deterministic** second-pass half is `_meta/designcheck.py` — five checks, fail-direction
always REFUSE: stamp present and matching the exact grammar `designer/OI-NNNNNN@rN`; the stamp
tracing two hops to a real design record whose governance anchors themselves resolve;
byte-identity of the fenced block against the hash the Designer lane *measured* (not claimed);
well-formedness including the CLD-00088 self-close-out tripwire; and its own red-line pattern set
run in addition to the orchestrator's.

### 1.3 The gap between the ratified end-state and the running system

DEC-260114 Amendment 1 item 7 ratifies the second pass split by capability: **code proves the
enumerable half, a judge answers one question, and design-quality review is explicitly excluded.**
ACI-260001's 2026-08-06 ruling item 5 sequences "V/D is redesignated as the Verifier and its role
reworked" *after* the Designer lane lands. The lane landed 2026-08-06 and has run.

The live code shows the lag precisely. The V/D prompt (`run_vd_pass`, :967–1020) still instructs a
full judgment: viability and impact, the ≥3-genuinely-viable-alternatives discipline, a
recommendation, a variation call, and the authoring and classification of questions. Every one of
those is Designer-lane work under the ratified division of labour — and `finish_fresh_adjudication`
consumes them as its routing inputs, so the legacy pass is not merely running, it is **load-bearing**.

### 1.4 What that costs, measured today

Four things observed in the live tree during this pass, all dated 2026-08-07:

- **Clarification rounds are doing Designer work.** OI-000047's round-2 clarify sidecar — read at
  16:32 from `orchestrator/items/OI-000047.clarify.md`, and now at
  `orchestrator/archive/2026/OI-000047.clarify.md` because the item was delivered and closed at
  16:33, mid-pass — holds three `[clarification]` questions, and each is
  fence-precision drafting: enumerate every self-description string in a script, give the exact
  fixture path because the descriptor points at two real-but-wrong directories, and pin the
  assertion scope of three named checks. The rounds aged out and became David's. *(Consistent with
  ACI-260001's 2026-08-07 progress entry; re-checked against the live sidecar this run.)*
- **Seven judge calls were refused today by the write guard**, six in the orchestrator and one in
  the Designer lane, each destroying the offending files first: ten distinct paths including two
  estate action items, the estate index, two skills files, `orchestrator/items/OI-000054.md`, two
  session transcripts, `ACI-260008-260807-Open.md` and `orchestrator/inbox/decision-20260807-oi-000055.md`.
  None of the offending writes was made by a judge. They were made by concurrent writers whose
  only crime was writing during a judge's window.
- **Long windows are the exposure.** The V/D pass is capped at 900 s and the Designer at 1500 s.
  The attester, the progress judge and the intent judge are capped at 300–360 s. Every breach
  today occurred inside a long window (V/D, Designer) except one — the 16:03 attester refusal,
  which is the 6-minute pass and still collided.
- **This very item paid the price twice.** OI-000056's first V/D call was refused at 15:45
  (rc=62, offending path: a session transcript) and lost a wake; its Designer pass was refused at
  16:13 (rc=62, offending path: another OI's spine) and lost another. Its attester was refused at
  16:03 and rung down to `substantiated=no`, which blocked auto-route — a **fabricated-looking
  disagreement between two readers that was actually an infrastructure failure**, recorded on the
  spine as though it were a judgment.

### 1.5 Two live defects in the design/clarify seam, found during this pass

Both are in the running code; both matter to the rework and neither is currently recorded anywhere
I could find.

- **A design round is recorded as a clarification round.** `handle_clarification_reentry` (:3572)
  handles the Designer's return filing by reusing the clarification path. It correctly credits the
  *design* counter when the prior status was `designing` (:3614–3620), but the response sidecar is
  still named `OI-NNNNNN.clarify-response-NN.md`, the spine still gets `clarify_response=`, and the
  ledger line still reads **"clarification round 0 consumed"** — which is what OI-000056's own
  ledger says at 16:20 for what was in fact design round 1. Amendment 1 item 8 exists to prevent
  exactly this class of quietly-false flow statement.
- **The Designer's executor selection is refused on the return path.** DEC-260114 Amendment 1 item
  4 and Amendment 2 say the Designer selects the executor (system and model) and *requests* the
  hand-off. In code, `execution:` on a re-entering filing is explicitly **not honoured** (:3600,
  ledger `clarify-in FLAG … NOT honored from a clarification`), and
  `finish_clarify_adjudication` reads the execution mode off the **spine** instead (:3677). Model
  selection does travel — it rides inside the fenced task block's own frontmatter (`model: opus` on
  this task) — but the supervised/headless choice does not. The record and the code disagree; §10
  **D8** puts it to David.

---

## 2 · Property 1 — the slim pass, check by check

### 2.1 The boundary, in one sentence

**The Verifier decides whether the record authorizes this work and whether what would run is what
was authorized. Everything about whether the work is a good idea, whether it can be done as
written, how it should be done, who should do it and on what model belongs to the Designer.**

That sentence is the whole boundary. The rest of this section is it made checkable.

### 2.2 The checks that remain at intake

Ordered as they run. "Emits" is what lands on the spine and the ledger. "May no longer decide" is
stated for every check, because that is where the boundary actually bites.

**S1 · Mechanical intake screen** — *code.*
Reads: the quarantined intake only. Checks: PHI/secret shapes, prompt-injection shapes, oversize,
consultation-claim-without-anchors, history-rewrite/force-push. Emits: `ACCEPT` or `REJECT:
<reasons>`; a reject disposes the item and notifies. **May no longer decide:** nothing changes —
this is `screen.py --intake` exactly as it stands today (`orchestrator.sh:3298`).

**S2 · Anchor resolution, with loudness** — *code.*
Reads: the spine's `related:` field. Emits: the resolved record paths, plus the name of every ref
that resolved to nothing, onto the spine (`ATT_UNRESOLVED` / `att_progress_line`, :1190). **May no
longer decide:** whether an unresolved anchor is fatal. It is not evidence of anything; it is
input to S5, which is conservative on partial resolution by construction.
*Precondition on this check:* §0 finding 1 — the resolver returns fuzzy candidates for ids it does
not hold, so "resolved" is not yet trustworthy for non-estate ids.

**S3 · Red-line tripwires** — *code.*
Reads: the artifact under judgment — the quarantined intake, a clarification/design response, or a
decision sidecar; **never the spine** (`red_line_hit`, :253, signature enforced since CLD-00085
A1). Checks: governance surfaces, `~/.openclaw/`, protected paths, irreversible operations, spend.
Emits: hit / where / context; a hit blocks auto-route and blocks entry to the Designer lane
(:3521). **May no longer decide:** nothing — unchanged, and it is the one check that must never be
argued past by a model.

**S4 · Well-formedness and the enumerable tripwires** — *code. This is the check that grows.*
Reads: the filing and the fenced block it carries, if any. Checks, all of which exist today but
only for *stamped* filings inside `designcheck.py`: parseable frontmatter, required fields, a
non-stub body, a declared deliverable that survives promotion normalization, and the **CLD-00088
self-close-out tripwire** (a headless task instructing the session to move its own file, set its
own `status:` or write its own `## Result`). Emits: `pass=yes|no` plus one `REFUSE: <check>:
<why>` per failure. **May no longer decide:** nothing — but it **takes over** the self-close-out
judgment, which today is a paragraph in the V/D prompt (:994–1000) asking a model to spot an
enumerable pattern. Code owns enumerable things.

**S5 · The substantiation attester** — *model, one question, minimal context.*
Reads: the resolved anchored records and the proposed work — and **nothing else**; specifically
not the rich findings of any other pass. That is the two-readers-different-inputs property David
established on 2026-07-23 and CLD-00109 protects. Answers: *does the anchored record substantiate
this work — is this something the record already contemplates and authorizes?* Emits:
`ATT-VERDICT: substantiated=<yes|no>`, plus the unresolved-ref list. Fail direction: any failure,
any doubt, and any unreadable input → `no` → escalate. **May no longer decide:** viability, worth,
doability-as-written, alternatives, variation, question authoring, question classification,
executor or model. It answers one question and it is the *only* general-purpose model judgment
left at the front door.

*One deliberate widening, flagged for David as D1.* Today the semantic half of the DEC-0091
capability check lives in the V/D prompt (:975–983): does the anchored record explicitly name
**both** the capability and the scope this item wants? That is a substantiation question, not a
viability question, and CLD-00109's 2026-08-02 ratified unified-authorization design already
widens the attester's question in this direction ("do grant, record and the conversation where it
was decided all align") and moves it to the front. **Recommendation: the attester absorbs it**, so
the capability/scope check survives the V/D pass's retirement rather than falling on the floor.
It is called out separately because it is the one place where slimming the Verifier requires
*adding* a sentence to a prompt rather than removing one.

**S6 · Stamp provenance and byte-identity** — *code; only for a filing carrying a design.*
Reads: the `Designed-by:` stamp, the design record it names, and the fenced block. Checks: the
stamp matches the exact grammar; hop one — the design record exists; hop two — its governance
anchors resolve; the block's bytes hash to the value the Designer lane **measured**. Emits:
`DESIGNCHECK: pass=… checks=N/N`. **May no longer decide:** nothing — unchanged
(`designcheck.py`, called from `design_second_pass`, :3101).

**S7 · The intent judge** — *model, one question; only for a filing carrying a design.*
Reads: the design record and the filing that would route. Answers: *does this implementation serve
the verified intent* — it implements the thing that was verified, does not silently widen scope,
does not drop substance. Emits: `INTENT-VERDICT: serves_intent=<yes|no>`. Fail direction: no →
back to the Designer for a bounded round. **May no longer decide:** provenance, authority, worth,
design quality, elegance, feasibility — all excluded in the prompt today (:3066–3070) and all
still excluded.

### 2.3 What the front door may no longer decide, in one place

| decision | today | after |
| --- | --- | --- |
| Is this work viable / worth doing? | V/D `viability` | **Designer** |
| Can it be done as written? Alternatives? | V/D, ≥3-alternatives discipline | **Designer** |
| Route, dispose, or needs-input? | V/D `recommendation` | **Designer** (dispose → D2) |
| Does it deviate from what the record contemplates? | V/D `variation` | **Designer**, reported in its design record; the attester's yes/no is what gates authorization |
| What questions block this, and whose are they? | V/D authors and classifies | **Designer** authors; only David-class questions leave the lane |
| Which executor, which model, headless or supervised? | not decided at the front door; `execution:` is refused on re-entry | **Designer** (D8) |
| Does the record authorize this? | V/D `provenance` + attester | **attester alone** (S5) |
| Does the record authorize this *capability at this scope*? | V/D prompt §2b | **attester** (D1) |
| Is this a red line / malformed / a self-closing headless task? | split between V/D prose and code | **code alone** (S3, S4) |
| Is what routes what was verified? | `designcheck.py` | unchanged (S6) |
| Does the implementation serve the intent? | intent judge | unchanged (S7) |

The shape of the answer: **the front door keeps every check that code can prove and exactly two
model questions — one about authorization, one about fidelity.** Both are short, both are
single-question, both fail closed.

---

## 3 · Property 2 — three shapes, weighed; one recommended

The record names these three and recommends none. Choosing is this pass's work.

### Shape A — slim in place *(RECOMMENDED)*

Keep the pass inline in the orchestrator's wake. Strip it to S1–S7 above. Move clarification
rounds wholesale to the Designer.

**What it costs.** The Verifier remains a subroutine of the component it exists to check — the
structural objection CLD-00109 raises ("it would stop being a subroutine of the component it
exists to check"). No per-item model selection: the attester's model is a launch-time env var
(`ATT_MODEL`, :73), the same for every item. No fan-out. The wake stays serial, so a slow judge
still delays the wake — though the whole point of slimming is that "slow" goes from 900 s to
~360 s.

**What it buys.** It is the literal reading of DEC-260114 Amendment 1: the orchestrator layer
"stays slim — intake, verification, notification", with verification named as one of the three
things the orchestrator *does*. It requires no new daemon, no new watched folder, no asynchronous
waiting state, and it raises no recursion question. Most importantly it attacks the actual
measured cost — **window length, not window placement.** Every failure priced in §1.4 is a
consequence of a 900-second full-judgment pass; none of them is a consequence of the pass being
inline. Moving a 900-second pass into its own lane leaves it 900 seconds long and adds a daemon.

**Why it is recommended.** Three reasons, in order of weight.

1. **It is the change the evidence asks for.** Seven refusals today, all inside long windows;
   clarify rounds doing Designer drafting; a judge asked five questions when the ratified design
   asks it one. Slimming fixes all three. Re-lane-ing fixes none of them.
2. **It is reversible and it makes Shape B cheaper, not harder.** The increments in §9 end with
   the front-door decision expressed as a single function whose inputs are (screen result,
   red-line result, deterministic checks, attester verdict, stamp/block presence) and whose output
   is a route/hand-off/escalate branch. A pass with that contract is *far* easier to lift into a
   lane later than today's tangle of verdict-string parsing. Shape B stays available at a lower
   price.
3. **The recursion question is genuinely unanswered.** "Screen at every promotion" is a standing
   invariant (CLD-00043); "the orchestrator mints the Verifier's task mechanically" is precisely
   the trusted-origin-is-not-trusted-authority trap that invariant exists to name. Recommending a
   shape whose central question the record explicitly flags as open would be recommending the
   design of it, not the thing itself.

**What it does not settle.** Per-item model selection and fan-out are real goods and Shape A does
not deliver them. They are deferred, not denied — §10 **D7** names the evidence that should
reopen the lane question.

### Shape B — the Verifier as its own lane *(rejected, for now)*

Its own watched inbox, own cadence, own model per item, artifacts home, fan-out; the shape
CLD-00109 raises as "the central architectural question" in David's own words.

**Rejected because**, at this moment and for this rework:

- **The recursion question has no answer in the record.** What screens the Verifier's own task?
  The obvious answer is the trap the invariant names. Shipping the lane means either answering
  that question first (a separate design pass) or shipping a known hole.
- **`verifying` becomes a real asynchronous waiting state.** Today it is an in-flight moment
  inside one wake. As a lane it is a durable status with its own age-out clock, its own
  dead-letter class, and its own "what if the lane is not installed" branch — three new failure
  modes to design and test, for a pass this rework is about to make *small*.
- **It needs either a third launchd daemon or contention on the executor lane's serial drain.**
  The daemon path adds an install (a David-authorized class — the Designer lane's own install
  needed his direct authorization on 2026-08-06). The contention path puts verification behind
  whatever 90-minute build is currently draining.
- **It does not address the measured harm.** The seven refusals, the misplaced clarify rounds and
  the five-questions-instead-of-one all survive a move to a lane unchanged.

**Not rejected on principle.** Every benefit CLD-00109 names is real. The rejection is one of
sequencing: slim first, then decide whether a small pass is worth a lane.

### Shape C — collapse verification into the Designer's return path *(rejected)*

No Verifier at intake at all. Everything goes straight to the Designer; the front door keeps only
the deterministic gate plus the attester on the way back out; no intent judge, because the
Designer's own output is what would be judged.

**Rejected because it forfeits the property the record most protects.** DEC-260114 Amendment 1
item 3 states the invariant plainly: *the session that writes the verdict never held the pen; the
session that held the pen never writes the verdict.* Shape C puts author and checker in one lane.
The attester would survive as a nominally separate pass, but it would be reading a document
produced by the same lane that decided what the document should say, from the same anchors, with
the same reading of them — and the two-readers-**different-inputs** property (David's 2026-07-23
walkthrough; CLD-00109's 2026-08-02 position set) is what makes the pair hard to steer. Two
readers with the *same* inputs is one reader with a second opinion.

A second, concrete reason: it deletes the cheapest guard in the system. The intent judge costs one
360-second sonnet call and is the only check that asks whether what would run matches what was
authorized. §1.4 shows the Designer lane failing twice today; a lane that can fail is a lane whose
output needs checking.

**What survives from it.** Shape C is right that the fastest path is fewer, shorter passes. Shape
A takes that and keeps the separation: the two model passes that remain are both single-question
and both short.

---

## 4 · Property 3 — where the clarification-round machinery goes

### 4.1 The change in one sentence

**Claim-side questions stop being a front-door artefact.** Today the Verifier authors and
classifies questions, the orchestrator sidecars the claim-side ones, hands them to the Designer,
and waits for a corrected intake to come back through the front door for a full re-verification.
After the rework, the Designer *is* the surface that answers claim-side questions — it has the
record, the tree and the pen — so it answers them **in-lane, without a round trip**, and only
David-class questions ever leave it.

ACI-260001's 2026-08-06 ruling item 3 already authorizes this: "**the lane decides how** duty (a)
executes — in-lane or via minted responder tasks."

### 4.2 Who does what, after

| duty | today | after |
| --- | --- | --- |
| Notice a claim-side defect | V/D, as a tagged `[clarification]` question | **Designer**, while drafting; it is the same act |
| Answer it | Designer, via a request written by the orchestrator, returned through the front door, re-verified in full by opus | **Designer**, in-lane, no round trip, no second opus pass |
| Notice an authority-side question | V/D, as `[interview]` / `[consultation]` | **Designer**, in its design record, per ACI-260001 2026-08-06 item 4 ("every Designer output distinguishes questions it raised and answered itself from those needing David") |
| Package and escalate it | orchestrator `run_escalation_pass` | **unchanged** — same pass, same package, same Telegram grammar; its input becomes the Designer's residual question list instead of V/D's |
| Refuse to answer an authority question | mechanical class filter (`filter_questions_class`, :899) | **unchanged** — the filter stays, applied to the Designer's list; a lane must not answer an `[interview]` question and the machinery, not the prompt, is what prevents it |

### 4.3 The three bounds — each upheld or named for amendment

DEC-260114 item 3 and Amendment 1 item 9 leave DEC-0093's round cap, per-round progress judgment
and ~24h age-out standing. Here is each one, explicitly:

**(a) Round cap — UPHELD, and it is already built.** `DESIGN_ROUND_MAX=3` (:2891), checked in
`designer_handoff` *before* the request is written (:2965), so a capped item cannot wake the lane
at all. At the cap the item parks on David's board with `design_promoted=cap-reached`. The
clarification cap (`CLARIFY_ROUND_MAX=3`, :88) becomes unreachable at intake because no clarify
round is opened there any more; it stays in the code as the bound on any future clarification
producer and is *not* deleted. **No amendment needed.**

**(b) Per-round progress judgment — NEEDS AMENDMENT OR A PORT, and this is the one real gap.**
The progress judge exists only on the clarification loop (`clarify_gate` :2079–2096 calling
`run_clarify_progress_pass` :1981). **The design loop has no equivalent** — `designer_handoff`
checks the cap and nothing else. So if clarification rounds move to the design loop as-is, a
mechanism DEC-0093 requires quietly stops running: a Designer that rehashes gets all three rounds
instead of being stopped at two. Two honest options, and this pass recommends the first:
- **Port it** (recommended). The judge is model-cheap (sonnet, 300 s), needs no file access, and
  compares two question sets. On the design loop it compares round N's refusal reasons with round
  N-1's — the same shape, the same conservative rung-down (any failure or doubt = not progressing
  = promote to David). Small, and it keeps DEC-0093's guarantee true.
- **Amend DEC-0093** to state that the progress judgment binds clarification exchanges only, and
  that the design loop is bounded by cap plus age-out alone. Cheaper, and weaker: it removes a
  live guard rather than moving it. Named here so the choice is explicit rather than a silent
  drop. → §10 **D3**.

**(c) ~24h age-out backstop — UPHELD, and it is already built.** `DESIGN_AGEOUT=86400` (:2892),
`design_ageout_pass()` (:3157) runs at every wake, escalates through the *normal* escalation path
with a real package, and notifies. It is a faithful copy of `clarify_ageout_pass` (:2138). **No
amendment needed.** One note for the build: the clarify age-out is *per round* (it skips a hold
whose current round was consumed, :2151); the design age-out has no such guard and ages from
`design_since`, which is re-stamped at every hand-off (:3030) — equivalent in effect, worth a
fixture rather than a change.

### 4.4 The machinery that stays, unused, on purpose

`write_clarify_sidecar` (:1919), `clarify_gate` (:2049), `clarify_sidecar_questions` (:2027) and
`handle_clarification_reentry`'s clarification branch are **not deleted**. Two reasons: a
clarification producer may return (a human surface filing a correction is still a legitimate
path), and deleting a working bounded loop to prove a point is how a system loses a backstop it
turns out to need. What changes is that **nothing at the front door produces a clarify round any
more**, which is observable as `clarify-out` ledger events at intake going to zero.

---

## 5 · Property 4 — both flows, end to end

Notation: **[code]** deterministic, **[model]** a model call with its cap, **[spine]** what the
orchestrator records. The orchestrator writes the spine in every hop; no other lane ever does
(Amendment 1 item 8).

### 5.1 Flow 1 — a filing that arrives already designed

This is what happens after the Designer has drafted, and what happened to this very task at 16:20–16:26.

| # | hop | actor | reads | [spine] |
| --- | --- | --- | --- | --- |
| 1 | filing lands in `orchestrator/inbox/` | Designer lane (files; never routes) | — | — |
| 2 | recognised as a return for an OI in `designing` **[code]** | orchestrator `intake_pass` :3266 | `requested_by`, `related:` | — |
| 3 | **S1** mechanical screen **[code]** | `screen.py --intake` | the filing | reject ⇒ refuse, item stays `designing` |
| 4 | quarantine as an immutable numbered response, chmod 0444 **[code]** | :3605 | — | `design_consumed` +1, `design_response=` |
| 5 | **S3** red-line on the response **[code]** | `red_line_hit` | the response | hit ⇒ escalate |
| 6 | **S4** well-formedness + close-out tripwire **[code]** | `designcheck` | the response + its block | `REFUSE:` lines |
| 7 | **S6** stamp provenance + byte-identity **[code]** | `designcheck` | stamp → design record → anchors; block hash | `pass=yes checks=N/N` |
| 8 | **S7** intent judge **[model, 360 s]** | `run_design_intent_pass` | design record + filing | `INTENT-VERDICT:` |
| 9 | mint grants for any declared capability **[code]** | `mint_grants` :437 | the block | grant ids + authorization line |
| 10 | build + **re-screen** the routable task at the hop **[code]** | `build_routable_task` :1634 | the block | refusal ⇒ fail closed |
| 11 | route to the executor **[code]** — the orchestrator performs the hand-off, never the lane | `route_task` / `route_supervised` | — | `status=routed decision=designed-route executor= task= deliver_to= execution=` |
| 12 | flow projection regenerated from `ledger.md` **[code]** | `spine_flow_sync` :3207 | ledger lines keyed by OI | `## Flow` |

**Removed relative to today:** the full V/D re-verification at step 3½ — today
`handle_clarification_reentry` runs a complete opus pass (`run_vd_pass … "V/D Re-verification"`,
:3630) *before* the second pass, so a designed filing pays for both the legacy judgment and the
ratified one. That is the single largest window on this flow and Amendment 1 item 7 does not ask
for it: the second pass *is* the check on a designed filing.

**Kept deliberately:** the mechanical screen at step 3 and the re-screen at step 10 (defence in
depth — a designed filing is screened twice, exactly as today), byte-identity, the red-line gate,
and the intent judge.

**Refusal path:** any refusal at 3–8 ⇒ `design_refusal_route` (:3137) hands it back to the
Designer while rounds remain, and parks it on David's board at the cap. Unchanged.

### 5.2 Flow 2 — a filing that arrives at objective level

The normal case for a high-level intake (DEC-0098; DEC-260114 item 4).

| # | hop | actor | reads | [spine] |
| --- | --- | --- | --- | --- |
| 1 | arrival in `orchestrator/inbox/` | any surface | — | — |
| 2 | mint + quarantine **[code]** | `oilib mint` | the arrival | `OI-NNNNNN` minted, `status=received` |
| 3 | **S1** mechanical screen **[code]** | `screen.py --intake` | the quarantined intake | reject ⇒ `disposed`, notify, archive |
| 4 | **S2** anchor resolution **[code]** | `screen.py --resolve` | `related:` | resolved paths; **unresolved refs named** |
| 5 | **S3** red-line **[code]** | `red_line_hit` | the intake | hit ⇒ escalate, never enters the Designer lane |
| 6 | **S4** well-formedness / close-out tripwire **[code]** | `designcheck --any` | the intake | `REFUSE:` lines ⇒ escalate |
| 7 | **S5** attester **[model, 360 s]** | `run_attester_pass` | resolved anchors + the intake **only** | `ATT-VERDICT: substantiated=` (+ unresolved list) |
| 8a | `substantiated=no` ⇒ **escalate** | `run_escalation_pass` + `notify_david` | spine | `status=escalated decision=escalate` |
| 8b | `substantiated=yes` + no block ⇒ **hand to the Designer** **[code]** | `designer_handoff` duty=`draft` | spine | `status=designing decision=design design_round=1` |
| 8c | `substantiated=yes` + a block already present ⇒ Flow 1 from step 5 | — | — | — |
| 9 | Designer drafts: viability, alternatives, the block, executor + model, its own questions | Designer lane **[model, 1500 s]** | spine, intake, anchors, live tree | *(lane writes only its own tree)* |
| 10a | Designer has David-class questions ⇒ files them; orchestrator packages and escalates | orchestrator | design record | `status=escalated` |
| 10b | Designer files a corrected intake at the front door ⇒ **Flow 1** | Designer files; orchestrator routes | — | — |
| 11 | age-out backstop at ~24h at any hold | `design_ageout_pass` | `design_since` | `design_promoted=aged-out`, escalate + notify |

**Removed relative to today:** the 900-second opus V/D pass at step 7, and with it the
`recommend=` / `variation=` / `questions=` verdict fields that `finish_fresh_adjudication` branches
on; the clarify gate at the front door; and the auto-route branch's dependence on a V/D verdict.

**What replaces auto-route.** Today auto-route requires origin=`david-consultation` **and**
`provenance=verified` **and** `recommend=route` **and** `variation=none` **and** no red line **and**
the attester. After: **origin=`david-consultation` and the attester's `substantiated=yes` and no
red line and S4 clean and a block present.** The `variation=none` condition — "David has already
seen this; don't show him again unless it deviates" — is the one thing genuinely lost, because
"does this deviate from what the record contemplates" is a judgment the slim attester does not
make. Two ways to hold it, and this pass recommends the first: **the Designer states variation in
its design record** and a `variation: significant` statement blocks auto-route mechanically (the
Designer is the party that would know, since it did the design work); or accept that a
consultation-origin item with a verified anchor and a designed block routes without that gate. →
§10 **D2** covers the adjacent dispose question; this one is folded into **D1**.

---

## 6 · Property 5 — what retires, what replaces it, how you can tell

**Rule applied throughout: nothing retires with nothing named in its place.** Every row names the
replacement and an *observable* transition — something a reader can check in the ledger, on a
spine, or in the tree, without asking anyone.

| # | what retires | what it did | what now does it | observable transition |
| --- | --- | --- | --- | --- |
| R1 | **The V/D pass at fresh intake** (`run_vd_pass` called from `handle_fresh_intake`, :3317) | full judgment: provenance, viability, alternatives, capability semantics, recommendation, variation, question authoring + classification | provenance/capability → **S5 attester**; everything else → **Designer lane** | no `vd-prompt-OI-*.txt` or `vd-OI-*.log` is written for a fresh intake; the ledger's `V/D (opus)` progress line is replaced by `attester (sonnet)`; the longest *permitted* front-door model window on this path drops from 900 s to 360 s (a cap comparison — actual durations were not measured in this pass) |
| R2 | **The V/D re-verification on the design return path** (`run_vd_pass … "V/D Re-verification"`, :3630) | re-judged the Designer's filing in full before the second pass | **S6 + S7** — the second pass, which is the ratified check on a designed filing (Amendment 1 item 7) | spines stop carrying a `## V/D Re-verification` section; the `V/D re-verify (opus)` progress line disappears; `design-2nd` ledger lines appear without a preceding `vd` line |
| R3 | **The `VD-VERDICT:` grammar as a routing input** | `recommend=` / `variation=` / `questions=` were parsed by `finish_fresh_adjudication` (:3343–3347) and drove every branch | a **decision record built from code results** — screen, red-line, S4, `ATT-VERDICT`, stamp/block presence — assembled in one function | the spine's findings block changes shape from five prose fields to a check table plus one verdict line; `grep 'VD-VERDICT' orchestrator/items/*.md` stops growing |
| R4 | **Question authoring and classification at the front door** (V/D prompt step 5, :1001–1020) | produced the `[clarification]` / `[interview]` / `[consultation]` tagged list | **Designer**, in its design record, per ACI-260001 2026-08-06 item 4 | `clarify-out` ledger events at intake fall to zero; escalation packages cite the design record as their question source |
| R5 | **Clarification rounds as a front-door round trip** (`clarify_gate` producing a hold at intake) | held the item, wrote a sidecar, handed to the Designer, waited for a filing, re-verified it in full | the Designer answers claim-side questions **in-lane** (ACI-260001 2026-08-06 item 3 authorizes it) | no new `OI-*.clarify.md` files; `design-handoff duty=clarify` disappears from the ledger; `duty=draft` remains |
| R6 | **The V/D prompt's CLD-00088 self-close-out paragraph** (:994–1000) | asked a model to spot an enumerable pattern (a headless task told to close itself out) | **S4**, in code — `designcheck.py` already implements exactly this check for stamped filings | a `REFUSE: self-close-out: …` line is emitted by code on a filing that would previously have produced a `variation=significant` prose finding; a fixture pins it |
| R7 | **The 900-second opus window at the front door** (`VD_MODEL` :72, `VD_TIMEOUT` :74 — as an *intake* setting; both remain for the repair paths) | gave one pass 15 minutes and the most expensive tier, at every intake | two 360-second sonnet passes (S5, S7), each asking one question | no `opus` model call is made from `handle_fresh_intake`; the front door's worst-case model window is 360 s — checkable by timing successive ledger lines within one wake |
| R8 | **Autonomous dispose on a V/D `recommend=dispose`** (:3364) | closed obvious false alarms without David | **pending D2** — recommended: the Designer recommends disposal and the orchestrator enacts it only for `origin=system-alert`, preserving today's bound | `dispose` ledger lines cite a design record instead of a V/D verdict; the `origin=system-alert` restriction is unchanged and pinned by a fixture |

**Two things that explicitly do NOT retire**, because a reader might expect them to:

- **The write-restriction guard stack.** Not retired, not weakened, not modified by this design.
  §7 proposes a change to its *necessity*; enacting anything is out of scope and is fenced. The
  separately routed OI-000055 fix — "nothing is ever destroyed" — is fixed input here, not a
  variable.
- **The clarification machinery itself** (§4.4). It stops being *produced* at the front door; it
  is not deleted, and its cap, age-out and authority refusal all remain in force for any future
  producer.

---

## 7 · Property 6 — copies, not originals

### 7.1 The proposal, plainly

Today a judging pass is handed **paths into the live trees** and told to read them: the spine, the
quarantined intake, and the resolved governance records under `~/Documents/The_Estate/`
(`run_vd_pass` :945–952, `run_attester_pass` :1147–1164, `run_design_intent_pass` :3071–3073). To
stop those sessions writing where they read, the machinery wraps every launch in a three-layer
guard: tool-surface removal (`Read,Glob,Grep`, no MCP), a macOS seatbelt kernel write-deny over
the whole evidence base, and a post-hoc ground-truth check that snapshots every deny path before
launch and compares it after (`_lib/run_claude.sh`).

**The proposal: stage a copy.** Before the call, code copies the exact files the pass is entitled
to read into a per-call staging directory, hashes each one, and gives the pass paths into *that*
directory and nowhere else.

### 7.2 What it buys

- **Evidence integrity by construction.** The pass cannot write the evidence base because it
  cannot reach it. This is the same class of guarantee CLD-00109's position 2 sought ("the judging
  roles must be STRUCTURALLY unable to write the evidence base") obtained by removing the target
  rather than by fencing the actor.
- **It removes the false-positive surface, which is the actual harm.** This is the important
  point and it is easy to get backwards. Copies do not stop a judge writing; the tool-surface
  removal already does that. What copies do is make the **deny list unnecessary** — and the deny
  list is what produces the destruction. Every one of today's seven refusals was triggered by
  *someone else* writing to a deny path during a judge's window: an estate item, the estate index,
  a skills file, another OI's spine, a session transcript, the orchestrator's own inbox. None was
  a judge write. With a staging directory, the set of paths worth watching shrinks to the staging
  directory itself, which no other process touches — so the detector stops firing on innocent
  concurrent writers, and stops deleting their work.
- **A frozen read set makes findings reproducible.** A pass that runs 6 minutes over live files
  can read a record mid-edit. A hashed snapshot is what the pass actually saw, and it can be
  attached to the verdict.
- **It shortens the guard's blast radius to zero for the estate and the transcripts**, which is
  where the irreversible losses have occurred.

### 7.3 What it costs

- **Staging cost per call.** Small in absolute terms (a handful of markdown files), but it is new
  code on the hot path, and code that decides *which* files a pass may see becomes a security
  boundary of its own: a bug that omits an anchor makes a pass judge on incomplete evidence and
  answer `no` (the conservative direction — acceptable), and a bug that includes too much
  re-widens the surface (the dangerous direction — needs a fixture).
- **Staleness.** A snapshot is a moment. For a 360-second single-question pass this is
  immaterial; it would not have been immaterial for the 900-second full-judgment pass, which is
  another reason copies become viable **only after** the slimming in §2. Sequencing matters here.
- **The pass loses the live tree.** Today V/D's viability finding routinely inspects the running
  code — OI-000055's own findings cite `comm -13` at a specific line of `run_claude.sh`. That is
  genuine value, and it is exactly the work moving to the Designer, which keeps live-tree access
  (`DESIGN_TOOLS` includes `Write,Edit`; its deny list fences other lanes' trees,
  `designer.sh:172–173`). So the loss falls entirely on capabilities the slim pass is giving up
  anyway. **A Verifier that is not asked "is this doable" does not need to look at the code.**
- **Two paths must remain live-tree by nature.** S6's byte-identity check hashes the real filing
  and the real design record (it is a measurement of what would route — a copy would prove the
  copy). And the intent judge reads the design record, which is the Designer lane's own tree, not
  the evidence base. Both are code-adjacent and neither is in the deny list's dangerous half.

### 7.4 What it implies for the guard stack — proposal only

**This design proposes; it does not enact, and it must not be read as authority to change
anything.** With copies in place:

- **Layer 1 (tool-surface removal) should stay.** It is nearly free, it is independent, and it is
  what makes "write nothing" true even if staging has a bug.
- **Layer 2 (kernel seatbelt deny) becomes narrow rather than broad.** Its subject would be the
  staging directory's parent plus the lane's own tree, instead of five live trees. That is a
  proposal for the pass that owns DEC-0104, not a change made here.
- **Layer 3 (post-hoc snapshot + `rm -f` + refuse) is the one that destroys work**, and the
  correct sequence is unambiguous: **OI-000055's "nothing is ever destroyed" fix lands first,
  independently, on its own routing.** This design neither gates it, pre-empts it, nor
  re-specifies it. Treat its floor as fixed input. Only after that fix has landed and copies are
  in place is there a coherent conversation about whether layer 3's *scope* should shrink — and
  that conversation belongs to David and to whoever owns DEC-0104. → §10 **D4**.

**The honest counter-argument, stated because it is real:** today's layer 3 has caught genuine
leaks. Task 064's report documents five pre-launch canary shapes that all failed to predict a real
leak that then occurred, which is why the post-hoc form exists. Removing the broad deny list on
the strength of "the pass reads copies now" assumes the staging boundary holds. It should
therefore be **narrowed, not removed**, and the narrowing should follow a period in which the
snapshot check runs unchanged and reports zero judge-caused breaches. That period is an increment
(§9, I-6), not an assumption.

---

## 8 · Property 7 — role vocabulary: input to the naming pass, not a verdict

**This document does not settle names.** CLD-00109's 2026-08-07 entry records David's observation
that the vocabulary is costing real comprehension — "judge/verifier/attester read as three
mysteries" — and routes the decision to the naming-convention pass that OI-000037 carries. What
follows is this pass's contribution to that decision, offered as input.

**The observation from inside the code.** There are not three roles. There is one role that runs
several passes, and the passes are named after *implementations* rather than after the *questions
they ask*. "V/D" names a pair of duties that a ratified decision has already split apart.
"Attester" names a legal metaphor. "Judge" is used in the code for four different passes (V/D, the
attester, the progress judge, the intent judge) that share only a launch configuration.

**Recommendation (input, not decision): name the acts, not the actors.** One role — the
**Verifier** — running passes named for their question:

| proposed name | the question, in one line | today's name |
| --- | --- | --- |
| **screen** | Is this filing safe and well-formed enough to look at? | mechanical screen |
| **authorization check** | Does the record authorize this work, at this scope? | attester / V/D provenance + capability |
| **fidelity check** | Is what would run what was authorized? | second pass (deterministic half + intent judge) |
| **progress check** | Is this exchange moving or rehashing? | clarify progress judge |

And **Designer** keeps both of its duties, because they are one act: deciding what to do and
writing it down.

**Three specific notes for the naming pass:**

1. **"V/D" should be retired as a term, not renamed.** It is an abbreviation of a bundling the
   record has already undone. Any successor name that still covers both halves re-creates the
   confusion. *(Sequencing note: it appears in dozens of live progress lines, ledger event names
   and spine sections; renaming it is a mechanical sweep with real blast radius, and it should be
   sequenced after the behavioural rework, not with it.)*
2. **"Judge" should be a category, not a name.** Useful as "the judging passes launch
   write-restricted"; harmful as a name for any particular pass.
3. **The "coordinator lock" collision flagged on CLD-00109 (2026-08-07) is still open** — the
   orchestrator's serial-lock vocabulary versus the proposed Coordinator role name. Whatever name
   the residual dispatch role takes should be chosen against the lock vocabulary, not beside it.

---

## 9 · Property 8 — the build, in order

Nine increments, total order, each independently landable. "Before" is what must be true to start;
"after" is what a reader can observe once it lands. No increment depends on a decision §10 has not
raised; where one does, the decision is named in its "before".

### I-1 — **FIRST STEP.** Deterministic checks run on every filing, advisory only

**Before:** nothing. This is the first step and it is deliberately the safest one.
**Do:** extend `_meta/designcheck.py` with a mode that runs its enumerable checks — well-formedness,
required fields, non-stub body, deliverable declaration, the CLD-00088 self-close-out tripwire,
and its red-line set — against *any* filing, stamped or not. Call it from `handle_fresh_intake`
immediately after the mechanical screen. **Record the result and route on nothing.** The V/D pass
still runs and still decides.
**After:** every fresh intake carries an `intake-check` line on its spine and in the ledger. Where
code and the V/D pass disagree, both are visible on the same spine. Zero behavioural change to
routing — this increment cannot break the front door, and it produces the evidence I-3 needs.

### I-2 — Port the enumerable half out of the V/D prompt

**Before:** I-1 landed and its checks have agreed with V/D's prose findings across the intakes seen
since (a handful is enough; disagreements are the signal, not the count).
**Do:** delete the CLD-00088 self-close-out paragraph (:994–1000) and the well-formedness asks from
the V/D prompt. Nothing else about the pass changes.
**After:** R6 is done. The prompt is shorter; the check is stronger (code cannot miss a pattern it
matches). A fixture asserts the refusal fires on a self-closing headless task.

### I-3 — The adjudication branch reads code results, not the verdict string

**Before:** I-1 and I-2 landed. **D1** answered (what the attester's one question must cover).
**Do:** rewrite `finish_fresh_adjudication` so its branch inputs are (screen result, red-line
result, S4 result, `ATT-VERDICT`, stamp present, block present) rather than
`recommend=`/`variation=`/`questions=`. Run the V/D pass unchanged, record its findings on the
spine, and **do not consult them**. Widen the attester's question per D1.
**After:** R3 is done. The spine says explicitly "V/D findings recorded, not consulted". Routing
outcomes for the wake are derivable from code results alone — checkable by replaying a spine's
inputs through the function. This is the increment that carries the risk; it is also the one that
can be reverted by a single conditional.

### I-4 — Delete the V/D call at fresh intake

**Before:** I-3 landed and has run for a week of real intakes without a routing outcome that
required the unconsulted findings.
**Do:** remove the `run_vd_pass` call from `handle_fresh_intake`. Keep the function — the
adjudication-retry and re-adjudication paths (`adjudication_retry_pass` :4145, `readjudicate_one`
:4213) reference it and are repair machinery.
**After:** R1 and R7 are done. No `vd-*` prompt or log for a fresh intake. The longest permitted
front-door model window is 360 s rather than 900 s — a worst case reduced by 9 minutes, with the
actual saving whatever the pass was really taking. The exposure window that produced today's seven
refusals shrinks with it.

### I-5 — Delete the V/D re-verification on the design return path

**Before:** I-4 landed. A fixture exists proving that a designed filing which fails the second pass
is returned to the Designer and never routes.
**Do:** remove the `run_vd_pass` call from `handle_clarification_reentry` for the `designing` case;
go straight from quarantine to `design_second_pass`. Leave the clarification case alone.
**After:** R2 is done. A design round costs one 360-second judge instead of a 900-second judge plus
a 360-second judge. Spines stop growing a `## V/D Re-verification` section per round.

### I-6 — Copies, not originals

**Before:** I-4 landed (short passes make a snapshot's staleness immaterial). **OI-000055's fix has
landed** — this increment must not gate or pre-empt it. **D4** answered.
**Do:** stage the attester's and the intent judge's inputs into a per-call directory, hash each
file, pass only staged paths. **Change no layer of the guard stack** — the deny list stays exactly
as it is, and the snapshot check keeps running, now expected to report nothing.
**After:** judge prompts name staging paths. The hashes of what a pass read are recorded with its
verdict. Any breach the snapshot check still reports is now genuinely interesting, because the
pass had no live path to write to.

### I-7 — Narrow the deny list for judging passes *(needs D4, and evidence from I-6)*

**Before:** I-6 has run for a stated observation period with zero judge-caused breaches. **D4**
answered in favour. This increment touches the guard stack and therefore needs David's word, not
this document's.
**Do:** narrow `JUDGE_DENY_WRITE` for the staged passes to the staging root and the lane's own
tree.
**After:** a concurrent estate write during a judge window no longer refuses the call and no longer
deletes anything. The metric is direct: `WRITE-RESTRICTION BREACHED` lines caused by non-judge
writers go to zero.

### I-8 — Clarification rounds move in-lane

**Before:** I-4 landed (the front door no longer authors questions). **D3** answered (progress judge
ported, or DEC-0093 amended).
**Do:** the Designer resolves claim-side questions in-lane and emits only David-class questions;
`clarify_gate` stops being called from `finish_fresh_adjudication`; if D3 says port, add the
progress judge to the design loop comparing successive refusal reasons.
**After:** R4 and R5 are done. `clarify-out` at intake is zero. No `OI-*.clarify.md` is created for
a new item. The round cap and the age-out are unchanged and pinned by fixtures.

### I-9 — Flow-record truthfulness on the design path

**Before:** I-5 landed. Independently landable at any point after it; sequenced last because it is
cosmetic-looking and is not.
**Do:** fix the two seam defects in §1.5 — name a design round's response sidecar as a design
response and stop the ledger saying "clarification round 0 consumed" for a design round; and,
subject to **D8**, honour the Designer's `execution:` selection on the return path.
**After:** a spine's `## Flow` projection describes what actually happened. Amendment 1 item 8's
requirement — that the flow record never be quietly false — becomes true on the design path.

**The first step is I-1.** It is additive, advisory, cannot change a routing outcome, and produces
the disagreement evidence every later increment leans on.

**Dependency order, compactly:**
`I-1 → I-2 → I-3 (needs D1) → I-4 → { I-5 → I-9 (needs D8) , I-6 (needs D4 + OI-000055 landed) → I-7 (needs D4) , I-8 (needs D3) }`.
Everything after I-4 is parallelisable; nothing before it is.

---

## 10 · Property 9 — everything that needs David, in one place

Nine decisions. Each states the question in business terms, the options, what each means in
practice, and a recommendation. **Nothing inside an increment assumes any of these.**

---

### D1 · What must the one remaining model question at the front door cover?

**Plain English.** After the rework, only one general-purpose judgment happens when a request
arrives: *does the record authorize this?* Two things the old full-judgment pass used to check
would otherwise fall on the floor.

**(a) The capability-and-scope check.** Today the long pass asks whether the record names *both*
the capability a request wants *and* the scope it wants it at — the DEC-0091 check. That is an
authorization question, so it fits the attester's remit; but it must be added to its prompt
deliberately, not assumed.
- *Option 1 (recommended):* the attester's question widens to cover capability and scope. Costs
  nothing; consistent with CLD-00109's 2026-08-02 unified-gate design, which already widens this
  pass and moves it to the front.
- *Option 2:* a separate small pass. One more model call at the front door, for a question the
  same reader could answer from the same inputs.

**(b) The `variation=none` gate.** Today a verified consultation item routes without troubling you
only when the pass says the work matches what the record contemplates — your rule, "if there is a
CLD/DEC then I've already seen it; I don't want to see it again unless there is a significant
variation." The slim attester does not make that call.
- *Option 1 (recommended):* **the Designer states variation in its design record**, and a
  `significant` statement blocks auto-route mechanically. The Designer did the design work, so it
  is the party that would know — and it is stating a fact about its own output, not judging
  someone else's.
- *Option 2:* drop the gate; a consultation item with a verified anchor and a designed block
  routes. Faster, and it removes a check you specifically asked for.
- *Option 3:* keep a third short judge for this one question. Restores a window we are trying to
  close.

---

### D2 · Who may say "this is a false alarm, close it"?

**Plain English.** Today the machinery can close an item on its own, without you, in one narrow
case: a machine-raised alert (`origin=system-alert`) that the long pass says is already-resolved or
a duplicate, with no red line. That pass is retiring. Someone has to be allowed to make the call,
or every stale alert becomes a notification.

- *Option 1 (recommended):* **the Designer recommends disposal; the orchestrator enacts it only
  for `origin=system-alert`.** The authority bound is unchanged — machine-raised alerts only,
  never a human filing, never a red line. What changes is which component forms the opinion.
- *Option 2:* nothing may auto-dispose; every alert that is not routable escalates. Safe and
  noisy — it puts resolved alerts back on your board.
- *Option 3:* a deterministic duplicate check only (same summary, open OI exists). Catches
  duplicates, misses "already resolved", which is the more common case.

---

### D3 · The per-round progress judgment: port it, or amend DEC-0093?

**Plain English.** DEC-0093 requires that a back-and-forth exchange earn each additional round by
showing movement — a cheap check that stops a loop rehashing itself. It exists on the
clarification loop. It does **not** exist on the design loop. When clarification work moves to the
design loop, that guarantee stops being enforced unless we move the check with it.

- *Option 1 (recommended):* **port it.** Small (a 300-second sonnet call, no file access,
  comparing two sets of reasons), same conservative rung-down, keeps DEC-0093 true as written.
- *Option 2:* **amend DEC-0093** to say the progress judgment binds clarification exchanges only.
  Cheaper, and it removes a live guard rather than relocating it. If you pick this, the amendment
  should be written — the guard should not lapse silently.

*This decision exists precisely so it is not dropped in the move. Either answer is fine; no
answer is not.*

---

### D4 · Copies-not-originals, and what happens to the guard stack

**Plain English.** Judging passes currently read the real records and are fenced by three layers
of write protection. The proposal is to hand them **copies** in a scratch directory instead, so
they cannot reach the real records at all. Today's damage comes from the third layer: it watches
the real records for changes during a judge's window, and when *anyone else* writes to them, it
deletes those files and refuses the call. That happened seven times today and destroyed ten files.

- *Option 1 (recommended):* **adopt copies (I-6), change no guard layer, and observe.** Then, only
  after OI-000055's "nothing is ever destroyed" fix has landed and the observation period is
  clean, **narrow** the third layer's watch list to the scratch directory (I-7).
- *Option 2:* adopt copies and narrow immediately. Faster; it assumes the staging boundary holds
  on its first day, and task 064's report is a warning against exactly that kind of assumption.
- *Option 3:* do not adopt copies; wait for OI-000055's fix alone. The fix stops the destruction
  but not the refusals — judge passes would still fail whenever someone writes to the estate.

**Constraint honoured throughout:** this design proposes and does not enact; OI-000055's fix is
fixed input and is neither gated nor pre-empted here.

---

### D5 · Two governance records appear to have been destroyed — what now?

**Plain English.** This one is not a design choice; it is a fact you need and an action only you
can authorize.

1. **`ACI-260008` does not exist.** It is cited by four live records as the item that documents
   the data-destruction defect. It is absent from `The_Estate/action-items/`, it was never
   committed to git, and today's log names it as an offending path in two breach cleanups (14:55
   and 16:03), each of which deletes the files it names.
2. **A decision document for OI-000055 appears to have been destroyed unconsumed.**
   `orchestrator/inbox/decision-20260807-oi-000055.md` is named as an offending path at 16:06; it
   is not in the inbox; no ledger line records it being consumed; and OI-000055 still sits
   `escalated` with two `[interview]` questions open. If that was your ruling on the destruction
   fix, it did not reach the machinery.

**Options:** (a) re-mint ACI-260008 from what the citing records say about it and re-file the
OI-000055 decision — both are governance-authoring acts and neither is this pass's to perform;
(b) treat ACI-260008 as lost and re-anchor the citing records on OI-000055 instead; (c) add a
commit-on-write backstop for the estate so an uncommitted registry file is never a single copy.
**Recommended: (a) plus (c).** (c) is the structural half — the reason this loss was permanent is
that the file existed only in the working tree.

---

### D6 · Role vocabulary

**Plain English.** §8 is this pass's input to the naming decision; the decision itself belongs to
the naming-convention pass carried by OI-000037. Nothing here needs your answer *now* — it is
listed so it is visibly parked rather than silently unfinished.

**Recommendation carried forward:** one role (Verifier) running passes named for their questions —
screen, authorization check, fidelity check, progress check — with "V/D" retired rather than
renamed, and the rename sequenced *after* the behavioural rework so a mechanical sweep does not
collide with a live redesign.

---

### D7 · When should the "Verifier as its own lane" question be reopened?

**Plain English.** §3 recommends slimming in place and explicitly defers the lane. That deferral
should have a trigger, not a vague "later".

**Recommended trigger — any one of these:** (i) a need for per-item model selection at the front
door (a class of request that genuinely warrants a different tier); (ii) front-door verification
becoming a throughput bottleneck after slimming (measurable: intake-bearing wakes still overrunning
their interval); or (iii) the CLD-00043 recursion question being answered by a separate design pass
— what screens the Verifier's own task. Until one of those, the lane is a cost without a case.

---

### D8 · Does the Designer's executor choice become authoritative?

**Plain English.** The ratified design says the Designer picks the executor and the model and
*requests* the hand-off, which the orchestrator performs. In the running code, the model choice
does travel (inside the task block), but the **supervised-versus-headless** choice is explicitly
refused on the return path and the orchestrator uses the value already on the item's record
instead. So the record and the code disagree, and the disagreement is about which work runs
attended.

- *Option 1 (recommended):* **honour it, with a floor** — the Designer may raise a task to
  supervised but never lower one to headless. Supervised is the more cautious mode; letting the
  designing party ask for more caution is safe, letting it ask for less is not.
- *Option 2:* honour it in both directions. Matches the record literally; lets a lane decide that
  work you marked attended runs unattended.
- *Option 3:* keep today's behaviour and amend the record to say the orchestrator owns execution
  mode. Also fine — but then the amendment should be written, since the record currently says
  otherwise.

---

### D9 · The resolver's quiet false positive — route a fix?

**Plain English.** The tool that turns a record id into a file path returns *guesses* when it
cannot find the id, instead of saying "not found". Two of the seven ids in this task's own
instruction came back as five unrelated files each. The attester reads that output as "the record
this work claims", so a request citing an id that does not exist can be handed five real documents
about something else.

**Options:** (a) route a small fix — an id that matches no record is named `unresolved-ref:` and
returns nothing, exactly as it already does for some shapes; (b) leave it and rely on readers
noticing. **Recommended: (a).** It is small, it is squarely in the "evidence integrity" family
this design is about, and the failure it prevents is a pass judging confidently on the wrong
documents. It is named here rather than built into an increment because it is not part of the
Verifier rework and should not inherit its sequencing.

---

## 11 · What this pass could not settle, and why

An honest gap is a result. These are the things this document deliberately did not close.

1. **What screens the Verifier's own task, if it ever becomes a lane.** CLD-00109 raises it; the
   record contains no answer; this pass did not invent one. It is the load-bearing reason Shape B
   is deferred rather than rejected (§3), and D7 names the condition for taking it up.
2. **ACI-260008's contents.** The item is gone (§0). Everything this document says about the
   destruction incident comes from ACI-260001's and CLD-00109's 2026-08-07 progress entries, from
   OI-000055's spine and findings, and from today's logs read directly — **not** from the item
   itself, which could not be read. Where the record and the logs agree I have said so; where I
   relied on the citing records alone, the sentence says which record.
3. **Whether the seven refusals today are representative.** They are one day's observations, on a
   day with an unusually busy consulting session writing to the estate. The direction of the
   argument does not depend on the count — one irreversible loss of a governance record is
   sufficient — but the *rate* is not established, and I did not attempt a historical sweep.
4. **The exact staging contract for copies.** §7 specifies the property (a pass reads only hashed
   copies) and not the mechanism (which files, named by whom, cleaned up when). That is build
   design and it needs the OI-000055 fix's final shape as input, which is still David's to settle.
5. **Names.** §8 is input. The decision belongs to OI-000037's pass, and this document does not
   pre-empt it.
6. **Whether the Designer can carry the load it is being handed.** The rework moves viability,
   alternatives, question authoring, drafting and executor selection onto one lane whose observed
   record is two runs — one of which failed on a write-restriction refusal (16:13 today). The
   design assumes the lane works; it does not prove it. I-1 through I-4 are sequenced so the
   Designer's load grows only after the front door's checks are demonstrably equivalent, which is
   the most this pass can do about it from here.

---

## Appendix · Claims taken from the record and NOT re-checked against live code

Everything else in this document was checked against the running tree during this pass and is
cited by file and function. These are the exceptions:

- **The 2026-08-05 age-out incident** (OI-000036 r3, OI-000039 r1; five claim-side questions
  promoted to David because the answering chats sat idle four days) — from DEC-260114 and
  ACI-260001. The OI files themselves are archived/deleted in the working tree and were not read.
- **The build-1 draft that bounced on 2026-08-05** (the drafting surface not mirroring environment
  facts the judge had in front of it) — from DEC-260114 Amendment 1 item 2.
- **Task 064's five failed pre-launch canary shapes** — from the comment block in
  `_lib/run_claude.sh` describing that report; the report itself
  (`artifacts/064-implement-write-canary-fix-for-cld-00109/report.md`) was not opened.
- **The 2026-08-03 frozen-container-clock incident** and **the 2026-07-27 requeue loop** — cited
  from DEC-260114 Amendment 1 item 8 and the V/D prompt's own CLD-00088 paragraph respectively.
- **David's verbatim rulings** quoted in §3, §7 and §10 — quoted from DEC-260114, ACI-260001 and
  CLD-00109 as those records report them; the originating chats were not read.
- **OI-000047's rounds "aged out and escalated, and David ruled agreed as recommended on all
  three"** — the round-2 clarify sidecar and its three drafting-shaped questions were read
  directly this run; the age-out and David's ruling are from ACI-260001's 2026-08-07 entry.



