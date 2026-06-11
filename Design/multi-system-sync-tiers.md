# Multi-System Memory Sync — Tier-by-Tier Rules (sketch)

**Status:** Sketch / thinking aid — 2026-06-11. **Not a committed design.** Tracking: **CLD-00041** (proposal to flesh out options).
**Context:** Sharing Cowork-me's file-based memory across ≥2 systems (e.g., Mac Studio + a laptop), each possibly running Claude desktop and/or Claude Code, possibly **concurrently**, so every system has an eventually-complete picture of activity across all of them. Substrate: the existing `cowork-memory.git` remote (files canonical, graph derived). Companion discussion: Pattern-1 (Tailscale SSH + Claude Code into the source machine) vs Pattern-2 (git-clone the memory, run the desktop on the second machine); Dropbox reserved for documents.

## Core principles
1. **Files canonical, derived rebuilt locally.** Never sync derived/binary state.
2. **Never co-edit a shared mutable file.** Append to your own per-system stream; *roll up* into shared narrative. (Converts write-conflicts into stream-merges.)
3. **Shared core + machine-local overlay.** Factor system-specific content out of shared files into per-machine, gitignored overlays.
4. **Eventual consistency, not real-time.** Each system learns the other's activity by the next sync. Real-time *coordination* (preventing both from doing the same task) is a separate, harder problem — avoid unless genuinely needed.

## The tiers

| Tier | Examples | Sync? | Rule |
|---|---|---|---|
| **1 · Capture** | transcripts, raw activity | ✅ | Per-system **append streams**; UUID/host-named → never collide. Namespace by system for clarity. Pure append, no co-edit. |
| **2 · Narrative** | daily log, `MEMORY.md`, wiki | ✅ (carefully) | The **roll-up/merge point** and the *only* real contention surface. Each system writes a **per-system** narrative; a roll-up merges into the shared view. Machine-specific lines move to Tier 5. |
| **3 · Structured records** | decisions, action-items (per-item files) | ✅ | Per-item files are append-mostly → safe. Contention is only the **shared single-files** (`_index.md`, the decisions file) and **ID allocation**. |
| **4 · Index** | graph DB, RAG embeddings | ❌ | Per-machine, **derived**, rebuilt locally from Tiers 1–3. Already gitignored. Never sync binaries. |
| **5 · Machine-local config** | paths, runtime refs, `~/.openclaw`, a `CLAUDE.local` overlay | ❌ | Per-machine, gitignored. Home for everything system-specific factored out of Tiers 2–3. |

## Sync rhythm
- **Baseline (sequential single-writer):** pull-before-start / push-when-done — extends the existing EOD job with a *pull*. One human at one machine ⇒ git fast-forwards, no conflicts.
- **Concurrent use:** more frequent pull/push (interval or event-on-write) so pictures stay close; the Tier-2 roll-up reconciles per-system narratives into the shared view.

## Contention surface (small + known)
Only **Tier-2 shared narrative**, **Tier-3 shared single-files**, and **ID allocation**. Everything else is append-safe or per-machine. Mitigations: per-system narratives + roll-up; **pull-before-create** or **per-system ID space** for IDs; rare manual merge.

## Open questions → flesh out under CLD-00041
1. Sync transport + frequency/automation (git EOD vs interval vs event-driven; vs alternatives).
2. Tier-2 **roll-up** mechanism (manual / scripted / agent; cadence; ownership).
3. **ID-collision** strategy (pull-before-create / per-system ID space / suffix).
4. **Shared-core vs machine-local split** mechanics (which files; overlay/include format; `CLAUDE.local`).
5. Conflict-resolution policy for rare Tier-2/3 collisions.
6. Whether **real-time coordination** is ever needed (and if so, lock/queue design).
7. Per-system **identity convention** (hostname tagging in transcripts / daily logs).
8. **Bootstrap portability** + path consistency across machines (`~/.claude/CLAUDE.md` @import; `~/Claude` same path).
9. Relationship to the two access patterns (SSH+Code vs git-clone-desktop) and Dropbox-for-documents.
