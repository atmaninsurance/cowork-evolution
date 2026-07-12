# Code Session Prompt — Night-3 Stage 5 Git-Sweep FAIL: Diagnose, Recover, Fix

**Authored:** 2026-07-12 (Cowork chat `remote_5fbe34b8-8763-5946-8a82-8d4fe5621f3f`, memory-design-action-items-review)
**Execute in:** Claude Code on the Mac Studio, David supervising
**Urgency:** yesterday's work (the `ded3b532` reconciliation session's edits + ~39 backfilled transcripts) may be uncommitted/unpushed across the roster. Also: tonight's 23:00 night-4 run will hit the same failure if the root cause isn't fixed. Fable 5 window closes tonight 11:59 PM PT.

---

## The failure (what is known)

Night-3 (2026-07-11 23:00): Stages 1–4 all OK — including the first live verification of the CLD-00063 Phase 3 changes (sentinel regex, `live-deterministic` ownership mode, backfill, FAIL-only alerting; all confirmed working). Then:

```
2026-07-11 23:05:06  4-graph-refresh   OK
2026-07-11 23:45:06  5-git-sweep       FAIL — claude -p exited 137; commits may be partial
2026-07-11 23:45:06  6-ledger-alert    OK   — ATTENTION-2026-07-11.md present (hard FAIL)
2026-07-11 23:45:06  wrapper-end       FAIL (wrapper rc=0)
```

- rc=137 at **exactly 2400s** after Stage 4 → the 40-min `run_claude` watchdog killed it (the watchdog worked; the alert worked).
- `stage5-sweep-2026-07-11.log` contains **only** `[run_claude] stage terminated rc=137 (timeout 2400s or signal)` — zero output from the `claude -p` session itself.
- **No per-repo sweep lines** in the ledger (night-2 had five).
- Night-1 precedent: Stage 2 hang from `claude -p` reading stdin under launchd (no tty) — fixed with `< /dev/null` + this watchdog. That fix IS in place, so this is either a different hang cause or the same class via a different path.
- Aggravating context: this was the **largest sweep payload yet** — the full `ded3b532` session's edits plus ~39 provenance-stamped backfilled transcripts (DEC-0075's first live backfill run also happened in Stage 1 of this same night).

## Context to load first

`~/Claude/Scheduled/nightly/`: `run-ledger.md`, `logs/run-2026-07-11.log`, `logs/stage5-sweep-2026-07-11.log`, `git-sweep-prompt.md`, `cowork-nightly.sh` (the `run_claude` wrapper + Stage 5 invocation), `README.md`. Plus daily/2026-07-11.md §Code `ded3b532` (what the sweep should have committed) and DEC-0069/0075 in COWORK-DECISIONS-2026.md.

## Part 1 — Diagnose (evidence before theory)

1. **Find the killed session's record.** Look under `~/.claude/projects/` for a session JSONL created ~23:05 PM 2026-07-11. Three tell-apart outcomes:
   - **No JSONL at all** → hung before session start (night-1 class: env/stdin/auth under launchd — but in Stage 5's specific invocation path; diff it against the working Stage 2 invocation).
   - **JSONL exists, stalled mid-work** → find the last record: was it waiting on a tool call? A permission that `bypassPermissions` doesn't cover? A git subprocess that never returned?
   - **JSONL exists, actively working when killed** → not a hang: a genuine 40-min-insufficient workload (the review-heavy Opus sweep over the largest-ever diff). Different fix class entirely.
2. **Check for classic no-tty git traps** in whatever the sweep was doing when it died: a pager (`git diff`/`log` without `--no-pager` or `GIT_PAGER=cat`), an editor spawn (`git commit` without `-m`), a credential/host-key prompt (should be SSH with known hosts — verify), `GIT_TERMINAL_PROMPT` unset, or a commit hook (the PHI-lint on The_Wiki) blocking on input.
3. **Check for kill debris:** a `git` process killed mid-operation can leave `.git/index.lock` in whatever repo it was touching — sweep every roster repo for stale lock files (this would also block tonight's run even if the root cause were fixed). Also confirm `nightly.lock` was released (wrapper-end wrote, so it should be).

## Part 2 — Recover (get yesterday backed up)

4. `git status` across the roster (`~/Claude`, `~/Documents/Claude`, `~/Documents/Projects/cowork-evolution`, `~/Documents/The_Wiki`, `~/Documents/The_Library`): determine what night-3 left uncommitted and whether anything is *partially* committed (staged-but-uncommitted, committed-but-unpushed).
5. Perform the reviewed commit + push manually per the sweep conventions: anomaly review, PHI-lint gate on The_Wiki, no force-push, push-verify against remote refs. This is the standing DEC-0024 delegation — David is present.

## Part 3 — Fix (match the fix to the diagnosis)

- Hang class → close the specific trap (env var, `--no-pager`, `-m`, hook stdin) in `git-sweep-prompt.md` / the Stage 5 invocation, same pattern as the night-1 `< /dev/null` fix.
- Workload class → don't just raise the timeout blindly: consider a per-stage `CLAUDE_TIMEOUT` override for Stage 5 sized to observed need, plus making the sweep less review-heavy (deterministic pre-checks before the model pass, or per-repo chunking so one big repo can't starve the rest).
- Either way: **improve forensics on kill** — have the watchdog dump the tail of the session JSONL (if any) into the stage log at kill time, so the next 137 isn't a zero-evidence event.
- Stale-lock guard: add a pre-sweep check that detects and reports (not auto-deletes) `.git/index.lock` in roster repos.

## Part 4 — Verify + record

6. Supervised re-run of Stage 5 standalone (David present) → clean per-repo lines. Tonight's night-4 (23:00) is the unattended confirmation; note the expectation in the ledger/daily log.
7. Resolve `ATTENTION-2026-07-11.md` per the README's convention once triaged.
8. Record: daily-log section for this session; if the root cause is structural (not a one-line trap), open a CLD action item for the remainder; run the DEC-0071 threshold test on any standing change (a per-stage timeout policy or sweep-architecture change may qualify; a pager fix does not).
9. ⛔ Final gate: David reviews the diff of tooling changes before commit; those changes ride the same manual commit as Part 2 or tonight's sweep.
