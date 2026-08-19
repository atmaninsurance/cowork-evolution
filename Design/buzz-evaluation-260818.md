# Buzz (Block, Inc.) — evaluation for estate agent comms

**Date:** 2026-08-18 · **Requested by:** David ("look into Buzz and how we might use
it for agent interactions and as a centralized communication platform") · **Tier:**
standard research pass per `The_Estate/skills/research/SKILL.md`, one delegated
researcher, Code session `cd41c78d`. Source snapshots:
`~/Documents/The_Library/agent-communications/` (new collection, 4 items).
Provenance: **[V]** verified (page fetched) · **[E]** estimated (assessment) ·
**[I]** inferred-related.

## What Buzz is

- **[V]** Free, open-source (Apache-2.0) team-chat workspace from Jack Dorsey's
  Block, Inc., launched 2026-07-21, built explicitly for humans and AI agents as
  co-equal workspace members. Hosted at buzz.xyz; self-hostable from source.
  Sources: https://block.xyz/inside/introducing-buzz-where-humans-and-agents-work-together ,
  https://github.com/block/buzz
- **[V]** Pre-1.0 and says so: README verbatim — "Not finished. We will tell you
  what works and what doesn't." Working today: relay, channels, threads, DMs,
  canvases, search, audit log, desktop app, CLI + agent harness, YAML workflows,
  git events. Still being wired up: **mobile clients**; pending entirely: **push
  notifications**, compliance features. ~28.3k GitHub stars in ~5 months; release
  `desktop-v0.5.14` on 2026-08-15; 2,800+ open issues.
  Sources: https://raw.githubusercontent.com/block/buzz/main/README.md , GitHub API.
- **[V]** TechCrunch's launch assessment: early stages — "probably not a good idea
  to port your team over just yet."
  Source: https://techcrunch.com/2026/07/21/jack-dorsey-is-taking-on-slack-with-buzz-a-group-chat-platform-for-teams-and-their-ai-agents/
- **[V]** Name disambiguation: not Buzz.ai (an AI sales-outreach product,
  https://buzz.ai/ — ruled out) and not Google's dead 2010 Buzz.

## The interesting mechanics

- **[V]** Built as a single Nostr relay: every message, reaction, workflow step,
  review approval, and git event is a **cryptographically signed event in one
  audit log**, identical in shape whether the author is a person or an agent.
  Agents hold their own keypairs, channel memberships, and audit trails.
  Source: https://raw.githubusercontent.com/block/buzz/main/ARCHITECTURE.md
- **[V]** Agent connection paths name our stack directly: the ACP harness supports
  **Claude Code and Codex** (and Block's Goose); `buzz-cli` speaks JSON in/out
  "designed for LLM tool calls"; there is an MCP bridge; workflows fire on
  message/reaction/schedule/webhook triggers. Sources: README + ARCHITECTURE.md.
- **[V]** Self-hosting = one relay (Docker Compose) with data in your own
  Postgres/Redis/MinIO; "no peer-to-peer event exchange, no gossip, no
  replication." Source: ARCHITECTURE.md.

## Fit against the estate's two uses

**(a) Agent-to-agent interactions — [E] good conceptual fit; the authority
boundary is ours to enforce.** Each estate actor (Code, Cowork, the OpenClaw
assistant, the Codex lane) would hold its own signing key and a per-event audit
trail — a stronger provenance story than Telegram or ad-hoc glue, and directly in
the spirit of ACI-260025's **conversation lane** (informs, never authorizes). The
caution: Buzz's defaults pull the other way — its pitch is agents *acting* from
chat (merging patches, running workflows). Work must stay gate-mediated through
the file queues; Buzz could only ever be the talk lane.

**(b) Centralized comms platform — [E] right shape, premature today.** As the
consulting surface that demotes Telegram to notify-only (CLD-00102), Buzz has the
right shape: David + all agents in shared channels, threads, DMs, searchable
history. But the two features that job depends on for reaching David —
**mobile clients and push notifications — do not exist yet** [V: README]. Until
they ship, Buzz cannot replace Telegram for the phone.

## Constraint scorecard

- **Self-host preference:** [V/E] strong match — Apache-2.0, own hardware, own
  database, no lock-in.
- **HIPAA/BAA:** [V-absence] no BAA or compliance offering found for hosted
  buzz.xyz; README verbatim: "Please do not plan your compliance program around
  the 💭 column yet." Hosted version is off the table for anything
  operational-data-adjacent; self-hosting keeps it inside the PHI-free estate
  boundary, which estate comms already satisfy by design.
- **Credential-at-rest:** [V] real concern — each agent's identity is a raw Nostr
  private key in a `BUZZ_PRIVATE_KEY` environment variable; no key-rotation
  tooling found. [I] No end-to-end encryption found in the architecture doc, so
  the relay host reads everything — self-hosting contains this but adds N new
  long-lived signing keys to manage.
- **Maturity:** [V] pre-1.0, vendor and independent press both say don't migrate
  yet.

## Recommendation

**[E] Monitor, don't adopt. Optionally: a small sandbox pilot.** One self-hosted
relay on estate hardware with two agents in one channel would test the
conversation-lane concept (ACI-260025) at near-zero risk, since estate comms are
PHI-free and the relay would be local. Re-evaluate for the CLD-00102 role when
three things ship: mobile clients, push notifications, and workflow approval
gates. Watch item shape mirrors ACI-260027 (DeepSeek Harness).

## What this rests on / still unverified

Rests on: the project's own README/ARCHITECTURE (fetched raw from the repo,
2026-08-18), Block's announcement, TechCrunch's independent coverage, and GitHub
API metadata. Still unverified: hosted buzz.xyz terms/pricing; any formal
compliance posture (likely nonexistent yet); DM encryption (absence inferred from
one doc, not positively stated); real-team adoption beyond stars; the competitor
Centaur (named by TechCrunch only); repo SECURITY/VISION docs not fetched.

## Wiki candidates (flag-only per DEC-0034)

- [WIKI-CANDIDATE?] Buzz (Block, 2026): open-source Nostr-relay team workspace
  with AI agents as first-class members (own Schnorr keypairs; CLI/ACP/MCP
  connection paths); Apache-2.0; pre-1.0 as of 2026-08.
- [WIKI-CANDIDATE?] Nostr NIP-42/NIP-98 as an agent-identity pattern: portable
  cryptographic identity for agents instead of platform-issued bot tokens.
- [WIKI-CANDIDATE?] ACP (Agent Client Protocol) as the emerging harness layer
  bridging coding agents into chat workspaces, bridged to MCP.
- [WIKI-CANDIDATE?] The 2026 "agents as teammates in chat" category: Buzz vs
  Centaur vs Slack-bot incumbents, with Matrix/Zulip as open alternatives.
