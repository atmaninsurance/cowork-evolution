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
