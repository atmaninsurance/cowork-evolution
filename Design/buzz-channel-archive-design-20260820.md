# The Buzz channel archive — working paper (design pass)

**Date:** 2026-08-20
**Task:** 133-design-pass-the-buzz-channel-archive--de (OI-000122, ACI-260036)
**Status:** paper only — nothing here has been built, created, or registered
**Related:** ACI-260036 (this workstream), ACI-260031 (the Buzz pilot), ACI-260032 (Planner lane / `#authorization`), CLD-00076 (exporter secret-scrub), DEC-0076 (deterministic transcript capture)

---

## 1. What this paper is

The Buzz relay — the self-hosted chat workspace where David and the estate's agents now talk — keeps its conversation history in a live database inside Docker containers on this machine. Estate decision documents have started citing Buzz **event ids** (each message's permanent fingerprint) as pointers to David's words. Today those pointers only resolve while that database is alive. This paper designs the **channel archive**: a deterministic nightly export of every channel's history into plain files under `~/Documents/`, so every provenance pointer resolves from files, forever, even if the relay is rebuilt.

David has already ruled five points, which this paper treats as fixed: the archive lives in a folder under `~/Documents/`; it is organised **by channel**, not by agent; the exporter is **deterministic** (no AI model anywhere in it); agent private keys are never read or extracted by it; and archived content obeys the estate-communications content rule ACI-260031 records (PHI-free by design, secrets never persisted).

Six questions were open. Each gets one named recommendation below, with the alternatives it beat and why. Section 8 is the decision list — the paper's actual purpose. David reacting to that list is the next step; a build intake follows his ruling.

---

## 2. What was inspected (so every claim can be re-checked)

Every claim about the running surface below names its source. The load-bearing ones:

| Claim | How established |
|---|---|
| Relay is live at the canonical address | `curl https://davids-mac-studio.tail841f5e.ts.net/_liveness` → `ok` (run 2026-08-20 14:23 PT, this session) |
| Both CLI anchors exist; they are different binaries | `ls -la`: `~/.local/bin/buzz` is a **symlink into `~/Applications/Buzz.app`** (the desktop app's bundled CLI); `~/Pilots/buzz/target/release/buzz` is the source-built binary (built 2026-08-18, repo at commit `8232299`, 2026-08-18) |
| The message-query surface | `buzz messages get --help`: flags `--channel <UUID>`, `--limit`, `--before <unix-ts>`, `--since <unix-ts>`, `--kinds` |
| CLI clamps a page to **200 messages** | `~/Pilots/buzz/crates/buzz-cli/src/commands/messages.rs:363` — `limit.unwrap_or(50).min(200)` |
| Default kinds fetched | `messages.rs:366` — `[9, 40002, 40008, 45001, 45003]` |
| `--before`/`--since` map to Nostr filter `until`/`since` (inclusive bounds) | `messages.rs:379–384` |
| When a page is truncated, the relay returns the **newest** matching messages | `~/Pilots/buzz/crates/buzz-db/src/event.rs:251–252` — `ORDER BY created_at DESC, id ASC LIMIT …`; relay-side page clamp 1,000 (`event.rs:25`) |
| The CLI then re-sorts ascending before printing (which hides the truncation from a naive reader) | `messages.rs:388` |
| Fields returned per message | `~/Pilots/buzz/crates/buzz-cli/src/client.rs:1307` `normalize_events`: `id`, `pubkey`, `kind`, `content`, `created_at`, `tags` |
| Kind meanings | `~/Pilots/buzz/crates/buzz-core/src/kind.rs`: 9 chat message, 40002 stream message v2 (`:481`), 40003 stream message **edit** (`:483`), 40008 code-diff message (`:493`), 45001 forum post (`:550`), 45003 forum comment (`:554`), 5 deletion (`:56`) |
| Channel enumeration | `buzz channels list --help`: lists channels **visible to the current identity**, default limit 500; channel types are `stream` and `forum` (`channels create --help`) |
| An identity is required for every relay call | top-level `buzz --help`: `BUZZ_PRIVATE_KEY … [required]`; the relay runs closed-membership (`BUZZ_REQUIRE_RELAY_MEMBERSHIP=true`, ACI-260031) |
| Nightly chain shape | `~/Claude/Scheduled/nightly/cowork-nightly.sh:7–13`: Stage 1 transcript export (deterministic, before EOD) → 1.8 lint → 2 EOD → 2.5 Codex EOD → 3 transcript lint → 4 graph refresh → 5 git sweep + push → 6 ledger |
| Existing truncation policy | `~/Claude/Scheduled/nightly/_transcript_common.py:27–28` — inputs verbatim ≤ 2 KB, outputs verbatim ≤ 10 KB; `:994–1003` — over 10 KB renders head 4,000 + tail 2,000 with a byte count |
| Existing shared scrub machinery | `_transcript_common.py`: `scrub_sensitive` (`:380`), `detect_sensitive` (`:410`), `mask_values` (`:361`), `scrub_and_tally` (`:542`) |
| Bookmark-file precedent | `~/Documents/Agent_Workflow/librarian/harvest-window.txt` — a one-line watermark advanced by each completed run |

**What was deliberately NOT done:** no live authenticated query was run. Exercising `messages get` requires `BUZZ_PRIVATE_KEY`, and every key on this box lives under `~/Pilots/buzz-pilot-keys/`, which this task's fence forbids opening. Feasibility claims are therefore grounded in the CLI/relay **source code** plus ACI-260031's recorded live round-trip, not in a query run by this session. See §9 (Not established).

**Message shape** (structural example only — invented values, no real content):

```json
{"id": "<64-hex event id — the hash of the whole signed event>",
 "pubkey": "<64-hex author public key>",
 "kind": 9,
 "content": "<the message text>",
 "created_at": 1766280000,
 "tags": [["h", "<channel-uuid>"], ["p", "<mentioned pubkey>"]]}
```

The event id is content-addressed: it is a cryptographic hash of the full signed event. That single fact drives several recommendations below — identical events always have identical ids (dedup is trivial and migration-proof), and truncating or altering stored content destroys the ability to re-verify it.

---

## 3. Where the record and the running code disagree

The task says the code governs; three divergences were found and they shape the recommendations:

1. **The candidate paging mechanism is unsafe as stated.** The record's candidate is "per-channel paging through the CLI with `--since` and a bookmark." In the running code, a page is capped at 200 messages and a truncated page returns the **newest** 200, not the oldest (`event.rs:251`), while the CLI re-sorts ascending (`messages.rs:388`) so the output *looks* like a clean oldest-first continuation. A naive `--since <bookmark>` loop would silently skip everything older than the newest 200 in any busy window. Recommendation (b) adopts the bookmark idea but pages **backward** to fix this.
2. **CLD-00076's exporter-scrub gap is no longer open the way the task describes.** The task text calls the gap "open on the sibling surface." The record itself shows the scrub, the `secret-suspect` lint class, and the automated Stage-3.7 masked triage all **shipped 2026-08-04/06** for the three transcript exporters (CLD-00076, Progress entries of 2026-08-06; `_transcript_common.py` carries the machinery today). What remains open on CLD-00076 is a one-time redaction of residual historic findings (OI-000054, ruled by David 2026-08-07) and a behavioral complement — neither blocks a new exporter. Recommendation (d) builds on this.
3. **The two CLI anchors are not the same binary.** `~/.local/bin/buzz` symlinks into the desktop app bundle and will change silently whenever the app updates; `~/Pilots/buzz/target/release/buzz` is source-built and pinned at commit `8232299`. A deterministic nightly exporter should call the pinned one.

---

## 4. Recommendations — the six open questions

### (a) Folder name and version-control posture — *read together with (d)*

**Recommendation: `~/Documents/Buzz_Archive/`, initialised as its own git repository, LOCAL ONLY — no hosted remote — until the screening step in (d) has run live for an agreed proving period, after which the remote question returns to David as its own decision.**

Alternatives considered:

- *Name it `Channel_Archive`* (David's in-thread phrase). Rejected narrowly: the name says what the folder is but not what it archives. If the estate ever runs a second conversation surface, "Channel_Archive" is ambiguous; "Buzz_Archive" is greppable and self-explaining. This is taste, not architecture — it is on the decision list.
- *A subfolder of `~/Documents/The_Estate/`.* Rejected: The_Estate is the governance registry — low-churn, human-authored, pushed to GitHub. The archive is high-churn machine-generated content; putting it there would push relay content to a hosted remote from day one (see the pairing with (d) below) and bloat the registry's history.
- *A plain folder, no git repository.* Rejected: the nightly Stage-5 sweep reviews and commits **repositories** — its secret gate ("flag the repo, do NOT commit") only protects content that flows through it. A repo also gives the archive an append-only audit history and tamper evidence for free, which suits a provenance store.
- *A repo with an immediate GitHub remote.* Rejected on the CLD-00076 lesson: in July a pasted credential reached a git-tracked transcript and was **pushed before detection** (CLD-00076, 2026-07-23 entry — the sweep caught it only after push). A brand-new exporter surface should prove its screening locally before anything leaves the machine.

**Why (a) and (d) are one decision:** the repo/remote posture is the blast-radius control for screening failures. While the archive is a local repo, a screening miss is a fixable file on this machine, guarded by the Stage-5 gate before any commit. The moment there is a hosted remote, a miss becomes GitHub history. So the remote should be earned by (d)'s proving period, not assumed.

### (b) Exporter mechanism, with failure and recovery behaviour

**Recommendation: adopt the record's candidate — per-channel CLI paging with a per-channel bookmark — with one structural adaptation: page BACKWARD with `--before` until the walk reaches the bookmark, then dedup by event id and append in ascending order. Two-layer storage (raw JSONL + rendered Markdown), append-only, run under a dedicated `@Archivist` read-only member identity, calling the pinned source-built binary.**

The mechanism, in plain terms: for each channel, keep a one-line bookmark ("archived through timestamp T"). Each run walks pages of up to 200 messages from *now* backward in time until it reaches messages it already has, then writes only the new ones, oldest first, onto the end of the channel's file, and finally advances the bookmark. The backward walk is what the relay's own paging actually supports (§3, divergence 1); the forward-only loop the record sketched would drop messages on any >200-message night.

Storage, per channel:

```
~/Documents/Buzz_Archive/
  channels/<slug>/            # slug fixed at first sight; UUID in manifest (renames don't move files)
    manifest.json             # channel UUID, name, type (stream|forum), relay URL, first/last event
    events.jsonl              # raw layer: one scrubbed event per line, append-only, ascending created_at
    2026-08.md                # rendered layer: human-readable monthly view (increment 4)
  _meta/
    bookmarks.json            # per-channel watermark: last archived created_at (+ event ids at that second)
    export-ledger.md          # one line per run: timestamp, per-channel new-event counts, scrub tally, FLAGs
```

**Failure and recovery — the three cases the task requires, plus two more:**

- **Interrupted run** (kill, crash, machine sleep): a channel's bookmark is advanced only *after* its new events are fully appended and flushed (append, fsync, then atomic bookmark replace via temp-file rename). An interruption therefore leaves the bookmark at its old value; the next run re-walks the same window and the event-id dedup discards everything already present. Worst case is wasted re-reading, never a gap and never a duplicate.
- **Re-run over an already-exported range:** same property. `--since`/`--before` bounds are inclusive, so the boundary second is always re-fetched; dedup by event id (a content hash — identical event, identical id, always) makes every re-run idempotent. Running the exporter twice in a row must produce a byte-identical archive; that is increment 1's acceptance test.
- **Rebuilt or migrated relay:** event ids are content-addressed and author-signed, so a migrated relay serving the same history yields the same ids — the export is idempotent across migration; the manifest and export ledger record the relay URL per run, so a URL change is visible, not silent. A relay rebuilt **empty** (or with lost history) simply returns nothing since the bookmark: the archive is untouched, because the exporter is append-only and never deletes or rewrites — the archive is the durable superset, which is the whole point. One tripwire: if the relay's *oldest* visible event in a channel is newer than that channel's bookmark, history was lost or the relay was swapped; the run should FLAG that in the export ledger rather than pass silently.
- **Relay down at run time:** an unauthenticated `/_liveness` pre-check; on failure, FLAG-and-skip in the export ledger. The bookmark stands; the next successful run catches up automatically. No retry loop inside the nightly.
- **A channel the archivist cannot see:** `channels list` shows only channels visible to the identity, and private channels require membership. The run compares the visible list against the manifest roster and FLAGs any known channel that has disappeared from view (membership revoked, archived channel) instead of quietly stopping its coverage.

**Kinds archived:** the CLI's default five (9 chat, 40002 stream v2, 40008 diff, 45001 forum post, 45003 forum comment) **plus 40003 (message edit) and 5 (deletion)** via `--kinds`, so revisions and removals are captured as events rather than silently lost. The archive itself never retro-edits or retro-deletes: a deletion event is *recorded*, the original stays. (Estate comms are PHI-free by rule and the relay owner is David, so append-only is safe here; if that ever changes, this is the line to revisit.)

**Identity:** a dedicated `@Archivist` member identity, minted by David, key stored beside the others in `~/Pilots/buzz-pilot-keys/` (mode 600, values never displayed — the ACI-260031 custody rule verbatim). The exporter process reads the key file at runtime into its environment and never logs, copies, or persists it. Ruled point 4 (agent private keys never read or extracted) stays intact: the archivist key is the exporter's *own* identity, not an extraction of any agent's. The archivist must be added as a member of every channel to be archived, including private ones.

Alternatives considered:

- *The candidate as literally stated (`--since` forward loop).* Rejected as-is for the silent-gap hazard (§3.1); adopted in adapted form.
- *Reading the relay's Postgres directly (docker exec / pg_dump).* Rejected as the archive mechanism: the schema is upstream-internal and version-fragile (the repo tracks a moving `main` image), and it bypasses the relay's own access model. A periodic `pg_dump` is worth having as *disaster backup* — a different artifact with a different job — and appears as an optional build increment, not part of the archive.
- *A live websocket subscription daemon.* Rejected: a long-running process with reconnect/replay logic to serve a freshness no consumer needs (see (c)); the nightly pull is strictly simpler and self-healing.
- *`messages search` / `feed` as the read surface.* Rejected: relevance-ordered and cross-channel respectively; wrong shapes for a complete per-channel walk.

### (c) Cadence

**Recommendation: nightly, as a deterministic sibling of the Stage-1 transcript exporters in the existing nightly chain — running before Stage 2 (EOD compaction) and committed by Stage 5 (git sweep) the same night. It depends on: the Buzz Docker stack being up (`~/Pilots/start-buzz.sh`), the Tailscale network, and the archivist key file being present; on any failure it FLAGs and skips, and the bookmark design makes the next night a clean catch-up.**

Why that slot: Stage 1 is already "deterministic exports before EOD, so EOD's discovery sees every chat" (`cowork-nightly.sh:514–520`). The channel archive is exactly that class of artifact — and placing it there means the EOD daily-log pass *can* read the day's channel record from files, and the sweep's secret gate reviews the archive repo every night it changes.

Alternatives considered:

- *Hourly (launchd interval).* Rejected: no consumer needs sub-day freshness — the live relay **is** the fresh surface; the archive's job is durability and provenance, not liveness. Hourly multiplies failure/FLAG noise by 24 for no consumer.
- *Real-time subscription.* Rejected with the daemon alternative in (b).
- *Weekly.* Rejected: decision documents cite event ids the day they are written; a pointer should resolve from files within a day, and a week is too long an unprotected window against relay loss.

### (d) The screening step — and its relationship to CLD-00076

**Recommendation: scrub-before-write, reusing the estate's existing shared scrub library — import `scrub_and_tally` / `detect_sensitive` from `~/Claude/Scheduled/nightly/_transcript_common.py` rather than writing a second pattern list — applied to BOTH layers (raw JSONL and rendered Markdown) before anything touches disk, with the Stage-5 sweep secret gate as the independent backstop and the Stage-3.7 masked-triage machinery covering suspect-tier findings. Detection tallies (never values) go to the export ledger.**

**The CLD-00076 relationship, stated plainly as the task requires:** this screening step **does not inherit the gap, is not blocked by it, and closes it for this surface by construction.** The gap CLD-00076 opened in July — deterministic exporters faithfully reproducing any pasted credential onto a git-tracked surface — was closed on the transcript surface in early August: the shared scrub, the `secret-suspect` lint class, and the automated nightly triage all landed (CLD-00076 Progress, 2026-08-04 through 2026-08-06). What remains open on that item — the one-time redaction of residual historic findings (OI-000054) and a behavioral complement — concerns old artifacts and human workflow, not exporter machinery, and neither touches this design. A new exporter that *imports the same guard* starts life on the closed side of the gap. Writing its own pattern list instead would re-open it in miniature: two guards that drift apart is the exact defect the estate's "same-guard sync invariant" exists to prevent (CLD-00076, 2026-07-28 entry — the fix-both ruling).

Mechanics that matter:

- **Order is load-bearing: scrub, then store; scrub, then truncate for display.** The transcript exporters learned this the hard way — truncating first can leave a partial credential the scrub no longer matches (`_transcript_common.py:516`, comment recording exactly this).
- **Redaction vs verifiability:** a scrubbed event's content no longer hashes to its event id, so signature re-verification is impossible for it. Scrubbed events get a `redacted` marker and are counted; verification tooling skips them loudly. The no-secrets discipline outranks verifiability — an archive that faithfully preserves a credential is worse than one with a marked hole.
- **PHI:** estate communications are PHI-free by rule (ACI-260031), so screening scope here is secrets; the stop-on-PHI behavioral rule stands unchanged on top.

Alternatives considered:

- *A fresh, archive-specific pattern list.* Rejected: guard drift; the shared library is live, tested (70+ fixture pins), and centrally maintained.
- *Post-hoc scrub (write verbatim, scrub on a later pass).* Rejected: the value lands on disk in a repo working tree first — the CLD-00076 amplification lesson is that generated copies outrun cleanup.
- *No scrub, rely on the Stage-5 sweep gate alone.* Rejected: the sweep is a flag-and-skip *reviewer*, not a filter, and the 2026-07-21 incident shows a push can beat detection. Belt and braces: scrub at generation, gate at commit.
- *Block-the-run on any detection instead of scrubbing.* Rejected: stalls the archive on false positives; scrub-plus-suspect-triage is the shape that already works nightly on the sibling surface.

### (e) Retention grain

**Recommendation: verbatim at the raw layer — no truncation of event content in `events.jsonl`, ever (scrub redaction is the sole permitted alteration). The rendered Markdown layer applies the estate's existing display rule unchanged: verbatim up to 10 KB per message; above that, head 4,000 + tail 2,000 characters with a byte count (`OUTPUT_VERBATIM_MAX`, `_transcript_common.py:27–28, 994–1003`).**

The rule's name and basis: **"raw verbatim, display truncated at the transcript exporters' 10 KB head+tail rule."** The threshold is inherited deliberately — one estate-wide display policy, already proven on the per-agent transcript surface — rather than invented fresh.

Why the raw layer must be verbatim: the archive's founding purpose is resolving provenance pointers, and an event id is the hash of the full signed event. Truncated content can never re-verify against its id — truncation at the raw layer would quietly convert the provenance store into a paraphrase store. Size is manageable: chat messages are small; media does not travel inline (uploads go to the relay's Blossom blob store and are referenced by hash/URL in message content), and oversized pastes are the exception, cheap to store, expensive to lose.

Alternatives considered:

- *Truncate raw like the transcript exporters truncate tool output.* Rejected: purpose-defeating, per above. The transcript exporters truncate *tool noise* around an agent's work; here the message content **is** the record.
- *Verbatim including referenced media blobs.* Deferred, not adopted: blob archiving is a real question (the MinIO store is part of the same rebuildable stack) but a separate increment with its own size and screening questions — listed in §7 as optional.

### (f) The authorization forum threads

**Recommendation: no distinct export mechanism — `#authorization` is archived by the same exporter through the same query (forum kinds 45001/45003 are in the default filter, `messages.rs:366`, and carry the same channel tag). Two distinct treatments at the edges: (1) forum channels get thread-grouped RENDERING in the Markdown layer (one section per root post, comments nested under it, section anchored by the root event id) so a cited thread reads as a unit; (2) any scrub redaction that lands in `#authorization` is FLAGged loudly in the export ledger rather than only tallied — a redaction there means decision provenance was altered, and David should see that same-night.**

A third, later safeguard belongs to this question but is a build increment, not a mechanism change: a **provenance resolver check** — a small deterministic assertion, runnable in the nightly, that every Buzz event id cited by a decision document resolves to an archived event. That converts the archive's purpose into a nightly-verified invariant.

Alternatives considered:

- *A separate per-thread export via `messages thread`.* Rejected: a second mechanism with second bookmark semantics to maintain, producing nothing the flat event stream doesn't already contain — thread structure is derivable from event tags at render time.
- *A special verbatim-signed vault for `#authorization` only.* Rejected: the whole raw layer is already verbatim and signature-carrying under (e); special-casing one channel adds ceremony, not integrity.

---

## 5. Exporter shape sketch (illustration only — nothing here is built)

```
for each channel in manifest roster (+ newly visible channels adopted):
    bookmark = bookmarks[channel]           # last archived created_at
    pages = []
    before = None                            # None = now
    loop:
        page = buzz messages get --channel UUID --limit 200 \
               [--before before] --kinds 9,40002,40003,40008,45001,45003,5
        if page empty: break
        pages.append(page)
        oldest = min(created_at in page)
        if oldest <= bookmark: break         # walked back into archived territory
        before = oldest                      # inclusive bound; overlap removed by dedup
    events = ascending(dedup_by_id(flatten(pages)) - already_archived_ids)
    for e in events: e.content = scrub_and_tally(e.content)   # shared lib; redaction marked
    append events to channels/<slug>/events.jsonl; fsync
    atomically replace bookmark with max(created_at)
write export-ledger line: counts, scrub tally, FLAGs
```

Binary: `~/Pilots/buzz/target/release/buzz` (pinned build, commit `8232299`); identity: `@Archivist` key via runtime env; relay: the canonical `wss://…ts.net` address from configuration, recorded per run.

---

## 6. Layer model this fits

Settled in-thread on ACI-260036 and preserved here: **relay/archive = what was said** (shared, by channel — this design); **per-agent transcripts = how each agent worked** (private, DEC-0076 exporters, unchanged); **daily log = what it meant** (EOD, unchanged). No per-participant duplication. Direct messages (`buzz dms`) are deliberately out of this design's scope — the ruling is per-*channel*; DMs raise their own privacy questions and would need their own ruling (§8, D9).

---

## 7. Build increments

Ordered so the first is independently useful; each names its preconditions and its proof of done.

1. **Folder, repo, one-channel exporter (raw layer only).** Create `~/Documents/Buzz_Archive/` as a local git repo; manifest; the backward-paging exporter with bookmark, dedup, and the imported scrub; run manually against `#planning` (or `#pilot-lounge`).
   *Preconditions:* David rules D1–D5 and D7; `@Archivist` identity minted, membered to the target channel, key file placed in `~/Pilots/buzz-pilot-keys/`.
   *Done when:* two consecutive runs yield a byte-identical archive (idempotence); a run killed mid-flight then re-run leaves no gap and no duplicate (verified by event-id count against a fresh full walk); a seeded fake-credential message in a test channel lands redacted with the tally incremented, value nowhere on disk.
   *Independently useful:* from this increment on, `#planning` provenance pointers resolve from files.
2. **All-channels enumeration and coverage.** Roster from `channels list` + manifest adoption of new channels; the missing-channel and lost-history FLAGs; the export ledger.
   *Preconditions:* increment 1; archivist membered to all channels (including `#authorization`).
   *Done when:* every channel in the desktop roster has an archive directory with matching event counts, and revoking the archivist from a test channel produces a FLAG, not silence.
3. **Nightly wiring.** The exporter joins Stage 1 of the nightly chain; `Buzz_Archive` joins the Stage-5 sweep roster (per ACI-260036 next-action 3); liveness pre-check FLAG path.
   *Preconditions:* increments 1–2; a David-invited edit of the nightly wrapper and sweep prompt (both live in governance-adjacent trees).
   *Done when:* two consecutive nightly runs produce ledger lines and swept commits; one deliberate relay-down night FLAGs, skips, and catches up cleanly the next night.
4. **Rendered Markdown layer.** Monthly per-channel files; thread-grouped rendering for forum channels; the 10 KB display-truncation rule.
   *Preconditions:* increment 1 (raw layer stable).
   *Done when:* a cited `#authorization` thread can be read end-to-end in one Markdown section anchored by its root event id.
5. **Provenance resolver check.** Deterministic nightly assertion: every Buzz event id cited in The_Estate decision documents resolves in the archive; failures FLAG.
   *Preconditions:* increments 2–3; a fixed citation format for event ids in decision docs (worth one line in the estate conventions when invited).
   *Done when:* the check passes on all existing citations and a synthetic dangling citation trips it.
6. **Optional / deferred:** periodic `pg_dump` disaster backup of the relay database (separate artifact, separate retention); Blossom media-blob archiving decision; the hosted-remote decision revisit after (d)'s proving period; the DM question (D9).

---

## 8. Decision list — what needs David's ruling

This list is the paper's product. Each is a yes/no or a pick, with my recommendation attached.

- **[DECISION REQUIRED] D1 — Folder name.** `Buzz_Archive` (recommended) vs `Channel_Archive` (your in-thread phrase) vs another name. Pure naming; everything else is unaffected.
- **[DECISION REQUIRED] D2 — Version control posture.** Own local git repository with **no hosted remote** until screening is proven live, then revisit the remote as its own decision (recommended) vs plain folder vs repo with immediate GitHub remote. This is the blast-radius pairing with screening (§4a/§4d).
- **[DECISION REQUIRED] D3 — Exporter identity.** Mint a dedicated read-only `@Archivist` member identity, key custodied like the others in `~/Pilots/buzz-pilot-keys/` (recommended — requires ~10 minutes of your time in the desktop app, and membering it into each channel including `#authorization`) vs running the exporter under your owner key (rejected: a nightly headless process holding the owner credential is needless blast radius).
- **[DECISION REQUIRED] D4 — What gets archived.** Default message kinds **plus edits and deletions as recorded events**, archive itself append-only (a deletion is recorded, never applied retroactively) (recommended) vs messages-only vs honoring deletions in the archive. Append-only is what makes the archive trustworthy as provenance; it also means "delete" on the relay does not delete from the archive — you should rule on that knowingly.
- **[DECISION REQUIRED] D5 — Screening.** Reuse the shared scrub library, scrub-before-write on both layers, sweep gate as backstop, Stage-3.7 triage for suspects (recommended) vs any of the rejected shapes in §4d. Note the stated relationship to CLD-00076: this closes that gap for this surface; nothing inherits or blocks.
- **[DECISION REQUIRED] D6 — Cadence.** Nightly, inside the existing chain as a Stage-1 sibling, FLAG-and-skip on relay-down (recommended) vs hourly vs real-time.
- **[DECISION REQUIRED] D7 — Retention grain.** Raw layer verbatim (redaction the only alteration); rendered layer truncates display above 10 KB per the transcript exporters' rule (recommended) vs truncating the raw layer too (rejected: breaks event-id verifiability, the archive's founding purpose).
- **[DECISION REQUIRED] D8 — `#authorization` handling.** Same exporter, thread-grouped rendering, plus loud FLAG when a redaction ever lands in that channel (recommended) vs fully identical treatment vs a separate mechanism.
- **[DECISION REQUIRED] D9 — Scope confirmation on DMs.** Confirm direct messages stay OUT of the archive for now (recommended — the ruling was per-channel; DMs have different privacy expectations) vs bringing them in under a future design.

---

## 9. Not established

Honest gaps, each with the reason:

- **No live authenticated query was run.** Every relay call requires `BUZZ_PRIVATE_KEY`; all key material lives under `~/Pilots/buzz-pilot-keys/`, which this task's fence forbids opening. Consequently the actual channel roster/UUIDs, live JSON output, and closed-relay read behaviour were established from source code and ACI-260031's recorded round-trip, not observed by this session. The unauthenticated `/_liveness` check was run and returned `ok`.
- **Maximum plaintext message size.** No relay-side cap on plain (kind 9/40002) content length was found in the greps run; only the encrypted-content bound (87,472 bytes, `buzz-core/src/observer.rs:23`) surfaced. Worst-case single-message archive size is therefore not established; the verbatim-raw recommendation assumes messages are chat-sized, which the pilot's usage supports but the code was not shown to enforce.
- **Edit-event storage semantics.** Whether the relay stores a 40003 edit strictly as a separate event beside the immutable original (the Nostr-native shape) or also rewrites what `messages get` returns for the original was not traced to code. The recommendation (archive both kinds, append-only) is robust under either answer, but rendering "current text" correctly in increment 4 needs this pinned down at build time.
- **Which kinds the pilot's real traffic actually uses** (e.g., whether managed-agent messages arrive as kind 9 or 40002) — requires a live query; deferred to increment 1's first run.
- **The exact channel roster beyond the four named in the records** (`#pilot-lounge`, `#planning`, `#watcher`, `#authorization`) — record-based (ACI-260031/-260032), not observed.
- **Relay-side `since`/`until` inclusivity at the SQL boundary** was not read line-by-line; NIP-01 specifies inclusive bounds and the design's overlap-plus-dedup does not depend on the answer.

---

*End of paper. Next step: David reacts to §8; the build intake follows his ruling (ACI-260036, next actions 2–3). Nothing was created, modified, or registered by this design pass outside this file.*
