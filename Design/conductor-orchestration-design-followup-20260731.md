# Conductor orchestration — follow-up design pass (addendum)

**Date:** 2026-07-31
**Anchor:** CLD-00109. **Authorized by:** DEC-0102 item 10.
**Revises:** `conductor-orchestration-design-20260731.md` ("the main design") — **Part 7 stages 1–2 and Part 8 only**. Parts 1–6 and stages 3–5 are decided (DEC-0102) and untouched here.
**Governing brief:** `Prompts/conductor-design-followup-20260731.md`. **Run as:** Opus, David-supervised terminal session (DEC-0102 ruling 3).
**Precedence:** where anything older disagrees with DEC-0101, DEC-0102, or DEC-0103 — including the main design and both consultation transcripts — the DEC wins.

**Evidence conventions.** As in the main pass: current-behaviour claims cite `file:line` (relative to `~/Documents/Agent_Workflow/` unless absolute), a DEC id, or a CLD id; unverified claims are labelled and collected in §Could-not-verify.

**State checks the brief required, as found at run time:**

- `librarian/topics.md` rubric item 6 still reads "flagged, not scored… forces a human read" (`topics.md:30–32`) — **David's DEC-0103 edit has not landed yet.** This pass designs against DEC-0103's statement of the rule, as instructed.
- `librarian/ideas-ledger.md` is still empty of entries ("*(none yet)*", `ideas-ledger.md:37`).
- `orchestrator/archive/2026/OI-000027.*` exists (spine, intake, escalation, clarify sidecar) — the withdrawn item archived as DEC-0101 item 1 states; both carried findings verified against the live tree (§Q11).
- The CLD-00105 edge-trigger fix is live in `orchestrator.sh` (`:629–737` — the level-to-edge converter, fingerprint state under `_meta/notify-state/`, 24h backstop).

---

## Executive summary

**One surface, not two — and it already half-exists.** The answer to "what is the review surface" is a single generated file, **`~/Documents/Agent_Workflow/REVIEW.md`** (the *review board*), rebuilt by deterministic code at the end of every orchestrator wake and by the nightly chain — never written by hand, never written by the session that reads it. It is a *view over state the machinery already keeps* (OI spines and index, the ledger, the notify-state fingerprints, the staleness report, the venture ledger), in the same regenerate-never-append family as the `_index.md` and PROMPT-LOG mirrors (DEC-0094; DEC-0082 choice 5). The weekly digest is **not a second thing**: it is the board's venture section, with a weekly snapshot archived for the calibration record. Items leave the board by being *resolved*, not by being *seen* — so nothing depends on a read-receipt, and a question that waits three days is still sitting at the top three days later.

**Fail-loud survives as "impossible to miss when he looks."** The board's top section — NEEDS YOU — admits only enumerated classes (decisions, holds, refusals, hard FAILs), states each entry with enough payload to react to without opening another file, and is explicitly empty when empty. Desktop notifications stay for FAIL-class events (they are free and local); Telegram goes dormant rather than being redesigned. What genuinely gets quieter: everything Telegram used to carry — which David has stopped reading anyway (DEC-0101 item 5) — and the cost of three sessionless days is stated plainly in §Q3: a hard failure can wait up to three days, softened only by desktop notices and by the board's own staleness banner. David accepted this class of cost when he chose the surface (DEC-0102 ruling 2; DEC-0099's no-active-chat bracket is the precedent).

**No push channel is built now, and the design does not foreclose one.** The board generator's tier classification *is* the future push filter: when David later wants "very limited, pointing me to check status," the channel carries the NEEDS-YOU count and a pointer to the board — a delivery change, not a redesign. The one candidate cloud route (a scheduled task reading the GitHub remotes) is assessed and **not worth building** (§Q5): day-old data, a credential in a new trust surface, duplicating the board remotely, feeding a channel that was just retired.

**The venture pipeline folds through with zero human gates, defended.** Promotion is the machinery's act within the ratified caps (DEC-0102 D1); the compliance flag is replaced by a mechanical client-data **disqualifier** (DEC-0103 item 1) — detected by a required declared field on every stub, checked deterministically at the gate, re-tested independently by the Analyst, and **recoverable**: disqualified stubs stay in the ledger and appear in the digest with their reason, where David can overturn one in a sentence. Zero gates is acceptable because everything inside the pipeline is a document — reversible by DEC-0102 ruling 1's own test — spend is capped at ~2 opus night-slots a week, and every selection is visible at the next session start. The gate returns the day the pipeline gains an actuator.

**The Scout learns through a three-tier memory, with David as the anchor.** Raw history in the ledger; a slim, bounded **calibration file** (`venture/calibration.md`) that rides in the Scout's prompt nightly, with source-tagged entries where a `[DAVID]` line mechanically outranks an `[ANALYST]` line; durable market knowledge to The_Wiki through The_Librarian's normal authoring path, preserving the authorship boundary. The Analyst grades every promoted stub independently (three lenses asking three different questions, on sonnet, inside the existing opus-slot bound); the gate contributes free per-criterion statistics on the 33 stubs a week the Analyst never sees; David's digest reactions are the anchor tier. The file is bounded by a named weekly compaction rule (§Q10) — an unbounded learnings file was ruled a failed answer, and this one cannot grow past its cap.

**The aggregate book-of-business profile is designed as a boundary-respecting import** (§Q13): Alfred compiles it in his own domain (he never writes into Agent_Workflow — the Stage-B fence stands, `README.md:367–368`); a deterministic import step pulls it across with a blocking PHI lint and a small-cell check (no cell below 5); the venture lane reads one file, read-only. Stage 1 does not wait for it: criterion 5 scores against a David-authored book sketch in `topics.md` until the profile exists.

Ten decision items for David are collected in §[DECISION REQUIRED] — the load-bearing three: adopt the board as the startup surface (his `MEMORY.md` edit), confirm the desktop/Telegram disposition and the DEC-0099/DEC-0090-item-8 amendments it implies, and rule on the Alfred→venture profile handoff path.

---

## Part A — The unified review surface

### Q1. What the surface is, concretely

**One materialized file: `~/Documents/Agent_Workflow/REVIEW.md` — "the review board."** A generated view, not a record. Properties, against the brief's constraints:

- **Assembled from state the machinery already maintains.** The generator reads: `orchestrator/_index.md` + OI spines (escalations, holds, statuses), `_meta/notify-state/` (the CLD-00105 fingerprints — what was pushed and when, `orchestrator.sh:652–668`), `ledger.md` (FAILs/FLAGs since last generation), `check_staleness.sh --dry` output (`check_staleness.sh:24–27` — the dry mode exists precisely for a no-side-effect read), the nightly `run-ledger.md`, and — once stage 1 lands — `venture/ideas-ledger.md` + the gate's weekly stats. **No new parallel record is created**; the board can be deleted and regenerated at any moment with no loss.
- **Produced by local machinery, not the reading session.** A small deterministic script (`_meta/reviewboard.py`, a sibling of `promptlog.py`, which already does exactly this shape of work — regenerate a marker-fenced view from `_index.md` rows, DEC-0094 item 2). Invoked at the end of every orchestrator wake and by the nightly chain. It exists whether or not a session ever opens, and its `generated:` timestamp is itself a health signal (§Q3).
- **Regenerated, never appended.** The push-maintained alternative drifts the moment one writer forgets — the exact reason `_index.md` is machine-maintained and the Completions mirror is pull-regenerated (DEC-0094 §Why). Same pattern, one level up.
- **Readable in the time David gives it.** Fixed section order, severity first; each section bounded (counts + top entries, never unbounded lists); the whole board targeted at one screen of reading when healthy.
- **Push-ready without redesign.** The generator computes a one-line summary (`NEEDS YOU: 2 · FAIL: 0 · selections this week: 1`) and writes it as the board's first line. A future push channel sends that line plus a pointer — the classification already lives in the generator, so adding a channel is a delivery change (the brief's forward requirement).

**Who reads it, and where the protocol changes.** The startup protocol already reads the action-items index (MEMORY.md step 4) and triages nightly FLAGs (step 6). The board becomes **the machinery half of that startup read** — a new step beside step 6: *read `Agent_Workflow/REVIEW.md`; anything in NEEDS YOU leads the greeting.* That is an edit to `MEMORY.md`, which is governance-protected and David-owned in practice — his edit to authorize [DECISION REQUIRED F1]. Claude Code sessions get the same pointer via the workspace bootstrap when relevant; the board is a plain file, so any surface can read it.

**How items leave the board: by state, not by sight.** An escalated OI leaves NEEDS YOU when a decision document resolves it; a hold leaves when released; a FAIL leaves when the ledger shows the condition cleared or an item absorbs it. There is deliberately **no read-receipt and no "mark as seen"** — a seen-but-forgotten decision is the failure mode a state-based board cannot have, and it sidesteps needing the reading session to write anything back.

**Sections, in fixed order:**

| # | Section | Admits | Empty-state line |
| --- | --- | --- | --- |
| 1 | **NEEDS YOU** | escalated OIs with David-class questions; scope-audit holds awaiting release; budget refusals; disqualifier overrides proposed; anything with `status: escalated` | "Nothing needs you. N items in flight." |
| 2 | **FAILURES** | staleness FAIL hits; nightly hard FAIL / ATTENTION; dead-letters since last board; board-staleness self-report | "No failures on record." |
| 3 | **SELECTIONS & PROPOSALS** | the venture section = the digest (§Q6): promotions with scores and near-misses; direction proposals; disqualifications; dive verdicts | "No venture activity this week." |
| 4 | **COMPLETIONS** | OIs delivered since last board (from `_index.md` terminal rows — the same rows the Completions mirror reads) | — |
| 5 | **FLAGS** | deduped FLAG classes since last board, count + one representative line each | — |
| 6 | **HEALTH** | one line each: last worker/orchestrator/nightly wake, queue depths, days since last session-start review | — |

### Q2. The per-class table — every class the machinery actually produces

Built from reading the call sites, per the verification bar. The orchestrator has **19 David-facing notification sites**; the worker, reviewer, watchdog, attention helper, and Librarian add six more producers. Classes, dispositions, and payloads:

| # | Class (producer, evidence) | Today's channel | Board section | Desktop kept? | What the board entry must carry |
| --- | --- | --- | --- | --- | --- |
| 1 | **Escalation with questions** — fresh intake (`orchestrator.sh:2133`) and post-clarification residual (`:2259`) | desktop + Telegram | NEEDS YOU | yes | OI id · one-line summary · **the questions themselves** (verbatim, numbered, with their DEC-0093 tags) · V/D's recommendation · options where the escalation package names them · spine path. The questions were the thing Telegram never carried — that omission is the "not enough information" complaint, and fixing it is the point of a surface with room. |
| 2 | **Clarify age-out** — a `clarifying` hold unconsumed ~24h becomes David's (`:1437`) | desktop + Telegram | NEEDS YOU | yes | as class 1, plus the age and the fact it started claim-side |
| 3 | **Scope-audit hold, unreleased/unidentifiable** — completion round (`:2483`, `:2506`, edge-triggered) | desktop + Telegram | NEEDS YOU | yes | OI · task id · which grant · the out-of-scope paths (the audit already lists them) · release instructions pointer |
| 4 | **Hold cleared** — the release landed (`:2516`) | desktop + Telegram | COMPLETIONS | no | one line: released, delivering |
| 5 | **Deliver_to refused** — The_Library target (`:2534`) or outside sanctioned roots (`:2545`) | desktop + Telegram | NEEDS YOU | yes | OI · the offending destination · what a corrected decision needs to say |
| 6 | **Decision-path errors** — unclear intent (`:2364`), unroutable (`:2401`), release refused (`:2300`), release without hold-id (`:2306`), interview-compose failure (`:1758`), rewrite re-verify significant (`:2347`) | desktop + Telegram | NEEDS YOU | yes | OI · which document failed · the specific defect · what a corrected document needs |
| 7 | **Supervised task routed** — run-this pointer (`:1054`, `:2093`, `:2232`, `:2398`) | desktop + Telegram | NEEDS YOU (it awaits his action) | yes | task path · copy-paste launch line · what it builds · age |
| 8 | **Intake screen-reject dispose** (`:2003`) | desktop + Telegram | FLAGS (FAILURES if cowork-authored — a reject loop is a producer defect) | no | arrival name · matched reason · refile guidance pointer (contract §7) |
| 9 | **Staleness hits** — queued-unclaimed, intake-rotting, orphan-claim, worker-silent (`check_staleness.sh:79–120`, summary notification `:193`) | desktop (summary) | FAILURES | yes | the hit lines verbatim — they already carry path, age, threshold, and diagnosis |
| 10 | **Staleness reminders** — escalated-pending, supervised-pending, supervised-unmoved (`:136–166`) | desktop (in summary) | mirrored under the NEEDS-YOU entry they nag about (age annotation), not as separate rows | no | age only — the parent entry carries the substance |
| 11 | **Task-shaped ATTENTION creation** — worker/reviewer/nightly hard findings (`_lib/attention.sh:86`; the item lands in `orchestrator/inbox`) | desktop once at creation | FAILURES until adjudicated, then follows its OI | yes | slug · what happened clause · the OI it becomes |
| 12 | **CLI-update preflight** (`worker.sh:207`) | desktop | HEALTH (one line) | no | version pair · probe outcome |
| 13 | **Nightly run results** — run-ledger FLAGs, ATTENTION on hard FAIL (DEC-0075; MEMORY.md step 6) | ledger + ATTENTION file | FAILURES (FAIL) / FLAGS (FLAG) | on FAIL, via attention.sh | stage · finding · the run-ledger line |
| 14 | **Librarian FAIL alerts** (`librarian-cycle.sh:152` `alert_fail`) | desktop + (broken-path) Telegram | FAILURES | yes | her ledger line + cycle report pointer |
| 15 | **Venture: promotions** (future, stage 1) | — (does not exist yet) | SELECTIONS | no | §Q7's entry shape — scores, near-misses, gist |
| 16 | **Venture: direction proposals** (future; DEC-0103 item 3 standing invitation) | — | SELECTIONS (own subsection) | no | proposed focus area · why · what it would displace |
| 17 | **Venture: disqualifications** (future; DEC-0103 item 1) | — | SELECTIONS (own subsection) | no | idea gist · stated reason · overturn instruction |
| 18 | **Venture: budget refusal** — a mandatory step could not run within its floor (main design Q14 ladder; DEC-0102 D11) | — | NEEDS YOU | yes | what was refused · the shortfall · degrade options |
| 19 | **Wiki candidates** | flags in daily logs, consumed by EOD sweep + harvester | **never on the board** — David's standing rule: evaluated against The_Wiki and general criteria, handled without him (brief §Q2; his 2026-07-31 instruction) | no | n/a |
| 20 | **Completions** — ordinary delivered OIs | no push today (pull: daily-log Completions mirror, DEC-0082 item 5) | COMPLETIONS | no | id · deliverable · destination — one line each |

**Classes named in the brief that do not exist in the code:** *venture selections* (15–18) — nothing produces them yet; they are stage-1 outputs and their board shape is specified here so the build has a contract. **Classes the code produces that the brief's examples omitted:** the decision-path error family (row 6), the supervised-routed pointer (7), the screen-reject dispose (8), the CLI-preflight notice (12), the deliver_to refusals (5), and the ledger-only classes (`notify-quiet`/`notify-edge`, `orchestrator.sh:723, 736` — correctly ledger-only, never David-facing; unchanged).

**The channel disposition this table implies:** `notify_david` keeps firing desktop notifications for the rows marked yes (they are free, local, and the only same-moment signal that exists); its Telegram half goes **dormant** — not removed, not redesigned (out of scope), just no longer treated by any DEC as a delivery guarantee. That requires naming two records for amendment: **DEC-0099** (its "Telegram notification-only" half becomes "the review board is the notification surface; Telegram dormant"; its consulting-surface decision channel is untouched) and **DEC-0090 item 8** (the Librarian's separate bot identity becomes dormant infrastructure — her digest lands on the board like everything else; the token-path defect in her cycle script stops mattering for delivery, though it should still be fixed for hygiene). [DECISION REQUIRED F2.]

### Q3. How fail-loud survives

DEC-0102 ruling 2 reinterprets DEC-0089: **loud now means impossible to miss when he looks**, not pushed while he is not looking. Mechanically:

1. **Position is the loudness.** NEEDS YOU and FAILURES are sections 1–2, always present, explicitly empty when empty ("Nothing needs you" is information — silence is not, DEC-0089 item 1). The startup protocol requires the session's greeting to lead with their contents — the same obligation step 6 already imposes for nightly FLAGs (MEMORY.md steps 6–7), extended.
2. **Admission to the loud tier is enumerated, which is what stops inflation.** Rows 1–3, 5–7, 9, 11, 13(FAIL), 18 of the table — every one is either a decision only David can make or a condition meaning work is lost/stuck. Everything else is structurally barred from section 1–2 (the generator admits by class, not by producer enthusiasm). Dedupe rides the CLD-00105 fingerprints: one entry per condition per item, age-annotated, never one per wake — the level-to-edge conversion (`orchestrator.sh:637–645`) applied to a page instead of a channel.
3. **The board polices its own recorder.** The generator stamps `generated:`; the startup step treats a stamp older than ~26h as a FAILURES entry in its own right ("the board is stale — the machinery that writes it may be down"), which the *session* can detect even though the broken machinery cannot report itself. The dead-recorder case is the one hole in any pull surface, and this is the structural patch for it.

**What gets quieter than today — stated plainly:**

- **Telegram: everything.** Cost in practice: near zero — David has stopped reading it ("Too much noise with not enough information and lost responses… I'm ignoring now", DEC-0101 item 5). Cost in principle: real, and it is the next item.
- **Desktop: rows 4, 8, 10, 12** (hold-cleared, screen-rejects, staleness reminders, CLI notices) drop to board-only. Escalations, holds, refusals, FAILs, ATTENTION keep their desktop notice.
- Nothing else quiets. The ledger records everything it always did.

**The three-day cost, plainly.** If David opens no session for three days: an escalation raised on day 1 waits three days (today it would have raised one ignored Telegram line plus a desktop flash — materially the same wait); a hard failure — say the nightly stalls, or the worker goes silent — waits up to three days before anyone knows, softened only by (a) the desktop notification if he is at the Mac at all, and (b) nothing else. That is the honest price of ruling 2, and it is the same price DEC-0099's no-active-chat bracket already accepted for decisions ("Accepted cost: an escalation raised overnight waits for the next session"). Two things bound it: David's actual cadence is multiple sessions a day (the startup protocol runs at every chat start), and the deferred push channel (§Q4) is designed to bolt onto exactly this hole when he asks for it. If three-day gaps become a real pattern, the dead-man's-switch class in §Q5 is the first thing to revisit. [Cost acceptance: DECISION REQUIRED F3.]

### Q4. Residual push — recommendation: none built now, one class pre-named for later

**Recommendation: build no push channel now.** Grounds: David deferred it explicitly ("Chatting will suffice for now… once you're up and running… I'll need a more proactive method. We'll see." — brief §platform correction); the only live channels are one he ignores (Telegram) and one that only works when he is already at the Mac (desktop, kept for FAIL-class); and ruling 2's whole architecture is that the machinery **waits and is first in the queue at the next session start** — which the board makes a real mechanism rather than a hope, because NEEDS YOU items cannot age off it.

**What the machinery does when stuck: wait, visibly.** An item that cannot proceed sits in NEEDS YOU with its age annotated; the staleness watchdog's escalated-pending reminder (`check_staleness.sh:126–138`) annotates it further at 7 days. Nothing loops, nothing re-pings, nothing is lost — the CLD-00105 state machinery guarantees the record outlives the wait.

**The one class that will eventually justify push — named now so the later build is a delivery change:** *recorder-down* (nightly FAIL / worker-silent / board stale — the conditions under which the pull surface itself degrades), plus, at David's option, *NEEDS-YOU count changed*. Both are already computed: the first is FAILURES-section admission, the second is the board's first line. When David asks for his "very limited, pointing me to check status" channel, it sends that first line and nothing else — the classification work is done, per the brief's forward requirement.

### Q5. The platform question — cloud reads of the GitHub remotes: **not worth building**

Assessed, not designed, per the brief.

**What it would be:** a Cowork scheduled task (cloud-fired, no device bridge — CLD-00061 Datapoint 4) cloning or API-reading the private `agent-workflow` repo, which the nightly Stage-5 sweep pushes (`README.md:455–458`), to derive something board-like and notify David's phone.

**What it would need.** (a) A GitHub credential available to the cloud task. Credentials are the structural class — never in prompts or tasks (DEC-0091 item 2) — so it would live in whatever secret store the Cowork cloud platform offers, a **new trust surface** outside the local chmod-600-outside-git discipline (`README.md:304–306`), holding a token that reads the entire private repo, not just the board. (b) A cloud-side parser of repo state — a second implementation of exactly what `reviewboard.py` does locally, which will drift from it (the single-semantic-layer failure mode, DEC-0096, in miniature). (c) A delivery channel — which is the thing David just retired for noise.

**What it could and could not see.** Could: everything in the repo as of the last successful push — the board file itself, the ledger, spines. Could not: anything since the last nightly (up to ~24h stale); anything in un-pushed working state; whether the Mac is even alive **when the push succeeded yesterday** — and when the push *fails*, it cannot distinguish "machinery broken" from "credential expired" from "Mac asleep."

**The one genuine value:** a dead-man's switch — "the repo has not been pushed in 48h" is detectable from the cloud with no local cooperation, and it covers precisely the recorder-down hole in §Q3. But that needs no repo *read* at all — commit-timestamp metadata suffices — and it only pays off attached to a push channel David reads, which does not exist yet.

**Recommendation: not worth it.** Park it with one sentence in the record: *if/when the deferred push channel is built, evaluate a metadata-only staleness probe (last-push age) as its dead-man's switch; full state reads from the remotes stay not-worth-it.* Flagged untested per the brief, deliberately not tested here: whether the device bridge reaches the Mac when a session is viewed from the phone with the desktop app running.

---

## Part B — The digest, inside stage 1

### Q6. What the digest is now

**The digest is the board's SELECTIONS & PROPOSALS section — one surface, not two — plus a weekly archived snapshot.** Stating the relationship explicitly, per the verification bar:

- **One surface for reading.** The venture section is regenerated into `REVIEW.md` by the same generator, from the ideas ledger and the gate's stats, after every venture wake. David reads it wherever he reads everything else. Giving the digest its own destination would recreate "two places to look and a reason to look at neither" — the Telegram failure mode DEC-0102 ruling 2 names.
- **Plus a durable weekly snapshot, because the calibration loop needs history.** At the weekly boundary the venture wake writes `venture/digests/week-YYYY-WW.md` — a frozen copy of that week's section. The board always shows the current state; the snapshots are what "did the loop improve over four weeks?" is measured against (§Q10's success test), and what the weekly discussion scrolls back through. This is an *archive of the one surface*, not a second surface: nobody is expected to read it routinely, and nothing appears there that was not on the board first.
- **Generator and cadence:** the venture lane wake (nightly, post-nightly slot) updates the section data after every Scout run and every Analyst verdict; the snapshot cuts weekly. **Report, not gate** — nothing in it awaits approval; it is the record of what the machinery already selected (DEC-0102 ruling 1 + consequence (a) of ruling 2).

### Q7. The entry shape that makes calibration work

Ruling 1's premise: David corrects the criteria by reacting to real selections. A selection is only judgeable against what it beat, so the section shows four things:

**1. Promotions (≤2/week), full detail — the shape per entry:**

```
### PROMOTED — IDEA-014: <one-line gist>
- topic: recurring-revenue-streams-using-ai   category: revenue
- gist: <2–3 plain-language sentences — the idea as David would tell it to someone>
- scores (self / analyst): budget 4/– · automatable 5/– · roi 4/– · ttfd 3/– · fit 5/– → total 21/25
- gate: threshold ≥20 met; rank 1 of 4 threshold-passers this week; client-data: none
- why it won: <one sentence naming the deciding criterion vs the runner-up>
- dive: queued for <date> (analyst scores fill in after independent grading)
- react: say "poor choice" (and why) or "good pick" — either lands in calibration as a [DAVID] entry
```

Topic, category (problem / efficiency / revenue), plain gist first — David's standing payload preference, verbatim in the brief. The mechanics live below the gist, not instead of it.

**2. Near-misses — the top 3 non-promoted stubs**, one line each: gist, total, and **the criterion that held it back** ("held by: rank cut — 3rd of 4" / "held by: roi=2 under floor"). A wrong pick is diagnosable only against the alternatives; three is enough to see the shape of the week without the section becoming the ledger.

**3. The week's floor, one line of gate statistics** (free — computed from scores already in the ledger, no model call): "12 stubs this week; 4 passed threshold; held back: 5 by roi floor, 2 by ttfd floor, 1 by rank cut." This is also the free tier of the feedback loop (§Q10).

**4. Disqualifications and proposals, each its own subsection:** every client-data disqualification with gist + the Scout's stated reason + the standing overturn instruction (§Q12 — visibility is the recovery path); every direction proposal (DEC-0103 item 3's standing invitation) with what it would explore and roughly what it would displace.

**Rejected ideas' visibility, directly:** near-misses top-3 with holdback reasons; the full list stays one `grep '^### IDEA'` away in the ledger, and the entry says so. Disqualified stubs are **always** listed (they are the class where a false positive is invisible-by-default, so the design makes them visible-by-default).

### Q8. Stage 1's close criteria, restated under machinery-selects

Replacing the main design's Part 7 stage-1 set (which assumed a human gate). All checkable by grep, diff, or fixture:

After **7 consecutive nights** of the venture wake:

1. **Ledger integrity:** every entry validates against the entry schema (`ideas-ledger.md:10–33` grammar + the new `client-data:` field, §Q12); ids sequential, none reused.
2. **Scout cap:** no calendar date has more than 5 new entries (count by `date:` field).
3. **Dedupe:** fixture — a night whose generator is fed a topic already covered produces a skip, not a duplicate (normalized-slug match demonstrated); live — no two entries share a normalized slug.
4. **Gate mechanics:** every `promoted` entry has total ≥20 and no criterion <3 (grep over score lines); promotions in any trailing-7-day window ≤2; zero entries with `client-data: transfers-to-third-party` in any status other than `disqualified` (or `disqualified-overturned` bearing a `[DAVID …]` line — §Q12); rank-cut demonstrable from the week's score set.
5. **Machinery-selects, no human in the loop:** at least one promotion occurred **without any decision document or David-attributed record predating it** (diff of `orchestrator/inbox` + the ledger shows the gate acted alone) — the inverted gate demonstrably exercised.
6. **Digest:** the board's venture section regenerated after every wake (mtime/content check); contains all four subsections with the §Q7 fields present (schema check); week-1 snapshot exists at `venture/digests/week-*.md`.
7. **Board integration:** `REVIEW.md` regenerated by machinery ≥ once per day of the window; NEEDS YOU contains no venture rows except any budget refusal actually raised.
8. **Scope:** post-run audit clean — no writes outside `venture/` + the board + its own ledger (the DEC-0091 item-5 audit pattern; `worker.sh:826–834`).
9. **Calibration file:** exists, within its line cap (§Q10), and carries ≥1 GATE-STATS entry (the free tier ran).
10. **Fencing (the Q11 findings):** the venture plist pins `CLAUDE_BIN` to the agent-pinned path (grep the installed plist), and its install rode a DEC-named launchd grant (the grant record exists in `_meta/grants/archive/` after consumption).

### Q12. The client-data disqualifier, mechanized — and zero human gates, defended

**The rule (DEC-0103 item 1):** an idea whose business model involves *selling, sharing or transferring client data to a third party* is **rejected, not escalated**. Marketing Atman's own services to Atman's own clients through Atman's own channels trips nothing — that is ordinary business (the Wellness Program is the live example). `topics.md` item 6 as found is still the old flag text (`topics.md:30–32`); the design follows DEC-0103, and David's file edit is noted as owed.

**Detection — three layers, because the judge is a model reading a paragraph:**

1. **A required declared field on every stub:** `client-data: none | marketing-own | transfers-to-third-party`, set by the Scout at generation, with one sentence of reasoning when it is not `none`. A missing field makes the stub schema-invalid (mechanical ledger check — close criterion 1). Making the classification a *declared output* rather than an inference someone runs later means the Scout must consider the question for every idea, and its reasoning is on the record when David reviews.
2. **The gate check (deterministic, no model):** `transfers-to-third-party` → status `disqualified`. Never promotable by arithmetic; excluded from the rank pool entirely.
3. **The Analyst re-tests it (independent second reader):** before a dive starts, the Analyst's independent grading (§Q10 deep tier) re-answers the classification from the stub text. A promoted stub the Analyst classes as transfer-type: dive aborts before spending the opus slot, stub reclassified `disqualified`, a feedback entry records the Scout's miss. Two differently-fed readers on the same question — the attester pattern (`orchestrator.sh:880–887`), applied to the one rule whose false negative wastes real budget.

**The asymmetry the brief names, handled in the direction that matters.** A false *negative* (a transfer-type idea slips through) costs at most one aborted dive — layer 3 catches it before the slot is spent, and the digest shows the miss. A false *positive* (a good idea wrongly killed) is the invisible one, so the design makes it structurally visible: **disqualified stubs are never deleted** (ledger status, preserved like negative results), they appear in **every weekly digest** with gist and reason, and the overturn path is one sentence from David at review — the consulting surface adds a `[DAVID <date>] overturned: <reason>` line to the entry, the status becomes `disqualified-overturned`, and the stub re-enters the next week's rank pool. Recovery is a standing property of the surface, not an appeal process.

**Zero human gates — stated plainly and defended.** Yes: with the flag dissolved into a mechanical disqualifier, the Scout → gate → Analyst pipeline contains **no step where a human must act** (DEC-0103 item 1 says so in as many words). This is acceptable because:

- **Everything the pipeline produces is a document** — stubs, scores, proposals, a business proposal at the end. Documents are the reversible class, and DEC-0102 ruling 1 scopes machinery autonomy to exactly that class. Nothing in the pipeline sends mail, spends money, contacts a client, or changes a system.
- **Spend is capped, not judged:** ≤5 stubs/night on sonnet, ≤2 opus night-slots/week (the ratified caps, DEC-0102 D1) — the worst week costs a bounded, known amount of pool.
- **Every choice is reviewed, just after the fact:** the digest shows each selection with what it beat, at the next session start — which is the calibration instrument David chose *in preference to* approvals ("I prefer a method of learning what interests me rather than getting approvals as we go", ruling 1).
- **Errors in both directions are recoverable:** wrong promotion → one opus slot and a diagnosable digest entry; wrong disqualification → visible weekly, overturnable in a sentence.
- **The red lines still sit above all of it** (`README.md:290–291`) — PHI, cross-actor, governance files, outward-facing acts, material spend — unchanged by this DEC chain.

**The condition under which a gate returns, named now:** the day any part of this pipeline gains an **actuator** — sending the direct-mail piece, buying the domain, contacting a client — that act is outward-facing/irreversible-class and stops for David regardless of everything above. The zero-gate property belongs to the document-only pipeline, not to the venture program as a whole.

### Q13. The aggregate book-of-business profile

**What it is for:** criterion 5 (*fit-with-existing-assets*) is currently scored against a guess. DEC-0103 item 2 authorizes the fix: the lane may read **compiled, non-specific aggregates** — "David has X Medicare Advantage clients, X MedSupp, X IFP" — **never client records**, and **Alfred compiles it**.

**The boundary problem, faced squarely.** Alfred neither reads nor writes anything in Agent_Workflow until Stage B is formally activated (`README.md:367–368`; DEC-0023 cross-actor scope). Alfred writing `venture/book-profile.md` directly would be the first Stage-B crossing, smuggled in as a convenience. The design that keeps the fence:

1. **Alfred compiles in his own domain** — a scheduled job in his runtime writing to a declared handoff path inside his home (exact venue is his workstream's to pick; the dependency is named below).
2. **A deterministic local import step** (the venture wake or the nightly — machinery, not Alfred) copies the file to `venture/book-profile.md` **only if it passes two blocking checks**: the PHI lint (`screen.py --phi`, the same blocking gate the nightly sweep already runs on this repo — `README.md:456–457`) and a **small-cell validator** (below). A file that fails either is not imported, the prior profile stays, and a FAILURES entry says so.
3. **The lane reads one file, read-only.** Ownership header in the `topics.md` style: *compiled by Alfred; imported by machinery after PHI-lint + small-cell check; the venture lane reads it and writes nothing.* The import step is the one writer.

The crossing — machinery pulling a file from Alfred's domain through a lint — is itself a boundary event the record should bless explicitly. [DECISION REQUIRED F7.]

**Permitted schema (aggregate by construction):**

```yaml
compiled: 2026-08-15          # by Alfred's job; staleness is computed from this
product_lines:                # counts only
  medicare_advantage: <n>
  medicare_supplement: <n>
  ifp: <n>
  ...
tenure_bands:                 # counts per band, bands ≥ 1 year wide
  under_1y: <n>
  1_to_3y: <n>
  ...
renewal_timing:               # counts per quarter
  q1: <n> ...
```

**Prohibited, enforced not promised:** names, dates of birth, addresses, policy numbers, health conditions, any free text about an individual — all pattern-classes the PHI lint already trips on (`screen.py:96–108`). **Small-cell suppression:** no numeric cell may be `0 < n < 5` — the compile step reports such cells as `<5` or merges bands until the count clears 5; the import validator parses every numeric field and **rejects the file** if any bare value is 1–4. Five is the conventional small-cell disclosure threshold in health-data practice (labelled as convention — §Could-not-verify); the enforcement mechanism is the point: a cell small enough to gesture at an individual person cannot transit the import, whatever the compiler intended.

**Refresh cadence:** monthly compile; the profile's `compiled:` date rides into the Scout's prompt, and at >60 days the digest annotates every criterion-5 score with "(stale profile)" — the silent-degradation failure mode named and made loud (DEC-0089 item 1).

**How the lane is prevented from reading more:** its tasks declare the profile as their only client-adjacent input (`inputs:`, main design Q1); the post-run scope audit watches declared trees (DEC-0091 item 5, `worker.sh:826–834`); the deny-list already hard-blocks Alfred's domain from any task body (`screen.py:161–163`); and the actual client systems (ShareFile, AgencyBloc, carrier portals) are credentialed surfaces the lane has no path to at all — the structural statement DEC-0103 item 2 asks for.

**The dependency, named:** Alfred's side needs a compile job producing the schema above — Alfred-workstream work (CLD-00058/CLD-00084 territory), not designed here. **Stage 1 does not wait:** until the profile exists, criterion 5 is scored against a **David-authored book sketch** — a short prose block he adds to `topics.md` (his file, his edit — e.g. product mix in round terms), with the digest noting "fit scored against the sketch" so nobody mistakes it for compiled data. When the profile lands, the sketch retires.

---

## Part C — The fold-through

### Q9. Stages 1 and 2, restated

Cap numbers are ratified and unchanged (DEC-0102 D1): Scout ≤5 new stubs/night with full-history dedupe; promotion needs total ≥20/25 with no criterion <3 **and** top-2-of-trailing-week, ≤2/week; Analyst ≤1 active dive, 1/day ceiling, one opus night-slot per dive.

**Stage 1 — Scout + gate + digest, machinery-selects.**
- The venture lane (`Agent_Workflow/venture/` — lane home, ledger location and `topics.md` co-location per main design Q20, unchanged) runs a nightly wake: Scout generates and scores stubs (sonnet); the **gate promotes mechanically within the caps** — no human act; the client-data disqualifier (§Q12) runs at the gate; the **digest is built in this stage** (DEC-0102 D1 addendum): the board's venture section + weekly snapshots; the calibration file starts (free tier + DAVID entries).
- What changed from the main design's stage 1: promotion was "David's act via the weekly discussion" — now the machinery's (DEC-0102 ruling 1); the digest was assumed to exist — now built here (its Librarian build was withdrawn, DEC-0101 item 4); the compliance flag's human read is gone (DEC-0103 item 1).
- Close criteria: §Q8's ten.
- DEC required: **yes** — the stage-1/2 build DEC (this is the DEC that finally supersedes DEC-0090 item 5, per DEC-0102 item 10), naming the launchd capability + scope for the venture plist so the intake auto-routes with a grant (the DEC-0090 Build-B bracket precedent).

**Stage 2 — Analyst, on the inverted gate.**
- A promotion triggers the Analyst step **inside the lane**: the wake script instantiates the dive task from a version-controlled template when a promoted, non-disqualified stub exists and no dive is active — a deterministic, code-evaluated condition (the Conductor routing property), screened at the hop like every instantiated task. **This replaces the main design's "promotion enacted by the consulting surface filing a front-door intake"** — under machinery-selects there is no consulting-surface act to hang that intake on. The template is code; model output never composes it (the stage-4 red line, DEC-0102 D4, honored early).
- Before diving, the Analyst runs the independent grading (§Q10 deep tier: three lenses, sonnet) — which includes the disqualifier re-test (§Q12 layer 3).
- **Research requests auto-route from stage 2** (DEC-0102 D6): origin `agent-proposal/analyst` + `related:` resolving to the promoted stub's record + P2-class request + scope within the stub's topic → routed to `librarian/inbox` through the **orchestrator front door** without escalation. The front-door path itself is unchanged from the main design Q21 — only the interim approve-each-request rounds are gone.
- Output: the formal business proposal, delivered per DEC-0099 (consulting surface + project folder); verdict recorded in the ledger (DEC-0102 D5 — not on a wiki page); non-viable dives preserved as ledger verdict + short memo.
- Close criteria (mechanical): one full cycle promoted-stub → verdict with **zero human acts between generation and verdict** (record diff shows no decision documents in the path); the three-lens grading artifacts exist for every dive (per-lens outputs + synthesis, the main design Q3 shapes); a Scout-vs-Analyst score delta recorded in the calibration file per dive; ≥1 research request auto-routed (OI minted, `librarian/inbox` received it, no escalation ledger line for it); caps held (never >1 `diving`; ≤2 new dives in any 7-day window); an aborted-dive fixture demonstrates disqualifier layer 3 (dive stops before the opus slot is spent).

**What the inversion breaks — flagged, per the brief:**

1. **The main design's stage-2 close criterion "promotion enacted via front-door intake" is void** — replaced as above. The audit trail survives in a different place: the gate's ledger line + the digest entry, instead of an OI.
2. **The board's NEEDS-YOU section loses its only routine venture feed.** Under the main design, every promotion visited David; now nothing venture-shaped needs him routinely — which is exactly why the digest's calibration payload (§Q7) has to be rich: it is the *only* remaining place his taste enters the loop.
3. **`check_staleness.sh` reminder semantics:** escalated-pending (7d) no longer fires for venture items (nothing escalates routinely). No change needed — noted so nobody reads the silence as coverage.
4. **DEC-0090 item 5's early-ping threshold** ("pinged early only when a candidate meets every criterion AND outscores all previously-flagged ideas") was defined for a push channel. It survives as a **board placement rule**: such a candidate is promoted to NEEDS YOU (with a desktop notice) instead of waiting in SELECTIONS — same rarity bar, new surface.

### Q10. The scoring feedback loop — self-contained

*This section stands alone: David proposed the loop; this is its design.*

**The proposal (David, verbatim, brief question 10):** *"How about a scoring loop? Scout grades its own idea and sends it to the Analyst. The Analyst also grades the idea (maybe sending it to three models for grading) then provides feedback to the Scout. Feedback includes not only how well did you score yourself, but by extension what was important or not important, and what direction should be considered for future ideas."*

**The shape in one paragraph.** The Scout has no session memory — every night is a blank session (`_meta/schema.md:86–88`), so feedback must be **a file it reads, not a message it receives**. Three different things called "memory" get three homes: the **ledger** keeps raw history (exists today); a slim **calibration file** carries operational scoring guidance into the Scout's prompt nightly; **The_Wiki**, through The_Librarian's normal authoring path, keeps durable market knowledge. David's reactions at the digest enter the calibration file as top-ranked entries — he is the anchor; the Analyst's independent grading feeds it continuously; the gate contributes free statistics on everything that never reached the Analyst. A weekly compaction rule keeps the file small enough to stay read.

**The three memory tiers (settling David's direct question — "a slim memory.md file… or The_Wiki or some other memory layer?"):**

| Tier | Home | Content | Why here and not elsewhere |
| --- | --- | --- | --- |
| Raw history | `venture/ideas-ledger.md` (exists; `ideas-ledger.md:3–6`) | every stub, score, status, verdict — append-mostly, never compacted | the audit substrate; too big and too raw for a prompt |
| **Calibration** | **`venture/calibration.md`** (new — the slim file David asked about) | how to score, what David valued, which directions died, current emphasis | operational and stale-within-a-month — putting it in The_Wiki pollutes an encyclopedia with tuning state and re-breaks the DEC-0090 item-6 authorship boundary; putting it in David's memory store confuses the lane's learning with his; a lane file that rides the nightly prompt is the only home that is both read every night and cheap to change |
| Durable knowledge | **The_Wiki, via The_Librarian** | what a dive actually established about a market or business model | encyclopedic and general; authored through her normal path, so the venture lane gets no second door into the commons (DEC-0090 item 6 preserved) |

**The structural parallel holds, and the discipline is borrowed.** This is David's own memory architecture in miniature — raw daily logs → curated decisions → encyclopedic wiki — and the part worth stealing is the curation discipline, because the middle tier is the one that dies of neglect. Hence the compaction rule below, which is the direct analog of decision-capture's "curate or it rots."

**The calibration file — schema, precedence, bounds:**

```
# venture/calibration.md — scoring calibration (bounded; compacted weekly)
# PRECEDENCE RULE (enforced by the compactor and stated for every reader):
# [DAVID] entries outrank [ANALYST] entries outrank [GATE] entries. On conflict,
# the lower-ranked entry is marked superseded at the next compaction. [DAVID]
# entries are never removed by machinery — only compacted verbatim or by David.

## Scoring guidance (per criterion)
- [DAVID 2026-08-09] roi: recurring beats one-off even at lower totals — weight it so. (digest wk32 reaction)
- [ANALYST 2026-08-06 IDEA-014] ttfd: scout scored 4, real path to first dollar is 6+ months → 2. Anchor ttfd to a named first-paying-customer path, not to build time.

## Directions
- [DAVID 2026-08-09] pursue: service productization for existing book. avoid: anything needing a new license.
- [ANALYST 2026-08-03 IDEA-009] died on: market saturated at the price point the scores assumed.

## Proposals standing (outside the register — surfaced in digest, awaiting David)
- [SCOUT 2026-08-07] proposal: efficiency-tools-for-independent-agents (adjacent to register; would displace nothing until promoted to topics.md by David)

## Gate statistics (rolling 4 weeks, machine-written)
- [GATE wk32] 12 stubs; 4 passed threshold; holdbacks: roi-floor 5, ttfd-floor 2, rank 1.
```

- **Who writes what, when:** the **gate** appends its weekly stats line mechanically (no model call); the **Analyst** appends per-dive entries at verdict time; **DAVID entries are written by the consulting surface from his digest reactions, in his words, source-stamped with the session** — the DEC-0099 pattern (his authority enters through the surface that records it). The **Scout appends only to §Proposals** — it never edits guidance about itself.
- **How a David correction outranks, mechanically — three enforcement points, not a principle:** (1) the tag *is* the authority field, and the file header states the precedence rule where every reader sees it; (2) prompt composition injects §Scoring-guidance with `[DAVID]` entries **last** (recency-position advantage in-context) and prefixed `DAVID:`; (3) the weekly compactor detects same-subject conflicts (same criterion or direction addressed by both tags) and **marks the `[ANALYST]` entry superseded** — the conflict is resolved in the file, not left to the model's judgment each night. A `[DAVID]` entry is removed only by David.
- **Growth bound and compaction rule (the answer the verification bar demands):** hard cap **120 lines / 8 KB** — small enough to ride every nightly prompt without crowding the task. Compaction runs **weekly, in the venture wake, at snapshot time**: (a) mechanical first — `[GATE]` entries older than 4 weeks dropped; `[ANALYST]` entries older than 6 weeks dropped **unless** re-affirmed by a later same-subject entry; superseded entries dropped; (b) then one bounded model step merges near-duplicate guidance lines, **verbatim-preserving every `[DAVID]` line** (it may group them, never rewrite them); (c) if still over cap, the oldest `[ANALYST]` entries go first, and the compactor writes a FLAG — a cap being *hit* is a signal the guidance isn't converging, not a housekeeping event. What gets promoted *in*: only entries with a source tag and a date; free-floating wisdom has no author and no entry.

**Coverage — the three tiers of feedback (the Analyst sees 2 of ~35; the loop must not be blind to the other 33):**

- **Free tier (every stub, zero model calls):** the gate already computes every score; it records per-criterion holdbacks for all non-promoted stubs and emits the weekly `[GATE]` stats line plus the digest's floor line (§Q7.3). Costs nothing; covers everything.
- **Deep tier (promoted stubs only):** before the dive, the Analyst independently re-scores the stub — **three lenses, three different questions** (below) — and writes the per-criterion delta plus a guidance entry. This is where "how well did you score yourself" gets a real answer.
- **Anchor tier (David):** his digest reactions — "poor choice, here's why" / "good pick" — entered as `[DAVID]` lines. **Without this tier the loop converges on machine consensus:** the Scout tuning to the Analyst, both models, is two instruments agreeing with each other, not calibration. The precedence rule is what makes his corrections dominate mathematically small input volume.

**The three graders — lenses, not votes** (Settled 6; main design Q11–Q12; David's own framing: alternatives over verdicts):

| Lens | Question | Output |
| --- | --- | --- |
| Re-scorer | score this stub against the rubric, cold — no sight of the Scout's scores | per-criterion scores + one line each |
| Improver | "provide a materially better version of this idea" | the better version, or "none found" with why |
| Killer | "what kills this idea that nobody named?" | the failure mode, or named checks cleared |

A synthesis step (not one of the three — the main design's Q12 rule, enforced by job description) writes the delta entry: where the lenses disagreed with the Scout and with each other, preserved rather than averaged. **Cost against the bound:** three sonnet lens calls plus a sonnet synthesis on a one-paragraph stub — minutes each, an estimated 10–20% overhead on the dive's opus night-slot **[estimate, not measured — Could-not-verify]** — inside the existing one-slot bound with the dive itself on opus (per-department tiers: Scout sonnet, lenses sonnet, dive opus — the per-lane model choice CLD-00109 records David wanting). If live runs show the lens work crowding the slot, the bound gets revisited then, with data.

**Direction proposals — first-class, not overflow (DEC-0103 item 3).** The Scout carries a **standing invitation** in its prompt: propose focus areas beyond the register, any night, as `[SCOUT] proposal:` entries + a digest subsection row. Exploring is desired and is not treated as a risk — David's correction, verbatim in the DEC. The only enforced boundary is the **write boundary**: proposals never touch `topics.md` (David-owned, machinery-read-only — its header contract, `topics.md:3–9`); sustained effort follows the register, and the register changes only by his edit. A proposal is a document; adopting one is resource allocation; the file ownership is the whole mechanism.

**How to tell after four weeks whether the loop works** (measured against the weekly snapshots):

1. **Score-delta trend:** mean |Scout self-score − Analyst re-score| per criterion, per week — should shrink. Flat or growing after 4 weeks = the Scout isn't absorbing the file, or the file isn't specific enough.
2. **David-correction rate:** `[DAVID]` corrections per digest — should decline or stabilize at near-zero *while selections still get "good pick"* (zero corrections with zero engagement is not success, it is non-review; the digest's react-line makes engagement one sentence).
3. **Promotion survival:** share of promoted stubs the Analyst finds viable — should rise (the gate learning what survives contact).
4. **Proposal engagement:** ≥1 direction proposal explicitly adopted or declined by David in the window — the DEC-0103 invitation demonstrably real.

All four are computable from the ledger + calibration file + snapshots by grep and arithmetic — the 4-week recalibration checkpoint the main design proposed (Q19) and DEC-0102 D1 made "more important, not less."

### Q11. The two carried findings — confirmed against the live tree, with stage-1 obligations

**(a) Model-binary pinning and the unfenced plist — CONFIRMED.** The three machinery plists set `CLAUDE_BIN` to the agent-pinned copy (`_meta/com.cowork.agent-{worker,reviewer,orchestrator}.plist` — grep confirms all three); the Librarian's installed plist deliberately carries none (its own comment: *"makes NO model call, so no CLAUDE_BIN is needed"*, `librarian/com.cowork.librarian.plist:14–16`) — deliberate and currently harmless, but it confirms the general finding: nothing outside the machinery lanes pins, and `_lib/run_claude.sh:70` defaults to the floating `~/.local/bin/claude` symlink, which is the un-granted-binary TCC hang class (`README.md:416–439`). The launchd capability is **unowned right now**: the live grants registry contains only the README (`_meta/grants/` — verified), GRANT-0001 is consumed in `archive/` (one-shot, DEC-0091 item 4), and DEC-0100 names no capability.
**Stage 1 must:** (i) the venture plist sets `CLAUDE_BIN` to the pinned path — the Scout *does* make model calls, so the Librarian's exemption argument does not transfer; (ii) the stage-1 build DEC names the capability and scope in the DEC-0091 item-3 form — *capability `launchd`, scope: the per-user service definition for the venture lane's nightly wake, label `com.cowork.venture` under `~/Library/LaunchAgents/`, and its one-time load* — so the intake auto-routes and mints the grant (the DEC-0090 Build-B bracket precedent, verbatim shape); (iii) close criterion 10 (§Q8) checks both after the fact.

**(b) The Librarian token-filename transposition — CONFIRMED, direction established.** On disk: `~/.config/cowork-workflow/librarian-telegram.token` (present, chmod 600, dated Jul 27 — verified by listing). In code: `librarian-cycle.sh:144` points notify.sh at `…/telegram-librarian.token` — the **script** carries the transposed name; the disk file matches what DEC-0090 item 8's out-of-band install created. And `notify.sh` degrades an unreadable token file to desktop-only + a ledger FLAG (`notify.sh:70, 156`) with **no fallback to any other lane's bot** — `TOKEN_FILE` is captured once at source time (`notify.sh:42`; `librarian-cycle.sh:144` exports it before sourcing), so her alerts have been desktop-only since install, silently doing exactly what the code says.
**What stage 1 does about it:** *nothing in her lane* — that fix belongs to the Librarian's workstream (it is already recorded on CLD-00109's Progress and CLD-00089's context; repairing another lane's script is out of this pass's scope). Stage 1's obligations are the lessons: (i) **the venture lane gets no bot identity at all** — its surface is the board; under §Q2's disposition the per-lane-bot pattern (DEC-0090 item 8) is dormant infrastructure, and creating a new instance of a pattern being retired would be perverse; (ii) any token-path indirection the lane ever does acquire must be existence-checked at wake start with a loud FLAG on mismatch — the transposition class is a one-line check to catch and was invisible for four days because nothing checked.

---

## Contradictions with the main design

**None with Parts 1–6 or stages 3–5.** Checked deliberately: the board design changes *delivery* of escalations and holds, not their production, adjudication semantics, or the DEC-0093 taxonomy; the calibration file is lane state, not a semantic-layer placement (CLD-00096 untouched); the profile import creates no new executor authority.

Two main-design load-bearings this pass *revises within its charter* (Part 7–8 territory, flagged per the brief's instruction rather than quietly absorbed):

1. **Stage 2's promotion-via-front-door-intake is void** under machinery-selects; the Analyst step is lane-internal instantiation from a code template (§Q9). The audit property the front door provided (a screened, recorded promotion event) is preserved by different means: the gate's ledger line, the screened instantiation hop, and the digest entry.
2. **The main design's D11 phrasing "refuse always notifies"** becomes "refuse always surfaces in NEEDS YOU, with a desktop notice" — already restated by DEC-0102 D11; the board is its mechanism.

One observation that touches a stage-4 precondition without contradicting it: the main design required "no repeat notifications for unchanged state" before the V/D lane. With the board as the surface, that precondition's *meaning* is what DEC-0102 D4 asked this pass to state: **an unchanged waiting state appears exactly once on the board (state-keyed, age-annotated) and re-pushes nowhere** — the CLD-00105 fingerprint discipline satisfied by construction on a state-based surface. Stage 4 inherits it for free.

---

## [DECISION REQUIRED]

**F1 — Adopt the review board, and its startup hook.** Options: (a) `REVIEW.md` as designed — machinery-generated at wake-end + nightly, state-based sections, startup-protocol step added beside step 6 (**his `MEMORY.md` edit** — governance-protected, and the protocol is his); (b) no new file — extend the existing step-4/step-6 reads and let the session assemble the view each time (rejected by the brief's own constraint: the surface must exist without a session and be producible by machinery). **Recommend (a).**

**F2 — Channel disposition + the two amendments.** Options: (a) as §Q2: desktop kept for FAIL/needs-you classes only, Telegram dormant, DEC-0099's notification half and DEC-0090 item 8 formally amended at the stage-1 DEC; (b) keep all desktop notices (more noise, zero build cost); (c) also disable desktop (rejected: it is the only same-moment signal and costs nothing). **Recommend (a).**

**F3 — Accept the stated three-day cost.** The board waits; a hard failure can sit up to three sessionless days softened only by desktop notices and the staleness banner (§Q3). This is ruling 2's own price restated concretely — but it should be accepted with the number attached, not implicitly. **Recommend: accept**, and revisit only if multi-day sessionless gaps become a real pattern.

**F4 — Park the cloud/GitHub read.** Not worth building (§Q5); one sentence kept for the future push design (metadata-only last-push-age probe as a dead-man's switch). **Recommend: park.**

**F5 — The calibration file's authority rule.** Confirm: `[DAVID]` outranks `[ANALYST]` outranks `[GATE]`; David entries machinery-immutable; the 120-line/8KB cap and the weekly compaction rule (§Q10). **Recommend as designed.**

**F6 — The disqualifier mechanism and zero gates.** Confirm: declared `client-data:` field + deterministic gate reject + Analyst re-test; disqualified stubs always visible in the digest with a one-sentence overturn path; the pipeline runs with zero human gates until it gains an actuator (§Q12). **Recommend as designed.**

**F7 — The profile handoff across the Alfred boundary.** Options: (a) as §Q13 — Alfred compiles in his domain, machinery imports through PHI-lint + small-cell validation, lane reads one file (a deliberate, blessed, lint-gated crossing); (b) defer the profile entirely and run indefinitely on the `topics.md` book sketch; (c) let Alfred write into `venture/` directly (rejected: the first silent Stage-B crossing). **Recommend (a)**, with the interim sketch either way. This is the one item here that touches the cross-actor boundary and should be ruled explicitly, not inherited from a design document.

**F8 — Three-lens grading inside the existing slot.** Lenses + synthesis on sonnet, dive on opus, within the one-opus-night-slot bound; revisit with data if the overhead estimate (10–20%) proves wrong. **Recommend as designed.**

**F9 — Weekly digest snapshots.** `venture/digests/week-YYYY-WW.md` as the calibration archive (the loop's 4-week test needs frozen history; the ledger alone doesn't preserve what the *digest showed*). **Recommend yes.**

**F10 — Two edits owed by David, restated:** the `topics.md` item-6 rewrite (DEC-0103 item 1 — drafted for him in-chat; the file still carries the old text) and, if F7(a), the book-sketch block in the same file. Plus the F1 `MEMORY.md` step. All three are his files.

---

## Could not verify

1. **The 10–20% lens-overhead estimate** (§Q10) — reasoned from prompt sizes, not measured; no venture lane exists to measure.
2. **The small-cell threshold of 5** (§Q13) — standard practice in health-data disclosure control, asserted as convention; not verified against a named regulation. The enforcement mechanism does not depend on the number; David can set K.
3. **Whether `~/Claude` (the run-ledger's repo) is pushed to a GitHub remote** — `agent-workflow` is (`README.md:455–458`); `~/Claude` has nightly EOD snapshots (CLAUDE.md bootstrap header) but I did not verify a remote. Affects only the (rejected) §Q5 route's hypothetical coverage.
4. **CLD-00061 Datapoint 4** (cloud scheduled tasks have no device bridge) — taken from the record (cited by DEC-0102 ruling 2's platform-limit paragraph); not re-tested.
5. **Phone-viewed session + desktop-app device bridge** — untested, flagged per the brief, deliberately not tested here.
6. **Cowork cloud scheduled-task secret storage mechanics** (§Q5) — asserted as "a new trust surface" without enumerating the platform's actual secret facilities; irrelevant under the not-worth-it recommendation.
7. **Whether desktop notifications are seen/valued by David in practice** — behavioral; the design keeps them only where they are free and drops nothing onto them that the board doesn't also carry.
8. **`librarian-cycle.sh` beyond the token/alert region** — read `:138–152` and the plist; the rest of the script was not re-read this pass.
9. **Anthropic pool telemetry** — carried unresolved from the main design (§Could-not-verify item 3 there); the board's HEALTH section reports run counts, not pool percentages, for exactly this reason.

---

## Appendix — verification-bar self-check

1. *Current-behaviour claims cite file:line / DEC / CLD* — throughout; the notify enumeration cites each call site individually.
2. *Q2's class list from reading the call sites* — 19 orchestrator sites enumerated by line (`:1054, :1437, :1758, :2003, :2093, :2133, :2232, :2259, :2300, :2306, :2347, :2364, :2398, :2401, :2483, :2506, :2516, :2534, :2545`), plus worker/reviewer/watchdog/attention/librarian producers. Brief-named classes that don't exist in code: venture rows 15–18 (future). Code-produced classes the brief omitted: rows 5–8, 12, plus the ledger-only `notify-quiet`/`notify-edge` pair. Wiki candidates: exist as data flags, are not a notification class, and never surface to David — stated in row 19.
3. *Fail-loud states what gets quieter and the three-day cost* — §Q3, explicitly, with the desktop-class table column and the named worst case.
4. *Q5 reaches a recommendation without designing an implementation* — "not worth building," with the single surviving future variant named in one sentence.
5. *Stage-1 close criteria grep/diff/fixture-checkable* — §Q8's ten; the one that involves machinery-selects (criterion 5) is a record-diff, not a judgment.
6. *Nothing out of scope designed* — stages 3–5 untouched (one precondition's meaning stated, as DEC-0102 D4 directed); no Telegram redesign (dormancy is a disposition, not a design); CLD-00106/CLD-00096/Alfred-Azure/PHI untouched; the profile's Alfred side named as a dependency, not designed.
7. *Digest/session-start relationship stated* — one surface (the board's venture section) plus an archival weekly snapshot, with the reason (§Q6).
8. *Q10 names schema, growth bound, and the mechanical precedence of a David correction* — §Q10: the tagged-entry schema, the 120-line/8KB cap, and three enforcement points (header rule, composition order, compactor supersession).
9. *Q12 states zero gates plainly, defends it, and keeps wrong rejections recoverable* — §Q12: yes-zero-gates, the four-part defense, the always-visible-plus-one-sentence-overturn recovery, and the named condition under which a gate returns.
9b. *The compaction rule is named, not just the schema* — §Q10: weekly, in the venture wake; mechanical age-outs first, bounded merge second, cap-hit FLAGs; `[DAVID]` lines machinery-immutable.
9c. *The profile schema is aggregate by construction with small-cell suppression as a mechanism* — §Q13: counts-only schema, import-side validator rejecting any bare cell 1–4, and the dependency named (Alfred-side compile job; interim = David's sketch in `topics.md`).
10. *Nothing assumes phone-initiated local access or an existing push channel* — the surface is the Mac-session board; push is a pre-classified future delivery change; the phone appears only as an untested-and-not-relied-on note.
11. *No file other than the deliverable created or modified* — confirmed; this document is the session's only write.

