# Prompt: CLD-00053 Project + Scope backfill (DEC-0077)

**For:** a local Claude Code session on the Mac Studio (interactive or nightly-adjacent; David-initiated).
**Authored:** 2026-07-13, Cowork chat `remote_e98d7863` (DEC-0077 ratification session).
**Closes:** CLD-00053 (when this backfill lands and is committed by the nightly Stage-5 sweep).

## Context

DEC-0077 (2026-07-13, `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`) ratified a two-tag
convention across memory surfaces: `**Project:** <slug>` (mandatory; `Uncategorized` explicit) and
`**Scope:** business | personal`. The convention is already live for new work (docs amended same
day: MEMORY.md step 3, action-items-framework.md Step 3, live-transcribe.md header template,
end-of-day-compaction.md Steps 4c/6/7; mapping at `~/Claude/memory/context/project-scopes.md`).
This prompt executes the ratified retroactive backfill — nothing here re-opens design questions.

## Ratified backfill scope (do exactly this, no more)

1. **Action items — full backfill.** Every `.md` file in `~/Claude/memory/action-items/` (top
   level) and `~/Claude/memory/action-items/closed-items/**/` except `_index.md`:
   - Ensure a `**Project:**` frontmatter line exists. If missing, infer from the item's content
     and the project slugs in `context/project-scopes.md`; use `Uncategorized` only when nothing
     fits. Insert below `**Surfaced:**` (or below `**Status:**` if no Surfaced line).
   - Add `**Scope:** business` or `**Scope:** personal` directly below the Project line.
     Default business; personal is currently only the CLD-00050 portfolio-exploration orbit
     (check `project-scopes.md` for the live mapping). Do not change any other content.
   - `_index.md` lines do NOT carry scope — leave the index untouched except its
     `_Last updated:_` footer note recording this backfill.
2. **Decisions — DEC-0050 forward only.** In `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`,
   for entries DEC-0050 through the newest: where a `**Project:**` line exists, add a
   `**Scope:** business | personal` line directly below it (same additive-edit class as DEC-0071
   supersession tags — no other text in any entry may change). Nearly all are business; judge
   per entry with default business. Entries before DEC-0050: DO NOT TOUCH. Any prior-year
   decisions file: out of scope (none predate 2026).
3. **Do NOT touch:** daily logs (going-forward only, EOD owns the Scope line), transcripts
   (going-forward headers only), anything under `wiki/`, `~/Documents/The_Wiki/`,
   `~/Documents/The_Library/` (excluded entirely per DEC-0077 item 2).

## Ambiguity handling

Default business. If an item is genuinely ambiguous between business and personal, tag
`**Scope:** business` and append the filename to a review list you print at the end (David can
retag individually — mid-life reclassification per DEC-0077 item 3 is cheap).

## Verification + close-out

- Spot-check: every open action item file has exactly one Project and one Scope line; no
  duplicate insertions on re-run (make the edit idempotent — skip files already tagged).
- Run `python3 ~/Claude/Scheduled/nightly/lint-transcripts.py` — the action-items index drift
  check must stay clean.
- **No git** (DEC-0024/0069): leave commits to the nightly Stage-5 reviewed sweep.
- Update CLD-00053 (`~/Claude/memory/action-items/CLD-00053-260703-Open.md`): append a Progress
  bullet with counts (files tagged, inferred-project count, ambiguous list). If everything
  landed, run the Step-6 close protocol (Resolution section citing DEC-0077, rename, move to
  closed-items/2026/, remove `_index.md` line).
- Note the run in today's Pacific daily log under this session's `## Chat:` section.
