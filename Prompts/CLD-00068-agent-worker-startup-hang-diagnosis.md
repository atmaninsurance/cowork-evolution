# Diagnostic plan — Agent Workflow worker: reproducible `claude -p` silent-startup-hang

**Prompt / plan ID:** CLD-00068-agent-worker-startup-hang-diagnosis
**Action item:** CLD-00068 (intermittent `claude -p` silent-startup-hang under launchd) — this incident is its first *reproducible* context. Cross-refs: CLD-00043 / DEC-0078 (Agent Workflow Stage A), CLD-00070 (nightly Stage-4 stall — candidate same-session pickup), DEC-0069 (nightly chain), DEC-0075 (FAIL-only alerting).
**Project:** cowork-evolution  ·  **Scope:** business
**Drafted:** 2026-07-14, chat `remote_8f299444` (cowork-evolution-open-items-review)
**Mode:** David-supervised — Phases 1–2 require David at the Mac. Phase 0 is read-only and may run as an unattended Code session. ⛔ gates mark David decision points; do not proceed past a gate without his explicit go.
**Executor:** Claude Code session (interactive, David present for Phases 1–2)

---

## Incident summary (ground truth from `~/Documents/Agent_Workflow/ledger.md` + run logs)

- 2026-07-14, 12 consecutive worker runs failed with the identical signature: **exit 137 at exactly the 240s startup grace, output EMPTY, no session JSONL ever created** ("died before session start"). Both `sonnet` and `opus`.
- Drain 1 (09:43–10:07): 6 runs killed while three first-run macOS TCC dialogs sat unanswered. David answered them ~10:45: **Desktop → denied, Documents → allowed, data-from-other-apps → denied.**
- Producer requeue + David-authorized cap reset (~11:20). Drain 2 (11:26–11:50): **6 more runs, same signature** — the answered dialogs did NOT unblock the worker. 010/011/012 dead-lettered; 013 requeued in inbox with attempts=0; daily cap re-burned (6/6).
- Contrast facts: (a) the supervised dry run (~09:20–09:35) ran `claude -p` successfully in the worker pipeline (001 done in 8s); (b) the nightly chain (`com.cowork.nightly`) runs `claude -p` via the SAME shared `_lib/run_claude.sh` and generally succeeds (its 137s are intermittent — the original CLD-00068 class); (c) CLI version 2.1.209 unchanged all day (preflight seeded, dormant).

## Hypotheses (ranked)

- **H1 — TCC identity mismatch:** the dry run's successful `claude -p` executed under a different TCC identity (e.g. invoked from Terminal, which holds its own grants) than the launchd-spawned worker. The worker's launchd context never actually received usable grants — the ~10:45 answers attached to some other responsible client, or the two DENIALS (Desktop / data-from-other-apps) block something `claude` touches at startup.
- **H2 — a further, undisplayable TCC prompt:** a fourth protected resource (e.g. app-data container, Downloads, keychain-adjacent) prompts at CLI startup; launchd cannot display it; the CLI blocks silently — exactly the observed signature.
- **H3 — credential/keychain access:** headless `claude -p` needs its auth material at startup; if that path touches the macOS Keychain or a TCC-protected store under the worker's context, startup blocks before any output. (The nightly working argues against this — but verify where auth actually lives rather than assume.)
- **H4 — plist environment delta:** some env difference between `com.cowork.agent-worker` and `com.cowork.nightly` (PATH, HOME, WorkingDirectory, ProcessType, session type) changes what the CLI resolves/touches at startup.

## Phase 0 — Evidence gathering (read-only; no Mac-side changes; may run unattended)

0.1 **Reconstruct the dry run's execution context.** From the Stage-A build session record (Code `f195ecdf` transcript/JSONL if retained, `ledger.md` 09:20–09:35 lines, and the 001 run log in `logs/`): was 001 executed by a genuine launchd wake (`launchctl kickstart` / WatchPaths) or by invoking `worker.sh` from the interactive terminal? This decides whether H1 survives. Record the answer explicitly.

0.2 **Read one failing run log end-to-end** (e.g. `logs/run-010-gemini-baa-verification-a2-2026-07-14.log`): exact `claude` command line, env echoed by `run_claude`, any stderr, forensics block. Confirm output was empty from t=0 (not truncated).

0.3 **Diff the two plists** (`~/Library/LaunchAgents/com.cowork.agent-worker.plist` vs the nightly's): EnvironmentVariables (PATH, HOME), WorkingDirectory, ProcessType, StandardOut/ErrorPath, SessionCreate/LimitLoadToSessionType, and how each invokes its script (direct `bash` vs wrapper). Also diff how `worker.sh` vs `cowork-nightly.sh` construct the `claude -p` invocation beyond the shared lib.

0.4 **Locate the CLI's auth + startup file surface.** Identify where `claude` 2.1.209 stores credentials on this box (`~/.claude/`, `~/.claude.json`, Keychain?) and what it reads at startup. If feasible read-only: `log show --last 6h --predicate 'subsystem == "com.apple.TCC"'` filtered around 11:26–11:50 to see which service/client TCC denied or held prompts for during drain 2. This alone may name the blocker.

0.5 **Inventory current TCC grants** as visible without changes: System Settings → Privacy & Security → Files & Folders / Full Disk Access (David screenshot or reads aloud), noting WHICH app identity holds the Documents grant answered at 10:45 (Terminal? bash? node? claude?).

⛔ **Gate 0 (David):** review Phase-0 findings; pick the hypothesis to test first; authorize Phase 1 (needs one wake's worth of runs — decide cap handling: diagnostic runs via a David-authorized cap reset, recorded per the producer convention).

## Phase 1 — Controlled reproduction (David at the Mac, watching the screen)

1.1 **Hold the queue state:** temporarily move `013-stale-item-sweep.md` out of `inbox/` (e.g. to `logs/held/`) so the probe — not a 45-min task — is what runs. Ledger-line the hold.

1.2 **Seed a 2-minute probe prompt** into `code/inbox/` (sonnet, `timeout_minutes: 5`, `max_attempts: 1`, requested_by: david): read one file under `~/Documents/Agent_Workflow/`, one under `~/Claude/memory/`, print `DIAG_OK`. (Same shape as the CLI-preflight probe.)

1.3 **Trigger a real launchd wake** (`launchctl kickstart gui/$UID/com.cowork.agent-worker` or touch a file in inbox for WatchPaths) while: (a) David watches for any TCC dialog and photographs/notes it verbatim; (b) a terminal streams `log stream --predicate 'subsystem == "com.apple.TCC"' --style compact`. This is the money step: a live failing run + TCC stream names the blocked service and client.

1.4 **Contrast runs, same probe body:** (i) `worker.sh`-equivalent `run_claude` invocation from an interactive Terminal (Terminal's TCC identity); (ii) if (i) passes and 1.3 fails, the launchd-vs-Terminal identity split is confirmed (H1/H2); (iii) optionally kickstart the nightly's context with a trivial `claude -p` to confirm its identity holds working grants.

⛔ **Gate 1 (David):** findings name a specific blocker. Choose the fix path before anything is changed.

## Phase 2 — Fix (choose per evidence; David approves the specific change)

- **TCC path:** re-surface the prompts deliberately (`tccutil reset` scoped to the specific service + client identity, then one supervised wake, answering ALLOW where needed), or grant the correct binary (likely the node/claude executable or bash as the responsible process) Documents / Full Disk Access in System Settings. Prefer the narrowest grant that passes the probe. Record final grant state in README §Runtime facts.
- **Keychain/credential path:** move auth to the headless-safe mechanism the CLI supports; verify with the probe.
- **Env path:** align the worker plist with the nightly's known-good values; `launchctl bootout` + `bootstrap` to reload; probe again.
- **Verification:** probe passes under a genuine launchd wake (DIAG_OK in log, JSONL created, clean exit). Then restore 013 to inbox, requeue 010/011/012 per the known-cause requeue convention (cause note: "unresolved TCC/startup blocker, fixed <date> — see CLD-00068"), David-authorized cap reset, and let the drain run watched once end-to-end.

⛔ **Gate 2 (David):** approve unattended operation resuming (worker back to normal; reviewer ATTENTION from today acknowledged).

## Phase 3 — Record + hardening follow-ups

- **CLD-00068:** append the full datapoint cluster (12× reproducible, context, root cause, fix). If the root cause explains the nightly's intermittent hangs too, say so explicitly; if it closes the investigation, close the item per conventions (index update).
- **Ledger + README:** `diagnosis` / `fix` ledger lines; README §Runtime facts updated with the real TCC/grant state.
- **Hardening candidates (list, don't build unless David says):** (a) generalize the CLI-version preflight into a consecutive-137 circuit-breaker — after N straight startup-hang kills, stand down + ATTENTION instead of burning the cap (yesterday it would have saved 10 runs); (b) CLD-00070's Stage-4 timeout wrapper — same session if time allows (its step 1 stall-source read is queue-safe).
- **Daily log:** narrative line for today's diagnosis under this chat's section; no DEC expected (operational fix, not an architecture change) unless the fix changes a standing convention — flag if so.

## Constraints / timing

- Worker stand-down 22:30–00:30 PT; nightly fires 23:00 — run Phases 1–2 before ~22:00 or after tomorrow's 08:00 reviewer pass.
- Today's 16:00 reviewer pass will (correctly) raise ATTENTION for the dead-letters — expected, not a new incident.
- All git operations belong to the Code session / nightly sweep (DEC-0024); any shell blocks handed to David for pasting follow the zsh rules (no inline `#` comments, no bare globs).
- The probe and all diagnostic runs are PHI-free by construction; nothing here touches `~/.openclaw` or Alfred.
