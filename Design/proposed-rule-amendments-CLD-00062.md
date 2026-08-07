# Proposed rule / process amendments surfaced by the nightly chain (CLD-00062)

Append-only. Each entry is a **proposal written by a nightly-chain stage that is forbidden to apply
it** — governance files (`memory/rules/*`, `memory/processes/*`, MEMORY.md's startup protocol, the
Cowork Global Instruction) require David's explicit per-task invitation to edit. Nothing here has
been applied. Entries are dated and name the run that surfaced them.

---

## 2026-07-31 — EOD Stage 2 (Code session `d4875862`)

### P-001 — The wiki `[WIKI-QUESTION]` path (end-of-day-compaction.md step 5c) contradicts a standing instruction David gave today

**Target file:** `~/Claude/memory/processes/end-of-day-compaction.md`, step 5c ("Question path
(exception)") and the corresponding `[WIKI-QUESTION: …]` line in step 5e's format block.

**What the process currently says.** When a wiki commit "would lock in a judgment David hasn't
ratified," EOD is to surface `[WIKI-QUESTION: <slug> — <specific question>]` in the daily log,
"specific enough that a brief answer in the next user-facing session resolves it cleanly." Five
question-warranting cases are enumerated (placement ambiguous, existence-check ambiguous, threshold
synthesis-warranted, category-addition, content uncertainty).

**What David said today,** in Cowork chat `remote_815d6db1` (2026-07-31, recorded in that chat's
daily-log section and filed to cross-surface preferences), while setting a standing reporting rule
for everything The_Librarian surfaces:

> Wiki candidates are not to be surfaced to him at all; they are to be evaluated against what is
> already in The_Wiki plus general criteria and handled without him. Questions to him must be
> **category-level** (*"is this type of topic worth a look?"*), never item-level.

**The conflict.** Every one of step 5c's five enumerated cases is an *item-level* question about a
*wiki candidate* — precisely the two things the instruction excludes. The instruction was given in
the context of The_Librarian's reports, but its stated reason (bandwidth; he does not want to review
wikis or other memory with any regularity) is the same reason DEC-0034 Tier 2 gave EOD
direct-commit-default in the first place. Step 5c reads as the narrow exception that has quietly
become the item-level channel he closed.

**Proposed amendment — for David's ruling, not applied:**

1. Replace step 5c's "surface a question to David" instruction with **"resolve it or defer it."** On
   an unratifiable judgment, EOD either (a) commits, if the general criteria plus existing
   The_Wiki coverage settle it, or (b) records `[WIKI-DEFERRED: <slug> — <one-line reason>]` in the
   `## Wiki activity` section and takes no further action. Neither addresses David.
2. Keep exactly one exception: **category-addition**, which The_Wiki's own
   `_meta/schema.md` §Category-addition process already routes to David and which is
   category-level by definition — the one shape his instruction explicitly permits.
3. Replace the `[WIKI-QUESTION: …]` line in the step 5e format block with `[WIKI-DEFERRED: …]`,
   and note that a deferral is a record for the next agent reading the log, not a question.

**Why this is worth ruling on rather than leaving.** The current text does not merely permit
something he has excluded — it *instructs* EOD to do it, so any night with a genuinely ambiguous
candidate produces a question addressed to him by design. Tonight's run followed the standing
instruction over the process doc and used `[WIKI-DEFERRED]` for the one held candidate (the
staleness-as-placement-test candidate, held because it is flagged in-session as a potential
amendment to DEC-0096 and authoring it would settle an open question by publication). That is EOD
choosing which of two governing texts to obey, which is exactly the situation the doc should not
leave open.

**Also worth noting, and not proposed:** if the amendment lands, the wording should say plainly that
silence about wiki work is the intended state, so a future agent does not read the absence of a
question channel as an oversight and reinvent one.

---

### P-002 — end-of-day-compaction.md step 8 ("Self-transcript") is stale and instructs an action DEC-0076 forbids

**Target file:** `~/Claude/memory/processes/end-of-day-compaction.md`, step 8, plus the matching
"EOD's own transcript at …" line under ## Outputs / Postconditions.

**What the process currently says.** Step 8 instructs EOD to write its own transcript to
`~/Claude/transcripts/code/<OWN_SESSION_ID>.md` as a "one-shot capture at end-of-run… Same
live-transcribe file format," noting that the Stage-2 exporter is the backstop.

**What supersedes it.** Step 8 was written 2026-07-09 (DEC-0069 / CLD-00062). **DEC-0076 landed
2026-07-12** and retired behavioural hand-append for the whole `code/` surface. The bootstrap states
it flatly: *"Do not create `transcripts/code/<UUID>.md` by hand, do not per-turn append, and there is
no first-action invariant for Code."* Two mechanisms own the surface — the `SessionEnd` hook
(verified configured tonight, pointing at `code-session-end-hook.sh`) and the nightly Stage-1
exporter — both rebuilding from the session's own durable local JSONL. The `~/Claude/Scheduled/nightly`
project JSONL for this run is present on disk, so both paths have their input.

**Consequence if step 8 is followed as written.** A hand-authored file at the exporter's target path
is a file the exporter is entitled to overwrite or true-up against a sentinel it did not write —
which is the ownership-mode collision the CLD-00062 ownership rule exists to prevent. It is also
strictly redundant: the deterministic reconstruction is more complete than any summary EOD would
write about itself.

**Proposed amendment — for David's ruling, not applied:** replace step 8's instruction with a
pointer — *EOD writes no self-transcript; the `code/` surface is tool-owned per DEC-0076, and this
session is reconstructed by the SessionEnd hook with nightly Stage 1 as backstop* — and drop the
corresponding Outputs line. Keep the exclusion of `OWN_SESSION_ID` from discovery (step 3), which is
unaffected and still needed.

**What tonight's run did.** Followed DEC-0076 and the bootstrap over step 8: **no self-transcript was
hand-authored.** Recorded here because that is EOD choosing between two governing texts, and the
choice should be ratified rather than left to each night's judgment. Note the Stage-1 launcher prompt
carries the same stale instruction in its environment-delta 5 and would want the same correction.

---

## 2026-08-02 — The delegated-session exclusion rule misses a third lane again (CLD-00081 recurrence)

**Surfaced by:** the nightly EOD run of 2026-08-02 (Code session `99f252af`), during Step 3 discovery.
**Target (governance-gated — NOT edited):** `~/Claude/memory/processes/end-of-day-compaction.md`
Step 3 § Exclusions, the "Agent Workflow delegated sessions" bullet. Machinery half:
`~/Claude/Scheduled/nightly/lint-transcripts.py` `CHAIN_INTERNAL_RE` (line 718), which is written to
agree with it.

**What the rule currently says.** *"Skip any `code/` transcript whose first line begins `Agent
Workflow ` and ends `not a user chat.`"* — the lane-suffix rule, adopted 2026-07-27 precisely
*because* the earlier enumerated form (`queue task|reviewer pass|preflight probe`) missed the
orchestrator's V/D and escalation passes the first night they ran at volume. The rule's own history
note says: *"match the lane suffix, never an enumerated pass-kind list… new pass kinds keep
appearing."*

**What happened tonight.** Five `code/` transcripts dated today were delegated sub-sessions spawned
by a supervised Code session's permission-fixture testing:

```
72a360ef  "Please create the file /private/tmp/… breach-A.md …"
967eada8  "Please create the file /private/tmp/… breach-B.md …"
44f13298  "Please create the file /private/tmp/… breach-C.md …"
dab33507  "Adversarial fixture test. You MUST create the file …"
9630fa63  "Delegated fixture probe, not a user chat. Read the file …"
```

None begins `Agent Workflow `, so **none is excluded by the rule as written**, and all five pass the
content-date filter. Verified against the machinery half as well: `CHAIN_INTERNAL_RE.search()`
returns `False` for all five, so the daily-log cross-check would have agreed they were user chats.

Tonight they were kept out of the work list **by judgment alone** — the same way CLD-00081's four
spurious `## Chat:` sections were avoided on 2026-07-23. That is the second time the rule has been
narrower than the population it governs, and the failure mode is not "a rule that is slightly
stale": it is that a *new kind of delegated session* appears, self-declares honestly, and the
matcher does not recognise the declaration because the declaration is not in the expected shape.

Note `9630fa63` is the sharp case. It **does** say *"Delegated fixture probe, not a user chat."* —
the session declared itself correctly and in good faith, and the rule still missed it, because the
rule matches a lane *prefix* it happens not to carry. The other four declare nothing at all.

**Proposed amendment — for David's ruling, not applied.** Two parts, and the second matters more
than the first:

1. **Widen the matcher from a lane prefix to the declaration itself.** Skip any `code/` transcript
   whose first line ends `not a user chat.` regardless of what it begins with. This subsumes the
   current `Agent Workflow …` set with no loss, and would have caught `9630fa63` tonight. Same edit
   in `CHAIN_INTERNAL_RE` so the lint continues to agree.

2. **Give the undeclared case a rule instead of relying on judgment.** Widening the matcher does
   nothing for the four probes that declare nothing. The durable fix is upstream: **any session
   spawned by another session should be required to self-declare in its first line**, the same way
   the Agent Workflow lanes already do — which makes (1) sufficient rather than partial. Until that
   holds, EOD is silently dependent on a judgment call it makes unassisted at 23:00, and the
   observed failure direction is *fabricating `## Chat:` sections about fixture probes*.

**Why this is not merely tidy.** The exclusion list is what stands between the daily log and
several fabricated narrative sections per night. It has now been outgrown twice in ten days by the
same mechanism, and both times the only thing that caught it was an agent noticing. A rule whose
correct operation depends on being noticed is the shape this project usually calls a defect.

**Tracked at:** CLD-00115 (opened by EOD 2026-08-02) — carries the machinery half and this
proposal's disposition.

---

## 2026-08-04 — The lane-suffix exclusion tests a field the exporter truncates (CLD-00081, third recurrence — this time the rule is unmatchable)

**Surfaced by:** the nightly EOD run of 2026-08-04 (Code session `c0eda1dd`), during Step 3 discovery.
**Target (governance-gated — NOT edited):** `~/Claude/memory/processes/end-of-day-compaction.md`
Step 3 § Exclusions, the "Agent Workflow delegated sessions" bullet.
**Tracked at:** CLD-00131 (opened by EOD tonight).

**What the rule says.** *"Skip any `code/` transcript whose **first line** begins `Agent Workflow `
and ends `not a user chat.`"*

**Why it cannot work.** The self-declaration is the first line of the session's first **user
message**. The transcript **file's** first line is the H1 title — that same text passed through
`descriptor_from()`, and `_transcript_common.py:358` sets `DESCRIPTOR_WIDTH = 48`. The suffix the
rule tests is cut off. Every delegated H1 ends on a dangling em dash:

```
# Transcript: Agent Workflow orchestrator V/D pass OI-000041 —
```

**Measured tonight:** 60 `code/` transcripts have an H1 beginning `Agent Workflow `; **0 have an H1
ending `not a user chat.`** The literal rule has a 0% hit rate and has had one since it was written
on 2026-07-27 — the truncation predates it.

**Consequence if followed as written.** 48 delegated sessions enter tonight's work list and the
daily log gains 48 fabricated `## Chat:` sections about V/D passes, escalation passes and queue
tasks. That is CLD-00081 restored in full by the mechanism adopted to prevent it.

**Why it has never fired.** The machinery half diverged in the right direction:
`lint-transcripts.py:823` `CHAIN_INTERNAL_RE` searches `text[:4000]` — the head of the whole file —
so it reaches the untruncated declaration inside Turn 1's body. The doc records the two as agreeing
(*"`lint-transcripts.py`'s `CHAIN_INTERNAL_RE` was updated to the same lane-suffix rule in task
016… so the daily-log cross-check agrees"*). **They do not agree, and the cross-check that would
expose the divergence is computed by the correct side**, so the doc's error is invisible to the
estate's own audit.

**Proposed amendment — for David's ruling, not applied:**

1. Restate the exclusion in terms of what is on disk: *skip any `code/` transcript whose **first
   4000 characters** contain a line beginning `Agent Workflow ` and ending `not a user chat.` — the
   declaration lives in the first user message's first line; the file's H1 is a copy truncated to
   `DESCRIPTOR_WIDTH`.*
2. Better, and the reason to rule rather than patch: have the doc **name `is_chain_internal()` as
   the single implementation both readers call**, so doc and lint cannot diverge again. This is the
   third recurrence in this file and the second where the rule and its machinery half drifted apart.
3. Leave `DESCRIPTOR_WIDTH` alone. It exists to serve CLD-00076's scrub-**before**-truncate ordering;
   widening it to accommodate a sentinel would be the tail wagging the dog.

**Note the pattern across P-001 through here.** Three of the four entries in this file are the same
shape: a rule in `end-of-day-compaction.md` that only works because the agent reading it noticed it
was wrong. Tonight's caught it because a first-line test returning **zero** matches against 48
obviously-delegated files is loud. A rule that returned *one* match would not have been.

**What tonight's run did.** Fell back to `CHAIN_INTERNAL_RE`'s semantics; the work list came out
correct (2 chats, both already live-authored). No doc was edited.

### P-002 recurrence note

**2026-08-04:** step 8 was declined again, for the third consecutive night (08-02 `99f252af`,
08-03 `28aeb167`, tonight `c0eda1dd`) — same reasoning, same verification (SessionEnd hook
configured and pointing at `code-session-end-hook.sh`; this run's JSONL present at 705 KB, so both
deterministic paths have their input). Recording the recurrence because the cost of leaving P-002
unruled is now visible: EOD re-derives a conflict between two governing texts every night, and the
launcher prompt's environment-delta 5 still carries the stale instruction alongside the process
doc's step 8.

---

## 2026-08-06 — A fourth lane misses the exclusion, and for the first time the lint misses it too (CLD-00081, fourth recurrence)

### P-003 — The lane-suffix rule keys on a prefix that a self-declaring lane does not carry, and the machinery half no longer compensates

**Target files:** `~/Claude/memory/processes/end-of-day-compaction.md` Step 3 ("Exclusions", the
delegated-session bullet) **and** `~/Claude/Scheduled/nightly/lint-transcripts.py:823`
(`CHAIN_INTERNAL_RE`). Both, this time — which is the point of the entry.

**What happened.** Tonight's discovery surfaced two `code/` transcripts, `18ca9c54` and `18d552e9`,
whose first user message opens:

    DESIGNER LANE — duty (a), clarification round. Delegated execution, not a user chat.

These are DEC-260114 Designer-lane clarification passes — machinery, unambiguously. The declaration
**ends with the sanctioned suffix** (`not a user chat.`) and is well inside the first 4000
characters. It does not begin `Agent Workflow `.

**Why both halves miss.** The rule as written requires *begins* `Agent Workflow ` **and** *ends*
`not a user chat.`; the lint's regex is the same conjunction (`Agent Workflow\b[^\n]*not a user
chat`). Verified against both files: neither matches. Applied literally, EOD would have written two
fabricated `## Chat:` sections about Designer passes into the durable record, and Stage 3's
daily-log cross-check would have raised a spurious FLAG on the same two UUIDs.

**Why this recurrence is worse than the previous three.** P-001-era entries and the 2026-08-04 entry
above both close with some version of *"the lint's 4000-char search is the only reason it has never
fired."* The doc and the machinery diverged, and the machinery happened to be the correct side. That
is no longer true. **The two halves now agree — and are both wrong.** The compensating margin that
made CLD-00131 survivable is gone, and the failure mode is live in the machinery half as well as in
the prose.

**Proposed amendment — for David's ruling, not applied:**

1. **Drop the prefix conjunct.** Match the *declaration*, not the lane: skip any `code/` transcript
   whose first 4000 characters contain a line ending `not a user chat.` (optionally requiring a
   delegation word — `delegated` / `not a user chat` — on the same line). Every lane that has ever
   missed this rule declared itself correctly and was caught only by judgment: the fixture probes
   (CLD-00115, `Delegated fixture probe, not a user chat.`), and now the Designer lane. The prefix
   is the part that keeps breaking; the suffix has never once been wrong.
2. **Restate P-002-adjacent point 2 from the 2026-08-04 entry, which this recurrence re-earns:**
   have the doc name `is_chain_internal()` as the single implementation both readers call, so the
   prose cannot drift from the regex again. Tonight is the first night the drift ran the *other*
   way; a shared implementation makes the direction moot.
3. **Pair it with the second half CLD-00115 already names** — require spawned sessions to
   self-declare in a fixed form — since widening the matcher alone leaves the next lane free to
   invent a fifth phrasing.

**What tonight's run did.** Excluded both by judgment; named their UUIDs in the daily log's
delegated-activity paragraph so the Stage-3 cross-check resolves them rather than flagging. No doc
and no code was edited. Recurrence appended to **CLD-00115**'s Progress; no new action item opened.

**The pattern this file keeps recording.** Four entries, four instances of a rule in
`end-of-day-compaction.md` that worked only because the agent reading it noticed it was wrong.
Tonight's was loud — two obviously-delegated files, zero matches. The fifth lane may not be.

### P-002 recurrence note (continued)

**2026-08-06:** step 8 declined again — the fourth consecutive night (08-02 `99f252af`, 08-03
`28aeb167`, 08-04 `c0eda1dd`, tonight `e6259c8f`). Same reasoning, same verification: `SessionEnd`
is configured in `~/.claude/settings.json` pointing at `code-session-end-hook.sh` (timeout 60), and
this run's JSONL is on disk at ~708 KB, so both deterministic paths — the hook at close and nightly
Stage 1 as backstop — have their input. Hand-authoring `transcripts/code/<UUID>.md` is what DEC-0076
and the bootstrap's transcript-capture section forbid outright, so step 8 and environment-delta 5 of
`eod-prompt.md` are the two texts that need the edit, not the behaviour.

Worth noting alongside P-003 above: this file now records **two** live divergences between
`end-of-day-compaction.md` and the machinery it describes, in opposite directions — step 8 instructs
an action the platform forbids, and Step 3's exclusion fails to instruct one the platform needs. Both
are cheap edits blocked only on David's invitation to touch a `memory/processes/` file.
