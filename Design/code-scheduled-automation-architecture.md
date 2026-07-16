# Design: Code-Scheduled Nightly Automation

**Status:** Design ratified 2026-07-09; **BUILT + LIVE** as of night-2 (2026-07-10 ran clean end-to-end). Build prompt: Prompts/CLD-00062-code-nightly-automation-build.md.
**Decision record:** DEC-0069 (COWORK-DECISIONS-2026.md)
**Action item:** CLD-00062 (Phase 4), CLD-00063 (remote transcript protocol + Phase-3 tooling reconciliation)
**Origin:** chat `remote_4bd6fe76-e364-5844-90b3-ad9cc6777f4b` (platform-test-fresh-session, 2026-07-09), building on CLD-00061 Datapoints 1–4
**Author:** Cowork-me (remote session, desktop-initiated)

---

## 0. As-built deviations from this design (2026-07-11, CLD-00062 Phase 4 / CLD-00063 Phase 3)

The build diverged from the design below in a few deliberate, validated ways. This annex is
**not rewritten** to match — the deviations are recorded here and the reasons noted inline:

1. **Stage order — export runs BEFORE EOD (design §3 had transcript tooling as Stage 2, after EOD).** The CLD-00062 Phase 2 dry run showed EOD's discovery must see every chat, including Cowork chats that didn't self-capture, so the deterministic exporters run first (create-missing) and only the integrity **lint** runs after EOD (it cross-checks EOD's daily-log writes). Wrapper stages as-built: 1 export → 2 EOD → 3 lint → 4 graph → 5 sweep → 6 ledger.
2. **Content-date discovery, not mtime.** "Today's sessions" are determined by the transcript header's `Live capture started` stamp (UTC→Pacific converted), not file mtime — a backfilled/reconstructed file has today's mtime but an older session date. Prevents evening-chat drop and backfill false positives.
3. **Cowork audit.jsonl exporter added (not in the original design).** Gate 0 inventory found the desktop app persists a full `audit.jsonl` per interactive Cowork session; a second deterministic exporter (`export-cowork-transcripts.py`) reconstructs the `cowork/local_<UUID>.md` surface from it, including `--backfill-closing` (enabled 2026-07-11 — fills `[assistant]\n<pending>` bodies + closing turns, alignment-checked and provenance-stamped; CLD-00063 A3).
4. **Remote surface is verifier-only (DEC-0070).** Remote cloud-container chats (`cowork/remote_<UUID>.md`) have no Mac-side source; they are captured in-container by `export-remote-transcript.py` and the nightly never sources/regenerates them. Tooling now classifies three ownership modes (`hand`/`tool-owned`/`live-deterministic`, CLD-00063 A2).
5. **Alerting is FAIL-only.** ATTENTION surfaces on hard FAIL; FLAG-level findings stay in the ledger for agent triage at next session start (CLD-00063 A4). Design §5/§9 anticipated a flag file for any FLAG/FAIL; narrowed by David's "automation owns transcript fixes" direction.
6. **Legacy EOD SKILL retirement is no-stub (DEC-0071), not "pointer stub."** §6/§ below say the legacy SKILL retires "to a pointer stub (CLD-00046)"; DEC-0071 changed the convention to **no-stub** (move to `_deprecated/`). The one live exception is a load-bearing neutering stub that stays until David removes the desktop task registration in the app UI (Code can't). See `~/Claude/memory/_deprecated/cowork-eod-skill-retirement-20260711.md`.

## 0b. As-built addendum (2026-07-14, DEC-0078): a second standing chain + the shared `run_claude` lib

The nightly chain is no longer the only launchd automation on the machine. The **Agent Workflow
queue** (CLD-00043 Stage A, DEC-0078) adds two standing agents: `com.cowork.agent-worker`
(WatchPaths on `~/Documents/Agent_Workflow/code/inbox` + hourly fallback; serial drain, one fresh
`claude -p` per prompt) and `com.cowork.agent-reviewer` (08:00 + 16:00 PT). Canonical documentation
is **DEC-0078 + `~/Documents/Agent_Workflow/README.md`** — this annex deliberately does not
duplicate it. What this annex MUST carry:

- **Cross-repo dependency (load-bearing):** the nightly's `run_claude` + kill-time JSONL forensics
  were extracted to `~/Documents/Agent_Workflow/_lib/run_claude.sh`, and `cowork-nightly.sh` now
  **sources it from there**. Moving/renaming Agent_Workflow (or restructuring its repo) breaks the
  nightly chain until the source line is updated; conversely, any change to the shared lib affects
  BOTH chains and must be verified against both (nightly preflight + a queue dry prompt).
- **Schedule interplay:** the worker stands down 22:30–00:30 PT so the 23:00 nightly runs
  uncontended; the reviewer's fixed slots (08:00/16:00) sit outside that window by design.
- **TCC runtime facts:** headless-launchd `claude` has its own macOS folder-permission identity —
  first unattended run (2026-07-14) raised prompts that stalled the whole first drain (grace-kills,
  exit 137). Grants chosen, the CLI version-change preflight that now guards updates, and producer
  recovery conventions live in the README §Runtime facts / §Producer conventions.
- **2026-07-13 night datapoint:** the EOD Stage-2 hang that night (rc=137, CLD-00068 class) was
  verified NOT caused by the lib refactor — EOD invoked the shared lib correctly and was killed by
  its own grace watchdog; the Stage-5 sweep completed in 3 min. Stage 4 (graph) still lacks a
  timeout wrapper — candidate hardening item.

## 0c. As-built addendum (2026-07-14, DEC-0079): CLD-00068 root-caused — the launchd startup-hang is a TCC per-version-path grant reset

The "TCC runtime facts" bullet above (and the intermittent nightly exit-137s) resolved to a single
root cause: **macOS TCC keys a CLI's file-access grants to the exact binary path it launches, and the
`claude` auto-updater installs each build at a new `~/.local/share/claude/versions/<ver>` path.** So a
freshly-updated `claude` is an un-granted TCC client; under launchd (no interactive session to answer
the consent prompt) its first Documents access **blocks → 240 s grace kill → "died before session
start."** Reproduced + confirmed 2026-07-14 (per-version `client_type=1` rows in `TCC.db`; live
`com.apple.TCC` stream with `AUTHREQ_SUBJECT`=the versioned path; and a natural experiment where 2.1.209
hung 41 min *after* 2.1.208 was consented). It is **stage-agnostic and chain-agnostic** — it hit the
nightly EOD/sweep and the Agent Workflow worker identically, because both run the same binary in the
same launchd context.

**Fix carried into BOTH chains (load-bearing):**
- Every launchd `claude -p` (worker, reviewer, AND this nightly chain) now runs
  `CLAUDE_BIN=~/.local/share/claude/agent-pinned/claude` — a stable-path copy granted **Full Disk Access
  once**. FDA is bound to Anthropic's Developer-ID requirement (Team ID `Q6L2SF6YDW`), not the cdhash, so
  the grant survives a content refresh (verified by a 2.1.209→2.1.210 overwrite — grant row unchanged,
  launchd probe still passed, no re-prompt).
- The nightly gains **Stage 1.5** (`_lib/sync-pinned-claude.sh`, another shared cross-repo file) that
  refreshes the pin from the current install once/day — `codesign --verify` + Team-ID gated, non-fatal
  FLAG on anomaly — **before** its own claude -p stages. So the agents stay ≤1 day behind latest while
  the path (and its grant) never move.
- Because `CLAUDE_BIN`'s pin path and `sync-pinned-claude.sh` are shared plumbing, they **join
  `run_claude.sh` on the "changing either affects both chains" list** — verify any change against both.
- The worker's version-change preflight is retained as the post-re-pin health check; `_meta/cli-version.last`
  must never be hand-seeded (that gap let the day's drain-2 skip the probe and hang anyway).

No MDM on this box (confirmed via `profiles status`), so the pin — not a signature-scoped PPPC/MDM
profile — is the durable fix available. Full incident + fix: DEC-0079 + CLD-00068; operational detail:
Agent_Workflow `README.md` §Runtime facts.

## 1. Problem

The 2026-07-07 platform change moved Cowork execution to Anthropic cloud sandboxes. Empirical findings (CLD-00061, Datapoints 3–4, 2026-07-09):

- Scheduled tasks fire as **headless cloud sessions with no device bridge** — even with the Studio desktop app open (probe trig_01F5nTd1dyjGA4ZbF2dQhGzk: fired on time, could not reach `~/Claude`; its session context carried no remote-devices connection).
- The remote scheduled-task registry contained **no EOD task**; the legacy desktop SKILL (`~/Claude/Scheduled/cowork-end-of-day-compaction/`) depends on `mcp__workspace__bash` + `mcp__session_info__*`, both **absent** from the remote environment.
- `mcp__session_info__read_transcript` — EOD's closing-turn backfill source — is **gone platform-wide**.

Net: nightly EOD compaction, and any scheduled job that must write to the Studio's canonical files, cannot run on Cowork's scheduling infrastructure. All canonical memory surfaces remain Studio-local (files-canonical, DEC-0004).

## 2. Decision (DEC-0069 summary)

Scheduled activity that reads or writes canonical files moves to **local Claude Code** — the CLI running on the Mac Studio under David's user account — launched headless (`claude -p <prompt-file>`) by **launchd**. Cloud-side scheduling remains available for self-contained cloud work only (nothing that needs the Mac).

Precedent on this machine: the graph-refresh LaunchAgent (23:25 PT, runs `refresh.py`, smoke-tests, commits corpus changes — DEC-0027/DEC-0029) and Alfred's daily-close cron. This design extends that pattern to the full nightly chain.

## 3. The nightly chain

One orchestrating wrapper (working name `cowork-nightly.sh`), launched by a single LaunchAgent at ~23:00 PT, runs stages **sequentially** — no independently-timed jobs racing each other:

```
Stage 1  EOD compaction        (claude -p, reasoning)      ~23:00
Stage 2  Transcript tooling    (scripts, deterministic)
Stage 3  Graph refresh         (existing refresh.py)
Stage 4  Git sweep + push      (claude -p, reasoning gate over deterministic git)
Stage 5  Ledger + alerting     (script)
```

Each stage writes a status line to the run ledger before the next starts; a stage failure marks the ledger and continues where safe (EOD failure does not block the sweep — commit-what-exists and flag).

**Integration note:** the existing 23:25 graph-refresh LaunchAgent already commits corpus changes. To avoid two automations committing the same repo, its refresh step is absorbed as Stage 3 and its commit step retires in favor of Stage 4. (Build Phase 0 inventories the existing agent before touching it.)

### Stage 1 — EOD compaction (Code port)

Canonical procedure stays `~/Claude/memory/processes/end-of-day-compaction.md` (updated by the build); the prompt file is a thin launcher per CLD-00046. Scope carried over intact:

- Discovery across all three transcript surfaces (`cowork/`, `code/`, `dispatch/`) via `find -newermt` on the Pacific date; exclude own session.
- True-up of today's daily log: per-chat sections, tag conventions, `[COMPLETE]`/`[DAY-COMPLETE]` idempotency, no-activity placeholder path.
- Promotion of flagged items (decisions → DEC file; `[WIKI-CANDIDATE?]` per DEC-0034; behavioral lessons routed per rule-authoring, **but rule-file changes are proposed, not applied — joint-review posture holds**).
- Action-item capture + `_index.md` reconciliation.
- Tomorrow's skeleton with Log Continuity carry-forward.
- Own transcript to `code/<session-id>.md` (one-shot variant).

**Deltas from the old process (explicit):** no `session_info` closing-turn backfill (capability gone platform-wide — `<pending>` blocks are now filled only when a source exists, see Stage 2 investigation); **no git commit inside EOD** (moved to Stage 4 by design).

### Stage 2 — Transcript tooling (deterministic, per DEC-0059 ruling b)

1. **Code-session exporter:** Claude Code stores its session records as JSONL on this machine (`~/.claude/projects/...`). A deterministic script generates/trues-up `~/Claude/transcripts/code/<UUID>.md` from them — the CLD-00040 / AFR-00004 pattern applied to Cowork-me's `code/` surface. Fully automatable; no reasoning model in the loop.
2. **Transcript-integrity lint:** sentinel turn-count continuity, header well-formedness, `<pending>` census, and daily-log-section ↔ transcript-file cross-check (both directions). Catches the CLD-00049 zero-append failure class mechanically. Output goes to the ledger + a `[COMPACTION-ISSUE]` line when violations found.
3. **One-time investigation (build Phase 0):** does the desktop app still persist any local Cowork session cache under the remote architecture (old `local-agent-mode-sessions` JSONL path, `~/Library/Application Support/Claude/...`)? If yes, a Cowork compare-and-fix becomes buildable later; if no, live-transcribe remains the only Cowork capture and its Tier-2 `<pending>` fidelity loss is accepted (DEC-0031 posture).

### Stage 3 — Graph refresh

Existing `refresh.py` + smoke test, sequenced into the chain (commit step removed — Stage 4 owns commits).

### Stage 4 — Git sweep (reviewed commits, then push + verify)

**Why Code and not a bare script:** commits are *reviewed*, not blind. For each repo, Code inspects `git status`/diff and flags anomalies before committing: unexpected mass deletions, secret-looking strings, files > threshold, changes outside expected paths. Anomaly → skip that repo, write `[SWEEP-FLAG]` to ledger, alert.

**Hard gates:** The_Wiki commits run the blocking PHI lint (`_meta/lint.py`) — lint failure blocks that commit, never bypassed. No force-push anywhere. Commit author/message discipline per DEC-0061 item 5.

**Repo roster (v1 — confirm in build Phase 0):**

| Repo | Path | In sweep? |
|---|---|---|
| cowork-memory | `~/Claude` | Yes |
| claude-ops | `~/Documents/Claude` | Yes |
| alfred-ops | `~/Documents/Alfred` | Yes (docs-only repo; David-authorized backup precedent CLD-00028) |
| alfred-evolution | `~/Documents/Projects/alfred-evolution` | Yes |
| cowork-evolution | `~/Documents/Projects/cowork-evolution` | Yes |
| The_Wiki | `~/Documents/The_Wiki` | Yes — PHI-lint gated |
| The_Library | `~/Documents/The_Library` | Yes |
| alfred-workspace | `~/.openclaw/workspace` | **No — Alfred's daily-close owns it** (boundary; avoids two automations on one repo) |

After committing: **push and verify** (`git push` + confirm remote ref advanced). The push is what makes the GitHub copy of `~/Claude` current — which unblocks git-as-transport (CLD-00061 continuity option 1) for cloud/web sessions.

**Cadence:** nightly only in v1. A midday pass is a later add if staleness demonstrably hurts.

### Stage 5 — Run ledger + alerting

- **Ledger:** `~/Claude/Scheduled/nightly/run-ledger.md` — one dated line per stage per night (`OK` / `FLAG` / `FAIL` + one-clause detail). The startup protocol can glance at it (a MEMORY.md startup-protocol amendment is *proposed* for the joint review, not applied by the build).
- **Alerting v1:** on any `FAIL`/`FLAG`, write a loud flag file (`~/Claude/Scheduled/nightly/ATTENTION-<date>.md`) that EOD/startup can't miss. **Option for David:** Telegram ping via Alfred's gateway — decide at review (keeps Alfred's runtime out of Cowork governance except as a dumb pipe; acceptable?).
- Silent failure is a design defect: every stage must write *something* to the ledger, including the wrapper itself at start/end.

## 4. Runtime facts to verify in the dry run (not assumed)

1. `claude -p` unattended: auth source, whether it prompts, which model it selects, per-run cost/usage-limit behavior.
2. launchd execution context: PATH, HOME, TCC/Full-Disk-Access for the invoked binary (see `reference/tcc-per-binary.md`), log capture.
3. Runtime ceiling and timeout behavior for a full EOD on a heavy day.
4. Concurrency: lock file so a nightly run never overlaps an interactive session's writes or a second nightly invocation.
5. Mac availability at 23:00 (Studio is always-on for Alfred; confirm no pmset sleep window).

## 5. Failure modes and stances

| Failure | Stance |
|---|---|
| EOD stage fails | Sweep still runs (commit-what-exists); `[COMPACTION-ISSUE]` in daily log + ledger FAIL + flag file |
| PHI lint blocks The_Wiki | That repo skipped; FLAG; never bypassed |
| Push fails (network/auth) | Commit stands locally; retry next night; FLAG |
| Anomalous diff | Repo skipped; FLAG with the diff summary; David reviews |
| claude -p auth expired | Wrapper detects nonzero exit fast; FAIL + flag file; nothing half-written |
| Whole chain doesn't fire | Morning startup notices ledger has no line for last night (this is why the ledger is glanceable) |

## 6. Governance and doc updates carried by the build

- **DEC-0069** records the architecture move (this doc is its design annex).
- `processes/end-of-day-compaction.md` updated for the Code environment (session_info steps removed, commit removed, discovery/tooling updated). `processes/live-transcribe.md` Storage/EOD references updated.
- `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` retired to a pointer stub (CLD-00046 thin-launcher convention; the real prompt lives with the nightly assets).
- COWORK-ARCHITECTURE.md + COWORK-ROADMAP.md notes (scheduled-automation section).
- **CLD-00051 closes** when Stage 4 is live (commit automation delivered). **CLD-00045** updates to its remote-era conclusion (EOD moved local; cross-space capture re-verified under the new EOD). **CLD-00046** gets its first applied instance.
- **Not touched by the build:** `~/Claude/memory/rules/*` and the Global Instruction / MEMORY.md startup protocol — amendments are drafted as proposals for the David+Cowork joint review (pending from 2026-07-09).

## 7. Open questions for David (settle at review or during dry run)

1. Telegram alerting via Alfred's gateway — yes/no?
2. Nightly model choice for `claude -p` (cost vs quality; EOD is judgment-light but not judgment-free).
3. Repo roster confirmation, esp. alfred-ops inclusion and alfred-workspace exclusion.
4. Ledger + assets home: `~/Claude/Scheduled/nightly/` (proposed) — or elsewhere?
5. EOD start time: 23:00 PT proposed (before the old 23:25 graph slot).

## 8. Related

CLD-00061 (platform findings; Datapoints 1–4), CLD-00045/00046/00049/00051 (folded or touched), CLD-00040 + AFR-00004 + DEC-0059 (deterministic-reconciliation precedent), DEC-0027/0029 (existing nightly LaunchAgent), DEC-0024 (git stays out of the Cowork sandbox — Code is the sanctioned actor), DEC-0031 (transcript two-tier capture), DEC-0068 (dual delivery), `reference/remote-cowork-platform.md` (platform mechanics reference created alongside this design).
