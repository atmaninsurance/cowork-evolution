# CLD-00075 Build Prompt — Transcript-store scoping fix + committed-noise cleanup

**Action item:** CLD-00075
**Project:** cowork-evolution
**Scope:** business
**Date written:** 2026-07-18
**Author:** Cowork-me
**Executor:** Claude Code
**Status:** Executed 2026-07-18
**Execution mode:** David-supervised session (bulk deletion of a transcript surface + git staging — do not run unattended)

---

## Context

`export-code-transcripts.py:discover_sessions()` globs `~/.claude/projects/*/*.jsonl` with no
project-dir scoping (see the item file, `~/Claude/memory/action-items/CLD-00075-260716-Open.md`,
for the full analysis). Every `claude` session spawned from a scratch/temp root therefore deposits
a permanent transcript into the git-committed `~/Claude/transcripts/code/` surface. David ratified
the fix direction 2026-07-18 (chat `remote_c99dee1d`): **(a)** deny-list ephemeral roots in the
exporter + redirect test fixtures at the source (item Options 2 + 4), and **(b)** remove the
already-committed noise from the repo.

**State as of 2026-07-18 morning (Cowork census, filename-level only):**

- ~173 `stub-*.md` files on disk in `transcripts/code/` (a ~120-file batch from the 07-16 suite
  runs and a ~53-file batch from 07-17/18). The 07-17 nightly Stage-4 sweep committed 53 stubs to
  `~/Claude` in `74bff88`; the 07-16 sweep's `498f21a` (279 files) likely committed the earlier
  batch — **verify with git, don't assume.**
- ~130 one-turn transcripts under ordinary UUID filenames, ~1.1 KB each, mtimes spaced ~10 minutes
  apart across 2026-07-16 — almost certainly the expired sampler's PONG probes. Filename carries no
  signal; these must be classified by content/source, not name.
- No `SAMPLER-*`-named files currently exist in `code/` (the item's 07-16 reference to 106 sampler
  transcripts evidently manifests as the UUID-named class above — confirm during census).
- Real user chats are interleaved throughout, including large load-bearing records
  (`ded3b532`, `f195ecdf`, `b3947f3e`, `99580b8f`, `39e396f4`, `9c8b915b`, …). Also present and
  **sanctioned**: Agent Workflow queue worker/reviewer session transcripts (DEC-0078 records them
  deliberately; they are excluded from EOD narrative, not from existence).

## Constraints (read first)

- **Census before deletion; manifest before action.** No file is deleted or `git rm`'d until it
  appears in a classification manifest David has seen in-session (⛔ gate below).
- **Never touch** hand-authored transcripts, `cowork/` `local_*`/`remote_*` files, queue
  worker/reviewer transcripts, or anything classified `real user chat`. When classification is
  uncertain, keep the file and flag it.
- **No history rewrite, no force-push, ever.** Removal is from HEAD via `git rm`; prior commits
  remain the recovery path (precedent: 010 report.md, recoverable at `0e758c0`).
- **Commits land via tonight's Stage-5 reviewed sweep** (DEC-0069): stage deletions with `git rm`
  in-session, but do not author the commit yourself unless David explicitly directs otherwise
  in-session.
- Do not modify launchd plists. Do not touch `~/.openclaw` or Alfred surfaces.
- The SessionEnd hook (`code-session-end-hook.sh`) runs this same exporter and inherits the
  `discover_sessions()` fix only if the fix lives in the shared code path — keep it there; don't
  fork logic into the hook.

## Tasks (in order)

### 1. Census + classification manifest

For every file in `~/Claude/transcripts/code/`, classify: `real-chat` / `queue-machinery
(DEC-0078, keep)` / `stub-fixture` / `sampler-probe` / `scratch-root fixture` / `uncertain (keep)`.
Use the source JSONL's project dir (`~/.claude/projects/<encoded-cwd>/`) where the JSONL still
exists (30-day retention window — most of this noise is recent, so coverage should be near-total),
and content inspection (one-turn `stub` body; PONG probe shape) where it doesn't. Record per file:
name, size, classification, evidence, git-tracked status (`git ls-files`). Write the manifest to
`~/Documents/Projects/cowork-evolution/Design/CLD-00075-cleanup-manifest-20260718.md`.

**⛔ GATE A:** show David the manifest summary (counts per class + any `uncertain`) and the exact
deletion list before proceeding.

### 2. Exporter deny-list (Option 2)

In `export-code-transcripts.py`, add a module-level `DENY_ROOT_PATTERNS` applied inside
`discover_sessions()` against the **encoded project-dir basename**, covering at minimum the
observed shapes:

- `-var-folders-*` (macOS per-user tempdirs)
- `-private-tmp-*` and `-tmp-*` (tmp roots)
- `*-scratchpad-*` (build scratchpads, e.g. the `awtest` dir)

Requirements: patterns documented inline with the CLD-00075 reference; skipped sessions are
**counted and logged** (a `skipped_denylisted: N` line in the exporter's summary output so Stage-1
logs show the filter working — never a silent drop); `--no-denylist` escape hatch flag for
debugging; deny-list applies identically via the SessionEnd hook path. Fails open by design: an
unknown new temp shape leaks (and lint catches it) rather than a real chat vanishing.

**Pattern-addition criterion (David's rule, 2026-07-18 — document this verbatim in the comment
block alongside `DENY_ROOT_PATTERNS` and in the README section):** a root may only be deny-listed
if it is ephemeral by nature AND a census shows it contains no real sessions. A stub or probe
found in a root that also holds real transcripts is NEVER grounds for a pattern addition — in a
mixed root the folder name is no longer a trustworthy proxy; fix the producer (redirect the
harness/probe per Task 3) and disposition the noise file individually instead.

### 3. Fixture-side redirect (Option 4)

Point the known fixture sources somewhere the exporter never reads: update
`~/Documents/Agent_Workflow/_meta/test_worker_timeout.sh` (and any other harness that spawns
`claude` — grep `_meta/` and `_lib/` for spawn sites) to set the session's config/project home to a
throwaway location (e.g. `CLAUDE_CONFIG_DIR` pointed at a tempdir, if verified effective — verify
empirically which env var actually relocates the JSONL for the installed CLI version; do not
assume). After the change, run the suite once and confirm **zero** new JSONLs appear under
`~/.claude/projects/` and the suite still passes (26/26 or current baseline).

### 4. Lint backstop

Add an **informational** (non-blocking) finding class to `lint-transcripts.py`: one-turn
transcripts whose body is trivial (< ~200 bytes of turn content) are reported as
`trivial-single-turn (possible fixture leak)`. Keep it informational so a legitimate tiny real chat
never blocks the chain. Also fix, if cheap: last night's false positive where `39e396f4` was
flagged "modified today not referenced in daily log" despite a `## Chat:` section under its
short ID — check whether the reference matcher requires the full UUID and make it accept the
short-ID prefix form used by daily-log headers. If not cheap, note findings in the item and leave.

### 5. Leak-to-inbox hook (standing update process)

Wire the detection loop to the orchestrator lane so a future leak becomes a work item with a
lifecycle, not just a ledger line. In the nightly wrapper (`cowork-nightly.sh`), after Stage 3:
if the lint's `trivial-single-turn` finding count is nonzero, call the shared `write_attention`
helper (`~/Documents/Agent_Workflow/`, CLD-00074 build) to write a task-shaped item to
`orchestrator/inbox/attention-YYYYMMDD-transcript-leak.md` with:

- queue frontmatter per the CLD-00074 convention, `related: CLD-00075`;
- body: the flagged file list, each file's source project dir (resolved from
  `~/.claude/projects/` while the JSONLs exist), and a concrete proposed action — a candidate
  `DENY_ROOT_PATTERNS` addition **only if** the source root satisfies the pattern-addition
  criterion above, otherwise a producer-side fix (which harness/probe to redirect);
- the helper's existing desktop notification (do not add a second notification path).

**Dedupe guard:** before writing, check `orchestrator/inbox/` (and `items/` if the CLD-00073
re-cut has landed by execution time) for an existing open `*-transcript-leak*` item; if present,
do not file a duplicate — the standing item covers subsequent nights until dispositioned.

**Autonomy boundary (do not cross):** the item PROPOSES; nothing in this hook edits the exporter,
the deny-list, or any harness. Execution of a proposed update remains human-gated (David approves
→ screened queue task or supervised session) until the CLD-00073 red-line/autonomy DEC decides
otherwise. This hook extends the ATTENTION-as-intake mechanics ratified on CLD-00073/00074 with a
new producer (the nightly lint); it introduces no new mechanism class.

### 6. Cleanup of committed + on-disk noise (b)

Per the Gate-A-approved manifest: `git rm` (tracked) / `rm` (untracked) every `stub-fixture`,
`sampler-probe`, and `scratch-root fixture` file. Leave deletions staged for tonight's Stage-5
reviewed sweep with a note in the ledger-visible place the sweep reads, unless David directs an
in-session commit. Append the final deleted-file list to the manifest.

### 7. Verification

- `python3 -m py_compile` / lint-clean on both touched Python files; `bash -n` on touched shell
  (including the wrapper's new hook).
- Exporter dry-run: skip counts present, zero noise regenerated, all real chats untouched
  (file count + spot-check mtimes unchanged for `real-chat` class).
- Test-suite run post-redirect: no new JSONLs under `~/.claude/projects/`, suite green.
- Leak-to-inbox hook dry-run: simulate a nonzero trivial-single-turn count → inbox item written
  with correct frontmatter + evidence body; run again → dedupe guard suppresses the duplicate;
  clean run → no item written.
- `git status` in `~/Claude`: staged deletions match the manifest exactly; nothing else staged.
- Nightly source-check (the chain's own preflight) clean.

### 8. Record-keeping (final step, per DEC-0046 discipline)

- CLD-00075 item file: progress entry (what shipped, counts, commit refs when known), Next-steps
  pruned; leave the item **open** pending one clean nightly (tonight's Stage 1/3/4) as production
  verification, note "close-ready on tomorrow's ledger check."
- CLD-00073 item file: one-line progress cross-ref — the nightly lint is now an ATTENTION-as-intake
  producer into `orchestrator/inbox/` (Task 5 here); intake mechanics unchanged, human gate stands
  pending the red-line/autonomy DEC.
- `~/Claude/Scheduled/nightly/README.md`: deny-list + pattern-addition criterion + leak-to-inbox
  hook documented under the exporter section.
- `processes/end-of-day-compaction.md` §Exclusions: only if you introduce any new marker
  convention (not expected under this design).
- Flip this prompt's Status to `Executed 2026-07-18`.

## Out of scope

Allow-listing real roots (item Option 1 — revisit later if the deny-list proves leaky); content
heuristics in the exporter itself (Option 3, rejected direction: judgment calls inside
deterministic tooling cut against DEC-0076); any git history rewrite; the `cowork/` surface.
