# Buzz as the estate's communication surface — design pass (ACI-260032)

**Status:** design pass, 2026-08-18 (Code session `38ff89fa`), on David's direction of the same
day. Nothing here is built; David reacts to §3 (the tier table) and §11 before any increment
files. Sibling: **ACI-260031** (the Buzz sandbox pilot, session `cd41c78d`) is the substrate —
its evaluation `buzz-evaluation-260818.md` and its constraints govern here.
**Project:** cowork-evolution. **Anchors:** ACI-260032, ACI-260031, ACI-260025, ACI-260030,
DEC-260112, DEC-0099 / CLD-00073, DEC-260135. **Sources:** `The_Library/agent-communications/buzz-*`.

## 0 · In one paragraph

Buzz gives the estate what Telegram never had: rooms where **agents are members**, threads,
a searchable durable event log, and a harness (`buzz-acp`) that runs a Claude Code or Codex
session as a live agent that answers @mentions. The design uses it for exactly one job —
**the conversation lane** (ACI-260025: informs and coordinates; never authorizes; never the
record) — in five increments: a Buzz sink behind the notify guard; a **policy table** that
turns today's dozens of identical pages into *zero immediate pages on a normal day* and a
digest at David's cadence; two-way decisions from Buzz threads (David's in-thread word →
a decision document, verbatim); `@Code` as a presence-independent **front desk** via
`buzz-acp`; and Telegram retired after a parallel week. Per-lane identities come with one
rule and one custody discipline. Documents at the front door stay the durable record.

## 1 · What is live today (verified on the box, 2026-08-18)

- Relay `wss://davids-mac-studio.tail841f5e.ts.net` (Tailscale-only), docker `buzz-prod-*`:
  relay :3000, Caddy TLS :443/:5443, pairing relay :5000, Postgres, Redis, MinIO. Desktop
  app; `~/.buzz` "nest" workspace with a Buzz-managed roster; **`Code` agent identity
  registered** (`@Code`) beside Buzz's stock personas (Fizz/Honey/Pollen).
- `buzz` CLI (`~/.local/bin`, arm64): `messages send|get|thread|search|edit`, `dms open|list`,
  `channels`, `reactions`, `feed`, `workflows` (YAML: message/reaction/schedule/webhook
  triggers), `notes` (NIP-23 long-form), `mem` (agent memory), `moderation`; JSON in/out;
  exit codes 0/1/2/3/4/5; `BUZZ_RELAY_URL`, `BUZZ_PRIVATE_KEY` (hex/nsec — **a secret**).
- `buzz-acp` (README + architecture doc §6): bridges relay events to an ACP agent subprocess
  (Goose/Codex/Claude Code) over stdio JSON-RPC; per-channel queue, one prompt in flight per
  channel, crash respawn, NIP-42 auth; pool 1–32; **does not persist state**.
- What the estate has today: `_lib/notify.sh` = desktop notification + Telegram (one bot,
  one chat), `notify_david <oi> <event> <msg> <qn> <ptr>` fired from **~14 call sites**
  (orchestrator: `escalated` ×14 shapes, `supervised`, `disposed`; designer:
  `design-refused`; PM: `pm-halt`; librarian: `FAIL`) with **no severity tiering**;
  `notify_count_only` (DEC-260112) — the 12:00/15:00 count-only Telegram; the receive half
  `poll_telegram_replies` (task 017): David's Telegram reply consumed as an interview answer
  → decision document.

## 2 · Principles (settled — from the record, not new)

1. **Buzz is the conversation lane** (ACI-260025 two-lane framework): it informs and
   coordinates. **It never authorizes and it is never the record.** A Buzz message enacts
   nothing; a decision is a decision *document* at the front door; a design is a sidecar.
2. **David's word in a Buzz thread is David's word** — quoted verbatim into a decision
   document by the surface that reads it, exactly as a Telegram reply or a terminal reply is
   today (DEC-260135 Effect 2's certification test applies to the filing, not the channel).
3. **Secrets:** every Buzz identity is a Nostr private key. Location only in any record;
   values live in the agent's launchd environment or the keychain; executor and panel
   sandboxes must not see any lane's key (a task must not be able to post as the
   orchestrator). ACI-260031's constraint verbatim.
4. **PHI-free by design; hosted buzz.xyz out of scope** (no BAA) — ACI-260031. Estate
   comms are summary-and-pointer (CLD-00073); nothing sensitive rides.
5. **Notifications are a delivery of a classification the machinery already computes**
   (DEC-260112's principle) — the board is the substance; a page only says "worth opening".

## 3 · The notification policy table (the substance David reacts to)

Owned by `notify.sh` as one table (event class → tier), not by each caller. Callers keep
saying *what happened*; the library decides *whether and how loudly to tell David*.

| Tier | Meaning | Event classes (from the ~14 live call sites + the board) | Channel |
|---|---|---|---|
| **Immediate** | stuck or unsafe — not merely waiting | stop-on-PHI / secret finding; **dead-letter** (a task exhausted its attempts); **model lane down > 2 wakes**; **PM sequence halted** (`pm-halt`); a red-line refusal on David-authored work; librarian `FAIL`; a `deferred` expiry with the loud finding | Buzz **DM** to David (phone buzzes) |
| **Next cycle** | waits without harm | ordinary escalations (`escalated`, [interview] questions); `supervised` hand-offs awaiting a sitting; anything else that lands on NEEDS YOU | Buzz **channel digest** at cadence: one post, one line per NEEDS YOU item = the question **and the filer's recommendation**, thread open under each |
| **Never** (log/board only) | self-correcting or informational | `design-refused` (the lane recovers or ages out — today's OI-000111 recovered in 3 min); clarify rounds; refiles; `disposed`; routine FLAGs; `pm-wait`; deliveries; `notify_count_only` when the count is 0 (already so) | ledger + `REVIEW.md` (+ a Buzz `#estate-log` mirror if David wants the narrative — read, never pushed) |

**Measured against 2026-08-18:** Immediate would have fired **0** times (nothing dead-lettered,
the model-lane blip lasted one wake, no halt); Next-cycle would have produced **2 digests
carrying 3 questions**; today's actual Telegram count was in the dozens. **Digest cadence
proposal:** 07:00 (the morning brief — the daily-log continuity block, distilled), 12:00,
15:00 (the DEC-260112 slots), plus **on change** when NEEDS YOU goes 0 → n (one post, then
quiet). The desktop notification keeps DEC-260112's rule: failure classes only.

**Two knobs David sets:** which classes are Immediate (the list above is the proposal, and
"escalations are never immediate" is its most consequential line), and DM vs channel for
the on-change post.

## 4 · Channels and identities

**Channels (proposal):** `#estate-attention` (NEEDS YOU digests + threads — the place David
reads), `#estate-status` (deliveries, PM sequence progress, the morning brief),
`#estate-log` (optional: a filtered ledger mirror — the narrative), `#estate-design` (design
conversations — the Designer/panel/`@Code` talking with David), DMs for Immediate.

**Identities — per lane, David's stated preference:** `@Code` (the consulting surface / front
desk — the identity that already exists), `@Orchestrator`, `@Designer`, `@PM`, later
`@Codex` and `@Reviewer`. Why per lane: legibility (a post reads as the lane that acted), and
Buzz's model is "agents are members"; each has its own audit trail. Cost: one key each,
custody per §2.3, minted by a small operator script (`buzz agents` is owner-reviewed
creation) so keys never pass through a session. **What a lane posts:** what it did and where
the record is — pointers, not payload (`OI-000112 escalated · 2 questions · pkg:
orchestrator/items/OI-000112.escalation.md · recommendation: …`).

**Lane-to-lane talk — two legitimate uses, one rule.** (a) *Surfacing*: the channel reads
like the ledger with judgment attached. (b) *Fast informal clarification*: `@Designer` asks
`@PM` "is step 3 landed?" and gets an answer in seconds. **The outcome of (b) still lands as
the durable thing it always was** — a corrected intake, a state file, a front-door filing.
Anything a lane learns in Buzz that would change what is authorized goes through the front
door. No lane's Buzz message is an input to any gate.

## 5 · The `@Code` front desk (buzz-acp)

**What it is:** a Claude Code session run by `buzz-acp` under the `Code` identity, bound to
`#estate-attention` and `#estate-design`, woken by @mention or by the digest it posted. It
does what the in-terminal watcher does today: reads the record (`REVIEW.md`, spines,
escalation packages, ledger), answers David's questions from it, answers record-answerable
escalations itself (DEC-260135 Effect 1), files corrected intakes and decision documents at
the front door, and briefs. **Presence-independent** — this is the durable answer to "does
the terminal need to be active".

**Restrictions (structural, not prompt):** the ACP session runs with the estate's write
restriction (`run_claude`'s deny profile: never `orchestrator/`, never lane inboxes except
its own filings via the front-door `mv`, never `_meta/grants`, never the estate decisions
tree except a new DEC on David's word); no lane key but its own; the DEC-260135 certification
test governs everything it files (a Buzz thread reply from David is his word — quoted
verbatim, dated, thread event id recorded as the provenance pointer). It never claims
authority; if it is unsure whether a reply is authority-side, it asks in-thread.

**Cost:** one Claude Code session per @mention or digest cycle; the measurement layer records
it (`RC_LANE=frontdesk`), so its cost is visible from day one — and the panel's later.
Bounded: `buzz-acp` pool of 1, one prompt in flight per channel.

## 6 · Two-way decisions from Buzz threads (replaces `poll_telegram_replies`)

Today: the orchestrator long-polls Telegram for David's reply to an interview and files it.
Design: the same receive step reads **`buzz messages thread <root>`** for the digest's
per-item root events; a David-authored reply (author = David's pubkey, the only authority
identity) under an item's thread is consumed exactly as a Telegram reply is — into a decision
document with the reply text verbatim and the Buzz event id as pointer. The front desk
(§5) can also do this conversationally: David asks two questions, gets answers, then says
"yes, (b)"; `@Code` files it. Either path ends in the same document. Telegram's poll stays
live through the parallel week, then retires.

## 7 · Alternatives considered (three, plus the recommendation)

| Option | Shape | Why not / why |
|---|---|---|
| **A. Tier only, keep Telegram** | policy table in `notify.sh`; no Buzz | Fixes the volume (0 immediate pages) but not the "open a session to learn anything" problem; no conversation; no presence-independence. Cheapest; a strict subset of the recommendation — worth doing *first* regardless. |
| **B. Buzz sink + digest, no front desk** | A + Buzz channels/DMs + two-way from threads | Fixes volume and detail; David reads the recommendation in the digest and rules in-thread. Still no one to *ask* — questions wait for a session. |
| **C. Full: A + B + `@Code` via buzz-acp + per-lane identities** | the design above | Conversation and presence-independence; the ACI-260025 lane finally has a substrate. Costs: key custody per lane, one more long-running process, front-desk session cost (measured). |
| **Recommendation: C, built in the order A → B → C** | | Each step is useful alone; each is reversible; A lands the biggest quality-of-life change in an afternoon. |

## 8 · Build increments (each files on its precondition; DEC-260135 enactment)

- **B-0 — the policy table** (Alternative A): `notify.sh` gains the tier table; every call
  site passes its event class (already does — the second argument); Immediate/Next-cycle/
  Never enforced by the library; the digest job (a housekeeper pass at cadence + on
  NEEDS-YOU change) composes from `reviewboard.py`'s classification. Telegram is the
  transport for now. *Precondition:* ACI-260030's guard landed (same file). **David reacts to
  the table first.**
- **B-1 — Buzz sink:** `notify.sh` gains a Buzz transport (`buzz messages send` / `buzz dms`)
  beside Telegram, behind `NOTIFY_LIVE`; channels created; the `Code`/lane identities'
  keys in the agents' environments (custody per §2.3). Parallel run begins.
- **B-2 — digest content:** morning brief (07:00) from the daily-log continuity block; the
  status posts; `#estate-status` deliveries/PM progress. Per-lane identities post their own
  lines (needs B-1's keys).
- **B-3 — two-way from threads:** the receive step reads Buzz threads for David's replies
  (his pubkey only) → decision documents; Telegram poll kept in parallel.
- **B-4 — `@Code` front desk:** `buzz-acp` + a Claude Code ACP config under the `Code`
  identity, write-restricted, `RC_LANE=frontdesk`; a design memo of its own for the prompt
  template (version-controlled), scope and cost bound; a launchd agent (David's word).
- **B-5 — retire Telegram** after ≥7 days parallel with no missed Immediate/Next-cycle item
  (a housekeeper comparison of the two transports' send logs is the proof).

## 9 · Risks, named

- **Authority leaking through chat** — mitigated by §2.1/2.2: nothing routes on a Buzz
  message; only David's pubkey is an authority source; the certification test applies.
- **Key custody** — per-lane keys multiply the secret surface; the operator script + launchd
  environment + a housekeeper check that no key value appears in any repo (the existing
  secret scan covers `nsec`/hex patterns — extend its fixture).
- **A second long-running process** (`buzz-acp`) — the housekeeper's staleness watch learns
  it; the front desk's absence degrades to "digest without answers", never to silence.
- **Buzz is pre-1.0** (README's maturity matrix): CLI/harness surfaces may move; pin the
  release, wrap the CLI in one adapter (`_lib/notify_buzz.sh`) so a change is one edit.
- **Relay availability** — Tailscale-only; if down, the sink logs and the desktop channel
  still fires for failure classes (DEC-260112 rule) — no single point of silence.

## 10 · What this design does not do

No PHI, no hosted Buzz, no authorization via chat, no lane writes into another lane's
watched folder via Buzz, no replacement of the front door or of decision documents, no
change to the red lines, no new model in the loop for tiering (the table is code).

## 11 · Open for David

1. **The tier table** (§3): confirm/edit the Immediate list; "escalations are never
   immediate" yes/no; DM vs channel for the on-change post; cadence 07/12/15.
2. **Identities:** per lane (recommended) — start with `@Code`, `@Orchestrator`, `@Designer`,
   `@PM`; add `@Codex`, `@Reviewer` when their lanes warrant.
3. **May `@Code` file a decision document from David's in-thread word?** (recommended yes,
   verbatim-quoted, event id as pointer — identical to today's terminal practice.)
4. Channel names (§4) — or David's own.

## Records

ACI-260032 (this item), ACI-260031 (pilot; `buzz-evaluation-260818.md`), ACI-260025 (two-lane
framework), ACI-260030 (notify guard), DEC-260112 (count-only notices), DEC-0099 / CLD-00073
(channel + shape), DEC-260135 (what a surface may answer), task 017 (Telegram two-way),
`_lib/notify.sh`, The_Library `agent-communications/buzz-*` (2026-08-18 captures).
