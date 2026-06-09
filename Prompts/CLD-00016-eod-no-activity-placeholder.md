# CLD-00016 — EOD: Restore SKILL.md + Add No-Activity Placeholder

**Project:** cowork-evolution
**Author:** Cowork-me (David + Claude), 2026-06-01
**Executor:** Claude Code
**Status:** Executed 2026-06-01
**Backing item:** `~/Claude/memory/action-items/CLD-00016-260601-Open.md`

---

## Background

The EOD compaction scheduled task (`cowork-end-of-day-compaction`, cron `0 23 * * *` PDT) has not been creating daily logs since approximately 2026-05-27 — six days of gap. Root cause: the scheduled task's `path` field points to `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md`, but that file does not exist. The actual SKILL.md is at `~/Documents/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` (the pre-CLD-00015 path). The task fires nightly but runs with a missing prompt and silently produces nothing.

The SKILL.md also contains stale paths from before the CLD-00015 Projects folder migration (2026-05-28).

This prompt fixes the broken EOD by creating the SKILL.md at the correct path, updating stale references, and adding the no-activity placeholder behavior (the original CLD-00016 scope).

**Note:** The scheduled task's internal `path` reference (`~/Claude/Scheduled/...`) cannot be updated by Claude Code — that requires Cowork's `mcp__scheduled-tasks__update_scheduled_task`. The fix here is to create the file at the path the task already expects. No Cowork follow-up needed for the path.

---

## Step 1 — Read the current SKILL.md

Read the existing SKILL.md at its current (stale) location:

```
~/Documents/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md
```

Use this as the base for the updated version.

---

## Step 2 — Create the SKILL.md at the correct path

Create `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` (create the directory if needed) with the following updated content:

```markdown
---
name: cowork-end-of-day-compaction
description: Daily end-of-day compaction at 11pm PDT — process today's chats, write daily log, create tomorrow's skeleton.
---

You are the end-of-day compaction agent for David Brabender's Cowork-me / Alfred Evolution project. Your job is to process today's Cowork chats, write today's daily log, and create tomorrow's daily log skeleton.

Run the full procedure per `/Users/alfredassistant/Claude/memory/processes/end-of-day-compaction.md`. Read it first if any step is unclear.

Required first action: load deferred tool schemas you'll need:
ToolSearch select:mcp__workspace__bash,mcp__session_info__list_sessions,mcp__session_info__read_transcript

Then proceed with the procedure. Critical points:

1. **Self-identify.** Derive your own session ID from cwd path (`local_<UUID>` segment). Save as OWN_SESSION_ID. You will exclude your own transcript from the discovery scan.

2. **Use local time.** Date computations must use David's local time (PDT/PST, US Pacific), not UTC. The bash sandbox is UTC by default — use `TZ=America/Los_Angeles date +%Y-%m-%d` for today's date. The spawned session's claudeMd typically shows local-today; cross-check.

3. **Discovery.** Find today's-edited transcripts via `find /Users/alfredassistant/Claude/transcripts/cowork/ -name 'local_*.md' -mtime -1 -type f`. Cross-reference with `mcp__session_info__list_sessions` for currently-visible chats. Exclude OWN_SESSION_ID. Prior-day EOD transcripts naturally excluded by mtime.

4. **No-activity path.** If discovery returns an empty work list (no chats with activity today), run the no-activity path:
   - Create today's daily log at `~/Claude/memory/daily/<TODAY>.md` with this stub:
     ```
     # Daily Log — <TODAY>

     ## Log Continuity
     - Prior log: <PRIOR_LOG_DATE>.md
     - No chat activity today — placeholder created by EOD compaction.

     [DAY-COMPLETE: <TODAY>] — EOD no-activity run
     ```
     Find `<PRIOR_LOG_DATE>` by listing `~/Claude/memory/daily/` and taking the most recent existing log before today.
   - Create tomorrow's skeleton per step 5 below (active-chats list will be empty).
   - Write self-transcript per step 6.
   - Report: "No activity today — placeholder log created for <TODAY>." Then end the session.
   - **Do not continue to step 5 of the normal path.**

5. **Per-chat work** (normal path only). For each chat: backfill closing turn from session_info if missed by live-transcribe; write `## Chat: <chat-internal-name>` section in today's daily log with [SESSION-OPEN], [SUMMARY], [SESSION-STATE], [COMPLETE] tags as appropriate; promote any items flagged for promotion (decisions to `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`; behavioral lessons to auto-memory feedback files; user context to user_david.md; pattern recognition to `~/Claude/memory/learnings/` if directory exists); capture any new open items to `~/Claude/memory/action-items/` per the per-item file convention (see `~/Claude/memory/processes/action-items-framework.md` — do NOT write to a flat open-items.md, that file is deprecated).

6. **Day-finalize.** Write [DAY-COMPLETE] in today's log. Create tomorrow's daily log skeleton at `~/Claude/memory/daily/<TOMORROW>.md` with Log Continuity carry-overs (active chats list without [COMPLETE], pointer to `~/Claude/memory/action-items/_index.md`, pointer to `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`).

7. **Self-transcript.** At end of run, write your own transcript at `~/Claude/transcripts/cowork/<OWN_SESSION_ID>.md` per live-transcribe format. For one-shot scheduled-task sessions, this is a single capture at end (one turn block) rather than per-turn appends.

8. **Report.** Brief summary: chats processed, daily log written, tomorrow skeleton created, anomalies if any. End the session after reporting.

If you encounter anything you can't resolve, write what you tried and observed to the daily log under a [COMPACTION-ISSUE] tag, and continue with the rest of the work. Don't block on a single chat's failure.

Edge cases (see process doc for full coverage): own-session exclusion required; if today's log already has [DAY-COMPLETE], skip (idempotency); if a session_info-visible chat has no transcript file, fall back to cross-chat session_info compaction.
```

---

## Step 3 — Verify Scheduled folder state

David has already completed the physical migration (DEC-0051, 2026-06-01):
- `~/Documents/Claude/Scheduled/` removed entirely
- `~/Claude/Scheduled/` is the single home
- `~/Claude/Scheduled/archive/cowork-end-of-day-inheritance-test/SKILL.md` — archived
- `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` — already in place (old content; this prompt updates it)

Confirm this state with a quick `find ~/Claude/Scheduled/ -type f` before proceeding. If the compaction SKILL.md is missing for any reason, create it per Step 2 above.

---

## Step 5 — Update the process doc

File: `~/Claude/memory/processes/end-of-day-compaction.md`

Make these targeted edits:

**3a. Formalize the no-activity path as Step 3a** (insert after Step 3, before Step 4):

```
### 3a. No-activity path

If the work list (Step 3) is empty, skip Steps 4–6 and run this path instead:

1. Find the most recent existing daily log in `~/Claude/memory/daily/` to use as the prior-log pointer.
2. Create `~/Claude/memory/daily/<TODAY>.md`:
   ```
   # Daily Log — <TODAY>

   ## Log Continuity
   - Prior log: <PRIOR_LOG_DATE>.md
   - No chat activity today — placeholder created by EOD compaction.

   [DAY-COMPLETE: <TODAY>] — EOD no-activity run
   ```
3. Create tomorrow's skeleton per Step 7 (active-chats list empty).
4. Write self-transcript per Step 8.
5. Report: "No activity today — placeholder log created for <TODAY>." End the session.
```

**3b. Update the "No chats with activity today" edge case** — replace its content with:
```
**No chats with activity today:** Handled as a first-class path — see Step 3a.
```

**3c. Fix stale paths** throughout the document:
- `~/Documents/Claude/COWORK-DECISIONS.md` → `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md`
- `~/Claude/projects/alfred-evolution/open-items.md` → `~/Claude/memory/action-items/` per-item files (point to action-items-framework.md for the convention)

**3d. Add a History entry:**
```
- **2026-06-01:** CLD-00016 — No-activity placeholder formalized as Step 3a. Stale paths updated (decisions file, open-items convention). SKILL.md restored to ~/Claude/Scheduled/ after CLD-00015 path breakage.
```

---

## Step 6 — Update CLD-00016 item

In `~/Claude/memory/action-items/CLD-00016-260601-Open.md`, add a Notes entry documenting what was done and confirming the fix. Do NOT close the item — leave open until the next EOD run confirms a log is created (no-activity or otherwise).

---

## Acceptance criteria

- [ ] `~/Claude/Scheduled/cowork-end-of-day-compaction/SKILL.md` exists with updated content
- [ ] `~/Documents/Claude/Scheduled/` contains only `archive/` with two archived task folders inside
- [ ] Process doc has Step 3a (no-activity path) as a first-class step
- [ ] Process doc stale paths resolved
- [ ] Next EOD run (tonight, 2026-06-01 at 11pm PDT) creates a daily log for 2026-06-01
- [ ] On a future no-activity day, EOD creates a stub log rather than producing nothing
- [ ] CLD-00016 item notes updated; item stays open pending first confirmed EOD run
