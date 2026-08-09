# Front-door routing map — the path of a new request, all routes accounted for

**Drawn 2026-08-08** (Code session `1b62176a`, David-requested). Sources: the live
`orchestrator/orchestrator.sh` as read this week, the Verifier design of record
(`verifier-rework-design-20260807.md` §1 and §5, whose code citations were verified against
the running tree), and DEC-260119 + Amendment 1. Diagrams are Mermaid — Obsidian renders
them natively in reading view.

**Two maps.** Map A is the system **as it runs today** — the one generating the current
notifications. Map B is the **ratified end-state** (DEC-260119) the increments are building
toward. Rows in the criteria tables cite the deciding rule.

> **This map goes stale by design:** each DEC-260119 increment that lands moves Map A toward
> Map B. Check the DEC's increment status before trusting Map A's V/D boxes.

---

## 0 · The transition, as underway (status 2026-08-08 ~10:40 PT)

The rework is not a future — three of its builds routed this morning. Where each piece
stands, and which Map A box it changes:

| build | what it changes on Map A | status |
|---|---|---|
| **I-1** advisory deterministic checks (task 073) | adds a code-check line beside the V/D box; routes on nothing — evidence-gathering | **routed, executing** |
| **I-6** staged copies, as amended (task 074) | every judge box reads copies, not live records; fingerprints land with verdicts | **routed, queued behind I-1** (fail-fast guard) |
| **D9** resolver says not-found (task 072) | S2/anchor box stops guessing; intakes citing nonexistent records hard-fail at the screen | **routed, executing** — the auth-echo's own "resolves to NO record" FLAGs this morning are the live demonstration of the gap it closes |
| **I-2→I-5** slimming (prompt port, code-driven branching, delete V/D at intake and on the design return) | the 15-min V/D boxes shrink, then disappear | pending — I-3 needs the D1 attester-widening; I-4 needs a week of I-1 evidence |
| **I-7** guard narrowing | breach refusals on concurrent writers end | gated on D4 evidence: **3 days or 20 staged passes, whichever later, zero judge-caused breaches** — returns to David with numbers |
| **I-8** clarify rounds move in-lane | the clarify-hold box disappears; Designer answers claim-side in-lane | pending, needs I-4 |
| **I-9** flow-record truthfulness | design rounds stop being logged as "clarification round 0" | pending, needs I-5 |
| **Reviewer/Housekeeper split** (OI-000037, ratified r4) | Map A4's reviewer becomes a GATE: outbox → reviewed/ → completion; two jobs, separate clocks | decision consumed; re-verification retrying after a breach-window bounce |
| **Spawn-exclusion, option (b)** (OI-000038, task 070) | not a front-door change — governs which SESSIONS the nightly narrates | **delivered + closed 10:36 today** |

```mermaid
flowchart LR
    I1["I-1 advisory checks<br/>EXECUTING (073)"] --> I6["I-6 staged copies<br/>ROUTED (074)"]
    I1 --> I2["I-2 port enumerables<br/>out of the prompt"]
    I2 --> I3["I-3 branch on code results<br/>needs D1 attester widening"]
    I3 --> I4["I-4 delete V/D at intake<br/>needs a week of I-1 evidence"]
    I4 --> I5["I-5 delete V/D re-verify<br/>on the design return"]
    I5 --> I9["I-9 truthful flow records"]
    I6 --> I7["I-7 narrow the guard<br/>GATED: 3d / 20 passes clean<br/>returns to David with evidence"]
    I4 --> I8["I-8 clarify rounds in-lane"]
    D9["D9 resolver not-found<br/>EXECUTING (072)"]
```

---

## 1 · What can arrive in the inbox

Every arrival in `orchestrator/inbox/*.md` is classified into exactly one of three classes
at the next wake:

| class | recognized by | examples |
|---|---|---|
| **Fresh intake** | anything not matching the two classes below | a consultation filing from this chat (`consult-YYYYMMDD-…`); a machine-raised alert (`origin: system-alert`); a Librarian/machine requester filing |
| **Decision re-entry** | `origin: david-decision` naming an open OI in `related:` | `decision-YYYYMMDD-oi-NNNNNN.md` — David's ruling, filed by the consulting surface |
| **Correction re-entry** | `requested_by: cowork` (or the Designer's return filing) for an OI currently held `clarifying` or `designing` | a corrected intake answering a clarify round; the Designer's drafted return (`design-…-rN.md`) |

```mermaid
flowchart TD
    A["Arrival in orchestrator/inbox"] --> B{Classify}
    B -->|"origin: david-decision + open OI"| D["Decision re-entry — Map A3"]
    B -->|"correction for OI held clarifying / designing"| C["Correction re-entry — Map A2"]
    B -->|"anything else"| F["Fresh intake — Map A1"]
```

---

## 2 · Map A1 — a FRESH intake, today

```mermaid
flowchart TD
    F0["Fresh intake arrives"] --> F1["Mint OI-NNNNNN<br/>quarantine arrival as immutable intake sidecar"]
    F1 --> F2{"Mechanical screen<br/>screen.py --intake"}
    F2 -->|REJECT| X1["DISPOSED<br/>notify; archived"]
    F2 -->|ACCEPT| F3["V/D full-judgment pass<br/>opus, 15-min cap<br/>(retires at I-4; reads STAGED<br/>copies meanwhile, once I-6 lands)"]
    F3 -->|"model call fails<br/>(rc=62 breach, outage)"| R1["retry-eligible<br/>re-run at a later wake<br/>bounded: 3 fails max"]
    R1 --> F3
    F3 --> F4{"Adjudicate the verdict<br/>(branch tests in order)"}

    F4 -->|"1 · recommend=dispose<br/>+ class resolved/duplicate<br/>+ origin=system-alert<br/>+ no red-line"| X2["DISPOSED autonomously<br/>(machine alerts only —<br/>never a human filing)"]
    F4 -->|"2 · filing carries a<br/>Designed-by: stamp"| SP["Second pass — Map A2 lower half"]
    F4 -->|"3 · AUTO-ROUTE:<br/>origin=david-consultation<br/>+ provenance=verified<br/>+ recommend=route + variation=none<br/>+ attester says substantiated=yes<br/>+ no red-line + complete task block"| RT["ROUTE to executor — Map A4"]
    F4 -->|"4 · only claim-side<br/>questions raised"| CL["Clarify hold<br/>questions sidecar'd<br/>hand to Designer (duty=clarify)<br/>(retires at I-8 — answered in-lane)"]
    F4 -->|"5 · verdict clean<br/>but NO task block"| DH["Designer hand-off (duty=draft)<br/>Designer drafts block + stamp"]
    F4 -->|"6 · otherwise<br/>(David-class questions,<br/>unverified authority,<br/>significant variation)"| ESC["ESCALATE<br/>package + count-only notify<br/>WAITS for a decision document<br/>(no expiry)"]

    CL -->|"corrected intake filed"| C0["Correction re-entry — Map A2"]
    CL -->|"~24h age-out,<br/>round unconsumed"| ESC
    DH -->|"Designer files stamped return"| C0
    DH -->|"3-round cap or ~24h age-out"| ESC
    ESC -->|"David rules in-chat;<br/>consulting surface files<br/>a decision document"| D0["Decision re-entry — Map A3"]
```

**Bounds on this map:** V/D failures retry at later wakes, 3 max, then escalate. Clarify and
design holds age out at ~24 h (per round) into the normal escalation path. Design rounds cap
at 3, then park on David's board. An escalated item **never expires** — it waits for a
decision document ("the decisions sit and wait for you").

---

## 3 · Map A2 — CORRECTION re-entry, and the second pass

The top half is how a corrected intake or Designer return is received; the bottom half (the
second pass) is also entered from Map A1 branch 2 when a fresh filing already carries a
stamp.

```mermaid
flowchart TD
    C0["Correction arrives<br/>(for OI held clarifying / designing)"] --> C1{"Mechanical screen"}
    C1 -->|REJECT| C2["Refused — item stays held<br/>(FLAG; nothing consumed)"]
    C1 -->|ACCEPT| C3["Quarantine as immutable<br/>numbered response sidecar"]
    C3 --> C4{"Carries decision-doc fields?<br/>(decision: / origin: david-decision)"}
    C4 -->|yes| C5["REFUSED — a clarification<br/>carries no enactment authority<br/>(DEC-0093 item 3)"]
    C4 -->|no| C6{"Which hold?"}
    C6 -->|"clarifying"| C7["FULL V/D re-verification<br/>(opus — retires at I-5)<br/>then the same six branches as Map A1<br/>(reads STAGED copies once I-6 lands)"]
    C6 -->|"designing (stamped return)"| S0

    subgraph SECOND_PASS["The second pass — a filing that carries a design"]
    S0["Red-line check on the response"] -->|hit| S1["ESCALATE"]
    S0 -->|clean| S2["Deterministic checks — designcheck.py, 5/5 required:<br/>stamp grammar · stamp resolves 2 hops to a real design record<br/>byte-identity of the block vs the hash the Designer measured<br/>well-formedness + self-close-out check · red-line set"]
    S2 -->|"any REFUSE"| S3["Back to the Designer<br/>(round + 1; cap 3 → David's board)"]
    S2 -->|"pass 5/5"| S4{"Intent judge (sonnet, 6-min):<br/>does this implementation<br/>serve the verified intent?<br/>(staged inputs once I-6 lands)"}
    S4 -->|no| S3
    S4 -->|yes| S5["Mint grants for declared capabilities<br/>build the routable task<br/>RE-SCREEN at the hop"]
    S5 -->|"re-screen refuses"| S6["Fail closed"]
    S5 -->|clean| RT2["ROUTE to executor — Map A4"]
    end
```

---

## 4 · Map A3 — DECISION re-entry (David's ruling comes back)

```mermaid
flowchart TD
    D0["decision document arrives<br/>origin: david-decision, related: OI"] --> D1{"Mechanical screen"}
    D1 -->|REJECT| D2["FLAG decision-reject<br/>left in inbox for correction"]
    D1 -->|ACCEPT| D3["Quarantine as immutable<br/>OI.decision-NN sidecar (0444)"]
    D3 --> D4["AUTHORIZATION ECHO (ACI-260004):<br/>the ruling is appended to every<br/>related estate action item<br/>before anything is enacted"]
    D4 --> D5{"decision: field"}
    D5 -->|approve| D6["Task sourced from the<br/>quarantined INTAKE verbatim<br/>(approve-as-recommended)"]
    D6 --> RT3["ROUTE to executor — Map A4"]
    D5 -->|rewrite| D7["V/D re-verifies the<br/>rewritten task (the sidecar<br/>IS the artifact under judgment)<br/>(Map B: S6+S7 suffice — no full pass)"]
    D7 -->|"provenance verified/no-claim<br/>+ variation=none<br/>+ not dispose + no red-line"| RT3
    D7 -->|"anything else"| D8["Escalation retry —<br/>back to David with the residue"]
    D7 -->|"model call fails"| D9["retry-eligible at a later wake<br/>(bounded 3)"]
    D9 --> D7
    D5 -->|release| D10["Mint RELEASE records for the<br/>named holds; completion re-checks<br/>delivery for the item"]
```

---

## 5 · Map A4 — after routing: the executor lane to closure

```mermaid
flowchart TD
    R0["Task written under code/logs<br/>then ONE mv into code/inbox<br/>(single watch event)"] --> R1["Worker wakes (watch or timer)<br/>claims serially — daily cap applies"]
    R1 --> R2{"Promotion screen<br/>(screen at every promotion)"}
    R2 -->|reject| R3["screen-reject FLAG<br/>(terminal-state gap = CLD-00122)"]
    R2 -->|accept| R4["Execute headless<br/>(or supervised session if execution: supervised)<br/>deadline injected; soft-landing handoff"]
    R4 -->|"exit + deliverable check PASSES"| R5["Result + status: done<br/>moved to code/outbox"]
    R4 -->|"deliverable check FAILS"| R6["DEC-0106 diagnostic ticket:<br/>original parks pending; ticket routes<br/>as ordinary work; original re-checked<br/>before any re-run"]
    R4 -->|"attempts exhausted"| R7["dead-letter + FLAG"]
    R5 --> R8["Reviewer audits the outbox entry<br/>ADVISORY today — becomes a GATE when the<br/>ratified OI-000037 split lands: Reviewer watches<br/>outbox, approves into reviewed/, orchestrator<br/>acts on reviewed/; Housekeeper keeps the timed<br/>checks + whole-backlog migration at cutover"]
    R8 --> R9["Completion round delivers<br/>per deliver_to<br/>(project folder / daily-log / queue / none)"]
    R9 --> R10["OI closed + archived<br/>nightly mirrors the completion<br/>into the daily log and the CLD record"]
```

---

## 6 · Map B — the ratified end-state (DEC-260119, as amended)

What changes: the 15-minute five-question V/D pass is gone. Code proves everything
enumerable; **two** short single-question judges remain; every judgment about worth,
feasibility, drafting, and executor choice lives in the Designer lane; judging passes read
**staged copies** of the records, not the live trees.

```mermaid
flowchart TD
    B0["Fresh intake"] --> B1["Mint + quarantine"]
    B1 --> B2{"S1 mechanical screen"}
    B2 -->|REJECT| BX["DISPOSED + notify"]
    B2 -->|ACCEPT| B3["S2 anchor resolution (code)<br/>unresolved refs NAMED<br/>(never fuzzy guesses — D9)"]
    B3 --> B4{"S3 red-line (code)"}
    B4 -->|hit| BE["ESCALATE<br/>(never enters the Designer lane)"]
    B4 -->|clean| B5{"S4 well-formedness +<br/>enumerable checks (code)"}
    B5 -->|refuse| BE
    B5 -->|clean| B6{"S5 ATTESTER — one question,<br/>6-min cap, reads STAGED copies:<br/>does the record authorize this,<br/>at this capability and scope?"}
    B6 -->|"substantiated=no<br/>(or any doubt/failure)"| BE
    B6 -->|"yes + filing already<br/>carries a designed block"| B8
    B6 -->|"yes + no block"| B7["DESIGNER LANE (duty=draft):<br/>viability · alternatives · the block<br/>executor + model (raise-only to supervised — D8)<br/>claim-side questions answered IN-LANE<br/>variation stated in the design record<br/>only David-class questions leave"]
    B7 -->|"files stamped return"| B8["Second pass:<br/>S6 stamp + byte-identity (code, live hash)<br/>S7 INTENT JUDGE — one question, staged:<br/>is what would run what was authorized?"]
    B7 -->|"David-class questions"| BE
    B7 -->|"cap 3 / age-out /<br/>progress judge says rehashing (D3)"| BE
    B8 -->|"refuse"| B7
    B8 -->|"pass + Designer stated<br/>variation: none"| BR["ROUTE<br/>(auto-route: consultation origin<br/>+ attester yes + clean code checks<br/>+ block present + variation none)"]
    B8 -->|"variation: significant"| BE
    BE -->|"David rules; decision<br/>document filed"| BD["Decision re-entry<br/>(same as Map A3, minus the<br/>full V/D re-verify — S6+S7 suffice)"]
    BR --> BW["Executor lane — unchanged from Map A4"]
```

**Dispose in Map B (D2):** the Designer recommends disposal; the orchestrator enacts it
**only** for `origin=system-alert` — same authority bound as today, different opinion-former.

---

## 7 · Criteria quick-reference

| route | criteria (all must hold) | where ruled |
|---|---|---|
| Autonomous dispose | machine-raised alert (`system-alert`) + already-resolved/duplicate + no red-line | today: V/D verdict; Map B: Designer opinion (DEC-260119 D2) |
| Auto-route (no David ping) | consultation origin + verified authority + no deviation from the record + attester yes + no red-line + complete block | "if there is a CLD/DEC I've already seen it; I don't want to see it again unless there is a significant variation" (David); DEC-260119 D1 moves the variation statement to the Designer |
| Designer hand-off | authority verified but no executable block (high-level filing) — the DEC-260114 no-block-no-stamp path | DEC-260114 Amendment 1 |
| Clarify hold (Map A only) | only claim-side questions — answerable from the record without new authority | DEC-0093; retires at I-8 (claim-side questions answered in-lane) |
| Escalate to David | anything needing his authority: unverified/absent anchors, significant variation, interview/consultation-class questions, red-line hits, caps and age-outs | DEC-0099 (the consulting surface is the decision channel; Telegram is count-only) |
| Route to supervised session | `execution: supervised` on the routed task; the Designer may RAISE headless→supervised, never lower | DEC-260119 D8 |

## 8 · The invariants that hold on every path

- **Quarantine-first:** every consumed arrival becomes an immutable sidecar before anything
  acts on it; the spine is the orchestrator's record and only the orchestrator writes it.
- **Screen at every promotion:** a task is re-screened at every hop that moves it toward
  execution, regardless of who authored it.
- **Author ≠ checker:** the session that writes a verdict never held the pen; the session
  that held the pen never writes the verdict (DEC-260114 Amendment 1 item 3).
- **Authorization echo:** the moment a decision document is consumed, its ruling is appended
  to the related estate records — before enactment, independent of routing success.
- **Fail toward David, never toward silence:** any doubt, failure, cap, or age-out lands the
  item on the board as an escalation that waits indefinitely; nothing is dropped.
- **Bounded loops everywhere:** adjudication retries (3), clarify/design rounds (3),
  age-outs (~24 h), worker attempts (2) + continuations (3), review return-cycles (parked at
  the bound). A loop with no bound is a defect.
