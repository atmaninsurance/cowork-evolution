---
title: The mandatory `action_item:` provenance field — design
date: 2026-08-20
task: 136-design-pass-the-mandatory-actionitem-pro
oi: OI-000124
action_item: ACI-260035
related: [OI-000124, ACI-260035, CLD-00074, DEC-0094]
status: working paper — SPECIFIES AND RECOMMENDS; nothing in it has been applied
---

# The mandatory `action_item:` provenance field — design working paper

**What this is.** The design pass ACI-260035 called for: a specification of the
`action_item:` frontmatter field — the single field that names *the* owning action item on
every pipeline document — plus the exact build change list, the ledger token and helper
script, the enablement sequence, the `project:` recommendation, and the decision list for
David. Six points were ruled in the Buzz `#planning` thread on 2026-08-20 and are treated
as fixed here: the name `action_item:`; the scope list; ledger Option A (mint-line token +
helper script); hard-fail enforcement landed with the template updates; new-documents-only
migration; and ONE standing default item (David: "Agreed on ACI-MAINT"). This paper does
not re-argue them.

**Nothing in this paper was applied.** Every file named in §3 is exactly as it was; no id
was minted, no template edited, no record opened or closed. This is by the task's fence:
the paper proposes, a later separately-authorized build lands.

**How to read the citations.** Every claim about the running machinery names the file and
line inspected on 2026-08-20 (e.g. `_meta/screen.py:157`). Where a record and the running
code disagree, the code governs and the divergence is stated (one is recorded in §8).

---

## 1. Document-class inventory (verified against the live templates and code)

The two live action-item id families, verified against the registry itself
(`~/Documents/The_Estate/action-items/`, listed 2026-08-20): the current estate family
`ACI-YYXXXX` (29 open files), and the legacy families `CLD-NNNNN` (82 open, 49 closed in
`closed-items/2026/`) and `ALF-NNN` (35 open, 22 closed) — migrated in full, frozen in id,
closed to new mints, draining by normal closure (`The_Estate/conventions/registry.md:12-14`).
"Both families" below means: a `CLD-`/`ALF-` value must be exactly as well-formed as an
`ACI-` value.

### 1.1 The classes, their templates, and their provenance fields today

| # | Class | Defined by | Provenance fields today | In/out |
|---|-------|-----------|--------------------------|--------|
| 1 | Consultation intake | `_meta/intake-consultation-template.md:1-20` | `origin: david-consultation`, `requested_by`, `related:` (REQUIRED, screen-enforced anchor resolution — `screen.py:1102-1112`), `project:` (template-required, DEC-0094), `source:` | **IN** (ruled) |
| 2 | Decision document | `_meta/decision-template.md:17-38` | `origin: david-decision`, `related: [OI + authority ids]` (screen-enforced OI link — `screen.py:1114-1118`), `decision:`, `execution:`, `deliver_to:` | **IN** (ruled, as an intake-class document) |
| 3 | Clarification response / corrected intake | no dedicated template; shape per `_meta/authoring-contract.md` §6 and the Designer's `designer/templates/duty-clarify.md:58-66` | `origin: agent-proposal/designer` (Designer path), `requested_by: cowork`, `related: [OI]` | **IN** (ruled) |
| 4 | System-alert intake | code-emitted by `_lib/attention.sh:write_attention` (frontmatter at `attention.sh:66-79`) | `origin: system-alert`, `requested_by: system/<producer>`, `related:` (optional), `source:` | **IN — an AMENDMENT to the ruled list**, see §1.2 |
| 5 | Machinery-triage intake (nightly transcript lint) | code-emitted by `~/Claude/Scheduled/nightly/lint-transcripts.py` (grep-verified 2026-08-20; live example: `orchestrator/archive/2026/OI-000117.intake.md`, `origin: machinery-triage`) | `origin`, `requested_by`, `related`, `project`, `source` | **IN — same amendment**, see §1.2 and the divergence note in §8 |
| 6 | Executable queue task (headless and supervised; David bypass or orchestrator-instantiated) | `_meta/prompt-template.md:1-17`; schema in `_meta/schema.md` | `related:` OPTIONAL — screen ignores it (`schema.md:161-164`; no `related` check anywhere in `screen.py:screen_file`, L774-882); `requested_by`, `created`, `deliverable`, `verified`, `task_type` | **IN** (ruled) |
| 7 | Sequence sidecar (`OI-NNNNNN.sequence.md`) | no `.md` template; shape enforced by `_meta/sequencelib.py:validate_sidecar` (L394-503): `sequence`, `oi`, `version`, `designed_by`, `authorized_by`, `lane`, `risk_class`, `budget{max_model,total_steps}`, `completion`, per-step `precondition`/`verification` | `oi:` plus the two provenance stamps `designed_by`/`authorized_by` (L421-423) | **IN** (ruled) |
| 8 | Task report (output document) | `_meta/output-template.md:1-7` | `id`, `oi`, `related:` (echo of the task's), `completed`, `deliver_to` | **IN via a header line** (ruled). Note: no mechanical screen ever reads a report — see §3.9 |
| 9 | Design working paper (this document's class) | no template file — commissioned per-task by the task body; delivered under `~/Documents/Projects/<project>/Design/` | whatever the commissioning task requires; typically `related:`/`oi:` by convention | **IN** (ruled). Same enforcement caveat as reports (§3.9) |
| 10 | OI spine + machine-written sidecars (`.intake.md`, `.clarify.md`, `.escalation.md`, `.vd.md`) | machine-maintained by `_meta/oilib.py` (spine frontmatter is "tightly templated… authors never write it", `_meta/schema.md:341-345`) | `origin`, `requested_by`, `related`, `source`, `priority`, `project` carried from the intake at mint (`oilib.py:110`, `INTAKE_CARRY`) | **IN by mechanical inheritance** (ruled): one word added to `INTAKE_CARRY` |
| 11 | Designer design record (`designer/designs/OI-NNNNNN.design.md`) | skeletons inside `designer/templates/duty-clarify.md:83-113` and `duty-draft.md:115-152` | `oi:`, `design_round:`, `duty:`, `designed_by:`, `anchors:`, `block_sha256:` | **IN — amendment**: not named by the ruled list; placed in at one template line's cost, see §1.2 |
| 12 | Designer review-seat prompts (`designer/templates/review-assurance.md`, `review-challenger.md`, `review-codex-adversarial.md`) | themselves | they are session *prompts* (findings-only seats), not provenance-carrying filings | **OUT**: prompt scaffolding; the OI under review carries the field on its spine |
| 13 | Capability grants (`_meta/grants/GRANT-NNNN.md`) | orchestrator-minted (`orchestrator.sh:886`) | `oi`, `anchor`, `task_id`, `authorization` (`screen.py:430-431`) | **OUT**: machine-minted registry objects, already anchored (`anchor:` is a governance id); the ruled exclusion "the registry files themselves" covers them |
| 14 | Generated views — `orchestrator/_index.md`, the review board, prompt logs, `## Result`/`## Review` appended blocks, HANDOFF.md | various | n/a | **OUT** (ruled: generated views, bookkeeping) |
| 15 | Registry records, daily logs, transcripts | estate/`~/Claude` | n/a | **OUT** (ruled) |

### 1.2 Amendments to the ruled scope list

Nothing is grandfathered silently; three placements the ruled list did not name:

- **System-alert and machinery-triage intakes (rows 4-5) are IN.** The ruled list named
  "intakes (consultation, decision documents, clarification responses)" — but the running
  front door also takes intakes born from code: `write_attention` (sourced by
  `executor/worker.sh`, `executor/reviewer.sh`, `executor/housekeeper.sh`) and the nightly
  transcript lint. Since enforcement is hard-fail at `screen.py --intake` for **all**
  filings, leaving these producers un-updated would kill every machinery alert at the
  screen the day the switch lands. They are intakes; they go in, defaulting to the
  standing item (§2.3). This is the single most important amendment in this paper.
- **Designer design records (row 11) are IN.** They are template-authored documents keyed
  to an OI; adding `action_item: {{ACTION_ITEM}}` to the two skeletons costs one line each
  and keeps the class uniform. Enforcement is template-only (no screen reads them), same
  posture as reports.
- **Review-seat prompt templates (row 12) are OUT**, explicitly, for the reason in the
  table.

### 1.3 The three unsettled surfaces — explicit calls

**`_meta/schema.md` — IN.** The field gets a full definition there, in both the executable-
task field notes (beside `related:`, `schema.md:161-164`) and the intake-item section
(beside `project:`, `schema.md:283-292`). Reason: schema.md is the one frontmatter
reference authors copy from, and the decision-template's own header records what happens
when a field's function lives nowhere ("~90 decision documents… authored purely from
precedent-copying", `decision-template.md:3-6`). A screen-enforced required field with no
schema entry recreates exactly that failure.

**The estate registry's conventions record (`The_Estate/conventions/registry.md`) — IN,
small, David-gated.** One short subsection defining the *standing* lifecycle class (an item
that never closes by completion) and naming ACI-MAINT as its first member — plus, if D1
resolves to a literal id, a one-line exception to the numeric mint sequence. Reason: the
conventions file is where lifecycle vocabulary is defined (`registry.md:61-78`), and
without the class being named there, a standing item is indistinguishable from a stale
never-closed item to the EOD index reconciliation (`registry.md:50-52`). This file is on
the governance-modification list, so the edit itself needs David's invitation — it is in
the decision list (§7 D5).

**The wiki's `lint.py` (`~/Documents/The_Wiki/_meta/lint.py`) — OUT for now.** Reason:
lint.py lints wiki *pages* against the wiki's own schema (`lint.py:2-21`; its REQUIRED list
at `lint.py:42-43` is wiki-page fields), and wiki pages are not in the ruled scope — no
in-scope document class lives in The_Wiki. The screen.py↔lint.py "keep in sync" obligation
is specifically the twinned PHI/secret pattern sets (`screen.py:193-209`,
`lint.py:51-58`), which this design does not touch, so no drift arises. The matching rule
should be added if and when wiki documents start carrying the field — recommendation
recorded as §7 D4; David rules.

---

## 2. The field specification

### 2.1 Name and value syntax

- **Name:** `action_item:` — exactly this spelling, in YAML frontmatter.
- **Cardinality:** exactly ONE scalar value. Never a list — the field's whole point is to
  name *the* owner; everything else stays in `related:` (ruled point 1). A list value is a
  hard reject with its own reason.
- **Value syntax**, valid across both live id families:

  ```
  ACTION_ITEM_RE = ^(?:[A-Z]{2,4}-\d{3,6})$        (plus the literal ACI-MAINT if D1 = literal)
  ```

  Well-formed examples, all equally valid: `action_item: ACI-260035` (current family),
  `action_item: CLD-00074`, `action_item: ALF-040` (legacy families). A document owned by
  a legacy-family item is as well-formed as one owned by a current-family item, because the
  legacy items have real files in the same registry directory
  (`ALF-010-260430-Open.md`, `CLD-00001-260526-Open.md` — verified by listing).

- **Resolution rule (the real gate):** the value must resolve to a real action-item record
  via the existing narrow helper `_action_item_file()` (`screen.py:974-996`): a file named
  for the id under `~/Documents/The_Estate/action-items/` — open, **or**
  `closed-items/**` — and structurally never anything under the decisions tree. This is
  deliberately narrower than `related:`'s resolver `_ref_paths()` (`screen.py:944-971`): a
  DEC id passes the regex but resolves to a decision, not an action item, and rejects with
  a named reason ("resolves to a decision record, not an action item"). Reusing the
  existing helper means the "every value resolves to a real record" rule (ruled point 6)
  costs no new resolution machinery. A closed item is a legal value (a document authored
  while its owner was closing is still owned by it) — recorded as §7 D7.

- **Semantics:** `action_item:` names the one action item this document's work belongs to;
  `related:` remains the staging manifest and cross-reference list, unchanged, and should
  normally *also* contain the `action_item:` value when the V/D pass needs to read that
  record (the two fields have different consumers: `related:` feeds anchor resolution and
  V/D staging, `action_item:` feeds ownership and the derived trail).

### 2.2 Enforcement points (where hard-fail actually lives)

Hard-fail at the mechanical screen (ruled point 4) lands wherever a screen actually runs:

1. `screen.py --intake` (`screen_intake`, `screen.py:1055-1146`) — all front-door filings:
   consultation intakes, decision documents, clarification responses, agent proposals,
   system alerts, sequence-sidecar filings.
2. The full screen (`screen_file`, `screen.py:774-882`) — every executable task at claim
   and at the promotion hop, headless and supervised.
3. `sequencelib.py validate` — the sidecar head (§3.3).

Classes no screen ever reads — reports, design papers, design records — get the field by
template and by reviewer verification only; §3.9 says this plainly rather than implying a
gate that does not exist.

**The new/old boundary is the `created:` date.** Migration is new-documents-only (ruled
point 5), but the screens re-run on in-flight documents (the worker screens on claim; the
promotion hop re-screens), so a naive "field required, full stop" would retroactively fail
tasks authored before the switch. The mechanical rule: the field is required **iff
`created:` ≥ the enablement date** (a constant, `ACTION_ITEM_ENFORCE_FROM`, set to the
land date at build time). Every screened class carries `created:`
(`REQUIRED_FIELDS`, `screen.py:157-158`; intake template line 7) except the sidecar head,
which gets the filing-hop treatment instead (§3.3). Documents from current templates can
never fail the gate, because the same build that flips the constant updates every
template and producer (§5).

### 2.3 The standing default item — ACI-MAINT

**Ruled shape:** ONE standing registry item, not a family (ruled point 6); David ruled the
name: "Agreed on ACI-MAINT" (ACI-260035, Progress 2026-08-20). Category information stays
in `origin:`.

**What it owns:** any in-scope document whose work is machinery self-maintenance and has
no more specific open action item — recurring system alerts, machinery-triage intakes,
housekeeping tasks, and the two bounded transition cases in §3.4/§3.5.

**Id spelling** is the one genuine open in this section (§7 D1): the literal id
`ACI-MAINT` does not match the numeric shape the registry mints (`mint.py` allocates
`ACI-YYXXXX`; the resolver's general ref regex `GOV_REF_RE` at `screen.py:177` requires
digits). Recommendation: mint it as a **literal** `ACI-MAINT` record (file
`ACI-MAINT-<YYMMDD>-Open.md` in the registry), with the field's own `ACTION_ITEM_RE`
carrying the one alternation. Reason: David ruled the *name*, every document carrying it
stays self-documenting, there is zero collision risk with the numeric sequence, and the
accommodation is one alternation in the new field's regex — `GOV_REF_RE` and `related:`
resolution stay untouched. The alternative (numeric id titled "ACI-MAINT") needs no regex
change but puts an opaque number in every default-owned document. Either way the item is a
**real minted record** and the resolution rule holds with no sentinel branch in the
resolver.

**Lifecycle text, written out for the builder to paste into the minted record:**

```markdown
## Lifecycle: STANDING (never closes by completion)

This item is the standing default owner for pipeline documents whose work is
machinery self-maintenance and that have no more specific open action item. It
exists so the mandatory `action_item:` provenance field always resolves to a
real registry record, with no sentinel special case in any resolver (OI-000124
design paper §2.3; David's rulings on ACI-260035, 2026-08-20).

- This item never closes by completion: there is no deliverable whose landing
  finishes it. It closes only if David retires the default-owner mechanism
  itself, and the closing entry must name the superseding mechanism.
- No per-document progress entries are written here. The trail of documents
  and orchestrator items citing this id is DERIVED — from the `action_item=`
  token on the orchestrator's mint ledger lines, via the helper script
  (OI-000124 design paper §4) — never hand-maintained in this file.
- Promotion rule (OI-000124 design paper §2.4): a recurring class of documents
  that keeps landing on this item earns a real action item of its own and
  stops using this one. This item's traffic is expected to SHRINK over time;
  growth in any one class is the promotion signal, not a maintenance burden.
- Index/EOD note: this item is exempt from any staleness or no-recent-progress
  reconciliation nudge — standing is its ruled lifecycle, not neglect.
```

### 2.4 The promotion rule — with an evaluable trigger

A class of documents that keeps landing on the default earns a real action item and stops
using the default (per the ACI-260020 precedent: recurring alert classes earn real items —
cited in ACI-260035, Progress 2026-08-20, point 5).

**Trigger, stated so a reader can tell whether it has fired:** run the helper script (§4)
over `ACI-MAINT`. If, within the trailing 30 days, **three or more distinct OIs** carry
`action_item=ACI-MAINT` on their mint lines **and share the same producer** — the same
attention slug family for `write_attention` alerts (the `<slug>` in
`attention-YYYYMMDD-<slug>`), or the same emitting script for other machinery intakes (the
`source:` line's producer) — the trigger has fired for that class. The next step is
mechanical: mint a real item for the class (through `mint.py`, ordinary numeric id),
update that one producer or template to name it, and from then on the class's documents
stop using ACI-MAINT. Nothing is back-edited — the fired trigger changes future documents
only. Evaluation cost: one helper run and one group-by; both counts (3 OIs, 30 days) are
in the decision list (§7 D6) for David to ratify or re-tune.

---

## 3. The exact change list, file by file (proposed; NOTHING here was applied)

Grounding note on today's enforcement, which this list is built against: `related:` is
enforced unevenly **by design** — REQUIRED with anchor resolution on
`origin: david-consultation` intakes (`screen.py:1102-1112`), REQUIRED as an OI link on
`origin: david-decision` (`screen.py:1114-1118`), and **ignored entirely by the full
screen** (no `related` check exists in `screen_file`, `screen.py:774-882`; confirmed by
reading the whole function; `schema.md:161-164` documents it as "purely additive… the
screen ignores it"). `action_item:` is different on purpose: uniform hard-fail everywhere
a screen runs, date-gated per §2.2.

### 3.1 `_meta/screen.py`

- New constants near `GOV_REF_RE` (`screen.py:176-177`): `ACTION_ITEM_RE` (§2.1),
  `ACTION_ITEM_ENFORCE_FROM = "<land date>"`.
- New helper `check_action_item(meta)` returning a list of reject reasons: field absent
  (only when `created:` ≥ enforce-from); value is a list; value fails `ACTION_ITEM_RE`;
  value resolves to nothing via `_action_item_file()` (`screen.py:974`); value resolves
  only outside the action-items tree (the "that's a decision, not an action item" reason).
  Each reason names the repair, per the house style (`screen.py:124-129`).
- `screen_file()`: one call to the helper, inserted after the Rule-3 block
  (`screen.py:854-857`). `action_item` is NOT added to `REQUIRED_FIELDS`
  (`screen.py:157`) — that list is date-blind and would retro-fail in-flight tasks.
- `screen_intake()`: the same call, same date gate, for **all** origins, inserted near the
  origin checks (`screen.py:1079-1118`). Sidecar filings (`*.sequence.md`) are screened
  here too, and their head has no `created:` — for them the check runs unconditionally,
  which is safe because a file arriving in `orchestrator/inbox/` after the switch is a new
  filing by definition (ratified in-flight sidecars never pass through the inbox again).
- Docstring: the check list at `screen.py:11-30` gains one numbered entry.

Afterwards a reader of screen.py sees: one new pattern, one new helper beside the
existing resolvers, and one new date-gated check in each screen, with named reasons.

### 3.2 `_meta/test_screen.py`

New cases (the suite is the drift alarm, `screen.py:198`): new-date document missing the
field → REJECT; pre-enforce-date document missing it → ACCEPT; list value → REJECT; DEC
value → REJECT with the decision-not-action-item reason; legacy `CLD-`/`ALF-` value with a
fixture registry file → ACCEPT; unresolvable value → REJECT; `ACI-MAINT` with the fixture
file present → ACCEPT. The fixture registry rides the existing
`AGENT_WORKFLOW_ACTION_ITEMS_DIR` override (`screen.py:185-186`), built for exactly this.

### 3.3 `_meta/sequencelib.py`

- `validate_sidecar()` (`sequencelib.py:394`) gains an `E-FIELD-MISSING`/`E-FIELD-VALUE`
  pair for a head `action_item:`, beside the `designed_by`/`authorized_by` stamps
  (`sequencelib.py:421-423`). Because ratified in-flight sidecars ARE re-validated by the
  running expansion path (`orchestrator.sh:4721` and `:4769` both call
  `sequencelib.load_validated` on the quarantined sidecar), this check must be
  tolerant-by-default at parse and strict only via the screen's filing-hop call — the
  builder implements it as a validation flag (`validate(strict_action_item=True)` from the
  filing screen; default False elsewhere), so an in-flight ratified sequence keeps
  expanding. This is ruling 5 (never break in-flight work) applied to code paths.
- `expand_step()` stamps `action_item:` into each expanded step task's frontmatter: the
  head's value when present, else `ACI-MAINT` (§3.4's transition default). This is how
  later steps of an in-flight pre-field sequence survive the full screen at their
  promotion hop (their stamped `created:` is the release date — post-switch — so without
  the stamp they would hard-fail, breaking a ratified sequence mid-flight).

### 3.4 `orchestrator/orchestrator.sh`

- **Mint ledger token (Option A, ruled):** line 4950 —
  `ledger "mint" "OK" "$oid minted from $arrival (origin=$(oi_get "$spine" origin))"` —
  gains the token. Proposed exact form: when the spine carries the field,
  `(origin=<o> action_item=<id>)`; when it does not (a pre-field arrival), the token is
  **omitted entirely**, matching the `related:` precedent "absent field → no line, never
  an error" (`schema.md:163-164`). Full spec in §4.
- **`build_routable_task()`** (`orchestrator.sh:2591`): stamps `action_item` via the
  existing `queuelib.py set` call that already stamps `id`/`status`/`attempts`/
  `requested_by` (`orchestrator.sh:2607`). Value precedence: the authored task block's own
  value if present (exact-copy: what V/D certified wins), else the spine's, else
  `ACI-MAINT`. The else-branch is the second transition default: an in-flight OI
  (e.g. one held at `clarifying` across the switch) instantiates post-switch with
  `created:` = today and would otherwise hard-fail its own promotion screen.
- **Mint-time inheritance:** none needed in this file beyond the ledger token —
  `INTAKE_CARRY` (§3.5) does the spine copy, exactly as the `diagnoses` copy precedent
  directly above the mint ledger line does its own (`orchestrator.sh:4943-4948`).

Both transition defaults are deliberate, bounded to pre-field in-flight material, and on
the decision list (§7 D8) because they mechanically widen where `ACI-MAINT` can appear.

### 3.5 `_meta/oilib.py`

`INTAKE_CARRY` (`oilib.py:110`) gains `"action_item"` — one word. The spine then carries
it from mint, which is the ruled "mechanical inheritance from the intake" for spines, and
every machine-written sidecar composed from the spine can carry it forward. (The
individual sidecar-composition call sites in orchestrator.sh are enumerated at build time;
the spine copy is the load-bearing step. `INDEX_COLUMNS` at `oilib.py:101` is untouched —
the index is a generated view, excluded by ruling.)

### 3.6 Templates — one line plus one author note each

| File | Change; what a reader sees afterwards |
|---|---|
| `_meta/intake-consultation-template.md` | Frontmatter (after `related:`, line 8-17): `action_item: ACI-NNNNNN   # REQUIRED — THE one owning action item (either id family; ACI-MAINT only for machinery self-maintenance). related: stays the staging manifest.` Author-notes comment gains two sentences (hard-fail; mint/identify the owner before filing, per the anchor-first rule). |
| `_meta/decision-template.md` | Skeleton (lines 17-38) gains `action_item:` with the comment "the OI's owning item — copy it from the spine; a decision document is owned by the same item as the work it rules on." |
| `_meta/prompt-template.md` | Frontmatter (beside `related:`, lines 13-16) gains `action_item:` + comment; the author notes name the date-gated hard-fail. |
| `_meta/output-template.md` | Frontmatter (lines 1-7) gains the ruled header line: `action_item: ACI-NNNNNN   # echo of the task's — the owning action item`. Loose supporting artifacts stay keyed by their directory (ruled). |
| `designer/templates/duty-clarify.md` | Corrected-intake skeleton (lines 58-66) and design-record skeleton (lines 83-93) each gain `action_item: {{ACTION_ITEM}}`; `designer/designer.sh` fills the placeholder from the spine like its other `{{…}}` values. |
| `designer/templates/duty-draft.md` | Same two skeletons (lines 61-71, 115-132) plus the fenced task-block skeleton (lines 79-99) gain the field. |
| `_lib/attention.sh` | `write_attention` emits one more frontmatter line (at `attention.sh:75-79`): `action_item: <arg or ACI-MAINT>` — an optional trailing parameter, defaulting to `ACI-MAINT`, so its three sourcing callers (`worker.sh`, `reviewer.sh`, `housekeeper.sh`) need no change on day one and can pass a real item when they know one. |
| `~/Claude/Scheduled/nightly/lint-transcripts.py` | Its intake emission gains `action_item: ACI-MAINT` (or the standing item for transcript-hygiene work if one is minted by then). Out-of-repo, so the build must name it explicitly — it is the producer of the `machinery-triage` intakes (verified by grep 2026-08-20). |

### 3.7 `_meta/schema.md` and `_meta/authoring-contract.md`

- `schema.md`: full field definition in the executable-task field notes (beside `related:`,
  L161-164) and in the intake section (beside `project:`, L283-292): name, single-value
  rule, both id families, resolution rule, date-gated hard-fail, ACI-MAINT and the
  promotion rule (one paragraph, pointing at this paper's §2.4 and the ACI-MAINT record).
- `authoring-contract.md`: §1 (Anchor first, L19-23) gains the rule "identify or mint the
  owning action item before authoring; `action_item:` names THE owner, `related:` stages
  everything the V/D pass must read — normally including the owner"; plus one dated line
  in the lesson ledger (per the maintenance duty, L11-15).

### 3.8 The helper script — new file `_meta/aitrail.py`

Full spec in §4. Born with the DEC-260129 help gate like every estate tool
(`The_Estate/conventions/registry.md:110-125`), read-only, plus a small test.

### 3.9 What is NOT gated, said plainly

No mechanical screen ever reads a task report, a design working paper, or a design record
— the screens run on front-door filings and executable tasks only. For those three
classes the field arrives by template and is verified by the reviewer (which already
verifies rather than trusts reports — `output-template.md:34-38`). Extending the worker's
done-check to parse report frontmatter was considered and is **not** proposed: it grows
the done-check's job from "the deliverable exists and is non-empty" into content
validation, a scope change out of proportion to the gap. Optional, cheap, and advisory:
one more `designcheck.py --any-filing` lint line flagging a task block without the field,
on the existing recorded-and-consulted-by-nothing channel (`schema.md:88-94`) — the
builder may include it; nothing routes on it.

---

## 4. The mint-line token and the helper script

### 4.1 The `action_item=` token

The ledger line writer is `ledger()` (`orchestrator.sh:319-322`):
`YYYY-MM-DD HH:MM <event, padded 14> <status, padded 4> — <clause>`. The mint clause
today (`orchestrator.sh:4950`):

```
OI-000124 minted from consult-20260820-action-item-field-design.md (origin=david-consultation)
```

Proposed, with the token **last inside the existing parenthetical**, space-separated
`key=value`, same grammar as every other machine token on the ledger:

```
OI-000125 minted from consult-20260821-example.md (origin=david-consultation action_item=ACI-260035)
```

- Written from the spine (`oi_get "$spine" action_item`), which the `INTAKE_CARRY` copy
  populated at mint — so the token can never disagree with the spine.
- **Omitted entirely when the spine has no value** (a pre-field arrival): no empty
  `action_item=`, no placeholder. Absent field → no token, the `related:` precedent.
- One-line greppable by construction:
  `grep ' mint ' ledger.md | grep 'action_item=ACI-260035'`.

### 4.2 The helper script — `_meta/aitrail.py`

**Job (Option A, ruled):** derive an action item's full combined trail across orchestrator
items from the mint-line join. No per-line stamping by any other lane writer.

**Inputs.**
- Positional: one action-item id, either family or `ACI-MAINT`
  (validated against `ACTION_ITEM_RE`).
- `--ledger <path>` (default `<repo>/ledger.md`), `--items <dir>` (default
  `orchestrator/items`, consulted together with `orchestrator/archive/**` for spines).
- `--tsv` for machine output (default is a markdown table); `--unattributed` to list
  pre-token mint lines (below); `-h/--help` per the DEC-260129 gate; read-only always.

**What it does.** Scan the ledger for mint lines
(`^\S+ \S+ mint\s+OK` … `action_item=<ID>`); extract the OI id, mint date, arrival
filename and origin from each; join each OI to its spine file (items/ first, then
archive/) for current `status:`, `task:` and summary; emit one row per OI, oldest first.

**Output shape.** Header naming the item and its registry file, then:

```
| OI | minted | origin | status | task | intake arrival |
```

(TSV: the same six columns, tab-separated, no header decoration.) An empty result prints
"no attributable OIs for <id>" and exits 0 — a real answer, not an error.

**Behaviour on ledger lines written before the token existed** — the part that is easy to
skip, so stated exactly: those lines simply lack the token, so they never match. They are
**counted, never guessed at**: the script's footer always reports
`N mint lines carry no action_item token (pre-token history or pre-field intakes); the
derived trail is complete only from <date of the first tokened mint line>`, and
`--unattributed` lists those OI ids so a human can attribute by eye if ever needed. The
script never back-fills, back-edits, or infers an owner for them — the ledger is
append-only by construction (`ledger()` writes with `>>`, `orchestrator.sh:319-322`), and
migration is new-documents-only by ruling. The completeness boundary is stated in the output rather
than silently absorbed (the no-silent-caps principle).

---

## 5. The enablement sequence — one recommendation

**Recommendation: the single atomic change** — one build lands every template and producer
edit from §3 *and* the screen switch (the `ACTION_ITEM_ENFORCE_FROM` constant set to that
day) together, in one commit, with the ACI-MAINT record minted first in the same sitting
(the screen resolves values against the registry, so the record must exist before the
first post-switch filing).

**Why it beat the per-document-class rollout (intakes first, tasks second):** the two
halves of a split rollout are coupled through the same machinery anyway — the moment
intakes carry the field, the inheritance chain (spine → `build_routable_task` →
instantiated task) must already be in place or the field dies at the promotion hop; so
"intakes first" still requires landing effectively all of §3.4/§3.5 in stage one, and the
second stage shrinks to flipping one check in `screen_file`. A split therefore buys almost
no blast-radius reduction, while doubling the cutover moments, the test-matrix states
(enforced-here-not-there), and the chances that stage two is deferred and the task-side
gate quietly never lands. The atomic change has one date, one constant, one test run, and
the ruled pairing property (nothing authored from a current template can fail the gate)
holds by construction because templates and switch are the same commit. The `created:`
date gate (§2.2) already bounds the blast radius to brand-new documents, which is the
protection a staged rollout would otherwise be for.

A warn-then-fail shadow period is excluded by ruling: hard fail is ruled, and pairing the
switch with the template updates already removes the failure a warn tier would buy.

---

## 6. The `project:` question — one recommendation, three options costed

Today `project:` is a folder label: the exact basename under `~/Documents/Projects/`,
required on consultation intakes **by the template, not by the mechanical screen**
(`schema.md:283-292`; `intake-consultation-template.md:18` and its author note), carried
by `oilib.py` to the spine and the index's last column, and consumed by the nightly
Stage-3.6c PROMPT-LOG mirror, which loud-skips unknown tags and never creates folders.
An action item is the specific owner; `project:` is the broad category.

- **(a) Projects become formal registry-level groupings of action items.** Cost: a new
  estate registry object (mint rules, lifecycle, an index), a second membership surface to
  maintain in sync with both the folder tree and the items' own `**Project:**` lines, and
  a consumer migration — for no consumer that exists today. Benefit: authoritative
  grouping and cross-project queries — but `action_item:` now provides the precise join,
  and the item's registry file already names its project informally.
- **(b) `project:` stays a folder label validated against the projects folder, as it is
  treated today.** Cost: none beyond today; the "validation" recommendation is to keep it
  at today's level — template-required plus the mirror's loud skip on unknown tags, which
  is a working validation loop — rather than adding a screen reject (a misspelled folder
  name should not kill a filing; the mirror already flags it). Limitation: it stays a
  label, and cross-project analysis rides `action_item:` instead — which is fine, because
  that is what the new field is for.
- **(c) Projects become derived views over `action_item:` values, no independent
  registry object.** Cost, today: the index column is read positionally by the nightly
  Stage-3.6/3.6b readers and feeds Stage-3.6c (`schema.md:283-292`), so removing the
  independent field breaks running consumers; coverage is structurally incomplete for a
  long time (new-documents-only migration means the historical majority of documents never
  carries `action_item:`); and the derivation source — the items' own `**Project:**`
  lines — is free text today (ACI-260035's reads "cowork-evolution (Agent_Workflow
  machinery; estate-wide provenance)", not a clean basename), so the registry would need a
  hygiene pass first. Benefit: one source of truth, eventually.

**Recommendation: (b).** It beat (a) because (a) builds a second registry surface with
real maintenance cost for a query capability `action_item:` already delivers; it beat (c)
because (c) breaks running positional consumers for a view that new-documents-only
migration guarantees will be partial for a long time, and its derivation source is not yet
clean. (c) is the right *direction* and this field is what makes it possible — the honest
posture is a stated re-evaluation trigger rather than a build now: when the helper shows
`action_item:` coverage on substantially all active OIs in a quarter, re-open (c) with a
registry `**Project:**`-line hygiene pass as its first step. Recorded as part of §7 D3.

---

## 7. `[DECISION REQUIRED]` — David's list

The six ruled points are not here. Each entry: the choice, the options, the
recommendation.

- **[DECISION REQUIRED] D1 — the standing item's id spelling.** Options: (i) literal
  `ACI-MAINT` record (one alternation in the new field's regex; David's ruled name appears
  verbatim in every document; needs a one-line conventions note exempting it from the
  numeric mint sequence); (ii) ordinary numeric `ACI-YYXXXX` minted through `mint.py`,
  titled "ACI-MAINT", with the numeric id in documents. **Recommend (i)** — readability in
  every carrying document, zero collision risk, no change to `GOV_REF_RE` or `related:`
  resolution.
- **[DECISION REQUIRED] D2 — enablement shape.** Single atomic change vs per-class
  rollout. **Recommend atomic** (§5).
- **[DECISION REQUIRED] D3 — `project:`.** Options (a)/(b)/(c) as costed in §6.
  **Recommend (b)**, with the stated coverage trigger for re-opening (c).
- **[DECISION REQUIRED] D4 — wiki `lint.py`.** Add the matching rule now, or only when
  wiki documents start carrying the field. **Recommend later** (§1.3): no in-scope class
  lives in The_Wiki, and the screen↔lint sync obligation covers only the PHI twins, which
  this design does not touch.
- **[DECISION REQUIRED] D5 — the estate conventions record.** Add the small *standing*
  lifecycle subsection (plus the D1 literal-id note if (i)) to
  `The_Estate/conventions/registry.md` — a governance file requiring his invitation.
  **Recommend yes**: without it a standing item reads as a stale open item to the EOD
  reconciliation.
- **[DECISION REQUIRED] D6 — promotion-rule numbers.** The trigger fires at ≥3 distinct
  OIs in a trailing 30 days from one producer/slug family (§2.4). **Recommend as stated**;
  the numbers are tunable without touching the mechanism.
- **[DECISION REQUIRED] D7 — closed items as legal owners.** The resolver naturally
  accepts `closed-items/**` (`screen.py:987-989`). Options: allow (a document authored as
  its owner closes stays well-formed; matches existing resolution) vs require-open
  (stricter, but makes a document's validity change when its owner closes — a moving
  gate). **Recommend allow.**
- **[DECISION REQUIRED] D8 — the two bounded transition defaults.** `sequencelib.expand`
  and `build_routable_task` stamp `ACI-MAINT` when in-flight pre-field material would
  otherwise hard-fail its own promotion (§3.3/§3.4) — a mechanical widening of where the
  default appears, protecting ruling 5's never-break-in-flight intent. **Recommend yes,
  bounded exactly to those two sites.**

---

## 8. Not established

Honest gaps; each costs the next reader one targeted look, not a re-derivation:

- **The `machinery-triage` origin is not in the running screen's origin enum**
  (`ORIGIN_INTAKE_ALLOW`, `screen.py:174-175`), yet OI-000116..120 were minted from such
  intakes on 2026-08-20 (ledger.md:15255-15267) — minting precedes screening
  (`orchestrator.sh:4927` vs the screen call after L4950), so mint alone proves nothing
  about acceptance. I did not trace those items' post-screen fate. The divergence
  observation stands: a live producer emits an origin the screen's enum does not name; the
  build that touches `lint-transcripts.py` for §3.6 should look.
- **The exact placeholder-render call site in `designer/designer.sh` for the duty
  templates** was not read line-by-line (the review-template render at
  `designer.sh:340` passes `KEY=VALUE` pairs; the duty path is presumed parallel). The
  builder locates it when adding `{{ACTION_ITEM}}`.
- **The individual sidecar-composition call sites** (`.clarify.md` / `.escalation.md` /
  `.vd.md` writers in orchestrator.sh) were not enumerated; the spine copy (§3.5) is the
  load-bearing inheritance step, and the builder enumerates the sidecar writers.
- **The `pm/` lane** was not inspected for document classes of its own; the PM stamp
  fields ride ordinary task frontmatter (`schema.md:452-459`), which is covered, but a
  pm-lane-authored document class, if one exists, was not inventoried.
- **The sequence design doc "v1 §3.2"** was not located; the sidecar shape was read from
  the implementing code (`sequencelib.py:394-503`), which governs.
- **CLD-00109 and DEC-0094's full bodies** were not re-read this sitting; both are cited
  as ACI-260035 and `schema.md` present them.
- **Whether `screen_intake` runs on clarification-response filings with a `created:`
  field present in practice** (the date gate assumes it): the corrected-intake skeletons
  in the duty templates do not show `created:` (`duty-clarify.md:58-66`); if a live
  corrected intake lacks it, the field-required check falls back to unconditional for that
  filing — safe (the filing is new by definition at the inbox) but worth one look at a
  live example at build time.
