# Prompt: Extract Vision from COWORK-ROADMAP.md

**Action item:** CLD-00014
**Project:** cowork-evolution
**Date written:** 2026-05-28
**Author:** Cowork-me
**Executor:** Claude Code
**Status:** Executed 2026-05-28

---

## Context

Per DEC-0048 (2026-05-28), every project has four standard docs: Vision, Roadmap, Architecture, Schema. COWORK-ROADMAP.md currently conflates long-term vision narrative with scope-of-work content. This prompt separates them.

## Task

1. **Read** `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md` in full.

2. **Identify vision-level content:** Long-term direction for Cowork-me, how Cowork-me fits in the broader Alfred ecosystem long-term, speculative Stage 5+ content (multi-project support, cross-actor maturity, NemoClaw), the "why Cowork-me" narrative. This content is stable direction, not scope-of-work.

3. **Create `~/Documents/Projects/cowork-evolution/COWORK-VISION.md`** with the extracted content. Format:
   - Opening paragraph: what Cowork-me ultimately is in the Alfred ecosystem
   - Long-term capability direction (narrative prose, not stage lists)
   - Brief closing pointer: "For current implementation stages and scope of work, see COWORK-ROADMAP.md."
   - No implementation state, no in-progress items

4. **Update `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md`:**
   - Remove the extracted vision narrative
   - Replace with a 1–2 sentence header: "For Cowork-me's long-term vision and direction, see COWORK-VISION.md. This document covers current and near-term implementation stages."
   - Proceed directly to stage-level content
   - No content deleted — only moved

5. **Verify:** Both files are internally consistent. No vision narrative duplicated across both. Each has a cross-reference pointer to the other.

6. **Add outcome notes** to `~/Claude/memory/action-items/CLD-00014-260528-Open.md` Notes section before closing.

## Acceptance Criteria

- `~/Documents/Projects/cowork-evolution/COWORK-VISION.md` exists and contains Cowork-me's long-term vision narrative
- `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md` opens with pointer to VISION, then stages only
- No duplication between the two files
- CLD-00014 Notes section updated with outcome

## Notes for executor

This is a content-move operation, not a rewrite. The Stage 5+ section ("Multi-project, cross-actor maturity") and any architecture-philosophy notes that speak to Cowork-me's long-term role are the primary Vision candidates. Implementation-stage content (Stages 0–4 with completed/in-progress/pending markers) stays in ROADMAP.
