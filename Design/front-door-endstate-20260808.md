# The front door — designed end-state

**As designed through 2026-08-08.** Governing records: DEC-260114 (+ Amendments 1–2),
DEC-260119 (+ Amendment 1), the Verifier design of record, and the ratified
Reviewer/Housekeeper split (OI-000037 r4). This document describes the system those
decisions specify — one picture, present tense, no transition scaffolding. Diagrams are
Mermaid; Obsidian renders them in reading view.

**The design in one sentence:** code proves everything enumerable; exactly two short
single-question model checks guard authorization and fidelity; one lane — the Designer —
holds the pen for everything that requires judgment; every judging pass reads fingerprinted
copies, never the live records; and every path either routes, disposes within a named bound,
or waits on David's board forever — nothing expires, nothing is dropped.

---

## 1 · What arrives, and where it goes

| arrival | recognized by | enters |
|---|---|---|
| **Fresh request** | anything not matching the rows below | the intake flow (§2) |
| **David's decision** | `origin: david-decision` naming an open item | decision re-entry (§4) |
| **Designer return** | the Designer lane's stamped filing for an item it holds | the second pass (§3) |

```mermaid
flowchart TD
    A["Arrival — one .md document<br/>⇒ author's staging → orchestrator/inbox/<br/>(composed outside; single move)"] --> B{Classify}
    B -->|"origin: david-decision<br/>(decision-YYYYMMDD-oi-N.md)"| D["Decision re-entry — §4"]
    B -->|"stamped Designer return<br/>(design-…-rN.md)"| S["Second pass — §3"]
    B -->|"anything else<br/>(consult-….md, machine alert)"| F["Intake flow — §2"]
```

### 1.1 · Handoff mechanics — how work actually moves

Four principles govern every transition on these maps:

1. **A piece of work IS a document, and custody IS the folder it rests in.** A handoff is an
   atomic move from one folder to another; the receiving lane notices because its folder is
   watched, so the move itself is the wake-up call. Two standing rules exist to protect this:
   *compose outside the folder, then one move* (arrival must be a single atomic event — no
   partially-written file is ever visible), and *no lane writes into a folder another lane
   watches* (a folder with two writers has ambiguous custody).
2. **Item state is the exception — it changes in place.** The item's spine
   (`orchestrator/items/OI-N.md`) never moves during its life; status transitions are edits
   to it, and only the orchestrator holds that pen. Sidecars (intake, responses, decisions,
   escalation packages) accumulate beside it, each made read-only on arrival. The whole set
   moves exactly once, to the archive, at the end.
3. **The handoff to David is the other exception.** Escalation moves nothing: a package is
   written in place, the item enters a waiting state, and he is notified (count-only). His
   return follows the normal rule — a decision document moved into the inbox.
4. **Terminal handoffs leave the tree.** Delivery writes results to their `deliver_to`
   destination (a project folder, the daily log), and the authorization echo appends rulings
   into the estate record. Everything between intake and delivery stays inside
   Agent_Workflow — which is why the pipeline's entire state survives crashes and is
   inspectable with a file listing: the filesystem is the queue.

**Map legend** — steps are annotated only where documents change; a check that merely reads
carries no annotation:

| symbol | meaning |
|---|---|
| **＋** | document created |
| **✎** | document modified in place |
| **⇒** | document moved — `source folder → destination folder` |

**Folder roster:** `orchestrator/inbox/` (the front door) · `orchestrator/items/` (spines +
read-only sidecars) · `orchestrator/archive/` (closed items) · `designer/inbox → processing
→ done` (the Designer's lane) · `designer/designs/` (design records) · `code/logs/`
(composition staging for tasks) · `code/inbox → processing → outbox(transit) → reviewed/`
(the executor's lane) · `code/artifacts/` (deliverables) · `code/dead-letter/` ·
`_meta/grants/` (capability grants) · per-call staging (judges' fingerprinted copies,
removed after each call) · exports: `deliver_to` destinations + `The_Estate/`.



---

## 2 · A fresh request

Four code checks, then one model question. The only general-purpose judgment at the front
door is the authorization check; everything else the front door does is provable by code.

```mermaid
flowchart LR
    subgraph COL1 ["&nbsp;"]
        direction TB
        F0["Fresh request<br/>(consult-….md rests in orchestrator/inbox/)"] --> F1["Mint the item<br/>＋ items/OI-N.md — the spine<br/>⇒ inbox/consult-….md → items/OI-N.intake.md<br/>(quarantined read-only)"]
        F1 --> F2{"Mechanical screen — code<br/>sensitive-material shapes, injection,<br/>oversize, history-rewrite/force-push"}
        F2 -->|REJECT| X1["DISPOSED — notify, archive<br/>✎ spine: status=disposed<br/>⇒ items/OI-N.* → orchestrator/archive/"]
        F2 -->|ACCEPT| F3["Anchor resolution — code<br/>every cited record resolves to its file<br/>or is loudly named unresolved — never a guess<br/>✎ spine: resolved paths + unresolved refs recorded"]
        F3 --> F4{"Red-line check — code<br/>governance surfaces, protected paths,<br/>irreversible operations, spend"}
    end
    subgraph COL2 ["&nbsp;"]
        direction TB
        F5{"Well-formedness — code<br/>frontmatter, required fields, non-stub body,<br/>deliverable declaration, self-close-out check"}
        F5 -->|clean| F6{"AUTHORIZATION CHECK — model, one question,<br/>6-min cap, reads fingerprinted COPIES:<br/>does the record authorize this work,<br/>at this capability and scope?"}
        F5 -->|refuse| ESC["ESCALATE to David<br/>＋ items/OI-N.escalation.md — written in place<br/>✎ spine: status=escalated · board regenerates<br/>(nothing moves; the item WAITS)"]
        F6 -->|"no — or any doubt,<br/>failure, or unreadable input"| ESC
        F6 -->|"yes + filing already<br/>carries a designed block"| S0["Second pass — §3"]
        F6 -->|"yes + no block"| DL["DESIGNER LANE — §2.1<br/>＋ req-OI-N.md ⇒ → designer/inbox/<br/>✎ spine: status=designing"]
        ESC -->|"David rules in-chat"| D0["Decision re-entry — §4<br/>(＋ decision doc ⇒ → orchestrator/inbox/)"]
    end
    F4 -->|"red-line clean →<br/>continue to well-formedness"| F5
    F4 -->|"red-line hit →<br/>ESCALATE"| ESC
    style COL1 fill:#fcfcfc,stroke:#c8c8c8,stroke-dasharray:4
    style COL2 fill:#fcfcfc,stroke:#c8c8c8,stroke-dasharray:4
```

### 2.1 · The Designer lane — where judgment lives

One lane holds the pen. It decides whether the work is viable and how it should be done,
drafts the executable task, and selects who runs it.

```mermaid
flowchart TD
    DL["Item handed to the Designer<br/>(req-OI-N.md rests in designer/inbox/;<br/>⇒ designer/inbox/ → designer/processing/ on claim)"] --> D1["The Designer, with live-tree access:<br/>viability and impact · genuine alternatives<br/>drafts the fenced task block<br/>selects executor + model<br/>may RAISE execution to supervised, never lower<br/>states VARIATION vs what the record contemplates<br/>answers claim-side questions IN-LANE<br/>＋ designer/designs/OI-N.design.md — the design record"]
    D1 -->|"stamped return filed:<br/>＋ design-…-rN.md ⇒ → orchestrator/inbox/<br/>⇒ req → designer/done/"| S0["Second pass — §3"]
    D1 -->|"questions only David<br/>can answer"| ESC["ESCALATE — orchestrator packages:<br/>＋ items/OI-N.escalation.md citing<br/>the design record's question list"]
    D1 -->|"round cap 3 · ~24h age-out ·<br/>progress judge says the exchange<br/>is rehashing, not moving"| ESC
    D1 -->|"recommends disposal<br/>(false alarm / duplicate)"| DSP{"origin = system-alert?"}
    DSP -->|yes| X2["DISPOSED — the orchestrator enacts<br/>✎ spine ⇒ items/OI-N.* → archive/"]
    DSP -->|no| ESC
```

The lane is bounded three ways: a **round cap** (3), a **~24-hour age-out** per hold, and a
**progress judge** — a cheap single-question check that ends a rehashing exchange early
rather than letting it spend its rounds. All three exits land on David's board.

---

## 3 · The second pass — a filing that carries a design

Code proves the filing is what the Designer verified; one model question checks it serves
the intent. The session that wrote the verdict never held the pen; the session that held the
pen never writes the verdict.

```mermaid
flowchart LR
    subgraph COLA ["&nbsp;"]
        direction TB
        S0["Stamped filing arrives<br/>(design-…-rN.md rests in orchestrator/inbox/)"] --> S1{"Mechanical screen — code"}
        S1 -->|REJECT| SH["Refused — item stays held<br/>(inbox file quarantined as refused;<br/>✎ spine: FLAG recorded)"]
        S1 -->|ACCEPT| S2["Quarantine<br/>⇒ inbox/design-…-rN.md →<br/>items/OI-N.response-NN.md (read-only)"]
        S2 --> S3{"Red-line check — code"}
    end
    subgraph COLB ["&nbsp;"]
        direction TB
        S4{"Deterministic checks — code, all required:<br/>stamp grammar · stamp resolves two hops<br/>to a real design record · BYTE-IDENTITY of the<br/>block vs the hash the Designer measured (live)<br/>well-formedness + self-close-out check"}
        S4 -->|"any refusal"| S5["Back to the Designer<br/>(round + 1; cap 3 → David's board)<br/>＋ req-OI-N.md (round N+1) ⇒ → designer/inbox/"]
        S4 -->|pass| S6{"FIDELITY CHECK — model, one question,<br/>6-min cap, reads fingerprinted COPIES:<br/>is what would run what was authorized?"}
        S6 -->|no| S5
        S6 -->|"yes, and the Designer<br/>stated variation: significant"| ESC["ESCALATE<br/>＋ items/OI-N.escalation.md"]
        S6 -->|"yes + variation: none"| S7["Mint grants · build · re-screen<br/>＋ _meta/grants/GRANT-N.md (if declared)<br/>＋ task NNN-slug.md composed under code/logs/<br/>⇒ code/logs/NNN-slug.md → code/inbox/<br/>✎ spine: status=routed · task path recorded"]
        S7 -->|"re-screen refuses"| S8["Fail closed<br/>(nothing reaches code/inbox/)"]
        S7 -->|clean| RT["ROUTE — §5"]
    end
    S3 -->|"red-line clean →<br/>deterministic checks"| S4
    S3 -->|"red-line hit →<br/>ESCALATE"| ESC
    style COLA fill:#fcfcfc,stroke:#c8c8c8,stroke-dasharray:4
    style COLB fill:#fcfcfc,stroke:#c8c8c8,stroke-dasharray:4
```

**Auto-route without pinging David** requires all of: consultation origin, the
authorization check's yes, clean code checks, a designed block present, and the Designer's
stated `variation: none`. A significant variation always surfaces to him — "I've already
seen it; I don't want to see it again unless there is a significant variation."

---

## 4 · Decision re-entry — David's ruling comes back

```mermaid
flowchart TD
    D0["Decision document arrives<br/>(decision-….md rests in orchestrator/inbox/)"] --> D1{"Mechanical screen — code"}
    D1 -->|REJECT| D2["FLAG — left in inbox for correction<br/>(no move; ✎ spine: FLAG recorded)"]
    D1 -->|ACCEPT| D3["Quarantine<br/>⇒ inbox/decision-….md →<br/>items/OI-N.decision-NN.md (read-only 0444)"]
    D3 --> D4["AUTHORIZATION ECHO — before anything is enacted:<br/>✎ The_Estate/action-items/(each related item).md<br/>— the ruling appended verbatim"]
    D4 --> D5{"decision: field"}
    D5 -->|approve| D6["Task sourced verbatim from the quarantined intake<br/>＋ task NNN-slug.md composed under code/logs/<br/>⇒ code/logs/ → code/inbox/ · ✎ spine: routed"]
    D6 --> RT["ROUTE — §5"]
    D5 -->|rewrite| D7["The rewritten task passes the<br/>second pass (§3) — code checks<br/>plus the fidelity question;<br/>no full re-judgment"]
    D7 -->|clean| RT
    D7 -->|"refusal or<br/>significant variation"| D8["Back to David with the residue<br/>＋ items/OI-N.escalation.md refreshed"]
    D5 -->|release| D9["＋ _meta/releases/RELEASE-N.md per named hold;<br/>completion re-checks delivery"]
```

---

## 5 · The executor lane — routing to closure

Review is **in the path**, not beside it: nothing reaches completion without having been
reviewed. Two jobs with different clocks own the lane's health — the **Reviewer** wakes on
events; the **Housekeeper** wakes on time, because events catch things that happen and
timers catch things that fail to happen.

```mermaid
flowchart TD
    R0["Task composed outside the watched folder<br/>＋ NNN-slug.md under code/logs/<br/>⇒ code/logs/ → code/inbox/ (ONE move = the wake)"] --> R1["Worker claims serially<br/>(daily cap; deadline injected)<br/>⇒ code/inbox/NNN.md → code/processing/"]
    R1 --> R2{"Promotion screen — code<br/>(screen at every promotion)"}
    R2 -->|reject| R3["Rejection parked with a<br/>terminal state + one FLAG"]
    R2 -->|accept| R4["Execute — headless, or supervised if raised<br/>＋ code/artifacts/NNN-slug/ — report + artifacts<br/>✎ fenced files, exactly as the task authorizes"]
    R4 -->|"deliverable check passes"| R5["Result recorded — worker's pen:<br/>✎ task: ## Result + status<br/>⇒ code/processing/ → code/outbox/ (transit)"]
    R4 -->|"deliverable check fails"| R6["Diagnostic ticket<br/>＋ ticket task ⇒ → code/inbox/<br/>original holds in place (pending);<br/>RE-CHECKED before any re-run"]
    R4 -->|"attempts exhausted"| R7["Dead-letter + one FLAG<br/>⇒ → code/dead-letter/"]
    R5 --> R8{"REVIEWER — event-driven,<br/>wakes on the folder changing<br/>✎ task: ## Review appended"}
    R8 -->|approve| R9["⇒ code/outbox/NNN.md → code/reviewed/ —<br/>the orchestrator acts on THIS folder"]
    R8 -->|"return for further work"| R1
    R8 -->|"return for redesign"| DL["Designer lane — §2.1<br/>＋ req-OI-N.md ⇒ → designer/inbox/"]
    R8 -->|"return-cycle bound reached"| R10["Parked + FLAG<br/>(never cycles indefinitely)"]
    R9 --> R11["Completion round delivers<br/>＋/✎ result at deliver_to (project folder / daily-log)<br/>✎ spine: delivered ⇒ items/OI-N.* → archive/<br/>nightly mirrors into the daily log + estate record"]

    HK["HOUSEKEEPER — timed:<br/>work aging unreviewed past its bound<br/>stalled claims · registry audit<br/>terminal entry stranded in the transit folder<br/>retention: ⇒ reviewed/ terminal entries → archive (30d)"] -.->|"one FLAG per finding,<br/>never one per wake"| R10
```

Dependency resolution follows the work (a completed dependency counts wherever it rests);
task numbering never regresses across folder moves.

---

## 6 · How the judges read — copies, not originals

Every judging pass receives its record inputs as **fingerprinted copies in a per-call
staging directory** — the spine content, the quarantined sidecars, the resolved governance
anchors — and holds no path into the live estate, orchestrator, decisions, or transcript
trees. The fingerprints are recorded with the verdict, so what a judgment rested on is
reproducible. Three deliberate live reads, and only these: the byte-identity check hashes
the **real** filing that would route (a copy would prove the copy); the fidelity check reads
the **live** design record in the Designer's own tree; the Designer keeps live-tree code
access and write access to its own lane. The copier fails closed — an unreadable input
aborts the launch loudly rather than letting a pass judge on partial evidence. The write
guard watches the staging root; a pass that cannot reach the records needs no broad fence,
and a concurrent writer anywhere in the estate is invisible to it.

---

## 7 · Who decides what

| decision | owner |
|---|---|
| Is this filing safe and well-formed to look at? | **code** (screen, red-line, well-formedness) |
| Does the record authorize this, at this capability and scope? | **authorization check** (one model question) |
| Is this worth doing? Can it be done? How? Alternatives? | **Designer** |
| What questions block this, and are any David's? | **Designer** (only David-class questions leave the lane) |
| Which executor, which model, attended or not? | **Designer** (may raise to supervised, never lower) |
| Does it deviate from what the record contemplates? | **Designer states it**; a significant variation blocks auto-route |
| Is what would run what was authorized? | **code** (byte-identity) + **fidelity check** (one model question) |
| Is this alert a false alarm? | **Designer recommends; orchestrator enacts** — machine-raised alerts only |
| Did the finished work pass muster? | **Reviewer** (approve / return for work / return for redesign) |
| Is the lane healthy? | **Housekeeper** (timed; watches for what failed to happen) |
| Everything escalated | **David** — rules in-chat; the decision document is the enactment |

## 8 · Invariants — true on every path

- **Quarantine-first.** Every consumed arrival becomes an immutable sidecar before anything
  acts on it; only the orchestrator writes the item's spine.
- **Screen at every promotion.** Re-screened at every hop toward execution, whoever authored it.
- **Author ≠ checker.** The session that writes a verdict never held the pen, and vice versa.
- **Judges cannot touch the evidence.** Structurally — they read copies (§6).
- **Nothing routes on a guess.** An unresolvable cited record is a loud failure, never a
  fuzzy match.
- **Review precedes completion.** Nothing is delivered unreviewed.
- **Authorization echo.** A consumed ruling is written into the estate record before enactment.
- **Fail toward David, never toward silence.** Every doubt, cap, age-out, and refusal lands
  on the board and waits; escalations never expire; his answers arrive only through decision
  documents.
- **Every loop is bounded.** Adjudication retries, Designer rounds, review return-cycles,
  worker attempts, age-outs — a loop with no bound is a defect by definition.
