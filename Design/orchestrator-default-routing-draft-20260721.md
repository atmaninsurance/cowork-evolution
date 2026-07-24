# Orchestrator default routing — draft for David's review (2026-07-21)

*(Re-materialized 2026-07-22 at close of chat `remote_aea41040` per the 07-22 daily-log resume
instruction — originally delivered as a chat attachment only. Three open David calls at bottom.)*

> **RATIFIED 2026-07-23 as DEC-0081** (chat `remote_62d4de81`), with one amendment: the consulting
> chat authors the intake document and files it DIRECTLY into `orchestrator/inbox/` — the
> save-to-a-side-file-then-David-copies pattern is retired for machinery-bound work. Template
> installed at `_meta/intake-consultation-template.md`. Rule load class: always-load. See DEC-0081
> for the open placement details (rule home, design-docs home, output-doc template).

Two pieces, designed to work together. Neither is installed anywhere yet — placement is
your call (proposed homes at the bottom).

---

## Piece 1 — The standing "default prompt" (rule text chats load)

This is the behavioral half: a short standing instruction so any future Cowork or Code
chat routes buildable work to the Orchestrator by default instead of improvising.

> ### Rule: route-future-work-to-orchestrator (draft)
>
> When a chat surfaces work that should be **executed later by the machinery** (research
> passes, builds, document generation, recurring maintenance — anything a headless session
> could do), the default route is the **Orchestrator front door**
> (`~/Documents/Agent_Workflow/orchestrator/inbox/`), filed as a consultation intake item —
> NOT an ad-hoc promise in the chat, and NOT a direct drop into `code/inbox/`.
>
> **Before filing, the anchor must exist.** `origin: david-consultation` intake is
> hard-rejected unless `related:` resolves to a real CLD/DEC/action-item record. If the
> work has no record yet, open the action item first (updating `_index.md` per the
> action-items-index rule), then file the intake referencing it. The record is the
> authorization substrate — file the paperwork before the request.
>
> **Use the template** at `_meta/intake-consultation-template.md` (Piece 2). The intake
> describes and proposes; it never presumes routing — the orchestrator's V/D pass and
> David's decision own that. Zero executor attempts are burned before David decides
> (conservative defaults, CLD-00073).
>
> **Exceptions (the rare paths):**
> - David explicitly directs the `code/inbox/` bypass (David-authored tasks may skip the
>   orchestrator; still screened).
> - Work executed live in the current chat under David's supervision is not "future work" —
>   no intake needed.
>
> **Never in an intake file:** PHI/client data, credentials, or anything on the screen's
> deny-list. The repo syncs; intake must be PHI-free by construction.

---

## Piece 2 — The copyable intake template (`intake-consultation-template.md`)

Parallel to the existing `_meta/prompt-template.md` (which covers executable bypass
tasks). This one is the consultation-intake shape from `_meta/schema.md` §Orchestrator
intake items, made copy-ready:

```markdown
---
id: consult-YYYYMMDD-<slug>       # or a routable NNN-<slug> when the doc IS the candidate task (class b)
status: queued
priority: 3                       # 1-5 (1 highest)
origin: david-consultation
requested_by: cowork              # david | cowork | code — who is physically filing this
created: YYYY-MM-DD               # Pacific date — read the clock
related: [CLD-####]               # REQUIRED — must resolve to real CLD/DEC/action-item records
source: chat <chat-id>            # the consultation chat this evolved from
---
# <One line: what is proposed>

## What
<The work, concretely. What exists today, what should exist after, why now.>

## Provenance
<Which part of the anchored record contemplates this work — name the section or quote the
line, so the V/D judgment layer ("does the record substantiate it?") is easy to satisfy.
A resolvable anchor that doesn't actually contemplate the work is exactly what V/D exists
to catch — make the substantiation explicit.>

## Proposed routable task (draft — orchestrator/David decide; re-screened at promotion)
- model: sonnet | opus
- timeout_minutes: NN
- deliverable: artifacts/<id>/<file>
- body sketch: <or a full draft body if ready>

## Suggested deliver_to
<project-folder path> | queue | daily-log | none
<!-- Suggestion only: deliver_to flows from David's decision document, not from intake.
     The_Library is never a mechanical destination. -->

## Open questions for V/D / David
<Anything unresolved the adjudication should weigh.>
```

---

## Proposed placement (your call)

- **Template** → `~/Documents/Agent_Workflow/_meta/intake-consultation-template.md`
  (sibling to `prompt-template.md`; `_meta` is the singular constitution, so adding a file
  there should be deliberate — hence this review).
- **Rule** → `~/Claude/memory/rules/route-future-work-to-orchestrator.md`. Load class is
  a real choice: **always-load** makes the default stick in every chat (one more startup
  read); **load-on-trigger** is lighter but recreates the "process exists but doesn't fire"
  gap the decision-capture rule closed. My recommendation: always-load — it's short, and
  a default that isn't loaded isn't a default.
- **DEC:** adopting "Orchestrator as the default route for future work" changes how future
  work is done across all chats — this looks DEC-worthy under the threshold. If you ratify,
  it gets captured per processes/decision-capture.md (create → relate → sweep;
  it extends DEC-0078 and the CLD-00073 lineage).
