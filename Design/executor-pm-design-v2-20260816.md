# The executor Project Manager — design v2 (David's topology)

**Written:** 2026-08-16, Code session `4a95d40a` · **Supersedes in shape:** the task-078 design pass of 2026-08-10 (`Agent_Workflow/code/artifacts/NNN-executor-pm-design/report.md`, "v1" below) — v1's evidence, sidecar schema (§3.2), release act (§3.4), intake checklist (§5) and provenance conventions are **reused by reference**; only the topology and the ten decisions change.
**Anchor:** CLD-00109 (the 2026-08-09 17:04 PM brief and its 12:46 two-level-dispatch correction) · **Ruled by:** DEC-260132 (this sitting) · **Composes with:** DEC-0102 (compile-don't-interpret), DEC-260119 (Verifier rework), DEC-260120 (reconciliation), DEC-260121 (round governance v2), DEC-260122 (designs layer), CLD-00119 (reviewer/housekeeper split), CLD-00120 (drain loop), CLD-00043 (screen at every promotion).
**Status:** ruled design; nothing built. The build is the P-1..P-6 sequence in §9, of which only P-1 is filed at the front door today.

---

## 0 · What changed from v1, in one paragraph

David's shape (2026-08-16, in-chat, "let's proceed with this approach" after five refinements were accepted): the PM is a **separate lane for multi-step work only**. A design the Designer judges single-pass goes to the front door as today and never touches the PM. A multi-step design gets a **sequence sidecar** (every step body authored once), is ratified **once** at the front door, and is then handed to the PM, which releases **one component at a time to the orchestrator** — never into an executor folder. The Reviewer routes a passed step to a new **`code/staged/`** folder when more stages follow, or to `code/reviewed/` when it is the final stage; the PM wakes on `pm/inbox` and `code/staged/`. This kills v1's B4 problem (a lane writing where another watches), makes "screen at every promotion" literally true (every step still passes the orchestrator's mechanical screen), turns v1's freeze rule into a free property (no `staged/` arrival, no next release), and removes the in-flight cap (serial by construction). v1's judged practicality pass (an opus session inside the PM) is **cut for v1** — the whole sidecar already gets V/D's full read at ratification and the mechanical checklist moves to the Designer's self-screen — so the v1 PM is **deterministic only**: no model, tiny script, nothing for "second authority" to attach to.

## 1 · Topology

```
Designer authors a design
  ├─ single pass  → front door → orchestrator judges → executor            (today, unchanged)
  └─ multi-step   → authors sequence sidecar (all step bodies, v1 §3.2 schema)
                     → runs the mechanical checklist in its self-screen (P-2)
                     → files at the FRONT DOOR (one ratification of the whole sidecar)
                     → orchestrator ratifies → drops the ratified sidecar into pm/inbox
PM wakes (pm/inbox arrival, or code/staged/ arrival, hourly fallback :50)
  → finds the next eligible step (depends_on landed; precondition exits 0)
  → stamps sequence:/step: frontmatter, files the component at the front door
  → orchestrator FAST PATH (§4): mechanical screen + instantiate into code/inbox, no V/D
Worker executes → Reviewer audits
  → pass, more stages follow → code/staged/     (PM wakes → next component)
  → pass, final stage        → code/reviewed/   (PM sweeps staged/ → reviewed/; completion round closes the OI)
  → return-for-work          → worker, ladder-bounded (PM sees nothing; no release)
  → return-for-redesign      → hold/ + front door → Designer → new sidecar version → re-ratified delta → PM resumes
```

Roles are v1 §2.1 verbatim except the PM's charter, now: **receives a ratified sequence, releases its steps one at a time to the orchestrator as their preconditions turn true, and hands the finished whole back.** The four boundaries B1–B4 (v1 §2.2) hold; B4 now holds trivially — the PM writes only into its own tree and the front door.

## 2 · The one authorization

The Designer's "single or multi" decision is expressed by whether it authored a sidecar; the orchestrator routes on that. The **whole sidecar** — every step body — is what the front door judges (V/D + attester; David if escalated). That single judgment is what later steps inherit (§4). The ratified copy is quarantined byte-for-byte at the front door exactly like any intake original (`_meta/schema.md` "immutable sidecar"), which closes v1 D-6's residual: the Designer's working copy may drift, the ratified copy cannot, and the fast path compares against the ratified copy.

Where the sidecar lives: Designer authors it at `designer/designs/OI-NNNNNN.sequence.md` (v1 §3.3); the ratified copy is `orchestrator/items/OI-NNNNNN.sequence.md` (orchestrator single-writer, like the intake original); the PM's expansion state is `pm/state/OI-NNNNNN.state.md`.

## 3 · The PM lane (deterministic, v1 of the lane)

- **Files:** `pm/pm.sh`, `pm/inbox/` (ratified sidecars arrive), `pm/processing/`, `pm/done/`, `pm/state/`, `pm.lock`, `_meta/com.cowork.agent-pm.plist` — WatchPaths on `pm/inbox` + `code/staged`, hourly fallback at **:50** (the free minute: :00 reviewer, :15 worker, :20 designer, :30 housekeeper, :45 orchestrator), ThrottleInterval 300, `CLAUDE_BIN` pinned though v1 makes no model call.
- **Wake = drain to next stable state** (CLD-00120 shape): for each sequence in `pm/processing/`, if the last released step has landed in `code/staged/` (or none released yet), evaluate the next step's `precondition:`; exit 0 → release; else one deduped ledger line and wait. Serial: **at most one un-landed step per sequence** — no `PM_MAX_INFLIGHT`, no per-wake cap needed beyond "one release per sequence per wake."
- **Release** = v1 §3.4 minus steps 3–8: the PM does NOT allocate `NNN`, screen, or `mv` into `code/inbox`. It writes the step body — byte-identical to the ratified copy — plus stamped frontmatter (`sequence:`, `oi:`, `step: k/N`, `sidecar_version:`, `ratified_sha:`) as an intake at the front door, and appends to its state file. The orchestrator does 3–8 as it does for every task today. **The PM's release is a front-door filing with a stamp; the orchestrator's `route_task` is unchanged code.**
- **Completion:** when the final step lands in `code/reviewed/`, the PM moves the sequence's `code/staged/*` entries into `code/reviewed/` (they were reviewed; `staged/` only held them) and writes one `sequence-complete` ledger line; the orchestrator's completion round closes the OI. Delivery is **at the end, not per step** (resolves v1 D-9's open sub-question).
- **Returns from the PM** (a precondition that can never turn true, a step body that fails the mechanical screen at promotion, a stall past bound): filed at the **front door** as a return naming the OI — never into `designer/inbox`. One hub, one path.

## 4 · The orchestrator fast path — where D-3 lives

When a filing carries the PM stamp, the orchestrator checks, in order: (1) `oi:` names a ratified sequence it holds; (2) `ratified_sha:` matches the quarantined ratified copy; (3) this step's body is byte-identical to that copy's step k; (4) the ratification is younger than **21 days** (v1 D-2); (5) the step is not `risk_class: control-plane`. All five → **mechanical screen (`screen.py`, full) + instantiate**, no V/D, no attester. Any check fails → the filing takes the ordinary front door as a fresh intake, and the PM is told (ledger line + return) — the sequence halts until re-ratified. This is v1 D-3(a), "inherit with mitigations," **enforced by the authorizing seat itself**, and it is the one thing David's word was needed for (DEC-260132).

## 5 · The Reviewer's one new move (deterministic)

`reviewer.sh` reads the task's stamped `step: k/N`: on `approve`, k<N → `code/staged/`, k=N → `code/reviewed/`; no stamp → `code/reviewed/` as today. No model judgment is asked "is this multi-stage?" — the answer is three lines of frontmatter the PM wrote at release. Returns are unchanged (`return-for-work` ladder; `return-for-redesign` → hold + front door).

## 6 · The Designer's one new move (advisory)

Its self-screen runs `sequencelib.py check` (v1 §5's mechanical rows: C-1, C-3, C-4, C-5, C-8, C-9, C-11 (dry-run screen over every step body), C-12, C-13) on any sidecar it authored, before filing. Advisory but printed; a failing row is a return-to-self before the front door ever sees it. This is v1 P-2 moved one hop earlier — a lint, not a judgment, so it adds no authority ahead of the authorizing seat.

## 7 · Backstops

- **Housekeeper check 8:** a sequence in `pm/processing/` whose next step has been eligible for > `PM_STALL_MIN` (180) with no release, or whose released step has been un-landed for longer than its `timeout_minutes` + the reviewer's cadence + grace — one ATTENTION, deduped.
- **Reconciler (DEC-260120):** `pm/state/*.state.md` joins the spine-vs-queue comparison — a state file that claims a released step no lane folder holds, or a lane folder holding a stamped step no state file names, are both reported (v1 P-6).
- **Staleness:** the 21-day bound in §4.

## 8 · The ten decisions, disposed

| # | v1 question | v2 disposition |
|---|---|---|
| D-1 | Where does the PM live? | **Own lane, deterministic, from the start** (a `.sh` + plist; no model in v1). The judged practicality half is cut; revisit only if ratification keeps admitting unbuildable sequences. |
| D-2 | Authorization staleness | **21 days**, as v1 recommended; checked in the fast path. |
| D-3 | Per-step inheritance | **Inherit with mitigations**, enforced as the orchestrator fast path (§4). David's ruling, DEC-260132. |
| D-4 | Caps | **Gone** — serial by construction (one un-landed step per sequence). |
| D-5 | Within-lane parallelism | **Deferred**, v1's T-1/T-2/T-3 triggers stand; the sidecar's `depends_on` already expresses a DAG for later. |
| D-6 | Sidecar home | Designer's tree for the working copy; **ratified copy quarantined by the orchestrator** (immutable). |
| D-7 | Prompt-guidance reference | Designs doc (`The_Estate/designs/machinery/model-capabilities.md` §"Prompt construction"), as v1; a precondition of nothing in v2 (the judged half is cut) — authored under ACI-260014's phase work when reached. |
| D-8 | Return bound | 2, reusing the reviewer's bound — applies to PM→Designer returns via the front door. |
| D-9 | OI granularity | **One OI per sequence; deliver at the end**, close at completion. |
| D-10 | Naming | "Project Manager", `pm/`, `pm.lock`, `*.sequence.md` — collision checks (`pm.lock` vs coordinator-lock vocabulary; `*.sequence.md` vs the red-line matcher) are P-1 build checks. |

## 9 · Build increments (v2), in dependency order

Written in the sidecar's grammar (precondition / deliverable / verification), so this sequence is itself the first thing the PM can run once P-3 lands. Paths relative to `~/Documents/Agent_Workflow`.

- **P-1 — `_meta/sequencelib.py`, dry-run only.** Parse a sidecar (v1 §3.2 schema, `lane:` may be `code` or `codex` — substrate-neutral from birth, ACI-260027), validate, compute eligibility from a supplied "landed" set + `precondition:` evaluation, emit expanded step files to stdout or a scratch dir only; `--dry-run` default that cannot be overridden in this increment. Golden test + task-039 fingerprint proof that no live folder was written. Also answers two reads v1 left open: the orchestrator's completion-round behaviour on a multi-task OI (`orchestrator.sh` near 4668–4812), and the two naming collisions. *Precondition:* v1 P-1's (dependency resolution live). *Filed 2026-08-16.*
- **P-2 — the checklist in the Designer's self-screen.** `sequencelib.py check` implementing v1 §5's mechanical rows; wired into `designer.sh`'s self-screen step, advisory. Fixture suite: one clean sidecar + one fixture per defect class. *Precondition:* P-1 in `code/reviewed/`.
- **P-3a — Reviewer routing + `code/staged/`.** Create `code/staged/`; `reviewer.sh` routes on `step: k/N` (§5); the housekeeper's and staleness audit's folder lists learn `staged/`. *Precondition:* P-1 landed.
- **P-3b — Orchestrator fast path (§4) + ratified-sidecar handling.** Recognise a sidecar filing at the front door (ratify whole, quarantine copy, drop into `pm/inbox`); recognise a PM-stamped step (five checks → mechanical screen + instantiate; else ordinary path + return). Test fixtures for each of the five checks failing. *Precondition:* P-1 + P-3a landed; **DEC-260132 open or locked** (David's D-3 word). Risk class: control-plane.
- **P-3c — The PM lane.** `pm/pm.sh` (§3), plist, lock, state, completion sweep, front-door returns. *Precondition:* P-3b landed **and a live capability grant covering launchd exists** (GRANT-0001 was one-shot; a David act at build time — the one external gate in the sequence).
- **P-5 — Housekeeper check 8** (§7). *Precondition:* P-3c landed.
- **P-6 — Reconciler learns `pm/state/`** (§7). *Precondition:* P-3c landed.

(v1's P-4 — the PM lane with a judged intake evaluation — has no v2 counterpart.)

## 10 · What this design does not do

- Build anything; only P-1 is filed. Every later increment files when its precondition turns true — by hand until P-3c exists, and by the PM afterwards.
- Design the Codex lane. It only keeps the sidecar's `lane:` field and the PM's front-door handoff substrate-neutral so a `worker-codex` lane (CLD-00065, CLD-00109 intra-lane dispatcher) plugs in without touching the PM.
- Re-litigate v1's evidence (§1), sidecar schema (§3.2), release mechanics (§3.4), checklist (§5) or testing philosophy (§7) — reused by reference.

## Records

- Ruling: DEC-260132 (2026-08-16). Brief and history: CLD-00109 (Progress entries 2026-08-09 17:04, 12:46 correction, 2026-08-16 v2 adoption). v1 report: `Agent_Workflow/code/artifacts/NNN-executor-pm-design/report.md` (task 078 / OI-000068). Custody registry (protects the sidecar and every claimed file from silent displacement): OI-000099.
