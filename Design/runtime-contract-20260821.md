# The one runtime contract — documented from the live surfaces

**Status:** design document. Descriptive, not normative-yet. Authorized by CLD-00109's
2026-08-20 D3 ruling as **a document only**; filed on David's 2026-08-21 proceed.
**Date:** 2026-08-21. **Item:** CLD-00109 (D3). **Related:** ACI-260032 (Planner/ACP
application), CLD-00065 (Codex adapter history), DEC-260133 (Codex design), DEC-260131
(measurement layer), DEC-260119 (staging / frozen inputs), ACI-260008 + OI-000099
(non-destructive breach disposition, custody registry).

---

## 0 · What this document is, and the fence around it

David's D3 ruling, verbatim in scope
(`~/Documents/The_Estate/action-items/CLD-00109-260731-Open.md:285-292`):

> **2026-08-20 — D3 ruled: DRAFTING authorized, as a document only** … Scope: a design doc
> under this item stating the one runtime contract — the facts every adapter (run_claude,
> run_codex, ACP/buzz-acp) must report: execution identity, frozen inputs, guard/write scope,
> progress, result, clean stop vs failure, measurement, continuation pointer. Explicitly NOT
> authorized: any shared-implementation refactor; runtime selection must not alter
> authorization, write scope, or verification.

Three consequences for this paper, and they bind it:

1. **It describes; it does not prescribe a build.** Every "gap" below is *named*, with the
   evidence that makes it a gap. Closing any of them is future authorized work.
2. **It changes no code.** No file outside this task's artifacts directory was written.
3. **The invariant it is written against** is the one the ruling states in its last sentence:
   *runtime selection must not alter authorization, write scope, or verification.* That is the
   test every row in §3 is scored against — not "are the three runtimes implemented alike",
   which is exactly the refactor the ruling forbids.

The originating observation is the CortextOS comparison note
(`CLD-00109-260731-Open.md:264-276`): orchestration should see **one typed contract** for
start, progress, result, stop/failure, guard evidence and measurement, while engine
differences stay inside adapters. Its own REVIEW GATE (`:273-276`) is what D3 answered.

**A note on evidence classes, because the three runtimes are not evidenced alike.** Two of the
three are code in this repo and are cited as code (`file:line`, quoting behaviour that exists).
The third — the ACP/Buzz seat — **has no script in this repository at all**; its behaviour is
evidenced by a design record (`Design/planner-lane-20260819.md`) plus Buzz desktop
configuration observed on the box. Every ACP row below is therefore marked
**[design-record]** or **[observed-config]**, never presented as code. That asymmetry is
itself Gap **G-1**.

---

## 1 · The reporting envelope — the eight facts

The contract is a *reporting* contract: these are the facts an execution adapter must make
available to the estate, in a form the estate can read without knowing which engine answered.
Each is stated here in engine-neutral terms; §3 scores each runtime against it.

| # | Fact | The question it answers | Why the estate needs it |
|---|------|-------------------------|-------------------------|
| **E-1** | **Execution identity** | Who ran, as what, on which engine and model, under which lane and phase? | Without it a transcript cannot be classified, a cost cannot be attributed, and a human session cannot be told from a machine one. |
| **E-2** | **Frozen inputs** | What exactly did the session read, and can a later reader prove it? | A judgement is only as good as the evidence it saw; a concurrent write must not be able to change what a pass read after the fact. |
| **E-3** | **Guard / write scope** | What was this session permitted to write, was that permission actually applied, and did anything outside it change? | This is the authorization surface. If it varies by engine, runtime selection changes authorization — the exact thing D3 forbids. |
| **E-4** | **Progress** | Is it alive, and how far has it got, *while it is still running*? | Distinguishes a slow-but-working run from a hung one without waiting for the hard timeout. |
| **E-5** | **Result** | What did it produce, and is that a work product or an apology? | The success test. An adapter that answers "it wrote bytes" instead of "it wrote work" is how a no-op gets recorded as done. |
| **E-6** | **Clean stop vs failure** | Did it finish, land short honestly, or die — and in which failure class? | Decides retry vs no-retry, requeue vs escalate. A class that cannot be told apart cannot be routed. |
| **E-7** | **Measurement** | What did this call cost, in what tokens, on what model actually answered? | Cost attribution, model-selection evidence, and the pool/gate machinery all read this. |
| **E-8** | **Continuation pointer** | Where is the durable record a successor can resume from? | The handoff ladder's rungs 2 and 3. It must survive a SIGKILL, because that is precisely when it is needed. |

Two properties of the envelope worth stating plainly, because they are what make it a
*contract* rather than a checklist:

- **Vocabulary before mechanism.** The two shell adapters deliberately share exit-code
  *numbers* (`run_codex.sh:131-137` sets the same 61/62/63/64 as `run_claude.sh:155-158`) even
  though the classifiers behind them are different code. One vocabulary across vendors is the
  contract; one implementation is not.
- **Fail-loud is part of the report.** "The guard could not be applied" is a reportable fact
  with its own code, not a silent downgrade to an unguarded run
  (`run_claude.sh:195-199`, `:971-989`; `run_codex.sh:339-359`).

---

## 2 · The three runtimes, in one line each

| Runtime | What it is | Where it lives | Evidence class |
|---|---|---|---|
| **`run_claude`** | Headless `claude -p` runner; the choke point every lane's model call passes through | `_lib/run_claude.sh` (1290 lines) | code |
| **`run_codex`** | The Codex adapter: `codex exec` under the *same* contract, sourcing `run_claude.sh` for one guard implementation | `_lib/run_codex.sh` (578 lines) | code |
| **ACP / `buzz-acp` seat** | Buzz Desktop supervises one `buzz-acp` process per agent; on an @mention it spawns `claude-agent-acp` (Claude Code as an ACP agent) | **no script in this repo**; `Design/planner-lane-20260819.md` §3/§10 + Buzz desktop config | design-record + observed-config |

`run_codex` is explicit that it is a second executor under `run_claude`'s contract, not a fork:
it **sources** `run_claude.sh` and calls eleven of its helpers as-is
(`run_codex.sh:2-4`, `:16-31`, `:101-113`), wrapping exactly three
(`codex_project_dir`, `run_codex_forensics`, `run_codex_record`) because each original is
welded to a Claude-only input (`run_codex.sh:33-51`). The stated proof that the Claude lane is
untouched is that `run_claude.sh`'s checksum is identical before and after that build
(`run_codex.sh:29-31`).

The worker dispatches on the task's `executor:` stamp and **refuses to substitute a runner**:
a `codex`-stamped task with no loadable adapter fails closed rather than running on Claude
(`executor/worker.sh:1259-1285`, refusal at `:1265-1272`). That refusal is the current
mechanism by which runtime selection is prevented from silently becoming a different
authorization surface.

---

## 3 · The contract, per runtime — what is provided today

Every non-ACP claim cites `file:line` in this repo. ACP rows cite the design record and are
tagged; none of them describe code in this repository.

### E-1 · Execution identity

| | Provided today | Where |
|---|---|---|
| **run_claude** | Prepends `[MACHINE-SPAWNED-SESSION: v1 lane=<lane>]` as the first line of the opening user turn, idempotently; lane defaults to the calling script's basename, overridable via `RUN_CLAUDE_LANE`. Model and permission mode are passed explicitly on the CLI. | `:939-959` (declaration, lane default `:954`); `--model` `:1072`; `--permission-mode "$CLAUDE_PERM"` `:1073`; defaults `:143-144` |
| **run_codex** | Same first line, same reason, `lane=codex` (`RUN_CODEX_LANE`, default `codex`). Model and reasoning effort passed explicitly, because C-0 learned that under `--ignore-user-config` the run reports `reasoning effort: none`. | `:328-337`; `RUN_CODEX_LANE` `:156`; `-c model=` / `-c model_reasoning_effort=` `:444-445`; the C-0 finding `:66-67` |
| **ACP seat** | **[observed-config]** The desktop supervises one `buzz-acp` per agent and spawns `claude-agent-acp` with the agent's *instruction field* as system prompt and the *configured* model. At the 2026-08-19 inspection: `backend: local`, `respond_to: owner-only`, `start_on_app_launch: false`; Watcher/Housekeeper on `model: haiku`, the original Planner on `claude-fable-5`. **Planner Sol's runtime configuration has not been re-verified in that record.** | `Design/planner-lane-20260819.md:478-486` |

**Gap G-2 — no machine-spawned declaration on the ACP path.** The declaration is emitted by
`run_claude_impl` (`run_claude.sh:939-959`), which the desktop-spawned session never passes
through. The session is Claude Code, but it is not *this fleet's* Claude Code, so the canonical
reader's tier-1 machine-readable marker is absent; classification falls back to prose
recognition, which is the prefix-drift class that marker exists to end (`:941-947`).

**Gap G-3 — one seat's runtime identity is unverified.** Planner Sol's model/backend are not
recorded (`planner-lane:485-486`). Identity that is not recorded is not reported.

### E-2 · Frozen inputs

| | Provided today | Where |
|---|---|---|
| **run_claude** | A full staging facility: open a per-call directory (containment re-proved against the caller's own deny list), copy each entitled input in, `chmod 0444`, SHA-256 each copy, append to a manifest, and emit a one-line full-fingerprint record that travels with the verdict. **Fails closed**: an input that cannot be read, copied or fingerprinted returns 1 and the caller must abort the launch. | `:650-760`; `stage_open` `:694-713`; `stage_add` `:720-747` (read-only copy `:740`, sha `:741`, manifest `:745`); `stage_fingerprints` `:755-760`; fail-closed rationale `:716-719` |
| **run_codex** | **Nothing of its own.** Its header lists `run_claude_stage_open/add/close` among the reused helpers (`:23`), but `run_codex_impl` (`:325-566`) never calls them. A Codex run gets frozen inputs only if its *caller* stages them. | absence verified across `:325-566` |
| **ACP seat** | **[design-record]** No staging. The seat's inputs are a version-controlled prompt template parameterized by the trigger's fields, plus whatever the session reads live. | `planner-lane:244-249` |

**Who actually stages today:** the judging lanes. `orchestrator.sh:635` and `designer.sh:567`
open staging directories; **`executor/worker.sh` does not** (zero call sites). So E-2 is
honoured for V/D, attester and design passes, and is absent for executor attempts on **all
three** runtimes.

**Gap G-4 — frozen inputs are a lane property, not a runtime property.** This is arguably
correct as designed (a worker attempt reads a live tree on purpose), but it means the contract
cannot be pinned at the adapter layer for E-2 without a decision about what "frozen inputs"
means for a *building* session as opposed to a *judging* one. See `[DECISION REQUIRED] D-1`.

### E-3 · Guard / write scope

This is the row the ruling's invariant lands on hardest, so it is broken out.

| | Provided today | Where |
|---|---|---|
| **run_claude** | Two opt-in knobs, both defaulting OFF: `RUN_CLAUDE_TOOLS` → `--tools <list> --strict-mcp-config` (a read-only list leaves no write-capable tool and no subagent to delegate to); `RUN_CLAUDE_DENY_WRITE` → a macOS seatbelt profile denying `file-write*` on each canonicalized subpath, kernel-enforced regardless of tools. | knobs `:174-201`, `:200-201`; profile builder `:215-244`; applied `:988`, `:1071`; tools flags `:990-992` |
| | **Fail-loud contract**: a relative/nonexistent/unquotable/uncanonicalizable deny path, a missing `sandbox-exec`, or a profile that fails preflight refuses the whole call with rc 62 before anything launches. There is no fallback to an unrestricted run. | `:195-199`; refusals `:971-989`; path checks `:220-236` |
| | **Post-hoc ground truth**: a sorted path+size inventory of the watched tree before and after the attempt; any difference refuses the call, discards the output, and returns rc 62. Deliberately not mtime-based — a live repro found a leaked file whose own mtime landed *earlier* than a reference created before it. | snapshot `:257-268`; the check `:1108-1134`; mtime rationale `:246-256` |
| | **Non-destructive disposition** (ACI-260008 / OI-000055): changed *tracked* file → committed HEAD baseline restored in place, post-state preserved in quarantine; changed *untracked* file → moved to quarantine; nothing is ever deleted; every path named in the FLAG; attribution from the session record is ADVISORY ONLY and never changes the disposition. | `:270-298`, `:499-648`; tracked branch `:575-597`; untracked `:598-610`; advisory `:366-374`, `:553-559` |
| | **Custody announcement** (OI-000099): if a displaced path is a live worker claim token, an extra greppable ledger line names whose custody was displaced and where the file went. Disposition itself is unchanged. | `:408-456`, `:631-643` |
| | **Narrowable watch** (DEC-260119 I-7): `RUN_CLAUDE_WATCH` narrows the *detector* to the pass's staging directory; the **seatbelt is deliberately not narrowed**. | `:202-211`, `:993-997` |
| **run_codex** | **Two sandboxes, both applied.** Codex's native `-s workspace-write` (default-deny over its own roots) *plus*, when a deny list is supplied, the same seatbelt profile built by `run_claude_build_deny_profile` (default-allow with named trees denied). They answer different questions, so both are applied; `RUN_CODEX_SEATBELT=0` drops to the native sandbox alone. | `:150-155`; seatbelt block `:339-359` (`build_deny_profile` at `:343`); `-s` `:448` |
| | **The declared write set**: `-C <cwd>` is the one always-writable root; each `RUN_CODEX_ADD_DIRS` entry adds another. `$TMPDIR` and `/tmp` are explicitly excluded, so *the declared write set is the whole write set*. Validation is fail-loud: a non-absolute or nonexistent add-dir refuses with rc 62 rather than silently handing the session a smaller write set than the task declared. | `:138-141`, `:365-398`; exclusions `:446-447` and rationale `:68-70`; refusals `:385-393` |
| | **Detector and disposition are `run_claude`'s functions, called as-is** — same snapshot, same non-destructive disposition, same custody announcement, same rc. | `:490-508` |
| | `--ignore-user-config` is load-bearing: David's desktop config enables browser / computer-use / node-REPL MCP servers and eight plugins, and a headless lane must never load them. | `:63-66`, applied `:443` |
| **ACP seat** | **[design-record]** §6 states the *intended* restrictions — writes only inside `planner/`, one sanctioned atomic exit into `orchestrator/inbox/`, kernel-denied everywhere else, never reads a private key. **[design-record]** §10 impact 4 states what is actually true today: *"a desktop-spawned Planner session runs outside our `run_claude` guard — no deny profile, no `RC_LANE` measurement. The global config carries an `env_vars` dict, so restrictions/labels can likely be injected — a PL-2 verification item, not an assumption."* | intent `planner-lane:372-401`; the live state `planner-lane:501-504` |

**Gap G-5 — the third runtime has no enforced guard, and this is on the record as a governance
gap, not an oversight.** `planner-lane:501-504` says it in those words. Every enforcement
mechanism in the two code rows above — seatbelt, tool restriction, fail-loud refusal, post-hoc
inventory, non-destructive disposition, custody announcement — is unavailable on the ACP path
because that path does not call `run_claude`. The §6 restrictions are therefore, today,
**behavioural rules asserted in a prompt**, structurally the same class of protection the rest
of the fleet moved away from. Against the ruling's invariant this is the sharpest finding in
this document: *choosing the ACP runtime today does change the write-scope enforcement.*
Note the design record already routes the remedy — `env_vars` injection — as **PL-2
verification work**, explicitly "not an assumption"; this paper neither adopts nor pre-empts it.

**Gap G-6 — the Codex declared write set is not wired to the task's declared work scope.**
`run_codex.sh:138-141` says `RUN_CODEX_ADD_DIRS` is "the task's declared `work_scope:`, mapped
1:1 onto `--add-dir` (§3.2)". Repo-wide, the only setters of `RUN_CODEX_ADD_DIRS` are the test
suite (`_meta/test_run_codex.sh:158,243,247,303,320`) and a build report; **no live lane sets
it.** The worker's dispatch block (`executor/worker.sh:1273-1277`) passes `RC_*` labels and
attempt/grace knobs and nothing else. So a Codex task's write set today is `-C <cwd>` alone,
and the `work_scope:` the grant declares reaches the Codex kernel sandbox not at all — it is
still honoured on the *audit* side (`worker.sh:790-808`, `:1170-1198`), post-run, which is a
detector rather than a fence. Named, not resolved.

**Gap G-7 — the guard is opt-in and the worker does not opt in.** `RUN_CLAUDE_DENY_WRITE` and
`RUN_CLAUDE_TOOLS` default empty (`run_claude.sh:200-201`) and are set by
`orchestrator.sh:1637,1812,3160,4301` and `designer.sh:357,652,850` — the judging and design
lanes — but not by `executor/worker.sh`. `RUN_CODEX_DENY_WRITE`/`RUN_CODEX_WATCH` inherit the
Claude values (`run_codex.sh:148-149`), so they are empty there too. Executor attempts on both
code runtimes therefore run with **no deny profile and no post-hoc detector**; their write
scope is governed by the pre-run screen, the grant, and the post-run scope audit instead. This
is a deliberate design (a building session must write), but it means E-3's *enforcement* half
is a lane property today, exactly like E-2. It also narrows G-5's sting: on the executor path
the three runtimes are closer than they look — what the ACP seat lacks relative to a *worker*
run is the measurement and identity layers more than the seatbelt.

### E-4 · Progress

| | Provided today | Where |
|---|---|---|
| **run_claude** | **None, structurally.** `claude -p` streams no stdout until the task completes, which is why the startup-grace guard had to stop using "wrote bytes" as its liveness test at all. The available proxy is *liveness*, not progress: a session JSONL newer than this attempt's semaphore. | `:1078-1089`, esp. the comment `:1078-1084`; semaphore `:1063`; JSONL liveness test `:1086` |
| **run_codex** | **A real event stream exists** — `--json` is written to `$out.events.jsonl` per attempt. But it is consumed only as a liveness signal in the startup-grace guard; nothing reads it as progress, and even the forensics reader walks the *rollout*, not the events file. | events file `:429-430`, `:453`; sole consumer `:462`; forensics reads the rollout `:267-306`, `:530`,`:542`,`:555` |
| **ACP seat** | **[design-record]** Progress is expressed at the *lane* level, not the runtime level: the Planner-side ledger's append-only state machine `NEW → LOCAL_REVIEW → RESOLVED\|NEEDS_DAVID → POSTED → ANSWERED → FILED`, with leases, generations and at-least-once idempotent delivery. Receipts are the existing transitions, not new states. | `planner-lane:252-268`, `:269-291` (record shape `:277`, leases `:280`, delivery `:283`, receipts `:285`) |

**Gap G-8 — progress is the weakest column in the envelope, and the one runtime that has the
raw material does not expose it.** Two of three provide only liveness; the third
(`run_codex`) already writes a structured event stream per attempt and discards it as a
progress source. The ACP seat has the richest progress model of the three, but it lives in a
*lane ledger*, not in anything an adapter reports — so it is not comparable to the other two
without a decision about which layer E-4 belongs to. See `[DECISION REQUIRED] D-2`.

### E-5 · Result

| | Provided today | Where |
|---|---|---|
| **run_claude** | Output is the captured stdout+stderr file. The success test asks **three** questions, not two: was it killed, did it write, and **is what it wrote a work product rather than an API error** (CLD-00097 F1). The error branch is evaluated *before* the success branch, so no error-shaped output can take the return-0 path whatever rc the CLI chose. The classifier is deliberately narrow — opening-token match gated on the output being SHORT (≤5 non-blank lines) — because a false positive here costs a *re-run of a session that already did work*. | success test `:1179-1182`; ordering rationale `:1136-1139`; classifier `:915-934`; narrowing rationale `:904-914`; the incident that forced it `:49-59` |
| **run_codex** | `-o <lastmsg>` **is** the output. When it is non-empty it becomes `$out` and the CLI's stderr is appended below it, bounded at 4 000 bytes, so no classifier can mistake a real answer for an error. When it is empty, stderr becomes the output verbatim (bounded at 8 000) — which is what lets the classifiers see the real text. Its error classifier calls `run_claude_output_error_shaped` **first and unchanged** and only *adds* the Codex openers: one vocabulary, extended, never forked. | compose `:472-488`; classifier `:189-216` (delegation `:199-201`) |
| **ACP seat** | **[design-record]** The result surface is a Buzz post or a lane-ledger terminal transition (`RESOLVED` / `NEEDS_DAVID` / `FAILED` with reason and evidence pointer), plus the sanctioned front-door filing. There is no adapter-level "did it produce a work product" test. | `planner-lane:260-268`, `:387-393`, `:373-379` |

**What consumes E-5:** the worker's mechanical `## Result` block —
`status`, `exit`, `attempt/max`, `model`, `executor` (emitted only for a non-default runner,
so Claude blocks stay byte-identical to every one written before the Codex build), `tokens`,
`actual-model`, `duration`, `finished`, `log`, `artifacts`, and on acceptance a SHA-256 per
declared deliverable (`executor/worker.sh:484-525`, executor field `:490-495`,
accepted-artifact hashes `:505-525`). **This block is the estate's real typed contract
surface today** — the place where the eight facts actually converge into one shape regardless
of engine.

### E-6 · Clean stop vs failure

Shared vocabulary, deliberately (`run_codex.sh:131-132`: "Deliberately the SAME numbers
run_claude uses, so a log reader, the worker's Result block and the ledger read one vocabulary
across vendors").

| Code | Meaning | run_claude | run_codex | ACP |
|---|---|---|---|---|
| `0` | success — a real work product | `:1179-1182` | `:545-548` | — |
| `61` | could not authenticate; **retry cannot clear it** | preflight `:1045-1057`, output class `:1153-1178` | preflight `:409-418`, output class `:534-544` | — |
| `62` | write restriction malformed **or breached** | `:976`,`:981`,`:986`,`:1132` | `:344-358`, `:373-393`, `:499-507` | — |
| `63` | wrote nothing at all | `:1206` | `:564`; also "no executable CLI" `:419-423` | — |
| `64` | wrote a CLI/API error and nothing else | `:1141-1147` | `:518-521` | — |
| `65` | **rate limit / quota — Codex-only, its own non-retry class** | — (no equivalent) | `:218-227`, `:523-532` | — |
| `137` | killed by a watchdog | hard `tmo` `:1077`, startup grace `:1085-1089` | hard `tmo` `:457`, startup grace `:461-465` | — |

Notes that matter to routing:

- **Retry safety is reasoned, not assumed.** The licence to retry is "the attempt did no
  work": a zero-output attempt did none, and an error-shaped output is the CLI saying it could
  not run the turn at all (`run_claude.sh:17-19`, `:60-67`).
- **Exhausting the loop can never return 0.** Both adapters coerce a trailing `rc=0` to 63,
  because the CLI can exit 0 having written nothing — a defect found while fixturing F1
  (`run_claude.sh:1197-1207`; `run_codex.sh:562-565`).
- **The kill model is SIGKILL only, deliberately** — no SIGTERM. The JSONL is written
  incrementally and durably, and Code's file writes are completed tool operations, not buffers
  a flush would rescue. The "landing grace" is **not a signal**: the worker sets `$tmo` to
  (work deadline + 1 min) and *tells the session the earlier deadline*
  (`run_claude.sh:42-47`; worker `:1252` and the budget arithmetic `:183-187`).
- **`65` is a genuine one-sided extension, and it is justified rather than accidental**: the
  lane shares David's ChatGPT plan limits with his interactive use, so a lane run must never
  silently eat his budget by retrying into a wall (`run_codex.sh:84-86`, `:218-222`).

**Gap G-9 — a non-retry class exists on one runtime only.** `65` has no Claude-side
counterpart. That is defensible (the underlying billing relationship differs), but it means a
caller that *did* branch on rc — none does today (`run_claude.sh:1156-1164`) — would behave
differently by runtime. Naming it now is cheaper than discovering it when the first such
caller is written.

**Gap G-10 — the ACP seat has no exit-code vocabulary at all.** Its failure surface is a
ledger `FAILED` line with a reason and evidence pointer (`planner-lane:263-264`, `:392-393`),
and a crashed `buzz-acp` subprocess is respawned by the desktop (`planner-lane:244-246`,
`:167-176`). There is no code, no distinction between the six classes above, and therefore no
way to express "do not retry, page David" on that path.

### E-7 · Measurement

| | Provided today | Where |
|---|---|---|
| **run_claude** | **The recorder.** On *every* exit — success, non-zero, refusal, timeout, kill — one JSON row is appended to `_meta/usage/usage.jsonl`: lane, phase, task id, OI id, judged ids, requested model, duration, exit, session JSONL. Because every lane's model call passes through this one function, the phase is **known** rather than inferred. | `:82-114`; the function `:1221-1276`; the CLI call `:1263-1273`; row assembly `_meta/usagelib.py:1366-1379` |
| | **Blast-radius containment**, four properties: `RC_RECORD=0` disables it at the first line (no file, no python, no log); it runs in its own subshell with `set +e` and `\|\| true`, diagnostics to `_meta/usage/recorder.log` and nowhere else, and cannot change `$?`; it is the **last** thing `run_claude` does; it writes **only** under `_meta/usage/`. The mechanism is a wrapper — `run_claude_impl` is the unmodified pre-build function — so exit status, stdout, stderr, `RUN_CLAUDE_JSONL` and every side effect are byte-identical with the recorder present, absent, disabled or failing. Proof: `_meta/test_run_claude_recorder.sh` (four-state diff). | `:116-132`; kill switch `:1227`; subshell `:1232-1234`; wrapper `:1278-1290` |
| **run_codex** | Reuses `run_claude_record` by reference: the wrapper points `$RUN_CLAUDE_JSONL` at *this* call's rollout for the duration of the recorder call and restores it after. Same kill switch, same containment, same log. Tokens come out of the Codex rollout because `usagelib.summarize` detects the Codex shapes; **an unrecognised shape yields NULLs, never a failed call.** The Codex token mapping subtracts deliberately: Codex reports `input_tokens` inclusive of cached, so storing it verbatim would double-count every cached token. | `:308-323`; wrapper `:568-577`; mapping `_meta/usagelib.py:158-164`, `:216-222` |
| **ACP seat** | **[design-record]** §6 specifies `RC_LANE=planner RC_PHASE=<consult\|plan\|decide\|tick>` on every session, recorded by the DEC-260131 layer. **[design-record]** §10 impact 4 records that a desktop-spawned session has **no `RC_LANE` measurement** today. §8 accordingly lists `RC_LANE=planner` measurement as something to be **verified rather than assumed**. | intent `planner-lane:397-398`; live state `:501-504`; verification item `:432` |

**Gap G-11 — the third runtime is unmeasured.** Same root cause as G-5 and the same single
sentence of evidence: it does not pass through `run_claude`. Consequence: Planner-seat calls
are invisible to `usagelib`'s cost attribution, scoreboard and pool/gate machinery. The
recorder's design note is what makes this a real loss rather than a cosmetic one — backfill
alone must *infer* a session's phase and labels some `unknown`; the recorder **knows**
(`run_claude.sh:88-92`). An ACP session gets neither: no recorder row, and a backfill walk
would have to find its JSONL first.

### E-8 · Continuation pointer

| | Provided today | Where |
|---|---|---|
| **run_claude** | Exports `RUN_CLAUDE_JSONL` per attempt — the session JSONL this attempt wrote, empty if it died before session start — captured *before* the semaphore is dropped. **The JSONL is durable on disk even after a SIGKILL, which is what makes post-mortem reconstruction possible at all.** The project dir is derived from the caller's cwd, never assumed. | `:31-41`, `:776-779`; reset `:1061`; capture `:1092-1096`; `claude_project_dir` `:804-824` |
| | **Kill-time forensics**: structural metadata only — record count, last record types/roles/tool names, timestamps — **never** message or tool content. And it refuses to manufacture a cause of death: "no JSONL here" only licenses "died before session start" when *here* is the directory the session would actually have written to; otherwise it says the forensics cannot tell. | contract `:20-22`; function `:826-892`; the inconclusive branches `:838-856` |
| **run_codex** | `RUN_CODEX_JSONL` exported per attempt, exactly as `RUN_CLAUDE_JSONL` is: the newest `$CODEX_HOME/sessions` rollout since this attempt's semaphore. **The lane never passes `--ephemeral`, so the session always lands in Codex-me's own record.** Discovery differs in kind — Codex writes one dated tree regardless of cwd, so there is no per-cwd directory and no project-dir-mismatch class. Forensics: same output contract, different reader (`{timestamp,type,payload}` vs `{type,message}`). | `:89-92`, `:159`, `:428`, `:470`; `codex_newest_rollout` `:171-179`; `codex_project_dir` `:163-169`; forensics `:262-306` |
| **ACP seat** | **[design-record]** The continuation surface is the Planner-side ledger item — stable id, source class, estate pointer, timestamps, state, owner/lease, attempt count, evidence pointers, thread pointer — which "preserves work while either [Buzz Desktop or the scheduled workflow] is unavailable". Ids are derived, not minted (`PWI-<8-hex fingerprint>` of the source ledger line), so the same source event can never create two items. | `planner-lane:252-259`, `:249-251`, `:271-276` |

**How the estate consumes E-8:** the worker reads whichever global its adapter exported
(`executor/worker.sh:1288-1293`) and the handoff ladder is format-agnostic text from there —
rung 1 the session's own `HANDOFF.md`, rung 2 the handoff-writer reconstructing from the
transcript (`:571-677`), rung 3 a raw-transcript pointer (`:688-696`). The worker snapshots
the session's *own* contribution before the writer runs, because afterwards "the writer wrote a
file" is not evidence the task advanced (`:1294-1299`).

**Gap G-12 — the ACP seat's continuation pointer is a lane record, not a transcript.** There
is no `RUN_*_JSONL` equivalent and no forensics reader; the durable record is the ledger's
pointers, which describe *what was decided*, not *what the session did*. No handoff ladder
applies.

---

## 4 · Gap register

Every gap named above, in one place. **None is resolved here.** The right-hand column names
where the work would belong if authorized — it does not authorize it.

| # | Gap | Runtime(s) | Class | Would belong to |
|---|---|---|---|---|
| **G-1** | ACP seat has no script in this repo; all its facts are design-record or observed-config, not code | ACP | evidence asymmetry | ACI-260032 / PL-2 |
| **G-2** | No `[MACHINE-SPAWNED-SESSION:]` declaration on the desktop-spawned path | ACP | E-1 | ACI-260032 / PL-2 |
| **G-3** | Planner Sol's runtime configuration unverified | ACP | E-1 | ACI-260032 |
| **G-4** | Frozen inputs are a *lane* property (judging lanes stage; the worker does not) | all three | E-2 | needs D-1 |
| **G-5** | Desktop-spawned session runs outside `run_claude`'s guard — no deny profile | ACP | E-3 | ACI-260032 PL-2 (`env_vars` injection, already named as a verification item) |
| **G-6** | `RUN_CODEX_ADD_DIRS` documented as the task's `work_scope:` but set by no live caller | run_codex | E-3 | DEC-260133 build line |
| **G-7** | The deny guard is opt-in; the executor lane does not opt in on either code runtime | run_claude, run_codex | E-3 | needs D-1 |
| **G-8** | Progress is liveness-only; `run_codex` writes an event stream nothing reads as progress | all three | E-4 | needs D-2 |
| **G-9** | Non-retry class `65` exists on one runtime only | run_codex | E-6 | CLD-00065 |
| **G-10** | ACP seat has no exit-code vocabulary; cannot express "do not retry" | ACP | E-6 | ACI-260032 |
| **G-11** | ACP seat is unmeasured — no recorder row, no `RC_LANE` | ACP | E-7 | ACI-260032 PL-2 |
| **G-12** | ACP seat's continuation pointer is a lane ledger, not a transcript; no handoff ladder | ACP | E-8 | ACI-260032 |

**The shape of the gap set is worth stating.** Seven of twelve are ACP-side, and six of those
seven (G-2, G-5, G-10, G-11, G-12, and G-1 as their cause) reduce to **one** structural fact:
*that runtime does not pass through `run_claude`, and there is no code in this repo that
represents it.* The two code runtimes are, by contrast, already close to one contract —
shared exit codes, one guard implementation reused by reference, one recorder, one forensics
contract with two readers. Whatever a future refactor DEC decides, this asymmetry is the
finding: the distance between `run_claude` and `run_codex` is small and shrinking by design;
the distance between either and the ACP seat is categorical.

---

## 5 · Compatibility checks — a sketch that pins the contract without any refactor

These are **checks**, not adapters: each is a test that reads the live surfaces and fails loud
when a runtime stops honouring a fact. They pin the contract as it stands, which is precisely
what makes a later refactor decision evidence-based rather than speculative. Sketch only; not
authorized here, and each would need its own build authorization.

**C-1 · The shared-vocabulary check (E-6).** Assert that both shell adapters define the same
numbers for the same meanings, by reading the defaults out of the files themselves
(`run_claude.sh:155-158` vs `run_codex.sh:133-137`) and diffing. Catches drift the moment one
side renumbers. *Cheapest check here; pure text over two files; no CLI invoked.*

**C-2 · The fail-loud-refusal matrix (E-3).** For each adapter × each malformed-restriction
shape (relative path, nonexistent path, quote in path, missing `sandbox-exec`, profile
preflight failure, non-directory `-C`, non-absolute add-dir), assert rc 62 **and** that nothing
launched. Both suites already carry pieces of this — `_meta/test_run_codex.sh:243,247` are
exactly the add-dir cases — so C-2 is mostly a matrix over existing fixtures rather than new
ones. *The one check that directly tests the ruling's invariant on the authorization axis.*

**C-3 · The envelope-completeness check (E-1, E-7, E-8).** Drive each adapter under a stub CLI
with `CLAUDE_CONFIG_DIR` pointed at a throwaway root (the CLD-00075 convention the recorder
already honours, `run_claude.sh:1242-1259`), then assert: the prompt's first line carries the
machine-spawned marker; exactly one usage row was appended with non-`unknown` lane and phase;
the adapter's `*_JSONL` global names a file that exists. Run the same assertions against both.
*This is the check that would make the ACP seat's absence measurable rather than argued —
it fails on that runtime today, which is the point.*

**C-4 · The recorder-inertness re-run (E-7).** `_meta/test_run_claude_recorder.sh` already
proves the four-state property (present / absent / disabled / failing → byte-identical
behaviour) for `run_claude`. The compatibility form asserts the same four states for
`run_codex`, whose recorder is a wrapper that mutates and restores a global
(`run_codex.sh:317-323`) — the one place where "reused by reference" could leak.

**C-5 · The result-classification corpus (E-5).** One shared corpus of output samples — real
API errors, auth failures, rate-limit texts, and work products that *mention* errors — run
through both classifiers, asserting the same verdict except where a runtime-specific class
(65) legitimately differs. Fixture-pinned wording is already the stated intent on the Codex
side (`run_codex.sh:185-188`); this generalises it across vendors.

**C-6 · The declared-vs-enforced write-set check (E-3, would surface G-6).** For a task
carrying `work_scope:`, assert that what the adapter was handed as its kernel-enforced write
set matches what the grant declared. Today this fails for Codex by construction (nothing sets
`RUN_CODEX_ADD_DIRS`), which is the check earning its keep on day one.

**What no check can cover today: the ACP seat.** C-1, C-2, C-4, C-5 and C-6 need a callable
surface, and there is none in this repo (G-1). C-3 is the only one that can be *pointed at* it
at all, and only to record its absence. Any real compatibility coverage of the third runtime
depends on the PL-2 `env_vars` verification the design record already names
(`planner-lane:501-504`) — that is a precondition, not a deliverable of this sketch.

---

## 6 · [DECISION REQUIRED]

Two questions this document cannot answer without ruling, and deliberately does not resolve
silently.

**[DECISION REQUIRED] D-1 — At which layer do E-2 (frozen inputs) and E-3's *enforcement* half
belong: the runtime adapter, or the lane?**
Today both are lane properties: judging lanes stage inputs and set deny lists; the executor
lane does neither, on either code runtime (G-4, G-7). Two readings are available and they lead
to different future work.
*(a) Lane-owned is correct as-is* — a building session must write, and freezing its inputs
would be wrong; the contract then says adapters must *support* E-2/E-3, and lanes decide when
to use them. Nothing is broken; G-4 and G-7 close as "by design", and the paper's per-runtime
scoring for those rows should be read as "capability present" not "applied".
*(b) The contract should bind at the adapter* — every session, including a worker attempt,
reports what it read and what it was allowed to write. That is a materially larger change and
would need its own authorization.
**Recommendation: (a).** It matches what is built, it is what the fail-loud opt-in design
(`run_claude.sh:174-178`: "both default OFF, so the worker, reviewer and nightly stages — which
legitimately write — are untouched by sourcing this") already says in words, and (b) would
edge toward the shared-implementation refactor D3 excludes. *This affects only how G-4/G-7 are
scored, not whether they are named.*

**[DECISION REQUIRED] D-2 — Is E-4 (progress) part of the runtime contract at all, or a lane
concern?**
The three runtimes answer at different layers: liveness proxies at the adapter (both code
runtimes), a full state machine at the lane (ACP's Planner-side ledger). They cannot be scored
on one scale until this is settled. Sub-question if E-4 stays in the contract: should
`run_codex`'s existing `--json` event stream be surfaced as progress, given it is already
written per attempt and currently read only as a liveness bit (G-8)? *No recommendation — the
answer depends on whether anything downstream would consume progress today, which this paper
did not investigate and should not assume.*

---

## 7 · Provenance and citation index

**Authority.** CLD-00109 D3 ruling `~/Documents/The_Estate/action-items/CLD-00109-260731-Open.md:285-292`;
filing on David's 2026-08-21 proceed `:278-283`; CortextOS comparison note and its REVIEW GATE
`:264-276`.

**Code read in full.** `_lib/run_claude.sh` (1290 lines), `_lib/run_codex.sh` (578 lines).
Supporting code read in part and cited: `executor/worker.sh` (dispatch `:1259-1293`, Result
block `:484-525`, handoff ladder `:544-696`, scope audit `:790-857`, `:1170-1198`, budget
arithmetic `:183-187`, `:1252`); `_meta/usagelib.py` (`record` `:1366-1379`, Codex token
mapping `:158-164`, `:216-222`); guard call sites in `orchestrator/orchestrator.sh:635,1637,1812,3160,4301`
and `designer/designer.sh:357,567,652,850`; fixtures `_meta/test_run_codex.sh:158,243,247,303,320`.

**Design record (ACP seat — not code).** `Design/planner-lane-20260819.md` §3 `:227-291`
(trigger/spawn `:244-251`, Planner-side ledger `:252-291`), §6 `:371-401`, §8 `:432`,
§10 `:461-514` (key custody `:463-476`, how the desktop runs agents `:478-486`, impacts
`:487-508`).

**Verified absences** (each checked repo-wide; an absence is a finding, so the method is
recorded): no ACP/Buzz runner script under `_lib/`; `run_claude_stage_open` has zero call
sites in `executor/worker.sh` and none inside `run_codex_impl`; `RUN_CODEX_ADD_DIRS` has no
setter outside `_meta/test_run_codex.sh` and one build report; `RUN_CLAUDE_DENY_WRITE` /
`RUN_CLAUDE_TOOLS` have no setter in `executor/worker.sh`.

**Fence honoured.** No code was changed. No file outside this task's artifacts directory was
written. No git remote was contacted.
