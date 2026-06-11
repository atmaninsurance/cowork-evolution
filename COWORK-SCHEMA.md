# SCHEMA — Cowork-me graph DB pilot

**Status:** v2, updated 2026-05-27 to reflect implementation through Pass E (2026-05-27, shipped per DEC-0042). Graph DB live and operational. Original v1 drafted 2026-05-05.

**Pass history:** Pass A = pilot population + retrieval test (2026-05-06); Pass B = SUPERSEDES extractor + DEC-0035 (2026-05-18); Pass C = wiki_page node type + DEC-0033 (2026-05-19); Pass D = library_source node type + DEC-0036 (2026-05-19); Pass E = action_item + resolution_note + wiki projects subdir + dash filename convention (2026-05-27 / DEC-0042).

**Scope:** Cowork-me's per-agent graph DB. Indexes Cowork-me's own canonical files (`~/Claude/*` + `~/Documents/Claude/*` + `~/Documents/Projects/cowork-evolution/*`). Excludes Alfred's domain (`~/.openclaw/*`, `~/Documents/Alfred/*`, `~/Documents/Projects/alfred-evolution/*`) per cross-actor scope decision (DEC-0023). Plus shared raw sources at `~/Documents/Library/` (per DEC-0036 / Pass D — see node type 13 below). Storage at `~/Claude/memory/graph/cowork-me.db`. **14 node types shipped** (Pass D added `library_source` as #13; Pass E added `resolution_note` as #14 and renamed `open_item` → `action_item`). *Project-doc paths updated 2026-05-28 per DEC-0050 / CLD-00015.*

**Companion docs:** [DEC-0001 through DEC-0025](~/Documents/Claude/COWORK-DECISIONS.md) (nav stub → `~/Claude/memory/decisions/COWORK-DECISIONS-YYYY.md`) for chronological decision history; [COWORK-ROADMAP.md](COWORK-ROADMAP.md) Stage 2 for context.

---

## Design principles

**Files canonical, graph derived (DEC-0004).** Daily logs, transcripts, decisions, open-items, MEMORY.md, process docs, and the rest of the canonical files in `~/Claude/` and `~/Documents/Claude/` are the source of truth. The graph DB is a derived index that rebuilds from these files. If the graph and the files disagree, the files win — re-extract and re-embed.

**Provenance over versioning (DEC-0023, ALF-007).** No integer schema versions. Every node and edge carries `added_date`, `added_by`, `last_modified_date`, `last_modified_by`. When the schema gains new fields, old rows simply have null for them; queries handle nulls. When an extraction approach changes for an existing node type, new rows reflect the new approach and old rows can be re-extracted lazily.

**Per-actor scope (DEC-0023).** Cowork-me's graph indexes only Cowork-me's canonical files. Alfred has separate per-sub-agent graphs that index only his own files. Cross-actor querying (Stage 5+) is a deliberate operation, not implicit.

**Embedding for retrieval, not for everything.** The graph supports search/retrieval ("when did we decide X", "have we discussed Y") via embedding similarity. Not all node types are embedded — only those whose content benefits from semantic search. Structural nodes (Transcript metadata, Project) are not embedded.

---

## Storage model

**SQLite + sqlite-vec (DEC-0003).** Embedded, file-based, zero-ops. One `.db` file per agent. sqlite-vec provides the `vec0` virtual table type for vector storage and similarity search. Schema portable to Kuzu or Neo4j later if traversal needs grow.

**Tables:**

- One regular table per node type (e.g., `exchange`, `decision`, `action_item`).
- One `vec0` virtual table per embeddable node type (e.g., `exchange_vec`, `decision_vec`). Keyed by node id; stores only the embedding vector.
- One `edges` table holding all inter-node relationships (graph-style, normalized).
- One `project` table holding the projects index.
- A `nodes` view that UNIONs all node tables for cross-type queries.

**Embedding model (DEC-0023, ALF-009):** nomic-embed-text via Ollama. 768 dimensions, 8192-token context window, Apache 2.0. Each `vec0` virtual table is configured for 768-dimensional float vectors.

**File location:** `~/Claude/memory/graph/cowork-me.db`. Outside any git repo (binary, high-churn, no value in version control). Same parallel-structure as `~/Claude/transcripts/`.

---

## Common fields on every node

These fields appear on every node-type table and on the `edges` table.

**Graph provenance** (when this node entered the graph):
- `added_date` — TEXT, ISO 8601 timestamp
- `added_by` — TEXT, agent identifier (e.g., `cowork-me-2026-05-05`, `eod-compactor-2026-05-05`)
- `last_modified_date` — TEXT, ISO 8601 timestamp
- `last_modified_by` — TEXT, agent identifier

**Source provenance** (where this node's data came from in canonical files):
- `source_file` — TEXT, absolute path
- `source_anchor` — TEXT, location within the file (section heading, line range, turn number, etc.)
- `source_hash` — TEXT, SHA-256 hex digest of the extracted content

**Project scoping (DEC-0023, refined post-ALF-025):**
- `project_id` — TEXT, nullable. Null = cross-project (Cowork-me design / agent-level); set = project-scoped (e.g., `alfred-evolution`).

The exact nullability of `project_id` per node type is documented per node below. Source-provenance fields are always populated when the node has a canonical-file source; for derived/computed nodes they may be null.

---

## Node types

Eleven node types plus `project`, with `wiki_page` (#12) added Pass C per DEC-0033 and `library_source` (#13) added Pass D per DEC-0036. Embedded types are marked.

### 1. `exchange` (embedded)

A single user-assistant turn from a transcript. Smallest semantic unit; primary embedding target for retrieval.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `<chat_id>:<turn_number>` |
| `chat_id` | TEXT | FK → transcript.chat_id |
| `turn_number` | INTEGER | 1-indexed within the chat |
| `timestamp` | TEXT | ISO 8601, from transcript header |
| `user_text` | TEXT | verbatim user message |
| `assistant_text` | TEXT | verbatim assistant response, including tool-call blocks (DEC-0020 truncation policy applies) |
| `has_tool_calls` | INTEGER | 0/1 |
| `agent_note` | TEXT, nullable | inline `[note: ...]` block content |
| `project_id` | TEXT, nullable | inherits from transcript |
| ...common fields | | |

`exchange_vec` virtual table: keyed by `id`; stores 768-d embedding of `user_text + assistant_text + agent_note`.

**Source:** `~/Claude/transcripts/cowork/<chat-id>.md`, anchored by `## Turn N` heading.

### 2. `transcript` (not embedded)

The per-chat transcript file as a metadata unit. Aggregates Exchanges. Content lives in Exchanges; this is the file-level metadata.

| Field | Type | Notes |
|---|---|---|
| `chat_id` | TEXT PK | `local_<UUID>` |
| `chat_internal_name` | TEXT | substance-focused name from header |
| `ui_title` | TEXT, nullable | Cowork UI auto-title; backfilled by EOD true-up |
| `surface` | TEXT | `cowork`, `code`, or `chat` |
| `started_at` | TEXT | ISO 8601 |
| `last_captured_at` | TEXT | ISO 8601, updated on each turn append |
| `turn_count` | INTEGER | last_captured_turn_number |
| `project_id` | TEXT, nullable | per-chat scope (most chats today are alfred-evolution-scoped or cross-project Cowork-design) |
| ...common fields | | |

**Source:** `~/Claude/transcripts/cowork/<chat-id>.md`, anchored by file header.

### 3. `daily_log_section` (embedded)

A per-chat section within a daily log (`## Chat: <name>` block). Aggregates Activities.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `<date>:<chat_id>` |
| `date` | TEXT | YYYY-MM-DD |
| `chat_id` | TEXT | FK → transcript.chat_id |
| `session_open_ts` | TEXT, nullable | from `[SESSION-OPEN]` tag |
| `session_state_body` | TEXT, nullable | from `[SESSION-STATE]` block |
| `summary_body` | TEXT, nullable | from `[SUMMARY]` block |
| `complete_ts` | TEXT, nullable | from `[COMPLETE]` tag |
| `project_id` | TEXT, nullable | inherits from chat |
| ...common fields | | |

`daily_log_section_vec`: 768-d embedding of `summary_body` (the curated narrative).

**Source:** `~/Claude/memory/daily/<date>.md`, anchored by `## Chat: <chat-id>` heading.

### 4. `activity` (embedded)

A single tagged entry inside a DailyLogSection (e.g., `[DECISION]`, `[FINDING]`, narrative paragraph).

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `<date>:<chat_id>:<index>` |
| `daily_log_section_id` | TEXT | FK → daily_log_section.id |
| `tag` | TEXT | `DECISION`, `FINDING`, `note`, etc.; empty if untagged |
| `heading` | TEXT, nullable | the heading text after the tag |
| `body` | TEXT | content of the activity entry |
| `project_id` | TEXT, nullable | inherits from daily_log_section |
| ...common fields | | |

`activity_vec`: 768-d embedding of `tag + heading + body`.

**Source:** `~/Claude/memory/daily/<date>.md`, anchored by `### Activity` subheading + entry index.

### 5. `decision` (embedded)

A chronological entry in COWORK-DECISIONS.md.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `DEC-NNNN` (4-digit padded, per DEC-0025) |
| `date` | TEXT | YYYY-MM-DD |
| `title` | TEXT | post-date portion of `## DEC-NNNN — YYYY-MM-DD — Title` |
| `body` | TEXT | full entry content including "Why:" |
| `project_id` | TEXT, nullable | null for Cowork-me design decisions; set for project-scoped |
| ...common fields | | |

`decision_vec`: 768-d embedding of `title + body`.

**Source (primary):** `~/Claude/memory/decisions/COWORK-DECISIONS-YYYY.md` (per DEC-0039 + 2026-05-26 consolidation: decisions folder moved from `~/Documents/Claude/decisions/` to `~/Claude/memory/decisions/`). Extractor walks `~/Claude/memory/decisions/*.md` and processes all matching files. Anchored by `## DEC-NNNN` heading within each file. Top-level `~/Documents/Claude/COWORK-DECISIONS.md` is a pointer stub — excluded from extraction. **`extract.py` path updated CLD-00002 (2026-05-26):** `DECISIONS_PATH` → `DECISIONS_DIR` glob walk across populate.py, refresh.py, and extract.py CLI smoke-test.

**Source (cross-actor):** `~/Documents/cross-decisions/alfred-about-claude/ALFRED-ABOUT-CLAUDE-YYYY.md` (per DEC-0040 cross-decisions bridge; renamed 2026-05-27 per DEC-0043 — "author-about-subject" naming convention replaces the prior directional naming). Contains full copies of decisions Alfred made that are relevant to Cowork-me, appended by Alfred's compaction process. Extractor walks `~/Documents/cross-decisions/alfred-about-claude/*.md`. Anchored by the same `## ALD-NNNN` heading pattern. These are additional `decision` nodes in Cowork-me's graph — cross-actor visibility without violating per-actor scope. Note: Cowork-me does NOT index `~/Documents/cross-decisions/claude-about-alfred/` (those are Cowork-me's own decisions about Alfred, mirrored to that directory for Alfred to read — they're already in Cowork-me's graph via the primary source above).

### 6. `action_item` (embedded) — Pass E rename from `open_item`

One per-item `.md` file in `~/Claude/memory/action-items/`. Replaces the flat `open-items.md` extraction from prior passes. Migration of existing `open_item` rows (40 as of Pass D) is part of Pass E.

**Naming convention.** The filename encodes ID, created date, and status:

- Open item at top level of folder: `CLD-XXXXX-YYMMDD-Open.md` (e.g., `CLD-00001-260526-Open.md`)
- Closed item archived by closed date: `CLD-XXXXX-YYMMDD-YYMMDD.md` (e.g., `CLD-00001-260526-260531.md`), filed under `closed-items/YYYY/` [**ARCHIVE STRUCTURE UPDATE — 2026-05-26**: simplified from `YYYY/YYYY-MM/` to `closed-items/YYYY/` — per David's decision, monthly sub-directories add little value at current volume; close date determines year directory] [**NAMING UPDATE — 2026-05-27 (Pass E / DEC-0042)**: separator between stable ID and date components changed from space to dash to eliminate `%20` URL-encoding noise in markdown links and avoid bash quoting hazards.]
- ALF-prefixed items follow the same pattern in Alfred's domain (`~/.openclaw/memories/action-items/`)

**Stable ID as graph PK.** The `id` field is the stable prefix extracted from the filename (`CLD-00001`, `ALF-00040`), NOT the full filename. File path is stored in `source_file` as an updateable field. When `refresh.py` finds that a stable ID prefix maps to a different path (item closed and archived), it updates the path + status rather than creating a duplicate node. Digit padding: 5-digit IDs (`XXXXX`) for new items; existing 3-digit IDs (e.g., `ALF-040`) are padded to `ALF-00040` during Pass E migration.

**File structure.** The per-item `.md` file grows freely: title/description at the top, progress notes inline, optional `## Resolution` section at the end (anchored for `resolution_note` extraction). No size constraint. Git history of the file is the full audit trail.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | stable prefix, e.g., `CLD-00001`, `ALF-00040` |
| `category` | TEXT | `action`, `discussion`, `decision-pending`, `deferred`, `proposal` (open categories); `closed` (terminal) |
| `surfaced_date` | TEXT | YYMMDD from filename (first date component) |
| `closed_date` | TEXT, nullable | YYMMDD from filename (second date component, when present) |
| `status` | TEXT | `open` or `closed` — derived from filename (`-Open` suffix = open; two dates = closed) |
| `title` | TEXT | first `# heading` or frontmatter `title:` in the file |
| `description` | TEXT | main body content of the file (before `## Resolution` section if present) |
| `resolution_path` | TEXT, nullable | planned approach section if present in frontmatter or body |
| `project_id` | TEXT, nullable | null for top-level Cowork-me items (`CLD-XXXXX`); set per project for project-scoped items |
| ...common fields | | |

`action_item_vec`: 768-d embedding of `title + description + resolution_path` — description captures the task substance; resolution_path adds the intended approach. Closed-item resolution narrative is captured in the linked `resolution_note` node (see §6b).

**Archive structure.** Open items live at the top level of `~/Claude/memory/action-items/`. Closed items are filed into `~/Claude/memory/action-items/closed-items/YYYY/` by closed date. `refresh.py` detects renames (open → closed path change) via stable ID matching and updates in place rather than inserting a duplicate.

**Source:** `~/Claude/memory/action-items/<item-id> <created>-Open.md` (open) or `~/Claude/memory/action-items/closed-items/<YYYY>/<item-id> <created>-<closed>.md` (closed). The extractor walks both the top-level folder and the `closed-items/YYYY/` archive subdirectories.

### 6b. `resolution_note` (embedded) — Pass E new type

An optional detailed resolution record extracted from the `## Resolution` section of a per-item `.md` file. Only emitted when the `## Resolution` heading is present in the file. Captures the "what actually happened, issues encountered, how it was resolved" narrative that is too long for the `action_item` node's description field but important for future retrieval ("find items that required escalation", "what did we learn from resolving X").

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `<action_item_id>:resolution` (e.g., `CLD-00001:resolution`) |
| `action_item_id` | TEXT | FK → action_item.id |
| `body` | TEXT | full content of the `## Resolution` section |
| `resolved_date` | TEXT, nullable | date parsed from resolution section heading or frontmatter |
| `project_id` | TEXT, nullable | inherits from linked action_item |
| ...common fields | | |

`resolution_note_vec`: 768-d embedding of `body`. Enables semantic search over resolution narratives independently of item descriptions.

**Source:** Same file as the linked `action_item`; anchored by `## Resolution` heading through end of file (or next `## ` heading). If the heading is absent, no `resolution_note` row is emitted for that item — this is expected and correct for simple items closed with a one-line outcome.

### 7. `memory_entry` (embedded)

A typed file in auto-memory (user/feedback/project/reference/learning).

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `<type>:<filename>` (e.g., `feedback:feedback_live_transcribe.md`) |
| `type` | TEXT | `user`, `feedback`, `project`, `reference`, `learning` |
| `name` | TEXT | from frontmatter `name` field |
| `description` | TEXT | from frontmatter `description` field |
| `body` | TEXT | post-frontmatter content |
| `file_path` | TEXT | absolute path |
| `project_id` | TEXT, always null | agent-level; cross-project by design |
| ...common fields | | |

`memory_entry_vec`: 768-d embedding of `name + description + body`.

**Source:** `/Users/alfredassistant/Library/Application Support/Claude/local-agent-mode-sessions/.../memory/<file>.md`, one row per file.

### 8. `process` (embedded)

A process doc in `~/Claude/memory/processes/`.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | filename without extension (e.g., `live-transcribe`) |
| `name` | TEXT | from `# Process: ...` heading |
| `file_path` | TEXT | absolute path |
| `status` | TEXT | `draft`, `active`, `deprecated` (parsed from `**Status:**` line) |
| `body` | TEXT | full file content minus frontmatter |
| `project_id` | TEXT, always null | Cowork-me-internal; cross-project by design |
| ...common fields | | |

`process_vec`: 768-d embedding of `name + body`.

**Source:** `~/Claude/memory/processes/<name>.md`, one row per file.

### 9. `stage` (embedded)

A stage entry from COWORK-ROADMAP.md.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `stage-N` |
| `stage_number` | INTEGER | 0, 1, 2, ... |
| `name` | TEXT | stage name from heading |
| `status` | TEXT | `complete`, `in-progress`, `planned`, `speculative` |
| `body` | TEXT | full stage section content |
| `project_id` | TEXT, always null | Cowork-me-internal; cross-project by design |
| ...common fields | | |

`stage_vec`: 768-d embedding of `name + body`.

**Source:** `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md`, anchored by `### Stage N` heading. *Path updated 2026-05-28 per DEC-0050 / CLD-00015.*

### 10. `amendment` (embedded)

A proposed AGENTS.md amendment from `~/Claude/memory/proposed-amendments-agents-md.md`.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `AMEND-N` |
| `number` | INTEGER | 1, 2, 3, ... |
| `title` | TEXT | amendment title |
| `body` | TEXT | full amendment content |
| `status` | TEXT | `pending`, `approved`, `rejected` |
| `surfaced_date` | TEXT | YYYY-MM-DD |
| `project_id` | TEXT, always null | constitutional; cross-project by design |
| ...common fields | | |

`amendment_vec`: 768-d embedding of `title + body`.

**Source:** ~~`~/Claude/memory/proposed-amendments-agents-md.md`~~ — **Deprecated 2026-05-26**: source file moved to `_deprecated/`; amendment text folded into ALF-012 for Stage 3 joint review. This node type currently has no active source file. When the Stage 3 joint AGENTS.md review produces formal amendments, the source anchor will need to be updated. Pending Pass E rework or formal deprecation of the node type.

### 11. `project` (not embedded)

The projects index. Pilot has one entry; multi-project future has more.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | `alfred-evolution`, `claude-evolution`, etc. |
| `name` | TEXT | human-readable project name |
| `path` | TEXT | filesystem location of project work |
| `started_date` | TEXT | YYYY-MM-DD when project began |
| ...common fields | | |

**Source:** Eventually `~/Claude/memory/projects-index.md` (per ROADMAP Stage 5+ anticipation). At pilot: hardcoded single row for `alfred-evolution`.

### 12. `wiki_page` (embedded)

The curated knowledge-memory primitive from DEC-0032/DEC-0033. One unified node type spanning all five wiki subdirectories with `subdir` as a discriminator column rather than five separate node types. Per DEC-0033: vector accuracy is content-determined not type-determined; cross-subdir retrieval is the dominant synthesis-query pattern; schema-extension cost compounds linearly with type count per ALF-037 so unified-with-discriminator is the right shape.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | compound `<subdir>/<slug>` (e.g., `concept/three-layer-architecture`) |
| `slug` | TEXT | filename without `.md`; unique within a subdir but `see_also` / `supersedes` references use the bare slug across subdirs |
| `subdir` | TEXT | one of `{concept, person, entity, system, source, project}` — `project` added Pass E for project-level notes wiki pages |
| `title` | TEXT | from frontmatter `title:` (required) |
| `type` | TEXT | from frontmatter `type:` — should match `subdir` semantically; stored separately for lint-checkability |
| `created` | TEXT | YYYY-MM-DD from frontmatter (required) |
| `updated` | TEXT | YYYY-MM-DD from frontmatter (required); freshness signal |
| `tags` | TEXT | JSON array string from frontmatter `tags:` |
| `aliases` | TEXT, nullable | JSON array string from frontmatter `aliases:` |
| `see_also` | TEXT, nullable | JSON array string from frontmatter; drives `RELATES_TO` edges |
| `supersedes` | TEXT, nullable | JSON array string from frontmatter; drives `SUPERSEDES` edges |
| `authors` | TEXT, nullable | JSON array, sources-subdir only |
| `source_url` | TEXT, nullable | sources-subdir only |
| `source_date` | TEXT, nullable | sources-subdir only |
| `retrieved_date` | TEXT, nullable | sources-subdir only |
| `credibility` | TEXT, nullable | sources-subdir only (`high` / `medium` / `low`) |
| `body` | TEXT | post-frontmatter content of the page |
| `project_id` | TEXT, always null | Cowork-me-internal; cross-project by design |
| ...common fields | | |

`wiki_page_vec`: 768-d embedding of `title + "\n" + structured frontmatter line(s) + "\n" + body` via nomic-embed-text. Combined-text-input pattern per DEC-0033 captures both the semantic gist (title + body) and the categorical signals (subdir, type, tags, aliases, see_also) so callers can disambiguate by content + by category. **Section-splitting for >8K-token pages:** none of the 13 current wiki pages approach that threshold, so the existing `EMBED_MAX_CHARS = 8000` truncation cap in `populate.py:_embed_into` (and `refresh.py:_upsert_vec`) is the operational fallback today; a `## ` heading split-and-embed should be added if/when a real wiki page first exceeds the threshold. Tracked as a TODO inline in `populate.py:_wiki_embed_input`.

**Source:** `~/Claude/memory/wiki/<subdir>/<slug>.md` across the six subdirectories listed above. **`~/Claude/memory/wiki/memory-schema.md` is the wiki's schema file (its CLAUDE.md equivalent), not a content page — excluded from indexing.** No other exclusions; future per-page exemption would surface through `memory-schema.md` lint rules.

**`projects/` subdir (Pass E).** Added to support project-level notes wiki pages. Each project gets one wiki page at `~/Claude/memory/wiki/projects/<project-slug>.md` capturing project context, goals, and running notes — the "what is this project and why does it exist" narrative (distinct from action-items tracking). `memory-schema.md` needs a `project` type entry added per Pass E. The `projects/` subdir name maps to `subdir = 'project'` (singular, matching the other subdir-name→value convention).

**Edge mappings from `wiki_page` nodes:**

- `see_also` slugs → `RELATES_TO` edges. Direction: from this page → target page. Target resolved by unique slug lookup across all subdirs (slug collisions across subdirs are ambiguous and warn-skip; the current corpus has zero collisions). Forward references (target not yet in DB) are warn-and-skipped at edge-emission time without breaking the build.
- `supersedes` slugs → `SUPERSEDES` edges. Same direction convention as DEC-0035 (newer page does the superseding, edge points at the older target). Edge properties include `superseded_date` (the superseding page's `updated` frontmatter date) and `source: "supersedes_frontmatter"`.
- `CITES` edges for `sources/` pages → `library_source` nodes: **deferred pending library landing (ALF-035 item (b)).** Library node type not yet defined; emission will land once the library tree + `library_source` node type are in place. Noted here so the integration point is explicit, not implementation-debt-hidden.

**Per-node-type freshness rule (extending the table in the SUPERSEDES section below):**

- `wiki_page` nodes: updated in-place; only current file content counts (`updated` frontmatter field is the freshness signal). No SUPERSEDES edges between successive versions of the same page — edits overwrite in place and git history is the version record. When a wiki page genuinely supersedes another page (a later, more accurate page on the same topic), the `supersedes:` frontmatter field on the newer page carries that relationship and produces a SUPERSEDES edge per DEC-0033.

### 13. `library_source` (embedded)

The shared raw-sources half of the knowledge memory primitive from DEC-0036. One unified node type spanning all six library subdirectories with `subdir` as a discriminator column (same pattern as `wiki_page` per DEC-0033). Sidecar-driven: the `.meta.yaml` companion file is the canonical anchor — one row per sidecar; the document file itself feeds the embedding body excerpt but does not anchor the node.

**Path note:** DEC-0036 was initially drafted with the library at a lowercase `library/` top-level under home, but on macOS APFS volumes the filesystem is case-insensitive — a bare home-level `library/` directory collides with the system `~/Library/` directory. The library lives at `~/Documents/Library/` instead, parallel to `~/Documents/Claude/` (Cowork-me) and `~/Documents/Alfred/` (Alfred), preserving the "shared top-level outside any single actor's tree" design intent. DEC-0036 text may be amended at David's discretion; the implementation uses the corrected path.

| Field | Type | Notes |
|---|---|---|
| `id` | TEXT PK | compound `<subdir>/<slug>` (e.g., `article/karpathy-llm-wiki-gist-20260516`) |
| `slug` | TEXT | filename of the sidecar without the `.meta.yaml` suffix (e.g., `karpathy-llm-wiki-gist-20260516`) |
| `subdir` | TEXT | one of `{article, paper, book, transcript, document, media}` |
| `title` | TEXT | from sidecar `title:` (required) |
| `retrieved_date` | TEXT | YYYY-MM-DD from sidecar (required) |
| `retrieved_by` | TEXT | `cowork-me`, `alfred`, or `david` (required) |
| `source_url` | TEXT, nullable | from sidecar `source_url:` |
| `source_date` | TEXT, nullable | original publication date |
| `authors` | TEXT, nullable | JSON array string from sidecar `authors:` |
| `publisher` | TEXT, nullable | |
| `license` | TEXT, nullable | |
| `language` | TEXT, nullable | defaults to `en` if absent in sidecar |
| `content_hash` | TEXT | SHA-256 of the source file (required) |
| `supersedes` | TEXT, nullable | bare slug of older version this replaces; drives `SUPERSEDES` edge |
| `phi_gate_result` | TEXT, nullable | `pass` or `pending` — lifted from sidecar `phi_gate.result` |
| `file_path` | TEXT | absolute path to the companion source file (sidecar path if no companion found) |
| `file_ext` | TEXT | `.md`, `.pdf`, `.epub`, etc.; empty when no companion file |
| `project_id` | TEXT, always null | cross-project by design (library is shared between actors) |
| ...common fields | | |

`library_source_vec`: 768-d embedding of `title + authors + source_date + subdir + body_excerpt` via nomic-embed-text. Body excerpt is the first ~6000 chars of readable content extracted from the companion file. Format support:

- `.md` / `.txt` / `.markdown`: direct read, head-truncated at 6000 chars.
- `.pdf`: best-effort via `pdfplumber` or `pypdf` if either is in the venv; fall back to empty body excerpt (title + metadata only) if neither is available or extraction fails. Logged at INFO level when fallback fires.
- `.epub`: best-effort via `ebooklib` if in the venv; fall back to empty otherwise.
- `.mp4` / `.mp3` / `.jpg` / other media: no text extraction; empty body excerpt (title + metadata only).

The venv on this machine at Pass D landing time has none of `pdfplumber` / `pypdf` / `ebooklib` installed — first real PDF/EPUB ingestion will hit the INFO-logged fallback path until a future pass adds extraction dependencies (intentionally out of Pass D scope per the prompt's "don't add new pip deps" constraint).

**Source anchor convention:** `library:<subdir>:<slug>` (mirrors `wiki:<subdir>:<slug>` from Pass C).

**Hashing:** `source_hash` covers sidecar text + body excerpt joined by a sentinel — swapping the companion file with the same sidecar invalidates the row and triggers re-embedding on refresh.

**Edge mappings from `library_source` nodes:**

- `supersedes` field → `SUPERSEDES` edge (`library_source → library_source`). Same direction convention as DEC-0035 (newer page does the superseding, edge points at the older target). Properties: `{"superseded_date": retrieved_date_of_this_row, "source": "sidecar_supersedes_field"}`. Unknown target slugs warn-and-skip via the `lib_supersedes_unknown` collector — surfaces a `SUPERSEDES [WARN]` line on the build summary.
- Incoming `CITES` edges from `wiki_page` nodes where `subdir='source'` — activated Pass D. Resolution: slug-prefix match (wiki source slug `foo-bar` matches library slug `foo-bar-YYYYMMDD`), with source_url equality as a fallback. Superseded library sources are excluded from CITES targets when a non-superseded match exists. No match → silent skip (correct on the empty-library first-run case); collected in `lib_cites_unmatched` for an INFO line on the build summary.

**Per-node-type freshness rule:**

- `library_source` nodes: sources themselves are immutable once ingested (per DEC-0036). The sidecar grows over time (append-only `ingestions:` list), and the source-hash extractor re-extracts when either the sidecar or body excerpt changes — so sidecar edits (a new ingestion entry, a sharpened title) invalidate and refresh the row. The `supersedes:` field on a newer version drives a SUPERSEDES edge to the older entry; both rows remain in the graph (mirrors the decision freshness rule from DEC-0035). The `phi_gate_result = pending` state is allowable in-graph but real ingestion workflows should not let `pending` rows surface to retrieval until the gate passes; gate-mechanism enforcement is deferred to a future DEC.

**Format note on tree visibility:** Each of the six subdirs contains a `.gitkeep` file so the empty tree is visible to filesystem walks; the extractor skips them. The library tree itself is **outside** the `atmaninsurance/claude-evolution` git repo (which is `~/Documents/Claude/`) — source content is intentionally not git-tracked at this stage.

---

## Edges

A single normalized table holds all inter-node relationships. Lets us add edge types without DDL changes.

| Field | Type | Notes |
|---|---|---|
| `from_node_type` | TEXT | e.g., `exchange`, `decision` |
| `from_node_id` | TEXT | id of the source node |
| `edge_type` | TEXT | semantic relationship name |
| `to_node_type` | TEXT | e.g., `open_item`, `decision` |
| `to_node_id` | TEXT | id of the target node |
| `properties` | TEXT (JSON), nullable | edge-specific metadata |
| ...common fields | | (graph + source provenance per edge) |

Primary key: `(from_node_type, from_node_id, edge_type, to_node_type, to_node_id)`.

### Initial edge types

Implement only what's needed for known retrieval queries. Add more as queries demand them.

| Edge type | From | To | Semantics |
|---|---|---|---|
| `BELONGS_TO` | exchange | transcript | turn → its transcript |
| `BELONGS_TO` | activity | daily_log_section | activity → its daily log section |
| `BELONGS_TO` | daily_log_section | transcript | section → the chat it summarizes |
| `MENTIONS` | exchange | action_item | exchange text references an `<PREFIX>-NNN` |
| `MENTIONS` | exchange | decision | exchange text references a `DEC-NNNN` |
| `LED_TO` | activity | decision | a tagged DECISION activity produced a Decision entry |
| `CLOSES` | decision | action_item | a Decision closed an action item (e.g., DEC-0023 closes ALF-006/007/008/009) |
| `SUPERSEDES` | decision | decision | one decision revises another (e.g., DEC-0025 supersedes DEC-0024 on file naming) |
| `SUPERSEDES` | wiki_page | wiki_page | one wiki page supersedes another via `supersedes:` frontmatter (DEC-0033) |
| `RELATES_TO` | action_item | action_item | cross-references between items (e.g., ALF-00021 relates to ALF-00002) |
| `RELATES_TO` | wiki_page | wiki_page | wiki pages cross-reference via `see_also:` frontmatter (DEC-0033) |
| `CITES` | wiki_page | library_source | `sources/` wiki page → raw library source. Stubbed Pass C; **activated Pass D** per DEC-0036. Resolution: slug-prefix match (`foo-bar` matches `foo-bar-YYYYMMDD`) with `source_url` equality as fallback. |
| `BELONGS_TO` | action_item | project | project-scoped item → its project |
| `BELONGS_TO` | resolution_note | action_item | resolution note → its parent action item |
| `REFERENCES` | process | decision | process docs cite decision rationale |
| `TRIGGERED_BY` | memory_entry | decision | feedback memory created by a decision |
| `CONTAINS` | stage | action_item | stage scope includes specific items |
| `BLOCKS` | action_item | action_item | item cannot proceed until blocking item resolves (e.g., ALF-00054 blocks ALF-00003) |
| `RESOLVES` | action_item | action_item | completing this item resolves or unblocks another (inverse of BLOCKS; emitted at closure) |
| `REFERENCES` | action_item | decision | item cites a specific decision as context or constraint |

`properties` JSON examples: for `MENTIONS`, `{"context": "...","citation_form": "DEC-0014"}`; for `CLOSES`, `{"closure_kind": "block"}` if a single decision closes multiple items.

### SUPERSEDES syntactic convention + retrieval behavior + freshness rules

The `SUPERSEDES` edge has the longest gap between schema-codification (DEC-0026, 2026-05-05) and extractor support (DEC-0035, 2026-05-18). The codification defined the relationship but no canonical source-file signal existed — verb-form parsing ("supersedes DEC-NNNN") was tried and produced zero matches because nobody writes that way in practice. DEC-0035 settled on a structured marker form and pinned the retrieval-side default behavior at the same time.

**1. Syntactic convention.** DEC entries that revise an earlier DEC entry get an explicit line in the body, typically near the top after the title and before the explanatory paragraphs:

```
**Supersedes:** DEC-NNNN
```

Multiple supersessions: `**Supersedes:** DEC-NNNN, DEC-MMMM`. The extractor reads this exact marker form (whitespace around commas tolerated; optional trailing period) as the canonical signal for `SUPERSEDES` edge emission. **Scope: DEC entries + wiki pages + library sources.** DEC entries use the `**Supersedes:**` body marker described above. Wiki pages (added Pass C, DEC-0033) use a `supersedes:` frontmatter list of bare slugs: `supersedes: [older-slug-one, older-slug-two]`; the wiki extractor reads the frontmatter list and `edges.py` emits SUPERSEDES edges with the same direction convention (newer → older). Library sources (added Pass D, DEC-0036) use a `supersedes:` scalar (single bare slug) inside the `.meta.yaml` sidecar; same direction convention (newer → older). Other source types (auto-memory typed files, process docs) may extend the convention later as patterns surface — when they do, the convention extends and the extractor for that type adds the parse.

**Decision immutability + bidirectional tags (DEC-0057).** A `decision` record is an immutable point-in-time artifact: once written, its content is not edited — the *only* sanctioned edit is adding the supersession tag. Supersession is recorded in **both** directions: the newer entry carries `**Supersedes:** DEC-NNNN` (the marker the extractor reads for edge emission, above), **and** the older, superseded entry gets a `**Superseded by:** DEC-MMMM` back-link added. Per-anchor hashing re-extracts just that one entry on the next refresh, so the back-link edit is index-safe (the `SUPERSEDES` edge is still emitted from the newer entry's `**Supersedes:**` marker, not the back-link). Superseded decisions are never removed — they remain in the file and the graph permanently as history; decision files are ordered newest-at-top per DEC-0056. Discovery of relevant priors is a graph/RAG job, not a hand-maintained index (CLD-00037). This immutability applies to `decision` nodes; `wiki_page` nodes use the update-in-place model below.

**2. Retrieval default behavior: return all + annotate.** When `query.py` returns decisions that have incoming `SUPERSEDES` edges (i.e., they've been superseded by later entries), the result row carries `superseded_by` (the most-recent successor's id, by date then id) + `superseded_by_date`. Default behavior is to return all results — both superseded and current — with the annotation so the caller can decide how to use them. This preserves history-aware reasoning ("we changed our mind on this 2026-05-18") at the cost of larger result sets. A future filter flag for "current-state-only" can be added if call patterns make filtering at the SQL layer cheaper than at the caller layer. Annotate-not-drop is the lossless default; the agent reading retrieval results can use only the current entry when asking "what's the current decision on X", use the history chain when asking "how did our thinking on X evolve", or surface superseded entries with explicit framing.

**3. Lightweight per-node-type freshness rules.** Different node types have different "freshness" semantics — the `SUPERSEDES` edge alone doesn't capture all of them:

- `decision` nodes: supersede via `SUPERSEDES` edges per part 1. The successor is the current truth; superseded entries remain in the graph but get the annotation per part 2.
- `open_item` nodes: use the `CLOSES` edge type (already in the schema). Closed open-items are not "superseded" — their lifecycle is different. Retrieval should generally exclude closed items from "current state" queries unless explicitly asked.
- `daily_log_section` and `activity` nodes: append-only history; never supersede each other. Retrieval may weight recent over distant for "current state" queries while preserving older for historical lookups.
- `memory_entry` (auto-memory typed files) nodes: supersede via file edits + `last_modified_date`; only the current file content counts (older versions live in git history, not the graph). No `SUPERSEDES` edge emitted between memory_entry versions.
- `exchange` (transcript turns) nodes: append-only within a chat; per-chat closure via `[COMPLETE]` tag. No supersession between exchanges.
- `process` nodes: like memory_entry — only current content counts; older versions live in git.
- `wiki_page` nodes: updated in-place; only current file content counts (`updated` frontmatter field is the freshness signal). No SUPERSEDES edges between successive versions of the same page — edits overwrite in place; git history is the version record. When a wiki page genuinely supersedes another page (a later, more accurate page on the same topic, e.g., consolidating two earlier `concepts/` pages into one), the `supersedes:` frontmatter field on the newer page carries that relationship and produces a SUPERSEDES edge per DEC-0033.
- `library_source` nodes: source files are immutable once ingested per DEC-0036. The sidecar grows over time via append-only `ingestions:` entries; the `source_hash` covers sidecar + body excerpt so sidecar edits invalidate and refresh. A newer version of a previously ingested source is a *new* `library_source` row (new slug with new date suffix) whose sidecar `supersedes:` field drives a `SUPERSEDES` edge to the older row. Both rows remain in the graph; retrieval can show the chain. The `CITES` edge resolution prefers non-superseded targets when both old and new versions match a wiki page's slug prefix.

This table is intentionally light. Per-rule formalization (e.g., a structured freshness-rule SQL view or per-type filter helpers in `query.py`) defers until call patterns warrant. The runtime-reasoning posture for the agent — "always current-state-only by default with historical flag" vs. "always all-with-annotation as Pass B's default" — is constitutional, deferred to Stage 3 per ALF-034 (Cowork-me doesn't have IDENTITY/AGENTS/SOUL.md yet).

---

## Source hashing for staleness

Canonical files change. The graph DB needs to detect when a source-content change has invalidated a stored node so it can be re-extracted and re-embedded.

**Per-anchor hashing (DEC-0023 open question 3):** for files that grow append-only (transcripts, daily logs, decisions), whole-file hashing would invalidate every node on every file change. Per-anchor hashing means we only re-process nodes whose specific source-content changed.

**Mechanism:**

1. At extraction time, compute SHA-256 of the bytes that constitute the node's content (e.g., the `## DEC-0014 — ...` heading through the next `## ` heading; the text of `## Turn N` through next `## Turn`).
2. Store the digest in the node's `source_hash` field.
3. At refresh time, walk canonical files; recompute hashes per anchor; compare to stored. Mismatch → mark stale, re-extract, re-embed, update.

**Cost:** SHA-256 is microseconds; embedding is the slow step. Re-embedding only on actual content change keeps refresh cheap. Whole-file refresh of a 50K-line decisions file: minimal because most anchors are stable.

**What counts as "the bytes":** for content nodes, the visible content (heading + body) without surrounding whitespace. For Exchange nodes, the full turn content (user + assistant + tool calls + agent_note). Per-node-type anchor parsing is part of the population code.

---

## Population strategy

### Initial walk (pilot)

One-time pass over all canonical files to populate the graph:

1. Create the database: SQLite file at `~/Claude/memory/graph/cowork-me.db`. Run schema DDL (table creates, vec0 virtual table creates, indices).
2. Insert the single `project` row (`alfred-evolution`).
3. Walk `~/Documents/Projects/cowork-evolution/COWORK-ROADMAP.md` — extract Stages. *(Path updated 2026-05-28 per DEC-0050 / CLD-00015.)*
4. Walk `~/Claude/memory/decisions/COWORK-DECISIONS-*.md` — extract all Decisions. Top-level `~/Documents/Claude/COWORK-DECISIONS.md` is a pointer stub; excluded. *(Path updated CLD-00002, 2026-05-26.)*
5. Walk `~/Claude/memory/action-items/` for open items (top level) and `~/Claude/memory/action-items/closed-items/YYYY/` for archived closed items — extract ActionItems (one row per file, stable ID from filename prefix) and ResolutionNotes (one row per file that contains a `## Resolution` section). **Pass E:** this replaces the prior step that walked `~/Claude/projects/alfred-evolution/open-items.md`. Pass E migration converts the 40 flat-file `open_item` rows to per-file `action_item` rows.
6. Walk `~/Claude/memory/daily/*.md` — extract DailyLogSection per `## Chat:` block, then Activities within each.
7. Walk `~/Claude/transcripts/cowork/*.md` — extract Transcripts (one row each), then Exchanges per `## Turn N`.
8. Walk auto-memory typed files — extract MemoryEntry per file.
9. Walk `~/Claude/memory/processes/*.md` — extract Process per file.
10. Walk amendment source — **currently no active source** (proposed-amendments-agents-md.md deprecated 2026-05-26; content folded into ALF-012). Pass E or Stage 3 item: update this step when Stage 3 joint review produces a formal amendment source, or deprecate the `amendment` node type if amendments fold into action items permanently.
10b. Walk `~/Claude/memory/wiki/<subdir>/*.md` across the five subdirectories (excluding `memory-schema.md` at the wiki root) — extract WikiPages with frontmatter + body per DEC-0033.
10c. Walk `~/Documents/Library/<subdir>/*.meta.yaml` across the six subdirectories (articles, papers, books, transcripts, documents, media) — extract LibrarySources per DEC-0036. Sidecar drives node fields; companion source file (`<slug>.<ext>` in the same directory) feeds the embedding body excerpt with format-specific fallbacks. Skips `.gitkeep` files; warns-and-skips on missing required fields or malformed YAML.
11. Compute and insert edges based on cross-references found during extraction:
    - `BELONGS_TO` edges from structural containment.
    - `MENTIONS` edges by regex-scanning text for `(?:DEC-|ALF-|CLD-)\d+` patterns.
    - `CLOSES` edges by parsing decision body for "closes ALF-NNN" or open-items closure outcome citing `DEC-NNNN`.
    - `LED_TO` edges from daily log `[DECISION]` activities to Decision rows by date+title match.
    - Other edges by ad-hoc parsing as added.
12. Generate embeddings via Ollama for all embeddable nodes; insert into per-type vec0 tables.

For pilot validation, do steps 1–4 first, then run a retrieval test (e.g., "when did we decide on live-transcribe?" should return DEC-0020 plus surrounding daily log + decision context). Iterate before doing the full corpus.

### Refresh

Triggered by: explicit refresh request, or scheduled task (low-frequency, e.g., nightly).

1. Walk canonical files; compute per-anchor hashes.
2. Compare to stored `source_hash` per node.
3. For mismatches: re-extract content, re-embed, update node + vec0 row.
4. For new anchors: insert new nodes + vec0 rows + edges.
5. For removed anchors (rare in append-only files; can happen for OpenItems that get reorganized): mark or delete depending on refresh policy. Recommend mark-as-deleted with `last_modified_*` set, retain for historical queryability.

### Provenance during population

`added_by` for the initial walk: e.g., `cowork-me-pilot-population-2026-05-XX`. `last_modified_by` for refreshes: e.g., `cowork-me-refresh-2026-05-XX` or `eod-compactor-2026-05-XX` if EOD does refresh.

---

## Pilot vs. steady-state

A few pieces of the schema are written for steady-state but partially-occupied at pilot:

- **`project` table** has one row at pilot (`alfred-evolution`). Multi-project future fills the rest from a `projects-index.md` (deferred per ALF-025 / ROADMAP Stage 5+).
- **`action_item` extraction** (Pass E) walks `~/Claude/memory/action-items/` (top level) and `closed-items/YYYY/` archive subdirs. Pre-Pass-E: 40 `open_item` rows from flat file; post-migration these become per-item `action_item` files. ALF-prefixed items remain in Cowork-me's domain (per DEC-0040 cross-decisions bridge); CLD-prefixed items are Cowork-me/Claude Code shared.
- **`exchange` and `daily_log_section` `project_id` field** is sometimes hard to assign because chats may discuss cross-project topics. Assign best-effort at pilot; refine assignment policy as multi-project use surfaces.
- **`amendment` rows** depend on `proposed-amendments-agents-md.md` which exists but has only 3-4 amendments; small input.

These are not blockers — the schema accommodates the steady state, and the pilot extraction simply has fewer rows for a while.

---

## Open questions / forward considerations

These don't block pilot implementation but are worth tracking:

1. **Content drift in transcripts when sentinel migrations happen.** Live-transcribe sentinel migrated mid-trial (generic → per-chat-UUID → turn-numbered). Per-anchor hashes from before the migration may diverge from post-migration anchors. For the trial chat specifically, accept some staleness or re-extract that whole file when refresh happens.

2. **Daily logs reference old filenames** (PROJECT-DECISIONS.md before the rename). Those references are accurate at time of writing and will not be retroactively updated. The graph's `MENTIONS` edges from old daily logs will point to a Decision via its old citation form. The Decision row itself uses `DEC-NNNN`. Edge resolution: parse old date-based references against `decision.date + title` for matching; fall back to nothing if no match.

3. **Cross-actor edges.** No cross-actor edges in v1 (per DEC-0023 scope decision). If Stage 5+ adds a deliberate cross-actor query mechanism, it lives outside this graph or as a separate edges-only file that joins two graphs at query time.

4. **Edge backfill latency.** New decisions may be added to COWORK-DECISIONS.md before refresh runs; new MENTIONS edges to that decision from existing exchanges won't exist until refresh re-scans. Acceptable for steady-state; flag if it bites during pilot validation.

5. **Embedding regeneration cost at model migration.** If we ever revisit DEC-0023 ALF-009 and switch embedding models (DEC-0023 said cheap because graph is derived; re-embed all nodes), the actual cost is ~one Ollama call per embeddable node. At pilot scale (~hundreds of nodes), trivial. At year-1 scale (~thousands), one-time hours-long batch job. Acceptable.

6. **Tool-call content embedding noise.** Including verbatim tool-call content in `assistant_text` (per DEC-0020 truncation policy) bloats embeddings with mechanical content. Counterargument: real content benefits search ("what file did we Read first when investigating X"). Decision: include for now; revisit if retrieval quality is noisy.

7. **Pass E migration scope.** 40 `open_item` rows (ALF-NNN 3-digit format) need to be migrated to per-file `action_item` rows (ALF-XXXXX 5-digit padded format) and physically filed as per-item `.md` files. Existing `~/Claude/projects/alfred-evolution/open-items.md` serves as the migration source; the flat file is retired once all items are migrated. ALF-prefixed items (currently in Cowork-me's domain) migrate to Alfred's domain (`~/.openclaw/memories/action-items/`) as part of the same pass; Cowork-me's domain retains CLD-prefixed items only after migration. This migration is Code's implementation task; COWORK-SCHEMA.md specifies the target state.

---

## Implementation checklist (Pass E) — ✓ COMPLETE (2026-05-27 / DEC-0042)

Pass E completed the action-items redesign. Final population counts: `action_item` = 58 (37 open + 21 closed), `resolution_note` = 21 (every closed item carries a `## Resolution` section), `wiki_page` = 16 (Pass D was 13, Pass E added 1 in `projects/` plus 2 wiki pages added in the interim). Edges table 1029 → 1034 from new wiki edges. Sub-step status:

1. **Create folder structure.** `~/Claude/memory/action-items/` with `closed-items/YYYY/` archive subdirs (seed with current year at minimum). [**DONE 2026-05-26**: `~/Claude/memory/action-items/` and `~/Claude/memory/action-items/closed-items/2026/` created; per-item migration complete — 36 ALF-prefixed open items + 1 CLD-00001 at top level; 20 closed items in `closed-items/2026/`]
2. **Migrate existing items.** Read `~/Claude/projects/alfred-evolution/open-items.md`; create one `.md` file per item using the `ALF-NNN-YYMMDD-Open.md` / `ALF-NNN-YYMMDD-YYMMDD.md` naming convention (original ALF IDs preserved; not padded to 5 digits). ALF-prefixed items remain in Cowork-me's domain per DEC-0040. CLD-prefixed items stay in `~/Claude/memory/action-items/`. [**DONE 2026-05-26**: 56 per-item files created from `open-items.md` — 36 open ALF + 1 CLD open + 20 closed ALF in `closed-items/2026/`. Pass E (2026-05-27 / DEC-0042) renamed all 58 files from space-separator to dash-separator.]
3. **Update schema.sql.** [**DONE 2026-05-27 / DEC-0042**: `action_item` table + `action_item_vec` + 3 indices, `resolution_note` table + `resolution_note_vec` + 2 indices; `nodes` view UNION updated; `amendment` table retained with deprecation comment. Schema applies cleanly to fresh DB.]
4. **Update extract.py.** [**DONE 2026-05-27 / DEC-0042**: `ActionItem` + `ResolutionNote` dataclasses, `extract_action_items(root)` walker with `ITEM_FILENAME_RE` dash-convention regex + per-file section parser. CLI smoke-test: `action_items: 58  resolution_notes: 21`. `OpenItem` dataclass + `extract_open_items` removed at end of pass.]
5. **Update edges.py.** [**DONE 2026-05-27 / DEC-0042**: all `open_item` references → `action_item`; `resolution_note → action_item` BELONGS_TO emission added; `outcome` column dropped from action_item SELECTs. `BLOCKS` / `RESOLVES` / `REFERENCES` (action_item→decision) stubbed with TODO — no `**Blocks:**` or `**References:**` frontmatter bullets observed in the current corpus; implement when a pattern emerges.]
6. **Update populate.py and refresh.py.** [**DONE 2026-05-27 / DEC-0042**: `OPEN_ITEMS_PATH` → `ACTION_ITEMS_DIR` in both. `insert_action_items` branches on `isinstance` to handle ActionItem + ResolutionNote. `_refresh_action_items` implements stable-ID rename detection (path divergence → in-place update, not duplicate). `insert_amendments` / `_refresh_amendments` calls commented out. Also: `populate.py` got a per-chat exchange-ID dedup guard to work around pre-existing duplicate `## Turn N` headings in two transcripts; flagged inline as data debt to fix in source.]
7. **Add `projects/` wiki subdir.** [**DONE 2026-05-27 / DEC-0042**: `~/Claude/memory/wiki/projects/` created; `memory-schema.md` updated (six top-level categories + `projects/` bullet + `projects/<slug>.md` page-type schema); first page `alfred-evolution.md` written. Also required adding `"projects": "project"` to `WIKI_SUBDIRS` in `extract.py` (hardcoded list).]
8. **Run refresh + smoke test.** [**DONE 2026-05-27 / DEC-0042**: clean rebuild via `populate.py` succeeded; py_compile clean on extract/populate/refresh/edges/query; query.py extended with `search_action_items` + `search_resolution_notes` (was previously hardcoded type list); query smoke for `"action items related to graph DB schema"` returns top-5 highly relevant ALF items; query for `"alfred evolution project goals"` returns `project/alfred-evolution` as #1; drift check clean. Stable-ID rename detection logic in place but not yet exercised by a real open→closed transition through the refresh path (CLD-00002 closed and moved during this session, but the rebuild was a full populate, not a refresh) — first real test will be the next item that closes after a refresh.]

---

*Last updated: 2026-05-27 (v2 — Pass E shipped per DEC-0042, 14 node types live).*
*Refer to COWORK-DECISIONS.md for the full reasoning trail. Key decisions: DEC-0003 (SQLite), DEC-0004 (files canonical), DEC-0023 (scope + embedding model), DEC-0025 (DEC numbering), DEC-0033 (wiki_page), DEC-0035 (SUPERSEDES), DEC-0036 (library_source), DEC-0042 (action_item + resolution_note + dash naming).*
