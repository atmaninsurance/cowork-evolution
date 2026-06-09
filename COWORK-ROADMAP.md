# ROADMAP — Cowork-me

## Purpose

Roadmap for Cowork-me's evolution as a collaborative design partner working with David on the alfred-evolution project. Tracks Cowork-me's own architectural progression, distinct from Alfred's roadmap. Patterns proven here may port to Alfred (see open items in operational memory at `~/Claude/projects/alfred-evolution/open-items.md`).

This roadmap focuses on Cowork-me's memory architecture, conventions, and constitutional structure. Alfred's roadmap (`~/Documents/Projects/alfred-evolution/ALFRED-ROADMAP.md`) covers the parallel work for Alfred. (Cowork-me's own roadmap is at `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md` — i.e., this file post-rename on 2026-05-05.)

*For Cowork-me's long-term vision and direction, see [COWORK-VISION.md](COWORK-VISION.md). This document covers current and near-term implementation stages.*

---

## Stages

### Stage 0 — Foundations ✓ (completed 2026-04-27)

Initial memory architecture and directory structure under `~/Claude/`.

- Two-location memory model established: auto-memory path (Cowork-internal, auto-loaded at chat start) and `~/Claude/` (David-visible working files).
- Auto-memory typed files (user, feedback, project, reference) with MEMORY.md as index.
- Initial daily log pattern adopted from AGENTS.md §II.A.1b, adapted for Cowork (chat = session, behavioral implementation since Cowork has no hooks).
- `memory-locations-reference.md` documenting both layers.
- Initial directory layout: `~/Claude/memory/`, `~/Claude/projects/<project>/`, with extensions added through Stage 1.

### Stage 1 — Memory architecture pilot 🔄 (in progress, 2026-04-28 to present)

Design and partially implement the per-agent graph DB memory layer; mitigate JSONL ephemerality; establish processes and conventions.

**Landed:**
- SQLite + sqlite-vec storage decision for graph DB pilot.
- Hybrid capture cadence: per-turn nothing real-time, per-activity inline writes when warranted, per-session compaction at user signal or schedule.
- Files canonical, graph derived. Per-node JSON file layer dropped as redundant.
- Channel = chat for Cowork; chat = session (collapsed from initial chat/session distinction).
- Buffer always written, level scales with substance — Amendment 1 pending joint review.
- Embedding model: nomic-embed-text via Ollama (tentative, formal confirmation pending).
- Cowork chat-deletion test (2026-04-30): confirmed JSONL is user-mutable / ephemeral; physical filesystem deletion when user deletes chat.
- Mitigation strategy: hybrid (per-chat transcript files via `session_info` curated layer) plus rich daily logs.
- Transcript file format locked: per-chat append-only at `~/Claude/transcripts/<chat-id>.md`, lazy creation, delta tracking by message count, source-mismatch handling, compaction-turn boundary explicit.
- `[BUFFER]` renamed to `[SUMMARY]` going forward — Amendment 3 pending.
- Open-items.md pattern: canonical current-state file with project-prefix sequential IDs (ALF-NNN), hand-off discipline with daily logs (history vs. state).
- Scratch deprecated: daily log + open-items together subsume the role; in-session evidence shows scratch was latent.
- Daily log per-chat sections.
- `~/Claude/memory/processes/` directory concept for behavioral reference docs (distinct from skills which are user-invokable capabilities).
- `~/Documents/Claude/` established as Cowork-me's project-planning home, parallel to `~/Documents/Alfred/`.

**In progress:**
- End-of-session and end-of-day compaction processes — end-of-session firmed up, end-of-day partially specified (scheduled-task trigger, dedicated maintenance chat, discovery model agreed at high level).
- Process documents to be extracted to `~/Claude/memory/processes/` once specs lock.
- `~/Documents/Claude/` git repo setup pending (ALF-018).

**Pending in Stage 1:**
- Scratch cleanup of three existing files (ALF-005) — closed 2026-05-05.
- *(ALF-016 hand-off process and ALF-012 amendments review rolled into Stage 3 documentation pass per 2026-05-07 decision.)*

### Stage 2 — Graph DB implementation ✓ (completed 2026-05-07)

Build the actual graph DB for Cowork-me, populate from existing files, automate refresh + EOD git commit/push.

**Landed (2026-05-05 → 2026-05-07):**
- Schema codified at `~/Documents/Projects/cowork-evolution/COWORK-SCHEMA.md` (DEC-0026): 11 node types + edges + 9 vec0 virtual tables (768d), two-layer provenance (graph + source), per-anchor source-hashing (DEC-0023, ALF-007).
- `.db` location locked at `~/Claude/memory/graph/cowork-me.db` (DEC-0023, ALF-008).
- Embedding model formally confirmed: nomic-embed-text via Ollama, unit-normalized → L2 ≡ cosine ranking (DEC-0023, ALF-009).
- Retrieval-at-runtime scope locked (DEC-0023, ALF-006).
- SQLite + sqlite-vec installed via Homebrew Python 3.13 venv at `graph-pilot/.venv/`.
- Pilot code at `~/Documents/Claude/graph-pilot/`: `populate.py` (canonical-file walk → all 11 node types + 6 edge types), `extract.py` (per-type anchor parsers), `embed.py` (Ollama wrapper), `edges.py` (edge inference), `query.py` (first retrieval test passes — DEC-0020 in top-3 for live-transcribe query). Steady-state corpus 170 nodes / 347 edges.
- **ALF-028 closing items (2026-05-07):** `refresh.py` (per-anchor source-hash incremental refresh), `eod-refresh-and-commit.sh` runner script, launchd LaunchAgent at 23:25 PDT for nightly graph refresh + EOD git commit+push. Cross-actor handoff documented in `~/Claude/memory/processes/end-of-day-compaction.md`. ALF-032 cleanups (LED_TO allow-list, vec-mismatch documented). DEC-0029 Stage 2 closure decision.
- **Production cadence:** Cowork EOD 23:00 PDT (narrative compaction) → LaunchAgent 23:25 PDT (graph refresh + git commit+push). Independent failure modes per DEC-0027.

### Stage 3 — Constitutional + per-actor configuration documents 📋

Cowork-me's own AGENTS.md / IDENTITY.md / SOUL.md, paralleling Alfred's per-agent constitutional structure. Plus Claude Code's per-actor configuration via `CLAUDE.md` — Stage 3 scope expanded 2026-05-06 to encompass both Cowork-me's constitutional layer and Claude Code's memory-bootstrap layer (ALF-029) as a unified architectural pass on per-actor configuration.

- AGENTS.md for Cowork-me with pointers to `processes/` files for operational detail and to open-items / amendments for evolving state.
- IDENTITY.md for Cowork-me's stable identity description.
- SOUL.md for Cowork-me's character / values description.
- Per-agent boundaries clarified vis-à-vis Alfred (Amendment 2 territory — how Cowork-me is treated in §VI/§VIII).
- **`~/Claude/CLAUDE.md`** for Claude Code's memory-bootstrap pattern in this workspace (ALF-029) *(consolidated 2026-06-07 per DEC-0054 / ALF-036 to one git-tracked file at `~/Claude/CLAUDE.md`, loaded via an `@import` stub at `~/.claude/CLAUDE.md`; was `~/Documents/Claude/CLAUDE.md`)*. Stub landed 2026-05-07 (live-transcribe section only). Hybrid style preferred at design lean — behavioral protocols inlined (live-transcribe, cross-actor scope, repo conventions); pointers to canonical files (decisions, daily logs, schemas) for task-relevance-dependent reads. May include nested CLAUDE.md files at subdirectory scope (e.g., `graph-pilot/CLAUDE.md`) layering implementation-specific norms. Four load-bearing sections added 2026-05-18 ahead of full Stage 3 pass (workspace identity + cross-actor scope, secrets prohibition, governance-file-modification rules, HIPAA boundary) per ALF-036.
- **Knowledge memory layer — per-actor wikis + shared top-level library (ALF-035, locked via DEC-0032 2026-05-18).** Adds a third memory primitive alongside graph DB and canonical files. Cowork-me wiki at preliminary `~/Claude/memory/wiki/`; Alfred wiki at preliminary `~/.openclaw/memories/wiki/` (Evaluator-owned per ALF-038); shared library at `~/Documents/Library/` for raw external sources with `.meta.yaml` provenance sidecars. Optional future global synthesis wiki deferred low-priority. Remaining design work within ALF-035: library subdirectory structure finalization, sidecar schema, ingestion process + PHI gate, INDEX.md generation, parallel amendments to REF_EVOLUTION_MEMORY + REF_MEMORY, `memory-schema.md` drafting, migration plan for existing `learnings/` + `reference/` content. Implementation execution lands in Stage 4 (per-actor wiki creation + lint scheduled task + PHI gate + Evaluator authoring scope on Alfred side).
- **Daily-log / open-items hand-off process documentation (ALF-016)** — flesh out the existing stub at `~/Claude/memory/processes/daily-log-and-open-items-handoff.md`; rolled into Stage 3 from Stage 1 carryover.
- **Joint review of proposed AGENTS.md amendments (ALF-012)** — four pending in `proposed-amendments-agents-md.md`; review alongside Cowork-me AGENTS.md drafting; rolled into Stage 3 from Stage 1 carryover.
- **ALF-031 Path 3 design** — graph DB query at runtime for memory-rule recognition. Session-loop integration design lives in Stage 3 (per ALF-031 resolution path).
- **ALF-030 axis (b)** — behavioral vs. hook-driven capture for Claude Code live-transcribe. Decide as part of CLAUDE.md flesh-out.
- Each constitutional doc derived from shared templates if those exist; otherwise drafted from Cowork-me's actual operating posture.

### Stage 4 — Port patterns to Alfred 📋

Reflect Cowork-me-pioneered patterns back into Alfred's architecture once they're stable.

- Open-items.md pattern (ALF-017).
- `processes/` directory concept.
- Hand-off discipline between daily log and open-items.
- Other patterns identified during Stages 1–3 that prove valuable.
- Each port may require an AGENTS.md amendment on Alfred's side; some may be Claude Code tasks.
- This stage is iterative — not a single push; patterns port as they prove out.

**What does NOT port to Alfred (insight surfaced 2026-05-09 architecture review; formalized as DEC-0030 on 2026-05-14):**

The macOS launchd LaunchAgent + bash runner pattern used for Cowork-me's nightly graph refresh (`~/Library/LaunchAgents/com.atman.cowork.graph-refresh.plist` invoking `~/Documents/Claude/graph-pilot/eod-refresh-and-commit.sh`) is **Cowork-sandbox-compensation scaffolding**, not a memory-architecture pattern to port. Cowork's sandbox cannot run the refresh tooling (Homebrew Python with sqlite-vec, Ollama, git+SSH per DEC-0024); the LaunchAgent is the binding layer that invokes the work outside the sandbox. Alfred has no equivalent constraint — runs in user-space, has hooks, can invoke sub-agents, runs continuously. Alfred's natural form for the same functionality is event-driven via hooks (e.g., a `PostToolUse` hook on canonical-file writes that triggers refresh) or delegated to a graph-maintenance sub-agent. Either path replaces the LaunchAgent + bash-runner binding entirely. **What ports is the *content* of the work** (refresh.py logic, gating on EOD completion, git commit+push semantics) — not the binding to launchd. The Stage 4 Alfred port should explicitly NOT recreate a LaunchAgent or equivalent on Alfred's side. The three-layer architecture model (DEC-0030) makes the underlying reasoning explicit: memory architecture (Layer 1) ports; binding layer (Layer 2) does not.

*Stage 5+ (long-term / speculative content — multi-project, cross-actor maturity, sub-agents, NemoClaw) extracted to [COWORK-VISION.md](COWORK-VISION.md) 2026-05-28 per CLD-00014 / DEC-0048.*

---

## Architecture notes

- Cowork-me is per-chat instances; Alfred runs continuously. Architectural choices reflect this distinction throughout.
- Cowork-me has no hooks; all behavior is declarative + behavioral pattern. Alfred has hooks; some processes Alfred can enforce programmatically that Cowork-me can only encourage.
- File naming convention: `COWORK-` prefix on Cowork-me planning files in `~/Documents/Claude/` to disambiguate from Alfred's same-named files in `~/Documents/Alfred/` — i.e., `COWORK-ROADMAP.md`, `COWORK-DECISIONS.md`, eventually `COWORK-CONVENTIONS.md`, `COWORK-BOOTSTRAP.md`, COWORK-REF docs. (Originally followed Alfred's exact names per 2026-04-30 decision; renamed 2026-05-05 after recurring cognitive ambiguity. See COWORK-DECISIONS.md 2026-05-05 entry.)
- *(Pilot/port-relationship bullet that lived here moved to `COWORK-VISION.md` 2026-05-28 per CLD-00014 / DEC-0048 — it spoke to Cowork-me's long-term role in the Alfred ecosystem rather than current implementation architecture.)*

---

*Last updated: 2026-05-28 — Stage 5+ section and the pilot/port-relationship architecture-note bullet extracted to `COWORK-VISION.md` per CLD-00014 / DEC-0048 (no content lost; only moved). Prior update: 2026-05-18 — `local_ac0308df` Phase 1 Stage 3 design chat expanded Stage 3 deliverables to include CLAUDE.md four-section ALF-036 addition (cross-actor scope, secrets, governance-file-modification, HIPAA boundary) and ALF-035 / DEC-0032 knowledge memory layer (per-actor wikis + shared top-level library + deferred future global wiki).*
