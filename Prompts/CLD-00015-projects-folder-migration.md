# Prompt: Projects Folder Migration

**Action item:** CLD-00015
**Project:** cowork-evolution
**Date written:** 2026-05-28
**Author:** Cowork-me
**Executor:** Claude Code
**Status:** Executed 2026-05-28

---

## Context

Per DEC-0050 (2026-05-28), project documentation moves from per-actor directories (`~/Documents/Alfred/`, `~/Documents/Claude/`) to a shared, actor-neutral `~/Documents/Projects/[project-slug]/` structure. This migration executes that structural change.

Full scope is in `~/Claude/memory/action-items/CLD-00015-260528-Open.md`. This prompt covers the execution steps.

## Preferred Execution Order

Run CLD-00013 and CLD-00014 first (or update them to target new paths directly), so VISION.md files are created in the right location rather than requiring a double-move.

## Task

### Step 1 — Create directory structure
```
~/Documents/Projects/
├── alfred-evolution/
│   ├── Prompts/
│   └── Design/
└── cowork-evolution/
    ├── Prompts/
    └── Design/
```

### Step 2 — Update CLD-00013 and CLD-00014 prompt files
Update both prompt files to target new paths before executing them:
- CLD-00013: change output path from `~/Documents/Alfred/ALFRED-VISION.md` → `~/Documents/Projects/alfred-evolution/ALFRED-VISION.md`
- CLD-00014: change output path from `~/Documents/Claude/COWORK-VISION.md` → `~/Documents/Projects/cowork-evolution/COWORK-VISION.md`

### Step 3 — Move alfred-evolution project docs
- `~/Documents/Alfred/ALFRED-ROADMAP.md` → `~/Documents/Projects/alfred-evolution/ALFRED-ROADMAP.md`
- `~/Documents/Alfred/ALFRED-ARCHITECTURE.md` → `~/Documents/Projects/alfred-evolution/ALFRED-ARCHITECTURE.md`
- `~/Documents/Alfred/ALFRED-SCHEMA.md` → `~/Documents/Projects/alfred-evolution/ALFRED-SCHEMA.md`
- `~/Documents/Alfred/Design/` → `~/Documents/Projects/alfred-evolution/Design/` (entire dir)
- `~/Documents/Alfred/Prompts/` → `~/Documents/Projects/alfred-evolution/Prompts/` (entire dir)
- `~/Documents/Alfred/Project-Reference/` → evaluate contents; move to `~/Documents/Projects/alfred-evolution/Project-Reference/` if project-scoped, leave in place if Alfred-operational

Also move existing top-level Alfred prompt files (pre-convention, living at `~/Documents/Alfred/*.md` that are prompts):
- `code-prompt-decisions-restructure-2026-05-27.md`, `code-prompt-openclaw-update-2026-05-21.md`, and similar → `~/Documents/Projects/alfred-evolution/Prompts/`

### Step 4 — Move cowork-evolution project docs
- `~/Documents/Claude/COWORK-ROADMAP.md` → `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md`
- `~/Documents/Claude/COWORK-SCHEMA.md` → `~/Documents/Projects/cowork-evolution/COWORK-SCHEMA.md`
- `~/Documents/Claude/Prompts/` → `~/Documents/Projects/cowork-evolution/Prompts/` (entire dir)

### Step 5 — Update cross-references
- `~/Documents/Projects/alfred-evolution/ALFRED-SCHEMA.md` — update any canonical_path entries referencing old locations
- `~/Documents/Projects/cowork-evolution/COWORK-SCHEMA.md` — same
- `~/Claude/memory/action-items/CLD-00013-260528-Open.md` — update **Prompt file:** path
- `~/Claude/memory/action-items/CLD-00014-260528-Open.md` — update **Prompt file:** path
- `~/Claude/memory/processes/prompt-lifecycle.md` — replace "pending Projects folder migration" placeholder with actual paths

### Step 6 — Backfill prompt file headers
For each prompt file in `Projects/*/Prompts/`, ensure the header has:
```
**Action item:** [ID or "pre-convention"]
**Project:** [project-slug]
**Date written:** YYYY-MM-DD
**Author:** [actor]
**Executor:** [actor]
**Status:** Pending execution | Executed YYYY-MM-DD
```
For pre-DEC-0047 prompts where execution date is unknown, use `**Status:** Executed (date unknown)` and best-effort Author/Executor from filename/content.

### Step 7 — Verify
Spot-check 3–5 cross-references. Confirm old `~/Documents/Alfred/` project doc paths no longer contain those files (the DECISIONS nav stubs, Archive, Ops, Scratch, Stages, model-eval, and graph-pilot code should remain).

### Step 8 — Add outcome notes to CLD-00015
Update `~/Claude/memory/action-items/CLD-00015-260528-Open.md` Notes section with what was moved, any disposition decisions made (especially Project-Reference), and any deviations from this plan.

## Acceptance Criteria
- `~/Documents/Projects/alfred-evolution/` and `cowork-evolution/` exist with four standard docs (plus VISION once CLD-00013/14 execute) and Prompts/ subdirs
- Old project doc paths under Alfred/ and Claude/ no longer contain those files
- COWORK-SCHEMA.md and ALFRED-SCHEMA.md canonical_path fields updated
- prompt-lifecycle.md updated
- All prompt file headers include Project, Author, Executor, Status
