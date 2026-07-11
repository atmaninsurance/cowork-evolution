# Proposed Amendments — Remote-Platform & Recent-Implementation Reconciliation

**Status:** PROPOSAL — for joint review with David. Nothing in this document has been applied.
**Date:** 2026-07-10
**Tracked at:** CLD-00064 (opened this date)
**Authored in:** chat `remote_88ecc9db-2341-5a94-9840-3699c213b996`
**Canonical copy:** `~/Documents/Projects/cowork-evolution/Design/proposed-amendments-remote-platform-20260710.md` (dual-delivered per DEC-0068)

## Drivers

**Anthropic platform changes (2026-07-07+):**

- Cowork sessions execute in an ephemeral Anthropic cloud container; the Mac is reached via a device bridge (`device_*` tools gated on `connectedFolders`) and via proxied local MCP servers (Filesystem, Desktop Commander, etc.), whose access is independent of Cowork folder connection.
- `mcp__cowork__request_cowork_directory` and `mcp__session_info__*` no longer exist. The session_info closing-turn backfill path is dead platform-wide.
- Remote chats leave **no audit.jsonl on the Mac** (verified 2026-07-10). The only complete record is the in-container session JSONL (`/root/.claude/projects/<encoded-cwd>/<uuid>.jsonl`), which dies with the container.
- `connectedFolders` metadata diverges from session-reminder claims (4 datapoints, 7/9–7/10): the reminder asserts a device link while the native folder list is empty; the Filesystem MCP works regardless.
- Scheduled Cowork tasks fire as headless cloud sessions **without** a device bridge (CLD-00061 Datapoint 4).
- Server-side Projects exist, with their own doc store and (untested) native project memory.
- Files written directly to the Mac produce no chat-side artifact (addressed by DEC-0068).

**Our implementations:**

- DEC-0069 / CLD-00062 — nightly local-Code chain (EOD port, transcript exporters + lint, graph refresh, reviewed git sweep + push). Night-2 verification pending (23:00 tonight).
- CLD-00063 — per-turn deterministic transcript true-up for remote chats (`export-remote-transcript.py`): piloted, defect-fixed (v0.2), Phase 2 close-out design (pre-capture + send_later sweep) validated twice including the cross-chat test 2026-07-10.
- DEC-0068 — dual-delivery standard (already codified in `rules/deliver-files-to-chat.md`; no further change needed).

---

## Cluster 1 — Global Instructions (Settings → Cowork)

Only David can install these; they cannot be git-tracked or agent-maintained. That constraint motivates Option A.

### Option A (RECOMMENDED) — slim to a pointer

Replace the entire Global Instruction block with:

```
IDENTITY & MEMORY
You operate with a persistent, file-based memory system on David's Mac
Studio. Canonical memory lives at ~/Claude/memory (rules, daily logs,
action-items, decisions, wiki, process docs) and ~/Claude/transcripts
(per-chat transcripts). ~/Claude/memory/MEMORY.md is the master index and
defines the startup protocol; it is canonical for all protocol detail.

STARTUP — at the start of every chat, before responding:
1. Reach the memory system. In remote (cloud) sessions, read Mac files via
   the proxied Filesystem MCP (mcp__remote-devices__Filesystem__*), whose
   allowed-directories list includes ~/Claude and is independent of
   Cowork's folder-connection state. Do not look for
   request_cowork_directory — it is retired. If no path to the Mac exists
   (Filesystem MCP absent or failing), tell the user the memory system is
   unavailable this session and continue without it.
2. Read ~/Claude/memory/MEMORY.md and follow the startup protocol it
   defines (always-load rules, transcription, daily log, action items,
   decisions, carry-forward greeting).
3. If the session is attached to a Project, check the Project's docs after
   memory startup for project-specific context.

WRITING MEMORY
Write all new memory-type files (rules, references, logs, decisions, etc.)
into ~/Claude/memory — never into Cowork's native per-space auto-memory or
native Project memory (superseded stubs). Follow the conventions in
MEMORY.md and the relevant process docs.

OPERATIONAL HOMES
- Cowork-me: ~/Claude/ (memory/, transcripts/, Scheduled/)
- Alfred: ~/Documents/Alfred/ with runtime at ~/.openclaw/
- Shared library: ~/Documents/The_Library/
Project documentation lives under ~/Documents/Projects/<slug>/. Anything
project-specific stays in that project's own instructions.
```

What this changes, and why: the current GI restates startup steps 2a–2e and the greeting in full — a second canonical copy of the protocol that drifts from MEMORY.md and can only be corrected by hand-editing Settings. Slimming to identity + access + "follow MEMORY.md" + writing rule + homes means every future platform or protocol change is absorbed by editing MEMORY.md under normal conventions. This should be the last Settings edit a platform shift requires.

Interaction with CLD-00049 (startup-protocol misses): consolidating the protocol into one document the GI unconditionally points at removes one hypothesized failure mode (GI/MEMORY.md divergence). Worth noting in CLD-00049 when this lands.

### Option B (minimal patch) — keep current GI, fix only what is broken

1. Replace step 1:
   - **Before:** "Ensure access. If ~/Claude/memory and ~/Claude/transcripts are already connected (e.g., inside a project), move to step 2. Otherwise call request_cowork_directory for each. If access is denied, tell the user the memory system is unavailable this session and continue without it."
   - **After:** "Ensure access. In remote (cloud) sessions, reach Mac files via the proxied Filesystem MCP (mcp__remote-devices__Filesystem__*); its allowed-directories list includes ~/Claude and is independent of Cowork's folder-connection state. request_cowork_directory is retired — do not search for it. If no path to the Mac exists, tell the user the memory system is unavailable this session and continue without it."
2. In step 2b, append: "Remote chats use the deterministic converter protocol (CLD-00063) per processes/live-transcribe.md §Remote capture mode."
3. Append new step 4: "If the session is attached to a Project, check the Project's docs after memory startup."

---

## Cluster 2 — MEMORY.md startup protocol

1. Access preamble:
   - **Before:** "At chat start, after ensuring `~/Claude/memory` and `~/Claude/transcripts` are connected (request if not — see [rules/folder-access](rules/folder-access.md); if denied, say so and continue without the memory system):"
   - **After:** "At chat start, after reaching the memory store (remote sessions: proxied Filesystem MCP against `~/Claude` — surface mechanics in [rules/folder-access](rules/folder-access.md) and [reference/remote-cowork-platform](reference/remote-cowork-platform.md); if unreachable, say so and continue without the memory system):"
2. Step 2:
   - **Before:** "**Live-transcribe:** create the per-chat transcript and append per turn (see [rules/live-transcribe](rules/live-transcribe.md) → `processes/live-transcribe.md`)."
   - **After:** "**Live-transcribe:** create the per-chat transcript and keep it current every turn. Remote chats: bootstrap the deterministic converter and run per-turn true-up + Mac push (CLD-00063; `processes/live-transcribe.md` §Remote capture mode). Legacy local surfaces: Edit-with-sentinel per-turn append. (see [rules/live-transcribe](rules/live-transcribe.md))"
3. Add a folder-connection step (validated 2026-07-10, this chat): "Check `connectedFolders` via `get_device_info`. Folder connection is **per-chat** and the `~/Claude` root is not connected wholesale — if `~/Claude/transcripts` and `~/Claude/memory` are absent and this chat will do transcript or memory writes, ask David to connect both via the desktop app's Add-folder control, then use the `device_*` pipeline for file transfers. The Filesystem MCP works regardless (reads and small edits)."
4. Add to "Key pointers": a line for `reference/remote-cowork-platform.md` (new; Cluster 5).

---

## Cluster 3 — Live-transcribe (rule + process doc)

### 3a. `rules/live-transcribe.md` — proposed replacement body

Keep frontmatter (update `context:` to add the new DEC from Cluster 5). Replace body with:

> At every Cowork chat open, create the per-chat transcript with the locked header. **Remote chats** (`cowork/remote_<UUID>.md`, UUID from the container session JSONL): bootstrap the converter (copy `export-remote-transcript.py` + `_transcript_common.py` from `~/Claude/Scheduled/nightly/` into the container), then at the **start of every turn — as the literal first tool call** — run the converter against the container working copy and push the appended turn(s) to the Mac file. Assistant bodies are captured verbatim by the converter; hand-copying and `<pending>` are retired on this surface. **Legacy local chats** (`cowork/local_<UUID>.md`): Edit-with-sentinel append per DEC-0022/0031 (Tier 1 required, Tier 2 best-effort).
>
> **Close-out (remote):** pre-capture the closing message into the transcript before sending it, and schedule a send_later tail sweep (~2 min) that re-runs the converter as verifier.
>
> **First-action invariant:** the converter run (remote) or sentinel append (legacy) is the first tool call of the turn. If violated, backfill on recognition.
>
> **Full procedure:** `~/Claude/memory/processes/live-transcribe.md`.

### 3b. `processes/live-transcribe.md` — itemized amendments

- **(A) Surface conventions:** add a fourth row — "`cowork/remote_<UUID>.md` — remote (cloud-container) Cowork chats, 2026-07-07+ platform. UUID = the container session JSONL filename (`/root/.claude/projects/<encoded-cwd>/<uuid>.jsonl`), not a working-directory path. Prefix disambiguates from legacy `local_` chats in the same folder."
- **(B) New section "Remote capture mode (CLD-00063)":** bootstrap step (converter + `_transcript_common` copied into the container at chat open; transcript header written to container working copy AND Mac); per-turn step (first action = converter run; then push the new block to the Mac file via Filesystem edit_file against the sentinel); push modes — **(i) verbatim push** (default; whole turn as the converter rendered it), **(ii) payload-summarized push** (fallback for oversized turns: assistant body verbatim, tool payloads semantically summarized, block flagged "payloads summarized for bridge push; full verbatim in container working copy"), **(iii) wholesale push** (target state — see Cluster 6; retires (ii) when available).
- **(C) End-of-chat section:** replace "End-of-day cross-chat compaction backfills it from session_info" with: "Remote: pre-capture (write the closing message into the transcript before sending) + send_later tail sweep (~2 min post-close; wakes the session once, re-runs the converter as verifier, appends a one-line `[SWEEP …]` confirmation). Validated 2026-07-10 ×2 including a concurrent-other-chat test. Legacy local: nightly tooling backfills where a source exists; session_info is retired."
- **(D) Tier model note:** in the per-turn append section, prepend: "The two-tier model below applies to LEGACY surfaces only. On the remote surface, the converter delivers deterministic verbatim assistant bodies — summaries and `<pending>` are not used (CLD-00063)."
- **(E) Stale pointers:** Related-artifacts section — replace the auto-memory feedback path with `~/Claude/memory/rules/live-transcribe.md`; replace `~/Documents/Claude/COWORK-DECISIONS.md` with `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md` (DEC-0020 entry); replace the ALF-002 open-items pointer with CLD-00063; all remaining `mcp__session_info__read_transcript` mentions get "(retired platform-wide 2026-07-07+; see reference/remote-cowork-platform.md)".
- **(F) Storage section:** add: "Remote chats maintain a container working copy (canonical-verbatim during the session, destroyed with the container) plus the durable Mac file. The Mac file is the only copy that survives; the close-out sweep is what guarantees it is complete at end of chat."
- **(G) History entry:** dated 2026-07-10, summarizing the remote surface + converter adoption with pointers to CLD-00063 and the Cluster 5 DEC.

---

## Cluster 4 — Compaction docs — ⛔ GATED on night-2 verification (do not apply before tomorrow AM's check)

- **(A) `processes/end-of-day-compaction.md`:** retire to `_deprecated/` with a header pointer: "RETIRED 2026-07-11 (pending night-2 verification) — superseded by the nightly Code chain (DEC-0069/CLD-00062). Canonical procedure: `~/Claude/Scheduled/nightly/README.md` + its stage docs, per the CLD-00046 thin-launcher/process-canonical convention." If night-2 fails, this amendment holds until the chain is verified.
- **(B) `processes/end-of-session-compaction.md`:** replace the closing-turn boundary text ("EOD backfills it into the live transcript file") with the pre-capture + sweep design; add a "Remote close-out additions" subsection: final converter run, daily-log section write, CLD/DEC updates, pre-capture, send_later sweep (~2 min), one-line sweep reply is the only permanently uncaptured content.
- **(C) `rules/end-of-session-compaction.md`:** one-line touch — "EOD backfills the closing turn" → "the close-out pre-captures the closing turn; the send_later sweep verifies it (remote), or nightly tooling backfills (legacy)."

---

## Cluster 5 — New artifacts

- **(A) `reference/remote-cowork-platform.md`** (new; per DEC-0063 layering, mechanics live in reference/). Contents: execution model (ephemeral container, per-session; bridge + proxied MCPs); session record (container JSONL path; no audit.jsonl on Mac for remote chats; JSONL dies with container); access paths matrix (device_* tools ⟷ connectedFolders; Filesystem MCP ⟷ its own allowed-directories; divergence datapoints); scheduled Cowork tasks = headless, no bridge (CLD-00061 D4); send_later wake = bridge available (2026-07-10 datapoint); retired tools list (request_cowork_directory, session_info, workspace bash); file-visibility rule (DEC-0068 basis); chat-ID derivation for remote sessions.
- **(B) `rules/folder-access.md`:** rewrite against (A) — remote access = Filesystem MCP first; `connectedFolders`/Add-folder as the device_* enabler (Cluster 6); "if denied/unreachable, say so and continue" retained; request_cowork_directory language removed.
- **(C) One canonicalizing DEC** (next number at authoring time), "Remote Cowork transcript protocol: remote_ naming, deterministic converter capture, pre-capture + sweep close-out." What it decides: the `cowork/remote_<UUID>.md` convention (extends DEC-0066's surface table); converter as the remote capture mode (supersedes DEC-0020's Edit-append and DEC-0031's tier model on this surface — both stand for legacy); first-action invariant re-targeted to the converter run (DEC-0022 extended); close-out design; push-mode ladder incl. the summarized fallback; nightly demoted to verifier for remote chats. Why: the platform facts in (A). Tracked at: CLD-00063/CLD-00064.

---

## Cluster 6 — Wholesale-push refinement — ✅ TESTED AND ADOPTED IN-CHAT 2026-07-10

Original gap: per-turn pushes routed transcript content through the agent's context window (read block → re-emit as edit_file payload). Oversized turns (turn 1 of the authoring chat: 76,575 bytes) forced a payload-summarized fallback, leaving the Mac copy less than verbatim until close-out — permanent if a container died mid-chat.

**Fix, validated live in the authoring chat (`remote_88ecc9db`):** with folders connected via the desktop app's **Add-folder** control, the `SendUserFile → device_commit_files` pipeline sends the container *file* and commits it to the Mac path directly — no content passes through the agent's context; ceiling 20MB/file vs ~25KB practical per edit; mtime guard available.

**Empirical results (2026-07-10):**

- Commit to `~/Documents/...` path: PASS (this document, first try).
- Whole working-copy commit to `~/Claude/transcripts/cowork/remote_88ecc9db-….md`: PASS — 157,509-byte verbatim file replaced the partially-summarized Mac copy in one operation, retroactively upgrading turns 1–5 to full verbatim.
- **Folder connection is per-chat** (David confirms; docs agree). Session-metadata claims of connected folders in earlier chats were stale — `connectedFolders` was accurate all along; divergence mystery resolved.
- **`~/Claude` root did not connect wholesale** — David connected `~/Claude/transcripts` and `~/Claude/memory` as separate roots (plus `~/Documents`). The Cluster 2 startup step and folder-access rewrite reflect this three-folder ask.

**Cadence — DAVID'S DESIGN, adopted 2026-07-10 (authoring chat, late session):** during the chat, the container working copy is the sole live record — the converter appends every turn, but NOTHING pushes to the Mac per turn (no cards, no context-routed edits). The Mac transfer happens at defined flush points only, always via the pipeline (full verbatim file, one card each):

1. **Bootstrap** — header write to the Mac (cheap Filesystem write; marks the chat's existence).
2. **Close-out** — full working-copy push + send_later sweep verify (the existing CLD-00063 Phase 2 design).
3. **Soft-close (David's lifecycle design, refined late 2026-07-10):** at bootstrap the chat arms a **named** send_later for **9:00 PM Pacific** (name embeds the chat ID so `list_triggers` can recover it if the container — and the stored trigger_id — is lost). If the chat reaches 9 PM un-closed, the wake turn runs a *soft-close*: converter run → full working-copy push to the Mac → a `[SOFT-CLOSE …]` marker line. **No daily-log narrative and no `[COMPLETE]`** — the 23:00 nightly EOD synthesizes the daily-log section from the flushed transcript, exactly as it always has for un-closed chats. **Lifecycle rules:** (a) explicit close-out **deletes** the pending 9 PM trigger and replaces it with the ~2-minute sweep; (b) continuing a closed or soft-closed chat **re-arms** — next 9 PM, or ~10:45 PM same night if resumed after 9 PM so the pre-nightly window stays covered; (c) a soft-closed chat that stays abandoned leaves no standing triggers (send_later is one-shot) — clean, no registry litter. **Piloted:** armed live in the authoring chat 2026-07-10 (trig_01ECXzDEtrQDs1ffLM4NSKJE, fire 21:00 PT).

**Correction folded in from review discussion:** the nightly EOD chain runs on the Mac and CANNOT reach any container — "transfer at end-of-day compaction" is therefore implemented as the chat's own pre-nightly send_later flush (3), not as a nightly pull. The nightly remains verifier-only for remote transcripts.

**Open empirical question (extends CLD-00063 Phase 2):** whether a send_later can wake a session whose container has already been reclaimed after long idle — and whether the JSONL survives to be flushed. The 2026-07-10 sweep datapoint (bridge=yes) was a fresh close; the long-idle case is untested. Until tested, the insurance flush should fire same-day rather than trusting multi-day wakes. Test: idle chat + multi-hour sweep.

Superseded en route (recorded for completeness): every-turn wholesale push (ran turns 6–7; maximum durability, one card/turn) and hybrid quiet-edit cadence (ran turns 8–9; no cards, content through context) — both remain documented fallbacks when folders aren't connected.

---

## Explicitly unchanged

`no-git-in-cowork-bash`, `zsh-paste-blocks`, `pacific-dates`, `action-items-index`, `compile-amendments` (scope review stays with CLD-00047), `auditor-scope`, `deliver-files-to-chat` (DEC-0068 already covers the platform's file-visibility change), `startup-delay-acceptable`, `wiki-authoring`, dispatch rules. The end-of-session **trigger discipline** (close vs pause vs ambiguous) is also unchanged — only the closing-turn mechanics update.

## Review checklist for David

1. GI: Option A (slim) or Option B (patch)? — then you paste into Settings.
2. Clusters 2, 3, 5: approve as written / with edits → I apply and author the DEC.
3. Cluster 4: auto-unlocks after tomorrow AM's night-2 verification — approve now contingent, or re-review then.
4. Cluster 6: ✅ done — pipeline tested green; cadence decided by David 2026-07-10 (container-only during chat; pipeline flush at bootstrap/close-out/insurance-sweep). Remaining: the long-idle wake test noted in Cluster 6.
5. Git commit of everything applied rides the nightly sweep (DEC-0024/0069) — no action needed.
