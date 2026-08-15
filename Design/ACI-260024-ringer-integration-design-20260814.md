# Ringer → estate integration design (ACI-260024)

**Author:** claude-code, Code session `1b404e2b`, 2026-08-14
**Item:** ACI-260024 (Ringer deep review — extract, design, David gate, build)
**Sources:** The_Library `claude-skills/` — first-party verbatim: SKILL.md, README,
MODEL-NOTES, templates README + example manifests, engines config + sandbox wrapper,
and 26 line-referenced `ringer.py` excerpts (`ringer-*-20260814.md`). Wiki synthesis:
The_Wiki `entities/ringer.md`. All mechanics below verified against the fetched
revision (2026-08-14).
**License note:** PolyForm Shield 1.0.0 — internal use fine; we adopt *ideas and our
own implementations*, not Ringer code, which also keeps the license question moot.

---

## 1. Extraction memo (keep/kill)

| # | Learning | Verdict | Why |
|---|---|---|---|
| 1 | **Check-writing craft, mechanically enforced** — lint detects checks that cannot fail (`true`/`exit 0`/echo-only) and checks that fail silently (only `test -f`/`grep -q`/`diff -q` probes with no printing branch); every task carries a `verified:` plain-English sentence of what the check proves; a **baseline mode** runs every check against the unmodified tree to catch checks that can never pass; a silent check failure gets a synthetic "prefer checks that print WHY" message | **KEEP** — highest value | The estate's done-check discipline is convention-enforced only; these are cheap mechanical guards for a lesson the estate has paid for repeatedly (false-OK incidents; "exit 0 is not proof"). The baseline idea inverts naturally into an even stronger estate rule: **a done-check must FAIL before the work starts** — a check that passes pre-work proves nothing about the work. |
| 2 | **Evidence-based model routing** — every attempt logs one JSONL row (engine, model, effort, task_type, verdict, tokens, duration, retry); aggregation computes **first-try pass rate** per (model, task_type); tier is *recomputed from the log at every render* (never a stored state machine); **proven = ≥3 tasks AND first-try ≥ 2/3** (exact fraction, deliberately not 0.67); "volume alone never proves a model"; a MODEL-NOTES judgment file allows only dated bullets that executed checks and raw logs support; harness-reported model is cross-checked against the manifest's and mismatches are stamped | **KEEP** | This is the evidence base CLD-00106's ruled design needs: David's "V/D recommends the worker's model on speed/cost/complexity" currently has no data to recommend *from*. Requested-vs-actual stamping is literally CLD-00106 gap 4. |
| 3 | **Bounded failure-context retry** — retry prompt = original spec + "Previous attempt failed: {last 40 lines/6KB of worker log + check output}. Fix it." — rebuilt from the original spec each time, never cumulative | **KEEP** | Mechanical embodiment of identical-retry-is-not-a-retry, with a bound. Lands in worker retry/continuation and the diagnostic-ticket re-check. |
| 4 | **Spec self-containment lints** — spec under 80 chars flagged ("workers are stateless and cannot ask questions"); pointer-spec heuristic (short spec + "read/follow \<path\> and do what it says"); missing `expect_files`/`task_type` nudges; negation-aware git-commit detection under worktrees | **KEEP** | Direct fits for the authoring contract and the screen's advisory layer; the negation-awareness point is one the estate's own matcher work (mention-is-not-use) already validates. |
| 5 | **Worktree patch-export** — passing tasks' worktrees are deleted, so the check exports `git diff --cached` to a path outside the worktree and validates the patch; gitignored outputs must be `cp`'d explicitly or they silently vanish | **KEEP (fold into ACI-260012)** | The worktree-adoption item needs exactly this deliverable-survival pattern. |
| 6 | **Named anti-pattern: the tiny-edit death spiral** | **KEEP (vocabulary)** | Candidate wiki concept page; useful discipline language for supervised sessions. |
| 7 | Wholesale adoption of Ringer itself | **KILL (standing boundary)** | Outside the screen/authorization control plane; needs Codex/OpenRouter credentials at rest; its own full-access escape hatches (config-gated `--dangerously-*` flags) are exactly what the estate's gates exist to prevent being ambient. Optional supervised sandbox trial remains a David option, but with mechanics now fully extracted its evaluation value is lower than it was. |

## 2. Design sketches

### D1 — Done-check hardening (authoring contract + screen advisory + worker)

1. **`verified:` sentence** required beside every task's done-check: plain English,
   what a PASS proves. (Schema addition to the task block; advisory lint.)
2. **Check lint** (advisory findings in `screen.py`'s lint layer, estate-written):
   cannot-fail detection; fails-silently detection; pointer-spec heuristic;
   spec-length floor. Advisory, not blocking — same posture as wiki lint rules 1–5.
3. **Pre-work baseline:** worker runs the done-check once *before* starting; a check
   that already passes is reported as `check-proves-nothing` and the task pauses for
   correction instead of burning an attempt. (Ringer runs baselines batch-side; the
   estate's serial worker can do it inline for near-zero cost.)
4. **Failure-context injection:** on retry/continuation after a failed check, the
   prompt carries the original spec + a bounded tail (last ~6KB) of the failing
   run's log + the check's output — never the full prior conversation (converges
   with Token Saver design D2's result-carry rule).

### D2 — Attempt log + model scoreboard (rides CLD-00106)

- **Record:** one JSONL row per executor attempt, written by the worker at Result
  time and backfilled by a nightly walk of session JSONLs (which are authoritative
  for *actual* model + tokens — same walk as Token Saver design D1's cost ledger;
  **build these together**). Fields: OI/task id, lane, requested model, actual model
  (mismatch stamped), effort, task_type, attempt #, verdict, tokens, duration.
- **`task_type:`** new task-block field with a small canonical vocabulary
  (code-fix, build, docs, design, research, probe, …); untyped buckets teach
  nothing, so the lint nudges.
- **Aggregation:** derived, recomputed on read (no stored tiers): first-try pass
  rate per (model, task_type); proven at ≥3 tasks AND first-try ≥ 2/3. Rendered as
  a section on the ops dashboard (CLD-00128) and a one-command CLI table.
- **Consumption:** V/D reads the scoreboard when recommending the worker's model
  (David's ruled design; guardrails unchanged — spend ceiling gates, nobody picks
  their own). The reviewer's rung-3 fresh-model re-run picks *against* the
  scoreboard (a model the task hasn't run under, highest first-try rate available).
- **Evidence-gap filling (the exploration ladder, estate-sized):** with a fixed
  allowlist {sonnet, opus, fable} + effort axis, exploration means filling empty
  (model, task_type) cells, not discovering catalog models: on low-stakes typed
  tasks with strong checks, V/D may recommend an under-evidenced allowlisted
  model/effort pair, bounded to ~1 task per batch and named in the wake FLAG so
  David can veto. No new models enter except by DEC (allowlist is governed).
- **MODEL-NOTES analog:** `Agent_Workflow/docs/MODEL-NOTES.md`, dated evidence
  bullets only, house rule copied: only what executed checks and raw logs support.

### D3 — Spec-contract amendments (authoring contract)

Add to the task-authoring guidance: role+boundary first; every owned file named;
exact commands embedded; output contract explicit; hard rules in the spec, not the
author's head; no pointer specs. One paragraph + the D1 lints enforce the floor.

## 3. Decisions for David (the step-3 gate)

1. **D1 done-check hardening** (verified-sentence, check lints, pre-work baseline,
   failure-context injection)? — recommended **yes**; smallest cost, pays down the
   estate's most-repeated failure class.
2. **D2 attempt log + scoreboard**, built jointly with the Token Saver cost ledger
   (one JSONL walk, two outputs)? — recommended **yes**; it operationalizes your
   ruled V/D-recommends design.
3. **Evidence-gap exploration** (bounded, veto-visible, allowlist-internal)? —
   recommended **yes with the stated bound**; decline costs only slower evidence.
4. **D3 spec-contract amendments**? — recommended **yes** (rides D1's lint build).
5. **Worktree patch-export** folded into ACI-260012? — recommended **yes**.
6. **Supervised sandbox trial of Ringer itself?** — recommended **skip for now**;
   mechanics are fully extracted, and the estate adopts designs, not the tool.
7. **Wiki concept page for the tiny-edit death spiral?** — recommended **yes**
   (one small page, credited to the source).
