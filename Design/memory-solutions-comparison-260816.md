# Four memory approaches from the video vs. what we already run

**Prepared:** 2026-08-16 (Code session `157be9d1`) · **Tier:** standard (one delegated researcher; retrieval on the public web; local state verified by reading the graph DB and tooling directly) · **Requested by:** David, after a video on AI-memory solutions · **Library deposit:** `~/Documents/The_Library/ai-agent-memory/` (11 sources + sidecars, uncommitted; nightly sweep owns commits)

Provenance tags: **[V]** verified against a fetched source or the local filesystem · **[E]** my own assessment · **[IR]** seen only in search snippets, not fetched.

---

## 0. The headline

**Two of the four are things we already have; the other two are additive tools worth a bounded trial, not replacements.**

| Video's item | What it is | Do we have it? | Verdict |
|---|---|---|---|
| Obsidian + wiki knowledge graph | A desktop app that views a folder of Markdown files and draws a picture of the links between them | **Yes, minus the picture.** The_Wiki *is* a vault-shaped folder of Markdown; our graph DB is more than Obsidian's graph view | Zero-cost viewer over what we have; not a memory system |
| graphify | A `/graphify` skill that parses a code/doc tree into a typed, explained knowledge graph — deliberately **no** vectors | **Partly.** Our graph is hand-schema'd from our own conventions; graphify's is bottom-up from AST + LLM | Trial it on our *tooling* (orchestrator, Scheduled/, graph-pilot), where we have no code map |
| Transcripts → vector database | Embed every transcript chunk; find by meaning | **Yes, already.** 3,595 transcript turns are embedded in `exchange_vec` inside our SQLite DB | Nothing to build; the open question is retrieval *quality*, not presence |
| Gemini Embedding 2 (multimodal) | Google's GA model that puts text, images, video, audio, PDF in one vector space | **No — ours is text-only and local.** | Not needed for transcripts (already text). Only earns its place if we want to search *visual* content, and it means shipping content to Google |

**Vector vs. graph, in one line:** a vector store answers *"what is most like this?"*; a graph store answers *"how is A connected to B?"*. They are different questions, and **our single SQLite file already does both** — the pattern the industry now calls "GraphRAG."

---

## 1. What we actually run today [V — read from disk 2026-08-16]

- **Canonical layer = Markdown files** (DEC-0004: files canonical, graph derived). The_Wiki: 102 pages in 7 categories, YAML frontmatter, relative Markdown links (57 counted), `see_also:` frontmatter, no `[[wikilinks]]`.
- **Derived layer = one SQLite file** `~/Claude/memory/graph/cowork-me.db` (138 MB, refreshed nightly, last 2026-08-15 23:09):
  - **Graph half:** ~5,840 nodes across 13 live types (transcript 1,397 · exchange 3,634 · action_item 188 · library_source 157 · daily_log_section 138 · decision 109 · wiki_page 108 · resolution_note 51 · activity 21 · memory_entry 18 · process 13 · stage 5 · project 1) and **17,956 typed edges** (MENTIONS, CLOSES, LED_TO, SUPERSEDES, RELATES_TO, CITES, BLOCKS, RESOLVES).
  - **Vector half:** 12 `vec0` tables (sqlite-vec 0.1.9, 768 dimensions), one per embeddable type — including `exchange_vec` (3,595 transcript turns) and `wiki_page_vec` (108).
  - **Embedder:** `nomic-embed-text` via local Ollama, text-only, 8,000-char cap per item, locked by DEC-0023 / ALF-009. **Nothing leaves the machine.**
- **Retrieval:** `query.py` (per-type vector search with superseded-entry annotation over decisions / stages / library / wiki / action items / resolution notes) and `battery.py` (one query joined against *every* vec table, incl. transcripts). Retrieval order per ARCHITECTURE §5: transcripts + daily logs → graph DB → wiki → MEMORY.md.

So the honest baseline is: **hybrid graph + vector store over a Markdown corpus, local, nightly-rebuilt.** That is the target state most of the video's advice is steering people toward.

---

## 2. Obsidian with a wiki knowledge graph

**What it is [V]:** Obsidian stores notes as plain Markdown in a local folder ("vault"); other tools can edit the files and Obsidian re-reads them ([data storage](https://help.obsidian.md/data-storage)). Links are `[[wikilinks]]` by default, with standard Markdown links equally supported ([internal links](https://help.obsidian.md/links)). The **Graph view is a core plugin that "lets you visualize the relationships between the notes in your vault"** — circles are notes, lines are links, node size grows with in-links; filters, colour groups, a local-graph mode with a depth slider ([graph view](https://help.obsidian.md/plugins/graph)).

**What it is not [E]:** the graph view is a *picture of the link structure*, not a queryable graph database — no query language, no typed edges, no traversal API in the core docs. Querying happens through other surfaces: Dataview / Bases (queries over frontmatter properties, not meaning), Smart Connections / Copilot (semantic search via their own local embedding index), or the new **official Obsidian CLI** ([V] `search`, `read`, `create`, `backlinks`, `links`, `orphans`; requires the desktop app running; the doc itself says the developer commands "allow agentic coding tools to automatically test and debug" — [CLI doc](https://help.obsidian.md/cli)) and **Obsidian Headless** (open beta; its own doc lists "give agentic tools access to a vault without access to your full computer" as a use case).

**Agent-memory ecosystem [V, GitHub metadata]:** MCP servers for Obsidian exist in two camps — REST-API-based (`MarkusPfundstein/mcp-obsidian`, 4.3K stars; needs the app + Local REST API plugin) and filesystem-based (`bitbonsai/mcpvault`, 1.6K, pushed 2026-08-15). The most-cited "Claude Code memory" recipe (`lucasrosati/claude-code-memory-setup`, 936 stars) pairs an Obsidian Zettelkasten vault ("what was decided") with graphify (code map) — i.e. it is *exactly our wiki + our graph*, done by hand.

**Against ours [E]:**
- **Already covered:** vault = folder of Markdown with links and frontmatter — The_Wiki qualifies today. Our `see_also` → RELATES_TO edges and MENTIONS edges from ID references are *more* structure than Obsidian's untyped links.
- **Real gap it fills:** we have **no visual browsing surface** for the corpus. Pointing Obsidian at `~/Documents/The_Wiki` (or a read-only vault over `~/Claude/memory`) gives David a graph picture and search over the same files at zero cost and zero architectural change (files stay canonical). Housekeeping: `.obsidian/` config dir would need gitignoring; The_Wiki's lint forbids nothing Obsidian needs.
- **Not a memory system:** nothing in the official docs is an agent-memory API. It works as agent memory *because it's a folder of Markdown agents can read and write* — which we already have without the app.

## 3. graphify (Graphify-Labs)

**Which one [V]:** `github.com/Graphify-Labs/graphify` — 107K stars, Apache-2.0, created 2026-04-03, pushed 2026-08-15, author GitHub user `safishamsi`, hosted product at graphify.com. Six other repos share the name; none is remotely as prominent. This is the one a 2026 memory-solutions video means [E].

**What it does [V, README v8]:** "Type `/graphify` in your AI coding assistant and it maps your entire project (code, docs, PDFs, images, videos) into a knowledge graph you can query instead of grepping." Explicitly: **"Not a vector index. No embeddings, no vector store: a real graph you traverse."** Code is parsed locally with tree-sitter (37 grammars, "no LLM, nothing leaves your machine"); docs/PDFs/images/video use the assistant's model (or an API key) for the semantic pass. Output `graphify-out/`: `graph.html` (interactive), `GRAPH_REPORT.md` (god nodes, surprising connections, suggested questions), `graph.json`; optional `--obsidian` (write a vault, or into an existing one), `--wiki`, `--graphml`, `--neo4j`, `--mcp`. Query: `graphify query "<question>"`, `graphify path A B`, `graphify explain X`; MCP server exposes `query_graph` / `get_node` / `get_neighbors` / `shortest_path`. Edges tagged `EXTRACTED` / `INFERRED` / `AMBIGUOUS`; Leiden community detection; `[[wikilinks]]` become `references` edges; a CLAUDE.md directive + PreToolUse hook nudges the agent to "query the graph first" (`--strict` blocks the first raw read). Install: `uv tool install graphifyy` (note the double y). Self-reported benchmarks (LOCOMO, LongMemEval) — not independently verified.

**Against ours [E]:**
- **Different philosophy, same shape.** Ours is *top-down*: 13 node types and 8 edge types we designed from our own conventions (DEC/ACI IDs, `see_also`, CLOSES, SUPERSEDES). graphify's is *bottom-up*: whatever the parser and the LLM find, with every edge carrying an explanation and a confidence tag. Ours knows that DEC-260130 amends DEC-260123; graphify would only know that one file mentions the other.
- **Where it beats us today:** (a) **code.** Our graph indexes governance and prose; it has no map of the *tooling* — `orchestrator/`, `Scheduled/nightly/`, `graph-pilot/`, `The_Estate/_meta/`. graphify's tree-sitter pass is exactly that map, local, no LLM. (b) **visualization + report** (`graph.html`, `GRAPH_REPORT.md`) — we have neither. (c) **the "query the graph first" hook** — a pattern we could copy against our own DB.
- **Where it doesn't replace us:** no vectors (by design — the opposite stance from ours, and we want fuzzy "similar to" lookups); no notion of our lifecycle semantics; the doc/PDF pass spends the assistant's tokens.
- **Boundary note:** if trialled, scope it to Cowork-side trees. Running it over Alfred-side files would produce a derived index of that content in our domain — the no-ingestion condition of DEC-260123/260130 says no.

## 4. Transcripts into a vector database — and vector vs. graph

**Plain English [E, grounded in V sources below]:** an *embedding* turns a chunk of text into a long list of numbers such that texts with similar meaning land close together. A **vector database** stores those numbers and answers "what is most like this?" fast, with metadata filters — but each hit is an isolated chunk that carries no idea of *how* it relates to anything else, and results are hard to explain ([Pinecone: what is a vector database](https://www.pinecone.io/learn/vector-database/)). A **graph database** stores named things and *typed* relationships and answers "how is A connected to B / what surrounds X?" with a traceable path — but someone (a parser or an LLM) has to extract the relationships first, and it cannot do fuzzy similarity on its own. Microsoft's GraphRAG docs put the vector-only weakness bluntly: baseline RAG "struggles to connect the dots" and "performs poorly when being asked to holistically understand summarized semantic concepts over large data collections" ([microsoft.github.io/graphrag](https://microsoft.github.io/graphrag/)). Neo4j's framing of the hybrid: "find starting points… via vector, fulltext, spatial, or other searches and then follow relevant relationships" ([Neo4j: what is GraphRAG](https://neo4j.com/blog/genai/what-is-graphrag/); vendor source). LightRAG describes itself as "a dual-layer architecture to manage both knowledge graphs and vector embeddings" ([LightRAG](https://github.com/HKUDS/LightRAG)).

**So: yes, a vector DB is different from a graph DB — and the answer the field has converged on is "both, with vectors as the entry point and the graph for expansion and explanation."** [E]

**Against ours [V/E]:**
- **We already index every transcript into a vector store.** `exchange_vec` holds 3,595 embedded transcript turns; `transcript` nodes (1,397) carry the file-level metadata; the vector and graph halves live in the same SQLite file via sqlite-vec — the same "one file, SQL" local store the researcher found as the natural single-machine choice ([sqlite-vec](https://github.com/asg017/sqlite-vec): "extremely small, 'fast enough' vector search SQLite extension"; pre-v1). Alternatives (Chroma, LanceDB, Qdrant-embedded) buy nothing we lack at this scale.
- **The gap is not presence but retrieval quality and use.** `query.py` exposes per-type search but has **no transcript/exchange search entry point** (only `battery.py` joins `exchange_vec`); there is no vector→traverse expansion step (find the top exchanges, then walk MENTIONS/CITES edges out); no reranking; and no measured recall on real questions. That is a small, well-scoped improvement to our own tooling — not a new system.

## 5. Gemini Embedding 2 (multimodal)

**Facts [V, Google docs]:** exists under that exact name. Announced 2026-03-10 as Google's "first natively multimodal embedding model"; **GA as `gemini-embedding-2` on 2026-04-22** (Gemini API + Vertex / Gemini Enterprise Agent Platform) ([model card](https://ai.google.dev/gemini-api/docs/models/gemini-embedding-2); [Vertex card with GA date](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/embedding-2); [developers blog, 2026-04-30](https://developers.googleblog.com/building-with-gemini-embedding-2/)). Text, image, video, audio and PDF are "mapped into the same embedding space." Dimensions 3,072 default, Matryoshka-truncatable to 128–3,072 (768/1,536 recommended). **Limits per request** ([embeddings guide](https://ai.google.dev/gemini-api/docs/embeddings)): 8,192 tokens total across modalities; images ≤ 6; **audio ≤ 180 s; video ≤ 120 s, ≤ 32 sampled frames, and the video's audio track is *not* processed** (Vertex offers 80 s *with* audio); PDF 1 file / ≤ 6 pages. Multiple inputs in one call → **one aggregated embedding**; per-item embeddings via the Batch API. No `task_type` field — task given as a prompt prefix. **Pricing** (Gemini API paid tier, per 1M tokens): text $0.20 · image $0.45 · audio $6.50 · video $12.00; batch 50% off; free tier exists ([pricing](https://ai.google.dev/gemini-api/docs/pricing)). Predecessor `gemini-embedding-001` is text-only and stays available; Vertex `multimodalembedding@001` is 1,408-d, English-only, text capped at 32 tokens. Paper: [arXiv 2605.27295](https://arxiv.org/abs/2605.27295).

**Against ours [E]:**
- **For transcripts it adds nothing.** Our transcripts are already text; a stronger *text* embedder is a separate question from *multimodal*. Switching embedders means a full re-embed (cheap: ~5,800 items, order of a few dollars at $0.20/M text tokens) but also **unlocking DEC-0023 / ALF-009**, which locked nomic-embed-text, and accepting that every chunk of Cowork-me's memory is sent to Google. Cowork-me's domain is PHI-free by design, so this is a *policy* choice, not a HIPAA violation — but the "nothing leaves the machine" property is currently load-bearing in ARCHITECTURE and would be gone.
- **Where it would genuinely matter:** searching *visual* content — screenshots, diagrams, video frames — by meaning. The 120-second video / no-audio-track limit means a YouTube talk has to be chopped into 2-minute pieces and its speech handled separately anyway; for spoken content, our existing path (transcribe to text → embed text) is arguably the better index. So the realistic use is a **side index for images/diagrams in The_Library**, not a replacement for the transcript store.
- **Alfred side:** anything PHI-adjacent would need a BAA-covered path (Vertex AI's HIPAA eligibility was **not** verified in this pass) and is out of scope until the ACI-260009 wall exists.

---

## 6. Recommendation [E]

In order of value per unit of effort:

1. **Do nothing new for "transcripts in a vector DB" — improve what exists.** Add an exchange/transcript search entry point to `query.py` and a one-hop graph expansion after the vector hit (vector → MENTIONS/CITES neighbours). Small; measurable with `battery.py`'s question set.
2. **Trial graphify on our own tooling trees** (`~/Documents/Agent_Workflow`, `~/Claude/Scheduled`, `~/Documents/Claude/graph-pilot`, `The_Estate/_meta`) — Cowork-side only, code-only pass first (local, no tokens). Judge it on whether `GRAPH_REPORT.md` and `graph.html` tell us something about our own machinery we didn't know. Keep its output out of the canonical layer (derived, gitignored) unless it proves out.
3. **Point Obsidian at The_Wiki as a read-only viewer** if David wants a picture of the commons. Ten-minute setup; no architecture change; gitignore `.obsidian/`.
4. **Park Gemini Embedding 2** unless a concrete need for image/diagram search appears. Note the option in the wiki page (below) so it's found when that need arrives.

None of these needs a DEC on its own; item 1 is ordinary tooling work under the existing design; item 2 is a bounded trial; item 4 would need a DEC only if we chose to unlock the embedder.

---

## 7. What this rests on / still unverified

- **Rests on:** Google's own docs and pricing pages (fetched 2026-08-16); the graphify v8 README (fetched verbatim) and GitHub API metadata; Obsidian's official help source (GitHub `obsidianmd/obsidian-help`, since the help site is JS-rendered); Microsoft/Neo4j/LightRAG/sqlite-vec primary pages; and a direct read of our graph DB, schema, and tooling on 2026-08-16.
- **Unverified:** graphify's self-reported LOCOMO / LongMemEval numbers; exact Obsidian CLI release dates [IR]; Vertex pricing and Vertex HIPAA-eligibility for Embedding 2; `multimodalembedding@001`'s deprecation date [IR]; whether the video David watched named *this* graphify (assessed [E] from prominence).
- **Wiki candidates flagged, not written** (DEC-0034 flag-only): `[WIKI-CANDIDATE?]` vector store vs. graph store vs. GraphRAG hybrid (concept); `[WIKI-CANDIDATE?]` graphify (entity/system); `[WIKI-CANDIDATE?]` Gemini Embedding 2 (entity, with limits table); `[WIKI-CANDIDATE?]` Obsidian as agent memory (system).

---

# Addendum — 2026-08-16, same session (David: "proceed with 1, set aside 3 and 4")

## A1. Item 1 implemented — transcript search + one-hop graph expansion [V]

`~/Documents/Claude/graph-pilot/query.py` now has `search_exchanges` (the missing entry point over `exchange_vec`), `expand_neighbors` (generic one-hop walk of the `edges` table), and `search_transcripts_expanded` (vector hit on transcript turns → the decisions / action items those turns MENTION, ranked by how many hits mention them). CLI: `query.py [QUERY] [--k N] [--expand] [--transcripts-only]`. Retrieval-only; no schema / extractor / nightly change. Regression bar (DEC-0020 top-3) still passes. Probe result and quality observations logged in `graph-pilot/NOTES.md` (2026-08-16 section). Items 3 (Obsidian viewer) and 4 (Gemini Embedding 2) set aside per David.

## A2. graphify — what it is, is it paid, what it would do for us

**Is it a paid service? [V, README v8]** Two things share the name:
- **The open-source tool** — `Graphify-Labs/graphify`, Apache-2.0, free. Code parsing is "free, fully local" (tree-sitter AST, "no LLM, nothing leaves your machine"). The **semantic pass over docs / PDFs / images / video is not free in tokens**: it "use[s] your assistant's model, or a configured API key" — inside Claude Code that means our subscription's model does the extraction; headless it needs an API key (Gemini/Claude/OpenAI/…) or a local Ollama backend (`--backend ollama`, fully local, slower/smaller models).
- **graphify Enterprise / graphify.com** — a hosted, "always-on layer built on top of graphify… meetings, files, docs, and code, updating continuously in the background." Status in the README: "early access… before the public v1 launch," "Join the waitlist… Free trial launching soon." No price published in the README; not fetched from graphify.com. **This is the commercial product; the CLI is the free on-ramp to it.**

**What it is really doing [V README / E assessment]:** it reads a folder and produces `graph.json` (nodes = concepts/functions/files/docs; edges = `calls` / `imports` / `inherits` / `references` / semantic relations, each tagged `EXTRACTED` or `INFERRED`), runs Leiden community detection to split the graph into "subsystems," ranks "god nodes" (most-connected concepts), and writes `GRAPH_REPORT.md` + an interactive `graph.html`. Then it gives the agent three question shapes over that JSON — `query` (a scoped subgraph for a question), `path A B` (how are these two connected), `explain X` — and installs a CLAUDE.md line + a PreToolUse hook that *nudges* the agent to query the graph before grepping/reading raw files (`--strict` blocks the first raw read once per session). It also has a small "work memory" (`save-result`, `reflect` → LESSONS.md). Its own benchmark table is honest in a way worth noticing: it wins on recall@10 (0.497 vs mem0 0.048 / supermemory 0.149) but **loses on LOCOMO QA accuracy (45.3% vs supermemory 49.7%)** and ties dense RAG on LongMemEval-S — i.e. it finds the neighbourhood well; it is not magic at answering.

**Value to us if we ran it (or built the equivalent) [E]:**
1. **A code map we don't have.** Our graph indexes governance and prose (decisions, items, wiki, transcripts). It has *no* nodes for the machinery itself — `orchestrator.sh`, `oilib.py`, `reviewboard.py`, the nightly stages, `graph-pilot`, `_meta/mint.py`. Every "which script owns X / what calls what / where does this hook fire" question today is answered by grep or by re-reading. A tree-sitter pass over `~/Documents/Agent_Workflow`, `~/Claude/Scheduled`, `~/Documents/Claude/graph-pilot`, `~/Documents/The_Estate/_meta` is local, token-free, and would give exactly that. This is the concrete, low-risk trial.
2. **A picture and a report.** `graph.html` + `GRAPH_REPORT.md` ("god nodes," "surprising connections," "suggested questions") are a browsing/diagnostic surface we lack. Even one-off, the report on our tooling would tell David — and us — what the machinery's centre of gravity actually is.
3. **The "query the graph first" hook is a pattern, not a product.** We could point the same nudge at *our* DB (`query.py --transcripts-only --expand`) so sessions consult memory before re-deriving. That's a settings.json hook, not a dependency.
4. **What it would not do:** replace our graph. It has no idea that DEC-260130 amends DEC-260123 or that an ACI CLOSES via a resolution note; it would see file mentions. It has no vectors, by design — we want both. And its doc/PDF semantic pass over our prose corpus would spend tokens to re-extract relationships our schema already carries deterministically.

**Boundary if trialled:** Cowork-side trees only (no-ingestion condition of DEC-260123/260130 stands); output kept derived and gitignored; code-only pass first (`graphify extract <dir> --code-only`, no key, no tokens). Not a DEC-level change unless we decide to keep the output as a canonical surface.

## A3. Local options for video and audio (instead of Gemini Embedding 2)

Second delegated researcher, same day; 8 more sources deposited to `The_Library/ai-agent-memory/`; 70 URLs link-checked by the researcher, 0 failures. Tags as above.

**The shape of the answer [E]:** locally, "ingest a video" is two jobs, not one. (1) *What was said* → transcribe the audio track to text, then embed the text with what we already have. (2) *What was shown* → sample frames and embed the images. Only the second job needs a new (vision) embedder; the first plugs into our existing `nomic-embed-text` + sqlite-vec unchanged. graphify itself does only job (1) — its README says video/audio is "transcribed locally with faster-whisper" and describes no frame step ([graphify README v8](https://raw.githubusercontent.com/Graphify-Labs/graphify/v8/README.md)).

**Job 1 — speech to text, fully local on Apple Silicon [V]:**
- **whisper.cpp** (MIT, 52.9K stars, pushed 2026-08-14) — "Apple Silicon first-class citizen… Metal and Core ML"; Core ML encoder on the Neural Engine "more than x3 faster compared with CPU-only execution"; experimental speaker segmentation (`tinydiarize`). ([README](https://raw.githubusercontent.com/ggml-org/whisper.cpp/master/README.md))
- **mlx-whisper / mlx-audio** (MIT) — Apple's MLX framework in Python; mlx-audio also serves Parakeet (NVIDIA's fast English ASR), Qwen3-ASR, and Sortformer speaker diarization without Hugging Face gating. ([mlx-audio README](https://raw.githubusercontent.com/Blaizzy/mlx-audio/main/README.md))
- **WhisperKit / Argmax OSS** (MIT) — Core ML, `brew install whisperkit-cli`, includes SpeakerKit (pyannote v4 on Apple silicon). ([README](https://raw.githubusercontent.com/argmaxinc/WhisperKit/main/README.md))
- **faster-whisper** (MIT) — what graphify uses; on a Mac it is **CPU-only** (GPU path is CUDA), so fine but not the Mac-optimal choice. ([README](https://raw.githubusercontent.com/SYSTRAN/faster-whisper/master/README.md))
- Speaker labels ("who said what"): pyannote `speaker-diarization-community-1` (CC-BY-4.0, HF token + gate; the `precision-2` tier is a **paid cloud** service, not local) or the Core ML / MLX routes above. ([pyannote README](https://raw.githubusercontent.com/pyannote/pyannote-audio/develop/README.md))

**Job 2 — image/frame embeddings that a text query can search [V]:**
- **nomic-embed-vision-v1.5** (Apache-2.0) — the model card says it "shares the same embedding space as nomic-embed-text-v1.5." That is the one that matters for us: frame vectors could go into our existing 768-d sqlite-vec tables and be found by the text-query vectors we already produce. **Catch:** Ollama cannot run it — Ollama's embedding endpoint is text-only and the multimodal-embedding request (issue #5304) has been open since June 2024. It runs via PyTorch/transformers on the Mac instead. ([model card](https://huggingface.co/nomic-ai/nomic-embed-vision-v1.5/raw/main/README.md); [Ollama issue #5304](https://github.com/ollama/ollama/issues/5304)) *(768-d output inferred from the shared-space claim, not stated in the card — [I].)*
- **Qwen3-VL-Embedding-2B/8B** (Apache-2.0) — text, images, screenshots **and video** in one space, adjustable 64–2048 dims; runs locally via `mlx-vlm` server. Higher fidelity, but a *different* space from our nomic text vectors — would need its own vec table and its own text encoder. ([model card](https://huggingface.co/Qwen/Qwen3-VL-Embedding-2B/raw/main/README.md); [mlx-vlm README](https://raw.githubusercontent.com/Blaizzy/mlx-vlm/main/README.md))
- **OpenCLIP / SigLIP2** (MIT / Apache-2.0) — standard image↔text retrieval; own space. ([OpenCLIP README](https://raw.githubusercontent.com/mlfoundations/open_clip/main/README.md))
- **ColPali / ColQwen** (MIT engine) — for *document page images* (PDF scans, slides) rather than photos; explicit Apple-Silicon MPS support. ([README](https://raw.githubusercontent.com/illuin-tech/colpali/main/README.md))
- Avoid for a business: **Jina CLIP v2** (CC-BY-NC) and Meta **ImageBind** (CC-BY-NC-SA — the one model that puts audio+image+text together, but non-commercial).

**Non-speech audio (optional) [V]:** LAION **CLAP** (Apache-2.0 checkpoints) for sound↔text embeddings; **Qwen2-Audio-7B** (Apache-2.0) via mlx-audio for describing audio in words, then embed the words. ([CLAP README](https://raw.githubusercontent.com/LAION-AI/CLAP/main/README.md))

**Frame captioning as the cheap alternative [V]:** Ollama already serves vision chat models (`qwen3-vl`, `qwen2.5vl`) that describe an image in text — so a "describe each keyframe, embed the description" pipeline works with **zero new embedders** and lands in our existing text tables. Lower fidelity than true image embeddings, zero new infrastructure. ([llama.cpp multimodal doc](https://raw.githubusercontent.com/ggml-org/llama.cpp/master/docs/multimodal.md))

**Ready-made local apps that already do this [V]:** **AnythingLLM** (MIT desktop app; transcribes uploaded audio/video with a local ONNX `whisper-small`, then embeds) — [model README](https://raw.githubusercontent.com/Mintplex-Labs/anything-llm/master/server/storage/models/README.md); **screenpipe** (source-available, personal non-commercial licence; 100% local screen+audio recorder with Whisper Large-V3-Turbo and diarization, SQLite store) — [README](https://raw.githubusercontent.com/screenpipe/screenpipe/main/README.md). Open WebUI and Khoj: audio/video *file* ingest not verified from their READMEs.

**Recommended local stack, if and when we want it [E]:**
1. `ffmpeg` → 16 kHz mono wav → **whisper.cpp (Core ML)** or **mlx-audio** → timestamped transcript chunks → existing `nomic-embed-text` → existing sqlite-vec. *No new store, no new embedder; a new node type (`media_transcript` or reuse `library_source`) at most.*
2. If visual search is wanted: `ffmpeg` keyframes → **nomic-embed-vision-v1.5** (torch, not Ollama) → same 768-d space, `modality` + `timestamp` columns. Or the zero-infra fallback: caption keyframes with Ollama `qwen3-vl`, embed the captions.
3. Qwen3-VL-Embedding only if (2) proves inadequate — separate table, separate space.
Everything above is MIT/Apache-2.0 and stays on the machine, so it does not touch DEC-0023's local-embedder rule or the "nothing leaves the machine" property.

**Could not verify:** exact output dimensionality of nomic-embed-vision (card silent); any Mac speed numbers for the ASR tools (READMEs give none); Qwen-Omni models on MLX; Open WebUI / Khoj audio-video ingest.

`[WIKI-CANDIDATE?]` local audio/video ingestion on Apple Silicon — tool matrix · `[WIKI-CANDIDATE?]` nomic-embed-vision shares nomic-embed-text's space, and Ollama has no image-embedding endpoint (the durable gotcha for our stack).

## A4. graphify trial — run 2026-08-16 (David: "go ahead and let's run the trial")

**Setup as scoped [V]:** `brew install uv` → `uv tool install graphifyy` (v0.9.45; later `graphifyy[openai]` for the Ollama shim). **No `graphify install` / no `claude install`** — no skill, no CLAUDE.md directive, no PreToolUse hook; command line only. Four Cowork-side trees, code-only (`extract --code-only --no-cluster`), exclusions via temporary `.graphifyignore` (Agent_Workflow: `alfred/`, `code/artifacts/`, `hold/`; graph-pilot: `.venv*`), removed after the run. Outputs to the session scratchpad, merged with `merge-graphs`, clustered `--no-label`, then labelled **locally** with Ollama `qwen3-coder:30b`. Copied to `~/Documents/Claude/graphify-trial-260816/` (`GRAPH_REPORT.md`, `graph.html`, `graph.json`), gitignored. **Token cost 0; nothing left the machine; footprint on the trees: none.**

**Numbers [V]:** 105 code files → 1,626 nodes / 3,077 edges (99% EXTRACTED, 1% INFERRED); 96 communities; a few seconds per tree. God nodes: `ledger()` (cowork-nightly.sh, 47 edges), `test_orchestrator.sh`, `finish_fresh_adjudication()`, `finish_clarify_adjudication()`, `Client`/`Harness` (sharefile lib), `worker.sh`, `orchestrator.sh`. Local labels came out sensible: "Escalation Management", "Nightly Workflow", "Queue Operations", "Adjudication Flow", "Embedding Operations", "Estate Lifecycle", "Wiki Harvesting", "Transcript Export/Scrubbing", "Design Delta Review"…

**The three test questions [V]:**
- `query "what runs at nightly stage 3"` → BFS from `Stage`, `write_rung3_pointer()`, `cowork-nightly.sh`: dumped ~60 nodes, essentially the function list of `cowork-nightly.sh` (`ledger`, `mark`, `model_stage`, `s5_verify`, `stage_timing_check`…) plus unrelated `Stage` hits from `extract.py` and a docstring node from the wiki harvester. Correct file, no answer — the *stage-3 step* is a shell case-branch, not a symbol.
- `path orchestrator.sh reviewboard.py` → **"No path found"**, directed *and* undirected.
- `explain oilib.py` → good: 29 connections, all `cmd_*` entry points, imports, `INFERRED indirect_call` for the dispatch table. `affected oilib.py` lists the nine `cmd_*` callers. This is the one that beat grep.

**Why the path failed — the structural finding [V, measured on graph.json]:** **zero cross-language edges** and **45 disconnected components** (largest 425 / 287 / 221 / 138 nodes). `orchestrator.sh` invokes `python3 _meta/oilib.py …` twenty times; `cowork-nightly.sh` invokes Python eight times; the LaunchAgent plists invoke the shell scripts — and none of that is visible to a tree-sitter AST pass, which sees calls/imports *within* a language. Our machinery's architecture *is* that shell ↔ Python ↔ launchd wiring; the code map graphify draws is a set of accurate per-language islands with the bridges missing. The doc/semantic (LLM) pass might infer some bridges as `INFERRED` edges — at token cost and lower confidence — which is exactly the part we kept off.

**Verdict [E]:** *Useful as an occasional, free diagnostic; not a memory-layer component; not adopted.*
- Keep: `explain` / `affected` for Python-side "who calls this / what does this touch" questions; `god-nodes` and the labelled report as a periodic health snapshot; `graph.html` as the first picture we've had of the tooling. Regenerable in a minute with the recipe above.
- Don't: install its hooks/skill; run its LLM doc pass over our prose (our graph already carries those relations deterministically); treat its graph as a source of truth for cross-script wiring — it cannot see it.
- Lesson worth keeping (`[WIKI-CANDIDATE?]`): AST-based code graphs are blind to process-boundary calls (shell → python, launchd → shell, subprocess). For a system built that way, the code map has to come from the *invocation* layer (parsing `python3 …`/`bash …` lines, plist ProgramArguments) — a small extractor we could add to *our* graph as a `script` node type with `INVOKES` edges, if the question ever matters enough. That would be our own machinery map, in our own DB, with our own vectors beside it.
- Uninstall when convenient: `uv tool uninstall graphifyy` (leaves `uv` from Homebrew).
