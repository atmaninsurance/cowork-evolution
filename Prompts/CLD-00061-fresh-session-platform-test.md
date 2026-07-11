# CLD-00061 — Fresh-Session Platform Test + EOD-Equivalent Dry Run

**Run in:** a FRESH Cowork session, Alfred Evolution project, started from the desktop app on the Mac Studio (Cowork mode — check the toggle).
**Authored:** 2026-07-09 (chat `remote_da00a1d5`, cowork-platform-changes-memory-impact)
**Purpose:** Verify what survived the 2026-07-07 remote-Cowork platform change in a fresh desktop-started session, and run the EOD-equivalent checks now instead of waiting for tonight's scheduled run.
**Posture:** OBSERVE AND RECORD ONLY. Do not fix anything, amend any rule, or open new action items. The only writes permitted are the marked test-writes below and the memory-file updates in Part D. Rule amendments are pending a joint review session.

**Background (one paragraph):** On 2026-07-09 the first session on the new remote architecture (chat `remote_da00a1d5`) found: execution moved to an Anthropic cloud container; the Mac is reached via a desktop-app bridge; this project's `~/Claude` folder connection did not carry over (device rejected it; session metadata claimed it); `request_cowork_directory` and `session_info` tools are absent; the working access path was the locally-installed Filesystem MCP proxied through the bridge. Full findings: `~/Claude/memory/daily/2026-07-09.md` and `~/Claude/memory/action-items/CLD-00061-260709-Open.md`. You are generating Datapoint 3 (fresh desktop session) and, with David's go-ahead, Datapoint 4 (true scheduled path).

---

## Part 0 — Startup observation (do nothing special; then report)

Run your normal startup protocol per the Global Instructions FIRST, exactly as you ordinarily would. Then report:

1. Did the protocol fire on turn 1 and complete? Which steps succeeded / failed / were skipped?
2. Which tools actually reached `~/Claude/memory` — native Cowork folder tools (device_list_dir / device_stage_files), or the proxied `Filesystem` MCP, or neither?
3. Did you create a per-chat transcript? Give the full path and the exact filename you chose. (Remote-session transcript naming is an undecided convention — `remote_<UUID>` was used provisionally on 2026-07-09. Whatever you chose, flag it as a naming datapoint; do not treat either form as ratified.)
4. Read the clock via bash (`TZ=America/Los_Angeles date '+%Y-%m-%d %H:%M %Z'`) and use the Pacific date for every stamp below.

## Part A — Environment diagnostics

- **A1. Device + folder grants.** Call `get_device_info`; report `connectedFolders` verbatim. Then attempt `device_list_dir` on each of: `~/Claude`, `~/Claude/memory`, `~/Claude/transcripts`, `~/Documents`, `~/.openclaw`. Report success/rejection for each. (DEC-0050 expected this project to mount all three roots — does it?)
- **A2. Tool inventory.** Using ToolSearch where needed, report present/absent for: `request_cowork_directory`; any `session_info` / `read_transcript` tool; `project_read` / `project_write` / `project_search`; the `mcp__remote-devices__*` family; `project_memory_read` / `project_memory_write`. One line each.
- **A3. Execution locus.** Run `pwd; uname -a; whoami` in Bash (expect: Anthropic cloud container) and, if available, one `device_bash` command like `hostname` (expect: local VM on the Studio). Confirm or correct the two-filesystem split.
- **A4. Write-path check.** Append ONE line to today's daily log (`~/Claude/memory/daily/<today>.md`) under a new section `## Chat: platform-test-fresh-session`: `[TEST-WRITE <Pacific timestamp>] fresh-session write path OK via <tool used>`. Read it back to confirm. Leave it in place.
- **A5. Read+edit check on transcripts.** Confirm you can both read and Edit-append a file under `~/Claude/transcripts/` (your own transcript from Part 0 counts).

## Part B — EOD-equivalent dry run (desktop path)

Perform end-of-day compaction's discovery and read steps WITHOUT doing the real compaction:

- **B1. Discovery.** Find transcripts modified today across all three surfaces: `~/Claude/transcripts/cowork/`, `code/`, `dispatch/`. List filenames + mtimes. (Expect at least `cowork/remote_da00a1d5-….md` and your own.)
- **B2. Closing-turn backfill capability.** EOD historically used `mcp__session_info__read_transcript` to read other chats' platform transcripts. Attempt whatever equivalent exists in this session. If none exists, state plainly: "EOD's backfill dependency is absent in this environment" — that finding is the point; do not improvise a scrape.
- **B3. Daily-log readability.** Read today's daily log end to end; confirm the Log Continuity block and all chat sections parse.
- **B4. Scheduled-task infrastructure.** List existing scheduled tasks (list_triggers or whatever this environment provides). Find the EOD task; report its schedule, next-run time, and which mechanism it rides on. DO NOT modify or delete anything.

## Part C — True scheduled-path probe (ASK DAVID FIRST, in-session)

Parts 0–B run desktop-attached; the real EOD fires as a scheduled task in a fresh cloud session, possibly with no device online. This is the decisive test. With David's explicit go-ahead:

1. Create a ONE-SHOT scheduled task ~10 minutes out with exactly this prompt:

   > Scheduled-path probe (CLD-00061, Datapoint 4). You were fired as a one-shot scheduled task to test device reachability from the scheduled path. (1) Report which device/file-access tools you have: any `mcp__remote-devices__*` tools, any proxied `Filesystem` MCP, connected folders. (2) Attempt to read `~/Claude/memory/MEMORY.md` on the Mac Studio. (3) If the read succeeds, append this single line to `~/Claude/memory/daily/<today>.md` under the `## Chat: platform-test-fresh-session` section: `[SCHEDULED-PROBE OK <Pacific timestamp> via <tool>]`. (4) If it fails, list exactly which tools were missing or rejected, and stop. Keep total output brief; change nothing else.

2. Tell David the exact fire time and that the pass/fail evidence will be the presence or absence of the `[SCHEDULED-PROBE OK …]` line in today's daily log (plus the task's own session record).
3. Note for interpretation: the Studio's desktop app will presumably be open during the probe. If the probe FAILS with the app open, tonight's EOD will fail too. If it SUCCEEDS, we still separately note that an app-closed scenario is untested — say so in the recorded finding.

## Part D — Record and report

1. Append a concise findings summary to today's daily log under your `## Chat: platform-test-fresh-session` section.
2. Update `~/Claude/memory/action-items/CLD-00061-260709-Open.md` → Findings: add **Datapoint 3 (fresh desktop session, Alfred Evolution project)** with Parts 0–B results; add **Datapoint 4 (scheduled path)** when/if Part C fires.
3. Report back in-chat as a compact table: item | expected | observed | verdict. Flag every divergence between session metadata claims and device reality (a known failure mode from 2026-07-09).
4. Deliverables rule reminder (DEC-0068): anything David should view goes into the chat as a card AND to disk; memory housekeeping stays disk-only with a stated path.
