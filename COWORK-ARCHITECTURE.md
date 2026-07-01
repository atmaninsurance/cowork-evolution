# ARCHITECTURE — Cowork-me

**Status:** v1 draft — 2026-05-26. Synthesizes the design decisions captured in COWORK-DECISIONS.md (DEC-0001 through DEC-0036), the data architecture in COWORK-SCHEMA.md (v2, 2026-05-26), and the stage arc in COWORK-ROADMAP.md.

**Role of this document:** the architectural-overview entry point for Cowork-me. If a new session (David in 6 months, a future chat after compaction) reads one document to understand Cowork-me's design, it should be this one. Narrative synthesis with cross-references to the detail documents — does not duplicate content.

**Parallel files within `~/Documents/Claude/`:**

- **COWORK-ROADMAP.md** — stage arc (where we're going and hope to go)
- **COWORK-DECISIONS.md** — reverse-chronological log (newest entry at top, DEC-0056) of choices with reasoning (DEC-NNNN); immutable point-in-time records, only edit = adding a `Superseded by:` tag (DEC-0057)
- **COWORK-SCHEMA.md** — graph DB data architecture (node types, edges, vector config, freshness rules)
- **COWORK-ARCHITECTURE.md** (this file) — narrative architectural overview

---

## What Cowork-me is

Cowork-me is David Brabender's AI strategic collaborator running in Cowork mode on the Claude desktop app. The role is analytical partnership — Cowork-me researches, drafts, organizes, reviews, and reasons alongside David — with all action authority remaining with David. Cowork-me is not a stateless assistant: it has durable memory that accumulates across sessions, a structured knowledge base, a graph DB that indexes its own history, and a set of canonical documents that govern how it operates.

Cowork-me is not Alfred. Alfred is a separate governed AI agent running on OpenClaw — David's operational chief-of-staff. Cowork-me is David's analytical collaborator and the design pioneer for patterns that Alfred adopts once proven stable. The two actors share no operational state; their relationship is design-level only.

---

## Core architectural principles

### 1. Files canonical, graph derived (DEC-0004)

Canonical content lives in markdown files at `~/Claude/` and `~/Documents/Claude/`. The graph DB at `~/Claude/memory/graph/cowork-me.db` is a rebuildable derived index. If the graph and the files disagree, the files win — re-extract and re-embed. Loss of the graph is recoverable; loss of canonical files is not.

### 2. Provenance over versioning (DEC-0023)

No integer schema versions on memory artifacts. Every node and edge carries `added_date`, `added_by`, `last_modified_date`, `last_modified_by`. When the schema gains new fields, old rows simply have null for them. The git history of canonical files is the version record for content; graph provenance fields are the version record for graph state.

### 3. Per-actor scope (DEC-0023)

Cowork-me's graph indexes only Cowork-me's canonical files. Paths under `~/.openclaw/` or `~/Documents/Alfred/` (Alfred's domain) are hard-excluded from every extractor. The boundary is symmetrical — Alfred does not index Cowork-me's files either. Cross-actor querying (Stage 5+) is a deliberate operation, not implicit.

### 4. PHI boundary

Atman Insurance is a HIPAA-covered entity. Cowork-me operates outside the BAA boundary. Cowork-me design artifacts contain no PHI by design — architectural and operational content only. Cross-actor file ingestion from Alfred's domain is forbidden in part to preserve this boundary structurally.

### 5. Single-surface retrieval is insufficient

No one memory surface is authoritative for all question shapes. A comprehensive lookup queries multiple surfaces in priority order: recent transcripts + daily logs (freshest, verbatim) → graph DB (structural cross-references, up to 24h stale) → wiki (durable curated knowledge, semantic) → MEMORY.md (always-true, but silent on recent events). The graph is stale for today's events; MEMORY.md is silent on recent emergent topics; wiki may not have promoted content yet; transcripts are unsearchable structurally. Each surface answers different questions.

---

## Memory architecture

### Three-tier model

| Layer | What it is | Injection pattern | Bar for entry |
|---|---|---|---|
| **MEMORY.md** | What Cowork-me always needs to consider (the handbook) | Always-injected via auto-memory | Promoted from wiki via deliberate evaluation; passes "always relevant + always true" threshold |
| **Wiki** (`~/Claude/memory/wiki/`) | Always true, durable, but on-demand (the encyclopedia) | Not injected; fetched via explicit Read or graph query when topic surfaces | Surfaced from daily log curation when synthesis-warranted |
| **Daily logs + transcripts** | Verbatim session record (the raw archive) | Not injected; read explicitly on startup or via graph retrieval | Written each session via live-transcribe + EOD compaction |

Most content never reaches wiki. Most wiki content never reaches MEMORY.md. The bars escalate; only what proves itself across sessions graduates.

### Promotion lifecycle

```
Session activity (transcripts + daily logs)
  → EOD compaction curates to [SUMMARY] / [SESSION-STATE] blocks
  → [WIKI-CANDIDATE?] markers flagged in-chat for Tier 2 evaluation
  → Tier 2 (daily, per EOD): evaluate candidates, draft/commit wiki pages
  → Tier 3 (weekly): schema lint + coverage gap detection
  → MEMORY.md promotion: David ratification required (constitutional bar)
```

In-chat, Cowork-me flags `[WIKI-CANDIDATE?]` markers only — no drafting in-chat. Tier 2 evaluation and wiki drafting happen at EOD via the EOD curation process (DEC-0034).

### Wiki structure

Five subdirectories at `~/Claude/memory/wiki/`: `concepts/`, `people/`, `entities/`, `systems/`, `sources/`. Pass E adds `projects/` for project-level notes. Each subdirectory holds `.md` pages with YAML frontmatter per `memory-schema.md`. The unified `wiki_page` node type in the graph handles all subdirs with a `subdir` discriminator — cross-subdir semantic retrieval works because content determines relevance, not directory bucket.

### Graph DB

The graph DB at `~/Claude/memory/graph/cowork-me.db` is **live and operational** as of Pass D (2026-05-19). 14 node types as of the Pass E spec. SQLite + sqlite-vec 0.1.9; Python 3.13 venv at `~/Documents/Claude/graph-pilot/.venv/`; `nomic-embed-text` via Ollama (768d, unit-normalized). Nightly LaunchAgent fires at 23:25 PDT, runs `refresh.py`, smoke-tests, and commits corpus changes to git.

Key implementation artifacts in `~/Documents/Claude/graph-pilot/`:

| File | Role |
|---|---|
| `schema.sql` | DDL source of truth — table defs, vec0 tables, indices, nodes view |
| `extract.py` | Per-node-type extractors; walks canonical files, parses anchors, computes source hashes |
| `edges.py` | Edge emission; cross-reference parsing (MENTIONS, CLOSES, LED_TO, SUPERSEDES, RELATES_TO, CITES, BLOCKS, RESOLVES) |
| `populate.py` | Clean-corpus rebuild (drops + recreates DB; use when in doubt) |
| `refresh.py` | Incremental nightly refresh (upserts changed nodes; does not drop) |
| `query.py` | Retrieval + smoke test; per-type vector search with superseded-entry annotation |
| `embed.py` | Ollama embedding calls; EMBED_MAX_CHARS=8000 cap; unit-norm assertion |
| `eod-refresh-and-commit.sh` | LaunchAgent runner; gates on [DAY-COMPLETE] in today's log before refreshing |
| `NOTES.md` | Pass-by-pass implementation observations; the running input to the schema-extension process doc |

---

## Action-items system

Action items are tracked as per-item `.md` files at `~/Claude/memory/action-items/`. Each item gets its own file that grows freely — title, description, progress notes, optional `## Resolution` section at close. The graph indexes them via the `action_item` and `resolution_note` node types (Pass E); the graph provides semantic search and cross-referencing; the files are the canonical record.

**Naming convention:**

- Open item: `CLD-XXXXX-YYMMDD-Open.md` at the folder's top level
- Closed item: `CLD-XXXXX-YYMMDD-YYMMDD.md` filed under `closed-items/YYYY/` by close date

`CLD-XXXXX` is the stable graph ID — a 5-digit prefix used by both Cowork-me and Claude Code. When an item closes and its file moves from the top level to the archive, the graph detects the rename via stable-ID prefix matching and updates in place rather than creating a duplicate.

**Index file:** `~/Claude/memory/action-items/_index.md` — open items only, one line each, updated at open/close time (behavioral rule: always updated inline when an item opens or closes; EOD reconciliation flags drift as a catch-all). Stays small for quick startup scanning without loading individual item files.

**Project wiki pages** (`~/Claude/memory/wiki/projects/`) complement action items: while action items track what needs to be done, project wiki pages capture what a project is and why it exists — goals, constraints, context, stakeholders. One wiki page per project.

**ALF-prefixed items** (Alfred-project action items) currently live in Cowork-me's folder at `~/Claude/memory/action-items/` per DEC-0040 (cross-decisions bridge decision to keep them in Cowork-me's domain until Alfred's memory infrastructure is stable). Migration to Alfred's domain (`~/.openclaw/memories/action-items/`) is deferred until Alfred's memory infrastructure lands in Stage 4.

---

## Document role map

| Document | Holds | Stable? |
|---|---|---|
| **COWORK-ARCHITECTURE.md** (this file) | Narrative architectural overview; what Cowork-me is and how the design fits together | Slow-changing; updated when architecture shifts |
| **COWORK-ROADMAP.md** | Stage arc; where we're going + deferred items | Updated as stages transition |
| **`~/Claude/memory/decisions/COWORK-DECISIONS-YYYY.md`** | Reverse-chronological log (newest entry at top, DEC-0056) of choices with reasoning (DEC-NNNN); year-based splits per DEC-0039. Moved from `~/Documents/Claude/decisions/` to `~/Claude/memory/decisions/` 2026-05-26. Top-level `~/Documents/Claude/COWORK-DECISIONS.md` is a pointer stub. | Immutable point-in-time records (DEC-0057); the only edit is adding a `Superseded by:` tag |
| **COWORK-SCHEMA.md** | Graph DB data architecture: node types, edges, vector config, freshness, population strategy | Updated when schema evolves (each Pass) |
| **`~/Claude/memory/MEMORY.md`** | Cowork-me's always-injected handbook — what's always true and always relevant | Slow-changing; David-ratified promotions only |
| **`~/Claude/memory/wiki/`** | Curated durable knowledge (encyclopedia layer) | Updated by EOD curation; slow-growing |
| **`~/Claude/memory/action-items/`** | Per-item action-item `.md` files + `_index.md` startup index | Active operational tracking |
| **`~/Claude/memory/daily/`** | Per-day session logs with [SESSION-STATE], [SUMMARY], [COMPLETE] structure | Written each session; append-only |
| **`~/Claude/transcripts/{cowork,code,dispatch}/`** | Per-chat live transcripts, one subfolder per chat surface: `cowork/local_<UUID>.md`, `code/<UUID>.md`, `dispatch/dispatch_<UUID>.md` (dispatch added 2026-07-01, DEC-0066). Edit-with-sentinel append pattern; all three walked into the graph as `transcript` rows discriminated by `surface` | Written each turn; append-only |
| **`~/Claude/memory/processes/`** | Process documentation (EOD compaction, live-transcribe, etc.) | Updated when process changes |
| **`~/Claude/memory/design/`** | Canonical architectural specs edited in-place: memory-locations-reference.md, and post-CLD-00002: COWORK-ROADMAP, COWORK-ARCHITECTURE, COWORK-SCHEMA | Slow-changing; updated when architecture shifts |
| **`~/Documents/Claude/graph-pilot/`** | Graph DB program files (schema, extractors, refresh, query) | Updated per schema extension Pass |
| **`~/Claude/memory/graph/cowork-me.db`** | Live graph DB (derived index; rebuildable from canonical files) | Refreshed nightly; never manually edited |
| **`~/Documents/cross-decisions/claude-decisions/`** | Full copies of Alfred's decisions relevant to Cowork-me; year-based files; populated by EOD review | Append-only; written by Alfred (future) |

The role distinction prevents content drift. SCHEMA stays narrow (graph DB only); DECISIONS stays chronological; ROADMAP stays forward-looking; ARCHITECTURE stays narrative. (Parallel principle in Alfred's design: ALD-0001 file role alignment.)

---

## Cross-actor relationship with Alfred

Cowork-me is David's other AI agent. The two actors share no operational state; the relationship is design-level only.

### Shared infrastructure

- **Library** (`~/Documents/Library/`) — shared cross-actor raw-sources library per DEC-0032/DEC-0036. Both actors can read and ingest sources. Per-`.meta.yaml` `ingestions:` list records which actor ingested which source.
- **Embedding model** — both actors use `nomic-embed-text` via Ollama (768d, unit-normalized) for consistency. Locked in DEC-0023 / ALD-0005.
- **Design patterns** — Alfred adopts Cowork-me's validated patterns once stable (graph DB schema, evaluation cadence, source hashing, wiki structure). Where Alfred's design diverges (e.g., A-Evaluator as a permanent sub-agent, per-agent `agent_id` discriminator), the divergence reflects Alfred's different operational shape and HIPAA context.

### Cross-decisions bridge

`~/Documents/cross-decisions/` is the deliberate exception to per-actor scope — a shared directory where each actor places full copies of decisions relevant to the other (per DEC-0040).

| Subfolder | Written by | Graphed by | Contains |
|---|---|---|---|
| `alfred-decisions/` | Cowork-me + Code (via EOD review) | Alfred | Decisions about Alfred's design made by Cowork-me/Code |
| `claude-decisions/` | Alfred (via EOD review, future) | Cowork-me | Decisions about Cowork-me's design made by Alfred |

Files are year-based (`alfred-decisions-2026.md`) created on first EOD run of the year. Full copies of decision entries — not summaries or pointers — so each actor can graph the other's decisions without accessing files outside their domain. Populated by EOD compaction review: scan new decisions added that day, append full copies of cross-actor relevant ones to the appropriate subfolder file.

### Hard boundaries

- **Cross-actor scope** (DEC-0023): Cowork-me does not index `~/.openclaw/` or `~/Documents/Alfred/`. Alfred does not index `~/Claude/` or `~/Documents/Claude/`. Extractor path roots enforce this. `~/Documents/cross-decisions/` is the explicit exception: each actor indexes only their own subfolder (`claude-decisions/` for Cowork-me; `alfred-decisions/` for Alfred).
- **Per-actor wikis** (DEC-0032): no shared wiki. Cowork-me wiki at `~/Claude/memory/wiki/`; Alfred wiki at `~/.openclaw/memories/wiki/`. Write-concurrency risk if two agents wrote to the same wiki page; per-actor scope sidesteps it.
- **HIPAA boundary**: Cowork-me operates outside the BAA boundary; Alfred operates inside it. Cowork-me design artifacts contain no PHI by design. Cross-actor file ingestion is forbidden structurally.

### Design pattern direction

Cowork-me pioneers patterns (smaller surface, faster iteration); Alfred adopts validated patterns once stable. This document encodes the current state of Cowork-me's own architecture; ALFRED-ARCHITECTURE.md encodes Alfred's.

---

## Implementation status (as of 2026-05-27)

### What's working

- ✓ **Graph DB live** at `~/Claude/memory/graph/cowork-me.db`. **14 node types shipped** (Pass D added `library_source` as #13; Pass E added `resolution_note` as #14 and renamed `open_item` → `action_item`). Nightly LaunchAgent refresh at 23:25 PDT.
- ✓ **Pass D complete** (2026-05-19): node types 1-13 populated, 329+ nodes, 800+ edges, wiki pages + library sources indexed.
- ✓ **Pass E complete** (2026-05-27 / DEC-0042): `action_item` (58 rows: 37 open + 21 closed) + `resolution_note` (21 rows) shipped; wiki `projects/` subdir + first page (`alfred-evolution.md`) live; item filenames migrated from space-separator to dash-separator (58 files renamed; `_index.md` links updated). Post-Pass-E counts: 41 decisions, 58 action_items, 21 resolution_notes, 16 wiki_pages, 1034 edges, 437 nodes total.
- ✓ **Live-transcribe protocol** operational: Edit-with-sentinel per-turn appends; EOD compaction writes [SUMMARY]/[SESSION-STATE]/[COMPLETE] to daily logs.
- ✓ **Wiki** at `~/Claude/memory/wiki/` — 6 subdirs (`concepts/`, `people/`, `entities/`, `systems/`, `sources/`, `projects/`), 16 pages, RELATES_TO edges from `see_also` frontmatter.
- ✓ **MEMORY.md** auto-injected each session with behavioral memories, feedback, project state.
- ✓ **EOD curation process** (DEC-0034): Tier 1 in-chat markers → Tier 2 daily evaluation → Tier 3 weekly lint.
- ✓ **COWORK-DECISIONS.md** DEC-0001 through DEC-0042 (Pass E and follow-on entries).
- ✓ **`~/Claude/` git-tracked** to `atmaninsurance/cowork-memory` (CLD-00002, 2026-05-26); nightly EOD commit + push via `eod-refresh-and-commit.sh`; action-items `_index.md` drift check runs after each EOD push.

### Pass E follow-ups (small, none blocking)

- **Stable-ID rename detection** in `refresh.py` is in place but not yet exercised by a real open→closed transition through the refresh path (CLD-00002 closed mid-day on 2026-05-26 but the verification used a full `populate.py` rebuild, not an incremental refresh). First real test will be the next item that closes between EOD runs.
- **Two transcript files with duplicate `## Turn N` headings** (`local_7fdc7383` turn 14; `local_d98310dd` turns 2+3) — pre-existing data debt; populate.py has a dedup guard that drops later occurrences but the source files should be cleaned up.
- **`entity/alfred-evolution-project` wiki page vs. new `project/alfred-evolution` page** — both indexed and both rank well. Consider deprecating the entity page or formally differentiating them (entity = organizational framing; project = project-narrative shape).
- **CLD-00001 body has stale `# COW-00001 ...` h1** — filename + index updated to CLD-XXXXX during the COW→CLD rename, but the page's own first heading wasn't.

### Outstanding open items (as of 2026-05-27)

Key items pending from recent design work:

- **ALF-052** — CONVENTIONS harvest pass (archived ALFRED-CONVENTIONS.md sections)
- **ALF-054** — Bootstrap Prompt 03 update for ALFRED-SCHEMA.md v1 additions
- **ALF-055** — Alfred memory directory creation tracking
- **ALF-057** — ALFRED-SCHEMA.md v1 review feedback (6 concerns for Code to address before Prompt 03)
- **DEC-0041 (still reserved)** — EOD process update for cross-decisions bridge (per DEC-0040 forward reference); Pass E used DEC-0042 to preserve this reservation.

---

## How to extend this architecture

When proposing a change:

1. **Confirm it's not already captured.** COWORK-DECISIONS.md has the chronological reasoning trail; this ARCHITECTURE document has the narrative state.
2. **Identify which document holds the change.** New schema entity → COWORK-SCHEMA.md (follow the ALF-037 8-step Pass process documented in `graph-pilot/NOTES.md`). New process or behavioral rule → COWORK-DECISIONS.md as a new DEC entry. New stage scope → COWORK-ROADMAP.md. Architectural reframing → this document.
3. **Add DEC entry first.** All architectural changes flow through a DEC entry with reasoning; SCHEMA / ARCHITECTURE updates reference the DEC.
4. **Schema extensions follow the Pass pattern.** NOTES.md documents the 8-step process established through Passes B–D. Steps: lock the design as a DEC entry → schema.sql DDL → extract.py dataclass + walker → edges.py function → populate.py + refresh.py → query.py → COWORK-SCHEMA.md update → NOTES.md observations.

---

## History

- **2026-05-26** — v1 draft written by Cowork-me. Synthesizes DEC-0001 through DEC-0036 + COWORK-SCHEMA.md v2 + graph pilot implementation through Pass D. Documents Pass E design (action_item + resolution_note + wiki projects subdir) as pending implementation.
- **2026-05-27** — Pass E shipped per DEC-0042 (Claude Code session, chat `b6bd1761-...`). Implementation status flipped from "designed but not yet built" to "What's working"; node-type count updated to 14 shipped; wiki subdir count updated from 5 to 6 (added `projects/`); added Pass E follow-ups subsection covering stable-ID rename detection first-real-test pending, two duplicate-turn-heading transcripts, and the entity-vs-project wiki overlap.
- **2026-07-01** — Dispatch adopted as a first-class transcripts surface (DEC-0066; Claude Code session, chat `f038b96b-...`). Transcripts row generalized from `cowork/` to `{cowork,code,dispatch}/`; graph walker (`extract.extract_all_transcripts`) now spans all three surfaces where it previously ingested only `cowork/` — so `code/` transcripts (30) entered the graph for the first time alongside the new `dispatch/` surface, discriminated by `transcript.surface`. Schema detail + PK-prefix-as-disambiguator rationale in COWORK-SCHEMA.md Pass G. ID-namespace collision (a Dispatch UUID matching a closed Cowork UUID) is CLD-00052 Phase 1, still open.

---

*Cross-references for the full design reasoning: COWORK-DECISIONS.md (DEC-0001 through DEC-0036 for the architectural choices captured in this document); COWORK-SCHEMA.md (data architecture detail); `~/Documents/Claude/graph-pilot/NOTES.md` (pass-by-pass implementation observations); Alfred-side parallels at `~/Documents/Projects/alfred-evolution/ALFRED-ARCHITECTURE.md` and `ALFRED-SCHEMA.md`.*
