# Evidence — live code, live logs, live tree (collected 2026-08-07, ~16:27–16:40 PT)

Supporting material for `verifier-rework-design-20260807.md`. Everything here was read out of the
running system during that design pass. Line numbers are as the files stood at collection time.

---

## 1 · Resolver output, verbatim

```
$ cd ~/Documents/Agent_Workflow && python3 _meta/screen.py --resolve \
    ACI-260001 CLD-00109 ACI-260008 DEC-260114 OI-000055 OI-000037 OI-000047
unresolved-ref: OI-000055                                   # (stderr)
/Users/…/The_Estate/action-items/ACI-260001-260805-Open.md
/Users/…/The_Estate/action-items/CLD-00109-260731-Open.md
/Users/…/The_Estate/action-items/CLD-00076-260720-Open.md
/Users/…/The_Estate/action-items/CLD-00089-260727-Open.md
/Users/…/The_Estate/action-items/_index.md
/Users/…/The_Estate/decisions/2026/DEC-260114.md
/Users/…/The_Estate/decisions/2026/DIGEST.md
/Users/…/The_Estate/action-items/CLD-00119-260803-Open.md
/Users/…/The_Estate/action-items/CLD-00124-260804-Open.md
/Users/…/The_Estate/action-items/closed-items/2026/CLD-00088-260727-260730.md
/Users/…/The_Estate/action-items/ACI-260007-260807-Open.md
/Users/…/The_Estate/action-items/CLD-00108-260731-Open.md
```

Resolved one id at a time, the attribution is:

| id | stdout | stderr |
| --- | --- | --- |
| ACI-260001 | the ACI-260001 file | — |
| CLD-00109 | the CLD-00109 file | — |
| **ACI-260008** | ACI-260001, CLD-00076, CLD-00089, CLD-00109, `_index.md` | **nothing** |
| DEC-260114 | DEC-260114 + DIGEST | — |
| **OI-000055** | *(empty)* | `unresolved-ref: OI-000055` |
| **OI-000037** | CLD-00089, CLD-00109, CLD-00119, CLD-00124, closed CLD-00088 | **nothing** |
| **OI-000047** | ACI-260001, ACI-260007, CLD-00089, CLD-00108, CLD-00109 | **nothing** |

Three of the seven ids returned candidate lists with **no** `unresolved-ref:` line. That is the
quiet false positive named in the design document §0 finding 1 and decision D9.

## 2 · ACI-260008 is absent and was never committed

```
$ ls ~/Documents/The_Estate/action-items/ | grep 2600
ACI-260001-260805-Open.md   ACI-260002-260805-Open.md   ACI-260003-260805-Open.md
ACI-260004-260806-Open.md   ACI-260006-260807-Open.md   ACI-260007-260807-Open.md
                                          # no ACI-260008; ACI-260005 is closed/archived

$ git -C ~/Documents/The_Estate log --all --oneline --diff-filter=A -- "action-items/ACI-260008*"
                                          # (no output — never added in any branch)
```

## 3 · Today's write-restriction breach refusals (rc=62)

Seven, six in the orchestrator and one in the Designer lane. Source:
`code/logs/orchestrator-2026-08-07.log` and `code/logs/designer-2026-08-07.log`.

| time | pass | offending path(s) — each `rm -f`'d before the call was refused |
| --- | --- | --- |
| 13:55 | V/D, OI-000054 | `The_Estate/action-items/CLD-00076-260720-Open.md` |
| 14:48 | V/D, OI-000054 | `The_Estate/action-items/CLD-00089-260727-Open.md` |
| 14:55 | V/D, OI-000047 | `ACI-260008-260807-Open.md`, `CLD-00076-…`, `CLD-00089-…`, `action-items/_index.md`, `skills/README.md`, `skills/wiki-writing/SKILL.md` |
| 15:45 | V/D, **OI-000056** | `~/Claude/transcripts/code/554316ac-….md` |
| 16:03 | attester, **OI-000056** | `ACI-260008-260807-Open.md` |
| 16:06 | V/D, OI-000054 | `~/Claude/transcripts/code/1b62176a-….md`, **`orchestrator/inbox/decision-20260807-oi-000055.md`** |
| 16:13 | Designer, **OI-000056** | `orchestrator/items/OI-000054.md` |

Verbatim, the 16:06 refusal as it appears at the head of `code/logs/vd-OI-000054-2026-08-07.log`:

```
[run_claude] WRITE-RESTRICTION BREACHED on attempt 1 — a deny-write path was modified despite the
seatbelt profile; refusing the call and discarding its output. Offending path(s):
[run_claude]   /Users/alfredassistant/Claude/transcripts/code/1b62176a-065b-4c14-b898-9861e40969e5.md
[run_claude]   /Users/alfredassistant/Documents/Agent_Workflow/orchestrator/inbox/decision-20260807-oi-000055.md
```

Not one of these paths was written by a judging pass. Every one was written by a concurrent
process — a consulting session's transcript, an estate write, a decision filing, another item's
spine — during a judge's window.

`orchestrator/inbox/` now contains only two `.superseded-*` files; `decision-20260807-oi-000055.md`
is not among them, no `decision-in` ledger line references it, and OI-000055's spine ends at
`2026-08-07 15:31 — escalated to David — 2 question(s)`.

## 4 · The guard, in code (`_lib/run_claude.sh`)

- `: "${CLAUDE_RC_BAD_RESTRICTION:=62}"` (:85) — the rc every refusal above carries.
- Pre-launch snapshot: `deny_before="$(run_claude_deny_snapshot "$RUN_CLAUDE_DENY_WRITE" | sort)"`,
  taken immediately before the CLI is launched.
- Post-hoc comparison, cleanup and refusal (inside the attempt loop):

```sh
if [ "$deny_before" != "$deny_after" ]; then
  local breach_files; breach_files="$(comm -13 … | cut -f1)"
  while IFS= read -r bf; do
    [ -n "$bf" ] && rm -f "$bf" 2>/dev/null          # <- the destruction
  done <<BREACH_EOF
$breach_files
BREACH_EOF
  … log "WRITE-RESTRICTION BREACHED …"
  return "$CLAUDE_RC_BAD_RESTRICTION"
fi
```

The comment above it states the intent plainly: *"The enforcement guarantee already failed once …
Best-effort cleanup limits residue; it is NOT the safety mechanism. Refusing the call loudly,
below, is."* The design document's §7 argument turns on exactly that distinction — the refusal is
the safety property; the deletion is not, and it is what destroys other actors' work.

## 5 · Front-door configuration (`orchestrator/orchestrator.sh`)

| line | setting | value |
| --- | --- | --- |
| 72 | `VD_MODEL` | `opus` |
| 73 | `ATT_MODEL` | `sonnet` |
| 74 | `VD_TIMEOUT` | `900` (15 min) |
| 75 | `ATT_TIMEOUT` | `360` (6 min) |
| 88 | `CLARIFY_ROUND_MAX` | `3` |
| 89 | `CLARIFY_AGEOUT` | `86400` (~24 h) |
| 90 | `CLARIFY_PROG_MODEL` | `$ATT_MODEL` (sonnet) |
| 91 | `CLARIFY_PROG_TIMEOUT` | `300` |
| 327 | `JUDGE_TOOLS` | `Read,Glob,Grep` |
| 328 | `JUDGE_DENY_WRITE` | `~/Claude/memory/decisions : ~/Documents/The_Estate : ~/Claude/transcripts : $GRANTS : $ORCH` |
| 2891 | `DESIGN_ROUND_MAX` | `3` |
| 2892 | `DESIGN_AGEOUT` | `86400` |
| 2896 | `DESIGN_INTENT_MODEL` | `$ATT_MODEL` (sonnet) |
| 2897 | `DESIGN_INTENT_TIMEOUT` | `360` |

Designer lane (`designer/designer.sh`): `DESIGN_MODEL=opus` (:94), `DESIGN_TIMEOUT=1500` (:95),
`DESIGN_TOOLS=Read,Glob,Grep,Write,Edit` (:172), `DESIGN_DENY_WRITE` covering the orchestrator
tree, the executor queue folders, The_Estate, `~/Claude/memory/{decisions,processes,rules}`,
transcripts, grants, `~/.openclaw` and `~/Library/LaunchAgents` (:173).

## 6 · Function map of the front door

| function | line | role |
| --- | --- | --- |
| `intake_pass` | 3227 | walks `orchestrator/inbox/*.md`, sorts into three paths |
| `handle_fresh_intake` | 3280 | mint → quarantine → screen → V/D → adjudicate |
| `finish_fresh_adjudication` | 3339 | the whole branch tree (dispose / second pass / auto-route / clarify / design / escalate) |
| `handle_clarification_reentry` | 3572 | consumes a clarification **or design** return filing |
| `finish_clarify_adjudication` | 3644 | post-re-verification branch, incl. the second pass |
| `run_vd_pass` | 925 | the legacy full-judgment pass |
| `run_attester_pass` | 1120 | narrow substantiation, minimal context |
| `run_clarify_progress_pass` | 1981 | moving-or-rehashing, no file access |
| `run_design_intent_pass` | 3046 | one question: serves the verified intent |
| `design_second_pass` | 3101 | deterministic half first; judge only if code clears |
| `designer_handoff` | 2931 | the only writer into `designer/inbox` — code-composed |
| `design_refusal_route` | 3137 | bounded return to the Designer, park at the cap |
| `design_ageout_pass` | 3157 | ~24 h clock on a `designing` hold |
| `clarify_gate` | 2049 | contract cross-check, cap, progress judge, sidecar, duty-(a) hand-off |
| `clarify_ageout_pass` / `clarify_age_out` | 2138 / 2168 | ~24 h clock on a `clarifying` hold |
| `red_line_hit` | 253 | tripwires over the artifact under judgment, never the spine |
| `spine_flow_sync` | 3207 | `## Flow` projection, regenerated from `ledger.md` |
| `build_routable_task` / `route_task` / `route_supervised` | 1634 / 1690 / 1732 | the promotion hop, which re-screens |

`_meta/designcheck.py` — five deterministic checks, fail direction always REFUSE: `stamp-present`
/ `stamp-shape` (grammar `^designer/(OI-[0-9]{6})@r([0-9]+)$`), `stamp-anchor` (two hops: the design
record exists; its governance anchors resolve), `block-present` / `byte-identity` (hash measured by
code, never claimed by the session), `well-formed` (frontmatter, required fields, non-stub body,
**self-close-out trap**), `red-line` (its own pattern set, additive to the orchestrator's).

## 7 · The V/D prompt's five asks (`run_vd_pass`, :967–1020) — what retires

1. **PROVENANCE** — verified / unsubstantiated / no-claim → *survives, as the attester's question.*
2. **VIABILITY / IMPACT** — "well-scoped, worth doing, and safe?", with the
   "≥3-genuinely-viable-alternatives discipline" → *Designer.*
   2b. **CAPABILITY CHECK (DEC-0091)** — "does the anchored record explicitly name BOTH the
   capability AND the scope this item wants?" → *attester, per decision D1(a).*
3. **RECOMMENDATION** — route / dispose / needs-input, "List the SPECIFIC questions-needed-to-proceed"
   → *Designer (dispose per D2).*
4. **VARIATION** — none / significant, including the CLD-00088 self-close-out check → *the
   close-out half to code (S4); the variation call per D1(b).*
5. **QUESTION CLASSIFICATION** — `[clarification]` / `[interview]` / `[consultation]` → *Designer
   authors; the mechanical class filter (`filter_questions_class`, :899) stays.*

## 8 · OI-000056's own trace (this task's item), from its spine and `ledger.md`

```
15:42  mint             OI-000056 minted from consult-20260807-verifier-rework-design.md
15:45  adjudication-fail  vd pass failed (cause=model-call-error(rc=62)) — no verdict recorded
16:03  adjudication-retry V/D retried successfully (kind=fresh)
16:03  attester (sonnet): substantiated=no        <- rung down from an rc=62 refusal, not a judgment
16:03  auto-route       FLAG  blocked by attester (substantiated=no)
16:03  design-handoff   OK    duty=draft round=1  (clean but blockless verdict)
16:03  design-claim     OK    Designer lane, opus, 1500 s
16:13  design           FAIL  rc=62 — request returned to designer/inbox
16:13  design-claim     OK    (second attempt)
16:20  design-file      OK    corrected intake filed at the front door, self-screen ACCEPT
16:20  clarify-in       FLAG  "declares execution: — NOT honored from a clarification"
16:20  clarify-in       OK    "clarification round 0 consumed"        <- it was DESIGN round 1
16:26  design-2nd       OK    deterministic half PASSED, checks=5/5
16:26  design-2nd       OK    second pass CLEARED (deterministic + intent judge)
16:26  designed-route   OK    -> 067-design-the-verifier-rework-slim-the-fron.md
```

Spine frontmatter at route time shows the seam directly: `design_round: 1`, `design_consumed: 1`,
`design_duty: draft`, `clarify_consumed: 0` — **and** `clarify_response:
OI-000056.clarify-response-01.md`. The design round is correctly counted and incorrectly named.

Between 16:03 and 16:20 the item also passed through a **full V/D re-verification** on the return
path (`run_vd_pass … "V/D Re-verification"`, orchestrator.sh:3630) before the second pass ran —
the window design-document §5.1 removes as R2.

## 9 · OI-000047's round-2 clarification questions (read from the live sidecar)

Read at ~16:32 from `orchestrator/items/OI-000047.clarify.md`. **The item closed while this pass
was running** — `ledger.md` records `2026-08-07 16:33 delivered OK — OI-000047 delivered
(daily-log) and closed` — so the same file now lives at
`orchestrator/archive/2026/OI-000047.clarify.md`. All three questions are tagged
`[clarification]`:

1. Restate a fence item as a general rule because its enumeration is incomplete against the live
   script — naming three further sites (`librarian-cycle.sh` lines 263, 201, 326–331) whose text
   would become false on the first live run.
2. Give the exact path of a fixture suite, because the descriptor "under the delivered artifacts
   tree of the 2026-07-28 build" points at two real-but-wrong directories.
3. Pin the assertion scope of checks (b1)–(b3) at lines 124–142 so an executor scoping to a
   parenthetical does not leave the suite asserting a refusal the script no longer performs.

These are fence-precision drafting decisions — enumerate the sites, pin the path, fix the scope —
which is the task-drafting duty DEC-260114 Amendment 1 assigns to the Designer. That they were
asked at the front door, by the pass that may not hold a pen, is the concrete instance of the gap
the rework closes.

## 10 · Collection method

All of the above was gathered with read-only commands (`ls`, `grep`, `sed`, `git log`,
`launchctl list`, `python3 _meta/screen.py --resolve`) run from
`~/Documents/Agent_Workflow`. **No file outside
`code/artifacts/067-design-the-verifier-rework-slim-the-fron/` was created, modified or deleted by
this pass.** No script, gate, screen, fixture or test suite was edited; no governance record was
authored; nothing was published anywhere.
