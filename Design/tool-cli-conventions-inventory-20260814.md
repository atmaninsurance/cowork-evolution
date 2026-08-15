# Estate tool CLI-conventions inventory — `--help` and `--dry-run`

**Prepared:** 2026-08-14, Code session `51464878` (David-directed, this sitting)
**Trigger:** a `--help` probe of `The_Estate/_meta/lifecycle.py` ran its real pass
(four DECs auto-locked early; benign, deterministic, but unintended — the tool has
no help handling and ignores unknown arguments).
**Scope:** every `.py`/`.sh` tool in `The_Estate/_meta`, `Agent_Workflow/_meta`,
`Agent_Workflow` executor lanes (`_lib`, `code`, `designer`, `librarian`,
`venture`, `orchestrator`), `The_Wiki/_meta`, `~/Claude/Scheduled/nightly`, and
`~/Documents/Claude/graph-pilot`. Test suites (`test_*`/`test-*`) inventoried but
out of scope for the convention — running on bare invocation is their job.
**Method:** static read of each file (argument handling, `__main__` behavior,
usage/exit paths). No tool was executed. Per-file findings verified by reading
the actual arg-parsing code, not just grep hits.

## The convention being evaluated

1. `-h`/`--help` prints the tool's self-description and exits **without acting**.
2. Unknown arguments are rejected with usage (never silently ignored).
3. State-mutating tools offer `--dry-run` (or an equivalent read-only mode).

## Group A — already meet the convention (no work)

| Tool | help | dry-run | Note |
|---|---|---|---|
| `The_Estate/_meta/mint.py` | argparse | n/a | `status` subcommand is the read-only door |
| `Agent_Workflow/_meta/check_staleness.sh` | usage-on-unknown | `--dry` | model citizen |
| `Agent_Workflow/_meta/cutover-swap.sh` | bare/unknown → usage, exit 2 | preflight mode | requires explicit mode; nothing invokes it automatically |
| `Agent_Workflow/librarian/librarian-cycle.sh` | `-h/--help` | dry by default, `--live` to act | model citizen |
| `Agent_Workflow/venture/venture-wake.sh` | usage-on-unknown | `--dry` | |
| `Agent_Workflow/_lib/notify.sh` | usage-on-unknown | `--test`/`--test-count` | sourceable lib |
| `Agent_Workflow/_lib/install-claude-token.sh` | `-h/--help` | n/a | |
| `nightly/export-code-transcripts.py` | argparse | `--dry-run` | |
| `nightly/export-cowork-transcripts.py` | argparse | `--dry-run` | |
| `nightly/export-remote-transcript.py` | argparse | `--dry-run` | |
| `nightly/lint-transcripts.py` | argparse | read-mostly | |
| `nightly/triage-suspect-findings.py` | argparse | n/a | |
| `graph-pilot/battery.py` | has help | read-only | |

## Group B — safe by accident (bare/unknown prints usage, but no first-class `--help`)

Low risk today; a one-line `--help` alias makes the accident a design.

- `Agent_Workflow/_meta/oilib.py` — unknown subcommand → docstring, exit 2
- `Agent_Workflow/_meta/queuelib.py` — same pattern
- `Agent_Workflow/_meta/screen.py` — bare → docstring, exit 2 (unknown flag path unverified)
- `Agent_Workflow/_meta/promptlog.py` — <2 args → usage, exit 2
- `Agent_Workflow/_meta/designcheck.py` — flag parser; unknown-arg path should be verified at patch time
- `The_Wiki/_meta/lint.py` — read-only linter; unknown `--flags` silently ignored (violates rule 2, harmless in effect)
- `graph-pilot/query.py` — read-only

## Group C — the trap class: bare invocation ACTS, no safe `--help`

### C1. Deterministic regenerators (low harm — same output every run, but still traps)

- `The_Estate/_meta/lifecycle.py` — **the proven instance.** Runs DEC auto-lock +
  immutability check; ignores unknown args; has `--dry-run` already.
- `The_Estate/_meta/digest.py` — bare run rebuilds `DIGEST.md` for every year;
  an unknown arg is treated as a *year name* (a `--help` probe would error on a
  nonexistent directory — ugly, not harmful).
- `Agent_Workflow/_meta/reviewboard.py` — bare run regenerates `REVIEW.md` and
  runs the staleness audit; flag loop, unknown-arg path unverified.

### C2. Wake/lane scripts — bare invocation runs a full pass (by design; launchd/hooks call them bare)

A `--help` probe on any of these runs the machinery. None advertise safe help at
top level (verified for `orchestrator.sh`, whose only usage line covers
`--readjudicate` misuse; the rest need per-file verification at patch time).

- `Agent_Workflow/orchestrator/orchestrator.sh` — full orchestrator wake
- `Agent_Workflow/code/worker.sh` — claims and executes queued tasks
- `Agent_Workflow/code/reviewer.sh` — reviewer pass
- `Agent_Workflow/code/housekeeper.sh` — housekeeping pass
- `Agent_Workflow/code/auth-healthcheck.sh` — auth probe
- `Agent_Workflow/designer/designer.sh`, `designer/designdelta.sh` — designer lane
- `Agent_Workflow/_lib/run_claude.sh`, `_lib/claude_auth.sh`, `_lib/attention.sh`,
  `_lib/sync-pinned-claude.sh` — shared executor plumbing
- `nightly/cowork-nightly.sh` — **the whole nightly chain**; biggest hammer in the class
- `nightly/code-session-end-hook.sh` — takes no args at all; any invocation exports
- `graph-pilot/eod-refresh-and-commit.sh` — refreshes graph AND commits
- `graph-pilot/refresh.py`, `populate.py`, `embed.py`, `extract.py` — graph DB writes

## `--dry-run` gaps (where it would mean something)

Present already: `lifecycle.py`, `check_staleness.sh`, the three transcript
exporters, `venture-wake.sh`, `librarian-cycle.sh` (dry-by-default).
Meaningful but ABSENT — and real design work, not a doorplate:

- `worker.sh` / `orchestrator.sh` / `reviewer.sh` / `housekeeper.sh` — a
  faithful dry-run of a wake is a project, not a flag; **recommend NOT
  bolting on** in the convention pass. The test suites are the read-only view.
- `digest.py` / `reviewboard.py` — regenerators; a `--dry-run` (diff-to-stdout)
  is cheap and honest here. Worth including.
- `graph-pilot` refresh chain + `eod-refresh-and-commit.sh` — worth a look when
  graph-pilot is next touched (CLD-00030 adjacency), not urgent.
- `mint.py` — allocation is the point; `status` already covers the read-only need.

## Recommended fix pass (pending David's word; most target files are governance-gated `_meta/`)

1. **Tier 1 — the doorplate (all of Group C + polish Group B):** intercept
   `-h`/`--help` before anything else; print the existing docstring/header
   comment; exit 0. Where a flag loop already exists, make unknown args reject
   with usage instead of being ignored. No other behavior changes; bare
   invocation stays byte-identical (launchd/hook/nightly callers unaffected).
2. **Tier 2 — cheap dry-runs only:** add `--dry-run` to `digest.py` and
   `reviewboard.py` (print-would-write). Defer wake-script dry-runs explicitly.
3. **Convention:** record as a DEC + a line in `The_Estate/conventions/registry.md`
   ("tools are born with a safe help gate; mutators state their dry-run posture"),
   so future tools inherit it. Both steps gated on David's invitation.
4. **Verification bar:** after each patch, the tool's bare invocation output and
   exit code are compared against pre-patch on a fixture (or its test suite where
   one exists); `--help` provably exits before any filesystem write.

**Counts:** 13 already compliant · 7 safe-by-accident · 3 regenerator traps ·
16 wake/plumbing traps (help-gate candidates: ~26 files; dry-run additions: 2).
