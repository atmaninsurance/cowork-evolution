# Cowork Action-Item Backlog — Overlap, Dependency and Routing Map

**Date:** 2026-08-01 (Pacific)
**Author:** Cowork chat `remote_f184a039-651e-567e-b789-1daddb0a73d0`
**Scope:** Cowork-me / machinery items only. Alfred runtime (CLD-00058/59/60/83/84, all ALF-*)
and Atman business items (CLD-00054, CLD-00077, CLD-00093) are excluded by David's instruction.
**Queue state at time of writing:** orchestrator inbox empty, code inbox empty, nothing in
process. Last night's nightly ran clean (23:00 → 23:16, no FLAGs, all six repos committed).

---

## Part 1 — Six items look CLOSABLE now (zero worker slots)

These are the cheapest wins in the backlog: work already delivered by last week's tasks that
nobody has folded back into the item files. Under DEC-0097 most of these self-close once the
criteria are shown met.

| Item | Close criteria status | What is missing |
|---|---|---|
| **CLD-00105** — held item re-notifies per wake | **All three met.** Task 036 fixed five branches including the `:2373` sibling the third criterion names; fixture F proves 6 wakes → 1 push. | Fold + close. Its status line still says "deferred until task 035" — stale. |
| **CLD-00107** — test harness writes the live registries | **All three met.** Task 039 made the sandbox structurally unable to write the live tree (per-file link manifest, not overrides), produced the full `$META` write-path census, and recorded the fail-closed decision. Suite 229 → 246 assertions, live `_meta`+`_lib` byte-identical before/after. | Fold + close. **Layer three stays recorded and unrouted** — that was your explicit call. |
| **CLD-00104** — 8.5h stall reported clean | **Both met.** Task 037 built per-stage windows + an in-flight watcher that names the stage and elapsed time, plus `refresh.py` progress instrumentation. Criterion 2 is met by the stated finding that the cause is not retrospectively determinable. | Fold + close. |
| **CLD-00103** — frozen date + live clock | Fix landed in task 037; run-start semantics for run-keyed artifacts deliberately preserved and stated. | Criterion 1 wants *a run crossing midnight* with coherent lines. Last night's run finished at 23:16 and did not cross. Either accept the fixture as proof or hold until a long run crosses. |
| **CLD-00098** — graph venv broken | (a) root cause named — a `brew upgrade` on 07-29 removed `python@3.13` as an orphaned dependency of the poppler chain; (b) Stage 4 OK with smoke passing, 07-30 and 07-31. | Fold. **Two residuals worth keeping somewhere:** the report's row/edge delta table is wrong (reviewer caught it), and the durability question is unanswered — a venv built against a Homebrew interpreter will break again on the next upgrade. That residual is really CLD-00030's argument. |
| **CLD-00095** — project tag + PROMPT-LOG mirror | Stage 3.6c ran OK on the 07-31 nightly: 2 PROMPT-LOGs regenerated, 0 tags skipped. That was the stated close candidate. | Verify the two regenerated logs read correctly, then close. |

**Net effect: the open Cowork queue drops by six with no machinery work at all.**

---

## Part 2 — The overlap map

Five genuine clusters. Within a cluster the items share a root cause, a code region, or a
governing decision — which means routing them separately would have two executors editing the
same lines a week apart.

### Cluster A — "A stage that cannot fail loudly cannot be trusted to report success"

**Members:** CLD-00097 (residual), CLD-00092, CLD-00070 · kin: CLD-00104, CLD-00103 (both closing)

This is DEC-0089 item 1 recurring in three different places, and it is the single largest
overlap in the backlog.

- **CLD-00097's residual is Stage 2, not Stage 5.** Task 031 gave Stage 5 an `s5_verify()`
  positive-evidence check. Stage 2 (EOD) still records `OK` on exit code alone. The same
  API-529 that killed the sweep on 07-29 killed EOD the same night, and the ledger said OK for
  both. The exact check already exists as a one-liner: grep for a line-anchored
  `[DAY-COMPLETE: <date>]` in that day's log.
- **Report 031 itself asked for the class fix and was not given it.** Its recommendation F2:
  *"A generic 'every claude -p stage that claims OK must have left evidence' assertion would
  have caught this without a Stage-5-specific fix, and would cover Stage 2 and any future stage
  on the same pattern. Stage 5 is now covered specifically; the class is not."*
- **CLD-00092 is the same disease on a different surface** — a BLOCKING lint finding aged out
  of the "modified today" window instead of being fixed, so the nightly printed `0 BLOCKING …
  CLEAN` while the condition persisted. It is the only member of this family still unrouted.
- **CLD-00070 is CLD-00104 seventeen days earlier** — same stage, same shape, 2026-07-13. Its
  distinct residual is *bounded timeouts on non-claude stages*, which task 037 deliberately did
  **not** build: DEC-0089 chose loud-but-never-fatal, and nothing in task 037 can kill a stage.
  So CLD-00070 step 2 is arguably **superseded by decision**, not outstanding. Worth a ruling
  rather than a task.

**Recommendation:** one task covering the Stage-2 verifier + the generic class assertion +
CLD-00092's carry-forward-blocking-findings fix. Three items, one code region
(`cowork-nightly.sh` + `lint-transcripts.py`), one sitting.

### Cluster B — The decision channel

**Members:** CLD-00102, CLD-00091, CLD-00094 (Cowork-side half), CLD-00101

DEC-0099 moved the decision channel to the consulting surface on 2026-07-30. **The convention
landed; the machinery did not.** OI-000022 escalated with `channel=interview` hours after
ratification, and the authoring contract §5 now describes a channel the orchestrator does not
use.

- **CLD-00102** holds four unbuilt work items plus a build-owned consequence: nothing in the
  startup protocol reads the orchestrator's escalated/clarifying queue. Your own ruling —
  *"If no chat is active, the decisions sit and wait for you. You'll likely catch it as part of
  your startup routine"* — makes that startup check load-bearing, and the item is explicit that
  it must ship **with or before** the notify-only change, or questions have no reader.
- **CLD-00091 closes inside CLD-00102 item 3.** The Telegram pause-vs-poll race is one instance
  of "an inbound message is consumed and written nowhere." CLD-00102 states the absorption;
  CLD-00091 does not know about it.
- **CLD-00094's Cowork-side startup clarify check is the same check**, one scope narrower.
- **CLD-00101 is small, independent, and in daily use as a workaround.** `decision: approve`
  sources its task block from the escalation document, which is prose and only accidentally
  fenced; four enactments of your authority have failed on it. Your recorded preference is
  options 1 + 3 — source from the intake, and split the FLAG so a route failure names *which*
  of the two causes happened. Every decision we file currently uses `decision: rewrite` to
  dodge it.

**Recommendation:** two tasks. CLD-00101 alone (cheap, unblocks the approve path). Then the
CLD-00102 build, sequenced startup-check-first, absorbing CLD-00091 and CLD-00094's overlap.

### Cluster C — Authorization write paths

**Members:** CLD-00107 (closing), CLD-00110, plus CLD-00100's two recorded latent findings

CLD-00107's own note says it: *"Two different unaudited writers into the same registry. They
should probably be fixed together."* With task 039 landed, what remains is:

- **CLD-00110** — CLD id allocation has no atomicity, and on 07-31 a collision destroyed a
  file. Your call, unrouted. Note the complication the item records: chats write action-item
  files through several different tools (Filesystem MCP, Desktop Commander, native Write), so a
  fix that lives only in a helper script binds nobody. Create-exclusive writes are the strict
  superset; `cldlib.py mint` is second. Also note `action-items-framework.md` is
  governance-gated — the item records the need, it does not authorize the edit.
- **CLD-00100's latent findings** (recorded on the closed item): hold detection is a whole-file
  grep, so a spine that merely *mentions* the marker holds delivery forever; and
  `orchestrator/*` + `_meta/grants/*` writes are unflagged by the scope audit. Both are the
  mention-is-not-use class again — the same family as CLD-00085/00086.

**Recommendation:** CLD-00110 needs a ruling from you before anything. The CLD-00100 latents
are a good small task once you want them.

### Cluster D — Model and execution policy — **not routable yet**

**Members:** CLD-00106, CLD-00109, CLD-00072, CLD-00073 (residual)

CLD-00106 states plainly that you want to work through where `auto` resolves and that it must
not be settled unilaterally. CLD-00109 depends on CLD-00106 for per-step model selection.
CLD-00072's `timeout_minutes` is the exact sibling of `model:` — both are static author guesses
the machinery cannot revise.

**One concrete blocker hides in here:** `screen.py`'s `MODELS = {"sonnet", "opus"}` allowlist
makes `model: fable` a hard reject. Any design pass intended to run on Fable *through the
orchestrator* is blocked until that changes — and CLD-00109's design pass is exactly that. It
is a one-line change to a gate, which is precisely why the item says to treat it with the care
gates get rather than slipping it in.

**Recommendation:** consultation, not a build. The allowlist decision could ride separately if
you want CLD-00109's pass to run.

### Cluster E — Capture integrity

**Members:** CLD-00076, CLD-00092 (also in Cluster A), CLD-00067, CLD-00049, CLD-00040, CLD-00009

**CLD-00076 is the only member carrying live risk.** The token was rotated on 07-27, but the
systemic half is untouched: the deterministic exporters have no redaction pass, so anything
credential-shaped pasted into any chat is reconstructed verbatim into `~/Claude/transcripts/`
and pushed to GitHub by the nightly sweep. The amplification finding makes it worse — each
night's EOD adds another affected file by the act of reading a flagged one, which is why
exporter-side redaction is the only terminating fix. It also touches the same file
(`_transcript_common.py`) that CLD-00092's exporter/lint disagreement lives in.

The rest are low-urgency: CLD-00067 is empirical and blocks nothing, CLD-00049 has been quiet
since the remote converter landed, CLD-00040 and CLD-00009 are old.

**Recommendation:** one task for the CLD-00076 systemic fix.

### Cluster F — Semantic layer and docs — **blocked on a consultation**

CLD-00096 states it directly: *nothing migrates before the refinement consultation.* CLD-00079
(design-doc layering), CLD-00031, CLD-00030 and CLD-00038 all sit behind it or beside it. The
CLD-00098 durability residual above is really an argument for CLD-00030.

### Cluster G — Knowledge lane (wiki-redesign)

CLD-00089, CLD-00108, CLD-00048, CLD-00042/43, CLD-00001, CLD-00003, CLD-00037. **CLD-00108 is
yours to release** — its criterion (d) is a DEC-0100 authorization boundary, so your word
releases P1 write-through, not the machinery's. Nothing here should be routed by me.

---

## Part 3 — Dependency and sequencing constraints

1. **CLD-00102's startup check ships with or before the notify-only change.** Stated on the
   item. Shipping notify-only first leaves a window where questions have no reader.
2. **CLD-00101 should land before or with CLD-00102.** The decision channel build will file
   decision documents; the approve path being broken is exactly what the channel exercises.
3. **CLD-00109 is blocked on CLD-00106 gap 6** if its design pass is to run on Fable through
   the orchestrator.
4. **CLD-00110 blocks nothing, but every day it stays open is another day two concurrent chats
   can destroy an item file.** It nearly cost CLD-00106 permanently on 07-31; recovery was two
   accidents, not design.
5. **CLD-00096 blocks the whole of Cluster F.**
6. **Cluster A's three members must not be split** — they are one code region and one class.

## Part 4 — Not mine to route (needs a ruling from you first)

| Item | The decision you owe it |
|---|---|
| CLD-00110 | Create-exclusive first, `cldlib.py mint` second, or accept-the-risk as an explicit option C |
| CLD-00108 | Release P1 write-through, or hold — DEC-0100 authorization boundary |
| CLD-00106 | Where `auto` resolves; and whether to widen `screen.py`'s model allowlist |
| CLD-00070 | Supersede by DEC-0089 (loud-never-fatal) rather than build bounded timeouts? |
| CLD-00096 | Schedule the refinement consultation — it gates Cluster F |
| CLD-00099 | Schedule the headless git commit/push consultation |
| `topics.md` item 6 | Still waiting on your paste; the old compliance flag stands until then |

---

## Part 5 — Proposed routing batch

Four intakes, in this order. All `project: cowork-evolution`, all anchored on existing records,
all authored objective-level per DEC-0098.

| # | Prompt | Anchors | Why now |
|---|---|---|---|
| 1 | **Every nightly stage proves it did something** — Stage-2 positive-evidence verifier, the generic class assertion report 031 asked for, and blocking lint findings that carry forward instead of ageing out | CLD-00097, CLD-00092 | Largest overlap; a known silent-failure path is live tonight |
| 2 | **Redact secrets at the exporter** — a shared scrub in the transcript exporters plus a `secret-suspect` lint finding | CLD-00076 | Only live-risk item in the backlog; self-amplifying until fixed |
| 3 | **The approve path sources its task from the intake, and a route failure says which cause** | CLD-00101 | Small, independent, removes a workaround in daily use |
| 4 | **Make the consulting surface the actual decision channel** — startup pending-escalation check first, then escalation targets the consulting surface, Telegram notify-only, no inbound ever discarded | CLD-00102, CLD-00091, CLD-00094 | The convention has been live since 07-30 with no machinery behind it |

Worker cap is 6/day and the queue is empty, so all four fit in one day with two slots spare.
