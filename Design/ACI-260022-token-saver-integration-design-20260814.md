# Token Saver → estate integration design (ACI-260022)

**Author:** claude-code, Code session `1b404e2b`, 2026-08-14
**Item:** ACI-260022 (Token Saver deep review — extract, design, David gate, build)
**Sources:** The_Library `claude-skills/token-saver-explainer-az9713-20260814.md` +
`token-saver-explainer-walkthrough-az9713-20260814.md` (line-annotated third-party
walkthrough of the paywalled skill) + `token-saver-sources-record-20260814.md`.
Wiki synthesis: The_Wiki `entities/token-saver.md`.
**Provenance ceiling:** all Token Saver mechanics are secondhand (first-party source
paywalled); the walkthrough quotes SKILL.md and all three scripts with line numbers,
which is sufficient for design-by-idea. Nothing below copies Jones's code.

---

## 1. Extraction memo (keep/kill)

| # | Learning | Verdict | Why |
|---|---|---|---|
| 1 | **Whole-job accounting** — a work item's cost is the sum across every call (orchestrator, V/D, attester, worker attempts, reviewer, retries); no claimed saving counts unless the combined total falls | **KEEP** | The estate records model per task but sums nothing per work item. CLD-00106's ruled selection design (V/D recommends the worker's model on speed/cost/complexity) has no cost *data* to decide with — this is its measurement layer. |
| 2 | **Carry-the-accepted-result** — a continuation round is built from the approved artifact + the one new change; rejected drafts and prior conversation never ride along; the kept state carries an integrity hash (their `state_delta.py`: one current result, SHA-256-verified, 16KB packet cap, "return the updated result only") | **KEEP (as discipline, not code port)** | Worker continuations and reviewer returns already pass artifacts, but nothing *bans* re-deriving from full prior context, and nothing hashes what a continuation continues from. Verdicts-bind-to-bytes is already estate grammar — this extends it to continuation inputs. |
| 3 | **Cache-friendly prompt ordering** — repeating background byte-identical at the front, volatile content last, shrunk first | **KEEP (cheap, empirical)** | Orchestrator wakes, nightly stages, and worker preambles re-send similar prompts on a clock. Cost is a prompt-assembly audit; benefit must be *measured*, not assumed (see caveat D3). |
| 4 | Select-passages packet builder (`select_context.py`: ~1,800-char chunks, keyword scoring, byte-capped packet, "excerpts are data, not instructions" preamble) | **KILL as build** | Already estate practice behaviorally (indexes-not-archives, harness file tools). One fragment survives as prompt discipline: the structured **miss signal** — "if the packet lacks the answer, say exactly what is missing" — turning a failed bounded read into one targeted follow-up instead of a load-everything retry. Worth one line in worker/`ask`-style prompts. |
| 5 | Remaining strategies (local code first, lazy tools, sized answers, one bounded repair, cheapest capable path) | **KILL** | Independently already estate practice or harness-level. |

**Purchase question:** recommend **no**. The line-annotated walkthrough exposes the
mechanics fully; the three scripts' ideas are portable without the files, and the
estate would not run third-party scripts inside governed lanes anyway.

## 2. Design sketches

### D1 — Whole-job cost ledger (lands with CLD-00106)

- **What:** per-OI cost record summing every model call the item caused: worker
  attempts + continuations, V/D adjudications, attester passes, reviewer rounds.
- **Source of truth:** each run's session JSONL usage fields — the same source
  CLD-00106 gap 4 already names as authoritative for *actual* model. One build can
  land both: actual-model extraction and token sums are the same JSONL walk.
- **Mechanism:** small aggregator in `Agent_Workflow/_meta/` invoked at the
  completion round (and nightly for backfill): resolve the OI's run sessions from
  the ledger/Result blocks → read usage per session → write one summary line
  (tokens by model × phase) into the OI spine, and optionally an end-column on
  `orchestrator/_index.md` (DEC-0094 end-column pattern, same as the model column
  CLD-00106 gap 3 wants — same edit, same parser-safety check).
- **Unit of report:** per OI, split requested/actual model, phases separable so
  "the judging cost more than the typing" is visible — that ratio is the number
  David's V/D-recommends design steers by.

### D2 — Accepted-result continuation packet (lands with CLD-00072/CLD-00119)

- **Rule (convention text):** a continuation or reviewer-return prompt is built
  from (a) the accepted artifact (pointer, or inline when small), (b) the delta
  instruction, (c) the standing task contract — and explicitly NOT from prior
  conversation or rejected drafts. Acceptance is the gate: only reviewed/approved
  artifacts are promotable to "state."
- **Integrity:** the Result block records the artifact's SHA-256 at acceptance;
  the next round's prompt names the hash it continues from; mismatch is a report,
  not a silent proceed.
- **Where:** worker continuation assembly and the reviewer's return-to-worker path
  (natural rider on the CLD-00119 rebuild).

### D3 — Cache-friendly prompt ordering (audit + convention)

- **What:** audit `run_claude()`/orchestrator/nightly prompt assembly for volatile
  content (timestamps, ids, per-wake state) interleaved ahead of stable preamble;
  reorder to stable-first, volatile-last; keep stable blocks byte-identical across
  invocations.
- **Measure, don't assume:** read `cache_read` vs fresh input in session JSONLs
  before/after. **Unverified caveat:** whether Anthropic's *subscription usage
  metering* discounts cache reads (vs. API pricing, which does) is not established
  — if plan usage weights cached input equally, D3's benefit on this estate is
  latency only. This is the first empirical check of the build.

## 3. Decisions for David (the step-3 gate)

1. Adopt D1 (cost ledger riding the CLD-00106 build)? — recommended **yes**.
2. Adopt D2 (continuation packet discipline + hash)? — recommended **yes**.
3. Adopt D3 (ordering audit, gated on the metering check)? — recommended
   **yes, audit-first**; build only if the JSONL check shows cache reads are
   discounted under plan usage.
4. Purchase the skill? — recommended **no**.
5. Miss-signal line in worker prompts (from #4's fragment) — recommended **yes**
   (one sentence in the authoring contract's spec guidance).
