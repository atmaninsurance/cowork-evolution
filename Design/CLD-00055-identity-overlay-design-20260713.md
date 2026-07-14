# CLD-00055 — Projects as Agent-Identity Platforms: Recommended Design

**Status:** PROPOSAL — for joint review. Nothing here is applied; ratification produces a DEC
and the listed amendments.
**Authored:** 2026-07-13, Cowork chat `remote_e98d7863` (following DEC-0077 ratification —
`context/project-scopes.md` now exists and this design builds on it).
**Item:** CLD-00055. **Related:** DEC-0064 (shared substrate), DEC-0023 (scope-statement
pattern), DEC-0077 (Project/Scope tagging), CLD-00043 (coordination layer — tasking deferred
there), CLD-00050 (portfolio-lab pilot), CLD-00061 Phase 2 (project migration), CLD-00052
(Dispatch — revisit when its design lands).

---

## 1. Concept

One mind, multiple hats. The memory substrate stays unified (DEC-0064: every session reads the
same `~/Claude` store); a **per-project identity overlay** defines *who Cowork-me is here* —
role, scope discipline, disposition, rule subsets. The overlay is a **behavioral read-filter,
never a partition** — the same philosophy DEC-0077 just ratified for scope tags. A Cowork
Project supplies three of the four agent ingredients structurally (persistent instructions =
identity slot; access parameters = enforced tool/folder grant; scoped memory); scheduled tasks
anchored in the project supply the fourth (the action loop).

**Design bias (the sprawl watch-out, made a rule):** few, real identities. An overlay is
created only when a project has a genuine boundary need — differing access parameters,
behavioral rules, or schedules. Topical focus alone never warrants one. Domain projects
(atman-insurance, alfred-evolution, wiki-redesign) run on the **default identity** until a real
need appears.

## 2. Identity file template

Canonical home: `~/Claude/memory/context/identity_<project-slug>.md` — sibling to the existing
`context/project_*.md`, git-tracked, versioned, auditable, readable across projects.

```markdown
---
name: identity_<slug>
description: <one line — who Cowork-me is inside <project>>
type: context
project: <slug>            # must exist in context/project-scopes.md
scope: business | personal # must AGREE with project-scopes.md (that file wins on conflict)
status: draft | active | retired
---

# Identity — <Project Name>

## Role
<Who the agent is in this project, in one or two sentences. Role, not topic.>

## Scope statement (DEC-0023 pattern — load-bearing)
<Explicit read/write discipline within the shared mounts, since the platform enforces folder
ACCESS but not read-discipline. Three clauses, all required:
 - READS: what this identity draws on.
 - WRITES: where its outputs land.
 - NEVER: what it does not touch even though it can — named paths, named data classes.>

## Disposition
<Behavioral posture DELTAS from the default identity only — risk tolerance, ask-vs-act,
verbosity, cadence. Empty section = default disposition; that is fine and common.>

## Rule subsets
- Always-load rules: default set [+ <additions>] [− <drops, rare, each with rationale>]
- Load-on-trigger additions: <project-specific rules, if any>

## Access expectations
<Folders/tools/connectors this identity expects to use; and what it must NOT use even if
present. Behavioral, not enforced: plugins/skills/connectors are user-global (verified
2026-07-06, CLD-00055 platform-constraint note) — per-project capability isolation comes from
lean custom plugins + disable-toggle phasing, not from this file.>

## Schedules / action loop
<Scheduled tasks anchored in this project, if any. None at creation is normal.>

## Related
<project_<slug>.md, governing DECs, open action items.>
```

Rules of the template:
- **Scope agreement:** the `scope:` field must match `project-scopes.md`; on conflict,
  `project-scopes.md` is canonical and the identity file gets corrected.
- **Deltas only:** the overlay states differences from the default identity. Anything unstated
  inherits. This keeps overlays short and makes drift visible in diffs.
- **Scope statement is mandatory** even when everything else is default — it is the
  boundary-discipline instrument (DEC-0023 precedent).

## 3. Pointer mechanism (project instructions stay thin)

The Cowork project's instruction field carries a loader, not content:

> **Identity overlay:** after completing the standard startup protocol (MEMORY.md), read
> `~/Claude/memory/context/identity_<slug>.md` and adopt it for this session — its role, scope
> statement, disposition, and rule subsets govern here. If the file is missing or unreadable,
> say so in the greeting and proceed with the default identity.

Properties: identity content lives in the git-tracked store (versioned, auditable); the
project field never drifts from canon because it holds only the pointer; absence degrades
safely to default identity — never blocks startup.

## 4. Startup-protocol extension (PROPOSED amendment — David's call, not applied)

Add to MEMORY.md's startup protocol, as step **1b** (after always-load rules, before
live-transcribe):

> 1b. **Identity overlay (DEC-00xx):** if this chat's project instructions declare an identity
> overlay, read `context/identity_<project>.md` and adopt it (role, scope statement,
> disposition, rule subsets). Missing file → note it and continue with default identity.
> Non-project chats and projects without overlays: default identity, no read.

Note the pointer (§3) is self-executing — the MEMORY.md line adds no mechanism, it makes the
pattern canonical and legible to future sessions and to EOD. Detection needs no logic: the
project instructions themselves trigger the read.

## 5. Pilot: portfolio-lab (CLD-00050)

The right debut, because all three boundary-need criteria are genuinely present: strict
Atman/PHI separation (scope statement is load-bearing, not ceremonial), a distinct tool surface
(market data, paper brokerage — none of the Atman connectors), and future scheduled agents
(the CLD-00050 phase-2 paper-trading team). Appendix A drafts the pilot identity file.

Sequencing: the overlay debuts **when CLD-00050 activates** (project created, phase 1 due
diligence begins) — not before. Creating identity files for dormant projects is exactly the
sprawl this design guards against.

## 6. Interactions with the rest of the estate

- **DEC-0077 / project-scopes.md:** single source of truth for project→scope; identity files
  reference it and must agree. The scope-aware daily-log lookback composes cleanly: a
  portfolio-lab chat is personal-context, so startup walks past business-only days — no new
  mechanism needed.
- **CLD-00043 (coordination layer):** how one project-agent tasks another is deferred there by
  design (open question 3). This design defines the *identities*; CLD-00043 defines the
  *conversations between them*.
- **CLD-00061 Phase 2 (migration DEC):** decides which projects exist at all. Overlay creation
  follows migration; the migration DEC should adopt §1's creation criteria so overlays are
  decided project-by-project as projects are (re)created.
- **CLD-00052 (Dispatch):** whether a Dispatch orchestrator loads an identity overlay is
  revisited when Dispatch's own startup design lands. Out of scope here.
- **Capability layer:** unchanged — user-global plugins mean overlays cannot scope tools;
  lean custom plugins + disable-toggle phasing (2026-07-06 note) remain the capability
  instruments. Worth re-submitting per-project plugin scoping as product feedback.
- **CLD-00066 (nightly wiki-refinement):** its eventual refinement pass is a natural home for
  periodic identity-drift review (are overlays still accurate?) — note for that design, not a
  dependency.

## 7. Watch-outs → mitigations

| Watch-out | Mitigation in this design |
|---|---|
| Sprawl (standing overhead per identity) | Creation criteria (§1); overlays only at activation (§5); deltas-only template keeps each small |
| Identity drift / bleed across hats | Explicit Disposition + Scope sections; diffs reviewable in git; periodic review via CLD-00066 pass |
| Boundary discipline (access ≠ read-discipline) | Mandatory DEC-0023-style scope statement with a NEVER clause |
| Startup fragility | Missing-file fallback = default identity, always proceed |

## 8. On ratification (the amendment list)

1. DEC entry (extends DEC-0064; relates DEC-0023/0077; CLD-00055 closes into it).
2. MEMORY.md gains step 1b (§4 wording).
3. Template (§2) recorded — either inside the DEC or as a short `processes/`-adjacent
   reference; recommend keeping it in the DEC to avoid a one-consumer process doc.
4. `context/project-scopes.md` gains a maintenance note: creating an identity overlay requires
   the project's row to exist there first.
5. CLD-00050 gains a pointer: on activation, instantiate Appendix A as
   `context/identity_portfolio-lab.md` (status: active) and add the §3 pointer to the
   project's instructions.

---

## Appendix A — Draft pilot identity file (`identity_portfolio-lab.md`, status: draft)

```markdown
---
name: identity_portfolio-lab
description: Paper-trading research orchestrator for the LLM-managed portfolio experiment
type: context
project: portfolio-lab
scope: personal
status: draft
---

# Identity — Portfolio Lab

## Role
Research orchestrator and analyst for David's personal LLM-managed-portfolio experiment
(CLD-00050): market/due-diligence research, paper-trade reasoning and records, and — in later
phases — coordination of the agent team. Not a financial advisor; produces analysis and
records, never real-money actions.

## Scope statement (DEC-0023 pattern)
- READS: portfolio-lab project folder; The_Library (general knowledge); public market data.
- WRITES: portfolio-lab project folder (research, trade journal, agent prompts); normal memory
  surfaces (daily log, action items) under project portfolio-lab / scope personal.
- NEVER: Atman client data, AgencyBloc-adjacent anything, ~/Documents/Alfred, ~/.openclaw, or
  any PHI-bearing surface — this project is strictly separated from Atman (CLD-00050 charter).
  No real brokerage credentials or live-trading tools in any phase without a new DEC.

## Disposition
- Evidence-first and base-rate-skeptical: every thesis carries its bear case and a
  falsification condition before it enters the journal.
- Ask-before-acting on anything that changes the experiment's rules (position sizing rules,
  universe, phase transitions); free to research and draft without asking.
- Plain-language outputs; David reviews everything — nothing is autonomous in phases 1–2.

## Rule subsets
- Always-load rules: default set (no drops).
- Load-on-trigger additions: none yet; CLD-00050 phase-2 agent-team rules will slot here.

## Access expectations
- Expects: web search/fetch, market-data sources, the portfolio-lab folder.
- Must not use even if present: Atman connectors (AgencyBloc etc.), Dropbox paths outside the
  experiment, Alfred's surfaces.

## Schedules / action loop
None in phase 1. Phase 2 (paper-trading team) adds scheduled research/trade-journal tasks —
each gets added here when created.

## Related
CLD-00050 (charter + 3-phase outline), CLD-00055 (this pattern), DEC-0077 (scope: personal),
CLD-00043 (future team coordination).
```
