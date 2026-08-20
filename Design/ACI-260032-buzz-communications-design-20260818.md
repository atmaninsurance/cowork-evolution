# Buzz as the estate's communication surface — design pass (ACI-260032)

**Status:** design pass, 2026-08-18 (Code session `38ff89fa`), amended 2026-08-19 with David's
selected Planner-side ledger + Resolver pilot. Nothing here is built. The operative Planner
contract is `Agent_Workflow/Design/planner-lane-20260819.md` v2; where this earlier design says
`@Code`, front desk, direct per-lane Buzz posting, or launchd-held Buzz keys, that contract
supersedes it. Sibling: **ACI-260031** (the Buzz sandbox pilot, session `cd41c78d`) is the substrate —
its evaluation `buzz-evaluation-260818.md` and its constraints govern here.
**Project:** cowork-evolution. **Anchors:** ACI-260032, ACI-260031, ACI-260025, ACI-260030,
DEC-260112, DEC-0099 / CLD-00073, DEC-260135. **Sources:** `The_Library/agent-communications/buzz-*`.

## 0 · In one paragraph

Buzz gives the estate what Telegram never had: rooms where **agents are members**, threads,
a searchable durable event log, and a harness (`buzz-acp`) that runs a Claude Code or Codex
session as a live agent that answers @mentions. The design uses it for exactly one job —
**the conversation lane** (ACI-260025: informs and coordinates; never authorizes; never the
record). David begins new work with `@Planner` in `#planning`. Pipeline events remain local:
Watcher writes a Planner-side ledger and triggers a Resolver to answer record-answerable
questions; a scheduled Buzz workflow wakes the Planner to post only `NEEDS_DAVID` items in
`#authorization`. David's replies become decision documents verbatim. Housekeeper keeps its
existing out-of-band notification path during the pilot. Documents at the front door stay
the durable record.

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
3. **Secrets:** every Buzz identity is a Nostr private key. Values stay inside Buzz Desktop;
   they are not extracted, recorded, or placed in launchd environments. Executor and panel
   sandboxes must not see any lane's key. ACI-260031's constraint governs.
4. **PHI-free by design; hosted buzz.xyz out of scope** (no BAA) — ACI-260031. Estate
   comms are summary-and-pointer (CLD-00073); nothing sensitive rides.
5. **Notifications are a delivery of a classification the machinery already computes**
   (DEC-260112's principle) — the board is the substance; a page only says "worth opening".

## 3 · The notification policy table (the substance David reacts to)

Owned by `notify.sh` as one table (event class → tier), not by each caller. Callers keep
saying *what happened*; the library decides *whether and how loudly to tell David*.

| Tier | Meaning | Event classes (from the ~14 live call sites + the board) | Channel |
|---|---|---|---|
| **Immediate** | stuck or unsafe — not merely waiting | stop-on-PHI / secret finding; **dead-letter** (a task exhausted its attempts); **model lane down > 2 wakes**; **PM sequence halted** (`pm-halt`); a red-line refusal on David-authored work; librarian `FAIL`; a `deferred` expiry with the loud finding | Pilot: existing `notify.sh`; later candidate: Housekeeper Buzz DM through a constrained bridge |
| **Next cycle** | waits without harm | ordinary escalations (`escalated`, [interview] questions); `supervised` hand-offs awaiting a sitting; anything else that lands on NEEDS YOU | Resolver prepares `NEEDS_DAVID`; scheduled Planner wake posts one `#authorization` entry per item |
| **Never** (log/board only) | self-correcting or informational | `design-refused` (the lane recovers or ages out — today's OI-000111 recovered in 3 min); clarify rounds; refiles; `disposed`; routine FLAGs; `pm-wait`; deliveries; `notify_count_only` when the count is 0 (already so) | ledger + `REVIEW.md` (+ a Buzz `#estate-log` mirror if David wants the narrative — read, never pushed) |

**Measured against 2026-08-18:** Immediate would have fired **0** times (nothing dead-lettered,
the model-lane blip lasted one wake, no halt); Next-cycle would have produced **2 digests
carrying 3 questions**; today's actual Telegram count was in the dozens. **Selected reminder
cadence:** hourly 08:00–17:00 Pacific, count-only and only when open items exist. The scheduled
collection wake may run more frequently; its exact interval remains open. The desktop
notification keeps DEC-260112's rule: failure classes only.

**Remaining knobs:** which classes are Immediate (the list above remains a proposal, and
"escalations are never immediate" is its most consequential line) and the scheduled Planner
collection interval. Delivery of Housekeeper failures through Buzz is deferred with the
bridge trial.

## 4 · Channels and identities

**Selected pilot channels:** `#planning` (David and Planner develop new work),
`#authorization` (one top-level post per David-class question; David replies in its thread),
and `#watcher` (created but reserved during the ledger-based pilot). Planner sends the hourly
count-only DM. Housekeeper uses the existing failure channel until a later bridge trial.

**Selected identities:** David created `@Planner`, `@Watcher`, and `@Housekeeper`. Only Planner
is active as a Buzz model surface in this pilot. Watcher and Housekeeper remain deterministic
launchd processes without access to their desktop-held keys; their Buzz identities are
reserved for a later constrained bridge trial.

**Lane-to-lane talk — two legitimate uses, one rule.** (a) *Surfacing*: the channel reads
like the ledger with judgment attached. (b) *Fast informal clarification*: `@Designer` asks
`@PM` "is step 3 landed?" and gets an answer in seconds. **The outcome of (b) still lands as
the durable thing it always was** — a corrected intake, a state file, a front-door filing.
Anything a lane learns in Buzz that would change what is authorized goes through the front
door. No lane's Buzz message is an input to any gate.

## 5 · The Planner lane: local Resolver + Buzz Planner

**What it is:** one logical Planner lane with two execution surfaces and one durable work
ledger. Watcher creates an idempotent item and mechanically triggers a local **Resolver**.
The Resolver claims only that item, researches the record, files record-supported answers,
or marks it `NEEDS_DAVID` with a question and recommendation. A scheduled Buzz workflow wakes
`@Planner`; the Buzz Planner claims those items, posts each in `#authorization`, and records
the thread pointer. Separately, David starts ideas and planning work directly in `#planning`.

**Restrictions (structural, not prompt):** the ACP session must be proven to run with the estate's write
restriction (`run_claude`'s deny profile: never `orchestrator/`, never lane inboxes except
its own filings via the front-door `mv`, never `_meta/grants`, never the estate decisions
tree except a new DEC on David's word); no lane key but its own; the DEC-260135 certification
test governs everything it files (a Buzz thread reply from David is his word — quoted
verbatim, dated, thread event id recorded as the provenance pointer). It never claims
authority; if it is unsure whether a reply is authority-side, it asks in-thread. Buzz Desktop
currently spawns outside the established wrapper, so enforcement and measurement are B-4
verification gates, not assumptions. The local Resolver uses the same write shape, receives
one item id, has no Buzz identity, and cannot author an authority-side decision.

**Coordination:** states are `NEW`, `LOCAL_REVIEW`, `RESOLVED`, `NEEDS_DAVID`, `POSTED`,
`ANSWERED`, `FILED`, and `FAILED`. Only one worker may lease an item. Buzz is never the only
copy of the work or its status. Cost is measured separately for Resolver sessions and
Buzz-Planning sessions; `buzz-acp` remains pool 1, one prompt in flight per channel.

## 6 · Two-way decisions from Buzz threads (replaces `poll_telegram_replies`)

Today: the orchestrator long-polls Telegram for David's reply to an interview and files it.
Design: the Buzz Planner receives David's reply in the item's `#authorization` thread
(author = David's pubkey, the only authority identity), marks the Planner-side ledger item
`ANSWERED`, and files a decision document with the reply text verbatim and the Buzz event id
as pointer, then marks it `FILED`. The same rule applies when David reaches a decision in a
`#planning` thread. Either path ends in the same durable document. Telegram's poll stays live
through the parallel week, then retires.

## 7 · Alternatives considered (three, plus the recommendation)

| Option | Shape | Why not / why |
|---|---|---|
| **A. Tier only, keep Telegram** | policy table in `notify.sh`; no Buzz | Fixes the volume (0 immediate pages) but not the "open a session to learn anything" problem; no conversation; no presence-independence. Cheapest; a strict subset of the recommendation — worth doing *first* regardless. |
| **B. Buzz sink + digest, no front desk** | A + Buzz channels/DMs + two-way from threads | Fixes volume and detail; David reads the recommendation in the digest and rules in-thread. Still no one to *ask* — questions wait for a session. |
| **C. Ledger + Resolver + Buzz Planner** | Watcher/Resolver local; scheduled workflow and David messages wake Planner | **Selected pilot:** no key extraction or Buzz fork; durable handoff and fewer David questions. Costs: wake latency and coordination between two Planner-lane sessions. |
| **D. Constrained local Buzz bridge** | Retain ledger; allow fixed Watcher post and/or Housekeeper DM through desktop-held identities | Deferred trial, likely Housekeeper first. Reduces latency but adds security-sensitive custom Buzz code and update maintenance. |

## 8 · Build increments (each files on its precondition; DEC-260135 enactment)

- **B-0 — the policy table** (Alternative A): `notify.sh` gains the tier table; every call
  site passes its event class (already does — the second argument); Immediate/Next-cycle/
  Never enforced by the library; the digest job (a housekeeper pass at cadence + on
  NEEDS-YOU change) composes from `reviewboard.py`'s classification. Telegram is the
  transport for now. *Precondition:* ACI-260030's guard landed (same file). **David reacts to
  the table first.**
- **B-1 — Planner work ledger + Resolver:** deterministic Watcher writes idempotent items;
  local Resolver claims one item, answers from the record or marks `NEEDS_DAVID`; leases,
  receipts, retries, stale-state checks and measurement included. No Buzz key is used.
- **B-2 — Buzz Planner wake:** scheduled workflow wakes desktop-brokered Planner to collect
  `NEEDS_DAVID`, post one question per `#authorization` thread, and send the hourly count-only
  DM; David's `#planning` messages also wake it.
- **B-3 — two-way from threads:** the receive step reads Buzz threads for David's replies
  (his pubkey only) → decision documents; Telegram poll kept in parallel.
- **B-4 — Planner hardening:** verify desktop-spawned restrictions and measurement, restart
  recovery, duplicate suppression, lease recovery, and preservation across Buzz outage.
- **B-5 — retire Telegram** after ≥7 days parallel with no missed Immediate/Next-cycle item
  (a housekeeper comparison of the two transports' send logs is the proof).

## 9 · Risks, named

- **Authority leaking through chat** — mitigated by §2.1/2.2: nothing routes on a Buzz
  message; only David's pubkey is an authority source; the certification test applies.
- **Key custody** — desktop holds the keys and provides no supported export. The selected
  pilot avoids key use outside Buzz; do not extract them.
- **Split processing** — Resolver and Buzz Planner could duplicate an item. Mitigation:
  single-item leases, append-only transitions, stable ids and idempotent filings.
- **Desktop-brokered Planner availability** (`buzz-acp`) — Housekeeper watches its health and
  stale Planner-ledger states; its absence delays David-facing delivery but cannot erase work.
- **Buzz is pre-1.0** (README's maturity matrix): workflow and harness surfaces may move; pin
  the pilot release and isolate Buzz-specific wake logic behind one adapter.
- **Relay availability** — Tailscale-only; if down, Planner-side items remain durable and
  Housekeeper's out-of-band `notify.sh` path remains available.

## 10 · What this design does not do

No PHI, no hosted Buzz, no authorization via chat, no lane writes into another lane's
watched folder via Buzz, no replacement of the front door or of decision documents, no
change to the red lines, no new model in the loop for tiering (the table is code).

## 11 · Open for David

1. Exact scheduled Planner collection interval for newly created `NEEDS_DAVID` items; the
   hourly 08:00–17:00 count-only DM is settled.
2. After the ledger pilot, whether to trial a constrained local Buzz bridge for Housekeeper.

## Records

ACI-260032 (this item), ACI-260031 (pilot; `buzz-evaluation-260818.md`), ACI-260025 (two-lane
framework), ACI-260030 (notify guard), DEC-260112 (count-only notices), DEC-0099 / CLD-00073
(channel + shape), DEC-260135 (what a surface may answer), task 017 (Telegram two-way),
`_lib/notify.sh`, The_Library `agent-communications/buzz-*` (2026-08-18 captures).
