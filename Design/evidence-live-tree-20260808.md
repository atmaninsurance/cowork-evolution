# Evidence companion — what was read from the live tree, 2026-08-08

Supporting material for `reconciliation-selfimprovement-design-20260808.md`. Everything here was
read during that run, read-only. Nothing in the tree was modified.

---

## 1 · Record resolution (by id, through the resolver)

Command, run from the repository root:

```
python3 _meta/screen.py --resolve ACI-260011 ACI-260008 CLD-00119 DEC-260119 DEC-0106
```

Output, verbatim:

```
/Users/alfredassistant/Documents/The_Estate/action-items/ACI-260011-260808-Open.md
/Users/alfredassistant/Documents/The_Estate/action-items/ACI-260008-260807-Open.md
/Users/alfredassistant/Documents/The_Estate/action-items/CLD-00119-260803-Open.md
/Users/alfredassistant/Documents/The_Estate/decisions/2026/DEC-260119.md
/Users/alfredassistant/Claude/memory/decisions/COWORK-DECISIONS-2026.md
```

**Five ids given, five paths returned, zero unresolved.** DEC-0106 resolves to the frozen legacy
decisions file rather than to a per-decision file, because DEC-0001–0110 predate the DEC-0110 estate
migration; its section begins at line 187 of that file. All five files were read in full (DEC-0106 as
its section).

---

## 2 · The tree as it stood at the start of the run

```
Agent_Workflow/
  ledger.md            787,505 bytes · 7,584 lines
  REVIEW.md            generated 2026-08-08 17:45 PDT
  _lib/                attention.sh claude_auth.sh install-claude-token.sh notify.sh
                       run_claude.sh sharefile.py sync-pinned-claude.sh
  _meta/               authoring-contract.md check_staleness.sh designcheck.py oilib.py
                       queuelib.py reviewboard.py screen.py + plists, grants/, releases/,
                       notify-state/, rules/, 11 test_*.sh|py
  code/                artifacts/ dead-letter/ inbox/ logs/ outbox/ processing/ supervised/
                       reviewer.sh worker.sh auth-healthcheck.sh
  designer/            designer.sh designs/ done/ inbox/ processing/ staging/ templates/
  orchestrator/        orchestrator.sh _index.md archive/ inbox/ items/ state/ unattributed/
  librarian/  venture/  alfred/  hold/  Design/
```

Line counts:

```
   418  code/reviewer.sh
  1105  code/worker.sh
  5202  orchestrator/orchestrator.sh
   444  designer/designer.sh
  1008  _lib/run_claude.sh
   233  _lib/notify.sh
   746  _meta/reviewboard.py
  1121  _meta/screen.py
   546  _meta/queuelib.py
   545  _meta/oilib.py
```

---

## 3 · The Housekeeper does not exist (design §1.2)

Three independent checks, all negative:

1. `grep -rn "housekeep" . --include="*.sh" --include="*.py" --include="*.plist" --include="*.md"` —
   every hit is prose in a record, a design sidecar, or an intake. **No housekeeper script.**
2. `ls code/` returns `artifacts auth-healthcheck.sh dead-letter inbox logs outbox processing
   reviewer.sh supervised worker.sh`. **No `reviewed/` folder.**
3. `ls ~/Library/LaunchAgents/` contains `com.cowork.agent-orchestrator.plist`,
   `com.cowork.agent-reviewer.plist`, `com.cowork.agent-worker.plist`, `com.cowork.designer.plist`,
   `com.cowork.librarian.plist`, `com.cowork.venture.plist`, `com.cowork.nightly.plist`,
   `com.cowork.auth-healthcheck.plist`. **No housekeeper job.**

And the build is blocked, from two live surfaces:

- `REVIEW.md:17–18` — `**OI-000037** — Split the reviewer into an event-driven reviewer and a timed
  housekeeper / escalated 5d ago`
- `orchestrator/_index.md` row OI-000037 — `escalated | david-consultation | verified`

---

## 4 · The state machine (design §1.4)

`_meta/oilib.py:82–84`, verbatim:

```python
STATUS_VOCAB = ("received", "verifying", "evaluated", "clarifying", "escalated",
                "routed", "executing", "reviewed", "delivered", "closed",
                "disposed", "superseded")
```

`grep -n "STATUS_VOCAB" _meta/oilib.py` → **one hit, line 82: its own definition.** Nothing
validates against it.

`grep -rn "parked" _meta/oilib.py _meta/reviewboard.py orchestrator/_index.md` → **zero hits.**

Yet `orchestrator.sh` `park_and_ticket()` writes it:

```sh
$OL set "$spine" "status=parked" "parked_reason=done-check-failed" \
       "parked_check=$safe" "parked_at=$(date +%s)" "parked_task=$tid"
```

**`parked` is a live status that is in no vocabulary, no board generator and no documentation.**

---

## 5 · The rc=62 collapse (design §1.7, §6.2)

### 5.1 The four return codes

`_lib/run_claude.sh:96–99`:

```sh
: "${CLAUDE_RC_ERROR_OUTPUT:=64}"    # wrote an API/CLI error and nothing else
: "${CLAUDE_RC_NO_OUTPUT:=63}"       # wrote nothing at all
: "${CLAUDE_RC_BAD_RESTRICTION:=62}" # write-restriction requested but malformed/unappliable
: "${CLAUDE_RC_NO_AUTH:=61}"         # could not authenticate — retrying cannot clear it
```

### 5.2 Four distinct causes returning rc=62

| line | log text (abridged) | class |
|---|---|---|
| 782–783 | `WRITE-RESTRICTION MALFORMED ($profile); call refused, nothing launched` | pre-launch refusal |
| 787–788 | `WRITE-RESTRICTION unappliable (no sandbox-exec); call refused` | pre-launch refusal |
| 792–793 | `WRITE-RESTRICTION profile failed preflight; call refused` | pre-launch refusal |
| 930–932 | `WRITE-RESTRICTION BREACHED on attempt $attempt (deny-write path changed: …); call refused, output discarded, nothing deleted` | **post-call guard fire** |

The fourth is categorically different from the first three: nothing launched vs. a call that ran and
may have been healthy.

### 5.3 The second, wider collapse — at the rendering site

`orchestrator/orchestrator.sh:1160`:

```sh
    VD_OK=0; VD_FAIL_CAUSE="model-call-error(rc=$rc)"
```

`orchestrator/orchestrator.sh:1397`:

```sh
    ESC_FAIL_CAUSE="$([ "$rc" -ne 0 ] && echo "model-call-error(rc=$rc)" || echo "empty-package")"
```

**Every** nonzero rc becomes the word "model". `VD_FAIL_CAUSE` reaches `record_pass_failure` at five
sites: `:3635, :3944, :4270, :4480, :4573`.

### 5.4 Where it reaches a human

`_meta/reviewboard.py:443` lifts ledger FAIL lines into the board. Live on the board at the start of
this run, `REVIEW.md:30`:

```
- **ledger FAIL** `adjudication-fail` 2026-08-07 13:55 — OI-000054 vd pass failed
  (cause=model-call-error(rc=62)); no verdict recorded — a failed call is never an adjudication;
  retry-eligible (1/3) at a later wake
```

Six further `cause=model-call-error(rc=62)` lines are in `ledger.md` (13:55, 14:48, 14:55, 15:45,
16:06 on 08-07; 08:31, 08:36, 09:02, 11:37, 12:30 on 08-08).

### 5.5 The half that already holds, and the precedent for the fix

- **P1 holds:** every failure path sets `VD_OK=0` and records no verdict, and the emitted line says
  so — "no verdict recorded — a failed call is never an adjudication".
- **The naming pattern already exists:** DEC-260119 I-6 added `VD_FAIL_CAUSE="staging-defect"` at
  `orchestrator.sh:1009, 1015, 1021, 1028`, and a correctly-named `stage-breach` FLAG class, live on
  the board at `REVIEW.md:58`:

```
- `stage-breach` ×4 — 2026-08-08 17:33: OI-000062 designer pass (duty=draft round=1, rc=62) — the
  post-call deny snapshot reported a breach during a STAGED pass. Guard behaviour is unchanged
  (call refused, output discarded, nothing deleted) …
```

That line names the right kind of failure. The `vd` path's does not. Same rc, two labels, one honest.

---

## 6 · Notification (design §1.6, §6.1)

`orchestrator.sh:817` opens `# ---- CLD-00105: EDGE-TRIGGERED PUSH NOTIFICATION`. Key lines:

- `:846` — `NOTIFY_STATE_DIR="${AGENT_WORKFLOW_NOTIFY_STATE_DIR:-$META/notify-state}"`
- `:857` — `NOTIFY_BACKSTOP_SECS="${ORCH_NOTIFY_BACKSTOP_SECS:-86400}"`
- `:890` — `notify_on_change() { # $1=oid $2=kind $3=fingerprint $4=status $5=summary $6=qcount $7=spine-ptr [$8=extra]`

Header rationale, verbatim: *"a wake is both scheduled (hourly) and event-driven … Calling
notify_david straight out of that loop therefore made the notification rate track MACHINERY ACTIVITY
rather than item state — 40+ notices for one unchanged finding."* And: *"FAIL OPEN, ALWAYS … the
push happens BEFORE the state is written, so a crash mid-call re-notifies next wake rather than going
quiet."*

**Eleven `notify_on_change` call sites:** `:4678, :4701, :4711` (hold), `:4729, :4740` (deliver),
`:4963, :4981` (ticket-bound), `:5004, :5016, :5099, :5121` (park).

**Five remaining direct `notify_david` sites:** `:1612` (infra fault, N failures in a row), `:1724`
(supervised handoff), `:2435` (clarify age-out), `:2756` (interview complete, decision doc not
composable), `:3450` (design-round age-out).

Live state file content (`_meta/notify-state/OI-000034.state`), tab-separated:

```
park	released:OI-000050	1786074301	1786074301
```

Only two state files exist (`OI-000034.state`, `OI-000041.state`) — the two DEC-0106 tickets.

---

## 7 · The ledger as an event history (design §1.3, §3.4)

Line shape, from the live tail:

```
2026-08-08 17:45 designed-route OK   — OI-000062 routed after the second pass -> 076-…md [execution=headless, stamp=designer/OI-000062@r1]
2026-08-08 17:45 clarify-ageout OK   — no clarify hold past the 86400s bound this wake
2026-08-08 17:45 completion     OK   — no reviewed results awaiting delivery
2026-08-08 17:45 claim          OK   — 076-design-the-reconciliation-and-self-impro claimed (attempt 1/2, continuations 0/3, model=opus, work 90m, hard kill +60s)
2026-08-08 17:45 reviewboard    OK   — REVIEW.md regenerated at wake-end (NEEDS YOU=2, FAILURES=6)
```

Event frequency over the last 3000 lines (`awk '{print $3}' | sort | uniq -c | sort -rn`), top of the
distribution:

```
304 wake            256 completion       200 orchestrator-end  195 telegram-poll
194 clarify-ageout  174 adjudication-retry 149 intake          129 reviewboard
124 staleness       117 review-start      117 review-end       117 retention
117 audit            94 no-op              90 design-ageout     53 designer-wake
48 notify            38 claim              30 stand-down        27 done
25 mint              24 clarify-out        22 delivered         19 escalate
18 route             17 stage-inputs       17 reverify          17 auth-echo
15 parked            12 notice             11 design-claim      11 clarify-in
10 adjudication-fail  9 cap                 8 model-lane         7 readjudicate
 6 no-deliverable     6 design-handoff      4 stage-breach       4 notify-edge
```

The transition-shaped events the design's §3.4 table is built on — `route, parked, delivered,
escalate, clarify-out, clarify-in, clarify-ageout, adjudication-fail, adjudication-retry, mint,
readjudicate, auth-echo, reverify` — are all present and all name their OI in the clause.

---

## 8 · The diagnostic-ticket lane, running (design §1.5)

Bounds, `orchestrator.sh:129–130`:

```sh
TICKET_PER_ITEM_MAX="${ORCH_TICKET_PER_ITEM_MAX:-1}"
TICKET_OPEN_MAX="${ORCH_TICKET_OPEN_MAX:-5}"
```

Helpers: `ticket_diagnoses()` `:4815`, `is_ticket()` `:4823`, `open_ticket_count()` `:4846`.

`park_and_ticket()`'s own header comment: *"Everything it can do is one of four outcomes, and every
one of them is a STATE CHANGE, so the FLAG it writes fires ONCE, at the transition, and the sweep
never sees the item again in that state (CLD-00112 / DEC-0106 item 7)."*

`parked_pass()`'s: *"For an unchanged parked state it does NOTHING and says nothing — that silence is
the whole of CLD-00112's close criterion (a), and it is structural rather than a dedup filter."*

Live instances, from `orchestrator/_index.md`: OI-000048 (the lane's build) `delivered` 2026-08-06;
OI-000050 and OI-000051, both `Diagnostic ticket — OI-0000{34,41} failed its mechanical done-check`,
origin `system-alert`, both `delivered` 2026-08-06.

---

## 9 · The staleness watchdog, and the precedent it sets (design §1.9, §3.7)

`_meta/check_staleness.sh` header, verbatim:

> Invoked by BOTH the reviewer pass and the nightly chain — two independent hosts, no new launchd
> job — so the queue is audited from OUTSIDE the machinery it reports on. It self-escalates: desktop
> notification + a ledger FAIL line, NEVER through the machinery being audited (it does not write an
> orchestrator/inbox attention item, because that inbox is one of the things it checks).

Five checks and their thresholds:

```sh
STALE_QUEUED="${AW_STALE_QUEUED_SECS:-$(( 3 * 3600 ))}"        # queued but unclaimed
STALE_INTAKE="${AW_STALE_INTAKE_SECS:-$(( 24 * 3600 ))}"       # orchestrator intake rotting
WORKER_SILENT="${AW_WORKER_SILENT_SECS:-$(( 24 * 3600 ))}"     # no worker wake
STALE_ESCALATED="${AW_STALE_ESCALATED_SECS:-$(( 7 * 86400 ))}" # escalated OI awaiting David
```

plus check 3, an orphaned `*/processing/` entry with no live lock. All five are **queue-shaped**;
none compares an item's state against its own history.

---

## 10 · The reviewer's audit, and where the generalization step attaches (design §1.8, §4.1)

`code/reviewer.sh` header, its own summary of what it does:

```
#   1. (mechanical) cleans up stale processing/ claims a dead worker left behind;
#   2. (LLM, sonnet) audits each outbox/ entry lacking ## Review …
#   3. (mechanical) escalates hard failures to task-shaped ATTENTION items …
#   4. (mechanical) log-retention sweep, then the paired outbox-archiving +
#      artifacts-retention sweep, then the staleness watchdog.
```

The `## Review` schema it emits, `reviewer.sh:193–197`:

```
    - **verdict:** meets-deliverable | partial | misses | failed
    - **assessment:** <2-4 sentences: did the result satisfy the prompt's stated deliverable? …>
    - **follow-ups:** <concrete recommended next tasks, or 'none'>
    - **reviewed:** $TODAY by reviewer (sonnet)
```

Four fields. None asks about wider application. `follow-ups` is the nearest thing and is explicitly
about *this* task's next steps, not about the class.

Follow-up writing is gated off by default (`REVIEWER_WRITE_FOLLOWUPS`, default 0): *"DO NOT create
any new files. Put follow-up ideas as recommendations in the ## Review text only (a human decides
whether to queue them)."*

---

## 11 · The Designer's pre-flight surface (design §1.8, §5.2)

`designer/templates/` contains exactly two files: `duty-clarify.md`, `duty-draft.md`. There is no
checklist artifact.

`_meta/authoring-contract.md` has seven sections — Anchor first; Word at class level; Self-screen
before filing; Intakes; Decision documents; Clarification responses; After a reject — and carries
hand-folded dated lessons (e.g. at lines 237, 285–286). It is the closest existing thing to a
pre-flight checklist and it grows by hand.

`_meta/designcheck.py` is the deterministic half of the front door's second pass: `check_well_formed`
(`:258`), `check_red_lines` (`:292`), `advisory_main` (`:315`, the DEC-260119 I-1 `--any-filing`
mode), `anchor_resolves` (`:523`).

---

## 12 · Work in flight, live status (design §8.0)

From `orchestrator/_index.md`, read this run:

| OI | summary | status |
|---|---|---|
| OI-000037 | Split the reviewer into an event-driven reviewer and a timed housekeeper | **escalated** |
| OI-000048 | Build the diagnostic-ticket lane ratified by DEC-0106 | delivered |
| OI-000056 | Design the Verifier rework: slim the front door | delivered |
| OI-000058 | The record resolver says "not found" instead of guessing (DEC-260119 D9) | delivered |
| OI-000059 | **Verifier rework increment I-1**: deterministic checks on every filing, advisory only | delivered |
| OI-000060 | **Verifier rework increment I-6 (as amended)**: judging passes read staged copies | delivered |
| OI-000061 | Design the reconciliation and self-improvement layer | **escalated** (1 question) |

I-6's effect is visible in the running ledger at 17:45 today:

```
2026-08-08 17:45 stage-inputs OK — V/D pass (opus) read STAGED COPIES, frozen at call start
  (DEC-260119 I-6) — inputs: 01-spine-OI-000062.md=sha256:2c5b62… 02-anchor-ACI-260011-260808-Open.md=sha256:ffe080…
```

DEC-260119's amended dependency order, from the decision file:

```
I-1 → I-6 → I-2 → I-3 (needs D1) → I-4 → { I-5 → I-9 (needs D8), I-7 (needs D4 evidence + David), I-8 (needs D3) }
```

I-1 and I-6 landed. **I-4, which retires the full-judgment V/D pass, is ahead** — and it is the pass
whose failure path holds `VD_FAIL_CAUSE` at `orchestrator.sh:1160`, the design's R-6 edit site. That
is the interaction driving decision D-3.

---

## 13 · Fence compliance

- Every read was read-only. No script, gate, screen, fixture or test suite was edited.
- No governance record was opened, closed, amended or authored.
- No item record, registry file or scheduled job was modified.
- Nothing was published to any remote; no git command other than `git log --oneline -1` (to note the
  repository's HEAD, `5b9d3db`) was run.
- The only files created by this run are the two in
  `code/artifacts/076-design-the-reconciliation-and-self-impro/`.
