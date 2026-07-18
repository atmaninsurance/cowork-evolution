# Prompt: Agent_Workflow folder reorg + hygiene protocol (CLD-00074 build)

**Action item:** CLD-00074
**Project:** cowork-evolution
**Date written:** 2026-07-17
**Author:** Cowork-me
**Executor:** Claude Code
**Status:** Executed 2026-07-17

---

## Context

Folder-management design session with David, 2026-07-16 (Cowork chat `remote_4cbf2cb1`). Eight changes
were ratified and captured in `~/Claude/memory/action-items/CLD-00074-260716-Open.md` — **that file is
the authoritative spec for this build; the design is decided, do not re-litigate it.** This runs as a
David-supervised session (no formal ⛔ gates — surface questions rather than guessing) because it edits
the launchd plists, which queue tasks are forbidden to touch.

## Read first, in order

1. `~/Claude/memory/action-items/CLD-00074-260716-Open.md` — the spec (§Ratified changes, items 1–8).
2. `~/Claude/memory/action-items/CLD-00073-260716-Open.md` §"Orchestrator lane mechanics" — context for
   items 6 and 8 (the orchestrator itself is NOT built in this pass; only its folder skeleton + the
   ATTENTION landing zone).
3. `~/Documents/Agent_Workflow/worker.sh` + `reviewer.sh` — current entry points (015's hardening is in).
4. `~/Documents/Agent_Workflow/_meta/` — queuelib.py, screen.py, prompt-template.md, schema.md, the two
   plists, both test suites.
5. `~/Library/LaunchAgents/com.cowork.agent-worker.plist` + `com.cowork.agent-reviewer.plist` — the LIVE
   plists (the `_meta` copies are references; keep both in sync).
6. `~/Documents/Agent_Workflow/README.md` — every section touched below gets rewritten to match.

## Task sequence

1. **Moves (git mv, history preserved):** `worker.sh` + `reviewer.sh` → `code/`; `logs/` → `code/logs/`.
   `_lib` and `_meta` do NOT move. Update: `LOGS=` in both scripts, the live plists' program paths and
   StandardOut/ErrorPath (then sync the `_meta` reference copies), `test_worker_timeout.sh`'s
   `$SRC/worker.sh` copy line, README paths. The existing `.gitignore` `logs/` pattern already matches at
   depth — verify with `git check-ignore code/logs/x` rather than assuming.
2. **Orchestrator skeleton (folders only):** `orchestrator/{inbox,evaluating,collected}/` with `.keep`
   files, plus an empty `orchestrator/routing.md` header. No orchestrator logic — the reviewer is the
   interim processor of its inbox.
3. **`related:` frontmatter field:** optional list of CLD/DEC IDs. Add to `schema.md`,
   `prompt-template.md`, and have the worker echo it into every Result block. Additive — absent field =
   no line, never an error.
4. **Result-block deletion date:** the log line becomes
   `log: code/logs/<name> (local; pruned after YYYY-MM-DD)` — computed as run date + 30 days.
5. **Retention step in the reviewer pass** (mechanical, one ledger line per sweep): delete `run-*`,
   `handoff-*`, and daily `worker-*`/`reviewer-*` logs older than 30 days; `runcount-*` older than 7
   days; truncate launchd out/err logs when large. `code/logs/hold/` is exempt; flag hold entries older
   than 30 days as still-hot-or-forgotten. Walk `*/logs/` (lane-generic), not a hardcoded path.
6. **ATTENTION reborn task-shaped:** replace both `touch_attention` implementations (worker + reviewer)
   with a shared helper that writes `orchestrator/inbox/attention-YYYYMMDD-<slug>.md` carrying queue
   frontmatter (`id`, `status: queued`, `priority: 1`, `requested_by: system/<source>`, `created`,
   `related:` where known, `source:` = failing stage/event) and the human-readable body (what broke,
   ledger lines, log pointers). The desktop notification at creation stays — it is the unconditional
   human channel. Root-level ATTENTION files are retired; delete the two stale ones (07-14, 07-15 — both
   incidents resolved; note the deletions in the ledger).
7. **Staleness watchdog:** new `_meta/check_staleness.sh` — pure bash, no LLM, seconds. Checks
   (thresholds as variables): `queued` file in any `*/inbox/` older than 3h (unclaimed despite hourly
   wakes); `orchestrator/inbox/` entry older than 24h; `*/processing/` entry with no live lock; ledger's
   last worker `wake` line older than 24h (absorbs the reviewer's silent-worker check — remove the
   duplicate there). Invoked from BOTH the reviewer pass and the nightly chain
   (`~/Claude/Scheduled/nightly/cowork-nightly.sh` — add a cheap stage/call; coordinate the edit with
   David since that file is nightly territory). Escalation = desktop notification + ledger FAIL line —
   never through the machinery being audited.
8. **Manual disposals (ask David live before deleting):** `logs/dry-run-held/` and
   `logs/pre-requeue-bak-2026-07-15/` — both look ripe (010–013 saga closed, CLD-00068 record corrected).

## Safety constraints

- If any part of this runs while the worker could wake (it wakes hourly at :15 and on inbox writes),
  use atomic replace (edit a copy, `mv` over) for `worker.sh`/`reviewer.sh` — never in-place edits —
  and do the moves between wakes or with the lock respected. Check `code/processing/` is empty first.
- Do not hand-edit `_meta/cli-version.last` (DEC-0079).
- `_lib/run_claude.sh` is shared with the nightly — this build should not need to touch it at all;
  if something seems to require it, stop and raise it with David.

## Verification (all required)

1. `bash -n` on both moved scripts, `check_staleness.sh`, and `_lib/run_claude.sh` (untouched — confirm).
2. `plutil -lint` both live plists; reload worker + reviewer (bootout/bootstrap); confirm loaded and idle.
3. `bash _meta/test_worker_timeout.sh` — must exit 0 (26/26) from the new layout; update the suite's
   paths as part of task 1, and extend it with at least: one retention assertion (an old fake log is
   pruned, a `hold/` file survives) and one task-shaped-ATTENTION assertion (a forced failure writes a
   frontmattered file into the test root's `orchestrator/inbox/`).
4. `python3 _meta/test_screen.py` still passes (schema addition must not break screening).
5. A dry staleness run against the real tree returns clean (or explains every hit).
6. Nightly compatibility: source-check `run_claude.sh` from the nightly's cwd; `bash -n` the edited
   `cowork-nightly.sh`; confirm `RUN_CLAUDE_LIB` path unchanged.
7. End-to-end smoke: drop a trivial task into `code/inbox/`, watch it claim/complete from the new
   layout, confirm its Result block shows the deletion date (and `related:` if set).

## Executor handoff duty

Append outcome notes to CLD-00074's Progress section (including David's disposal decisions and anything
deferred); flip this prompt's Status to `Executed <date>`; update README fully. The two still-open
design questions (collected/ pruning, outbox/ archiving) stay open — do not improvise solutions for them.
