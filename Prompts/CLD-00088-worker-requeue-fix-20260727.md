# Supervised build — worker requeue-loop fix pass (CLD-00088, four deltas)

**Mode:** David-supervised Code session (hand-bootstrapped; DEC-0081 supervised-work exception).
The machinery cannot safely carry its own worker fix headless — the components under repair are
the ones that would execute the task. Authorizing record: CLD-00088 (incident + rulings,
2026-07-27) ratified in consultation chat `remote_5720882c`; prompt authored same chat.

READ FIRST (in order):
1. `~/Documents/Agent_Workflow/_meta/supervised-build-guardrails.md` — its discipline governs,
   §5 close-out INCLUDED (this is a supervised session; §5 is correct here — and §5.4's
   status-flip line was added this morning).
2. `~/Claude/memory/action-items/CLD-00088-260727-Open.md` — the full defect chain, timeline
   correction, and rulings. This is the mandate; the four deltas below implement its
   "Fix directions."
3. The evidence: `~/Documents/Agent_Workflow/ledger.md` lines around `2026-07-27 09:51` (the
   `no-deliverable` ENOENT crash, the `failed exit 65`, and the collapsed-flood summary line);
   `code/logs/run-017-build-the-two-way-telegram-decision-chan-a1-2026-07-27.log` (tail: the
   done-check internal error); `code/logs/handoff-017-…-2026-07-27.log` (the false "died before
   session start" forensic); the mangled fragments preserved in `hold/`
   (`017-inbox-mangled-requeue-20260727.md`, `017-inbox-mangled-requeue-b-20260727.md`).
4. `code/worker.sh`, `_meta/queuelib.py` (esp. `cmd_next_eligible`, the claim/requeue/
   done-check paths), `_lib/run_claude.sh` (handoff-writer forensics), `_meta/prompt-template.md`
   + `_meta/intake-consultation-template.md` (delta D), and the V/D prompt block in
   `orchestrator/orchestrator.sh` (delta D's one-line check — the ONLY orchestrator.sh change
   permitted).
5. `~/Claude/memory/action-items/CLD-00072-260716-Open.md` §independent-review lineage — the
   prior worker failure-path work your changes extend, and the `claude_project_dir()` forensics
   precedent delta C repeats.

## Scope — four deltas, nothing else

**A. Done-check: never crash, never mis-fail an out-of-band completion.**
In the worker's post-run accounting, a MISSING `code/processing/<id>.md` is a first-class case,
not an exception path: `queuelib check-deliverable` (and any other step reading the processing
file) must not raise on ENOENT. New verdict logic when the processing file is absent:
if the task file already sits in `code/outbox/` AND the declared deliverable exists →
record `done-out-of-band` (ledger FLAG, one line, naming the cause: "session performed its own
close-out") and do NOT requeue, do NOT burn the attempt as failed; otherwise → FLAG + move
whatever remains to a parked state (`hold/` at the Agent_Workflow root) for human review —
never requeue what cannot be parsed as the original task.

**B. Requeue hardening: a requeue can never emit garbage.**
The requeue path writes the task file back to `code/inbox/` — after this delta it must
round-trip: compose the full file (original frontmatter + body + appended failure annotation),
parse it back with the same `screen.parse_frontmatter` the readers use, and only then
atomic-write (tmp + mv) into inbox. If the round-trip fails (frontmatter unparseable, source
content missing — the incident's file-splitting case), the file goes to `hold/` with a single
FLAG instead of inbox. The two `hold/` fragments from the incident are your test corpus.

**C. Loop guard + dead-letter for unparseable inbox files.**
`cmd_next_eligible`'s claimable-so-the-screen-rejects-loudly design stays (a silently ignored
file IS worse) — but rejection must be terminal: when the screen rejects a claimed file for
unparseable frontmatter, the worker moves it to `code/dead-letter/` (existing mechanism) with
ONE ledger FLAG, never back to inbox. Belt-and-braces: a per-wake guard — the same task id
claimed more than 3 times in one wake → dead-letter + FLAG regardless of cause, so no future
variant of this class can hot-loop. Also fix the handoff-writer forensic that printed
"NO session JSONL — died before session start" for a 36-minute session that delivered: the
one-reachable-branch class again (CLD-00072's `claude_project_dir()` precedent) — the message
may only print when the project-dir actually checked is the one the session would have used,
else say "forensics inconclusive (project dir mismatch)".

**D. Convention: close-out instructions become execution-mode-aware.**
1. `_meta/prompt-template.md` + `_meta/intake-consultation-template.md`: the close-out language
   splits by mode — HEADLESS tasks: "write the report/artifacts; the WORKER owns Result,
   status, and the outbox move — do not move or edit your own task file"; SUPERVISED tasks:
   guardrails §5 as today. Author notes explain why (this incident).
2. The V/D prompt in `orchestrator/orchestrator.sh` gains ONE check line: an
   `execution: headless` task whose body instructs self-close-out (moving its own task file /
   writing its own Result) is a **variation finding**. No other orchestrator.sh change.

DO NOT touch: `reviewer.sh`, `screen.py` deny/red-line lists, `oilib.py`, any plist, the
telegram/interview code paths installed by task 017, anything under `~/Claude/` except reading.
Control-plane edit discipline per guardrails §3 (copy → edit → verify → atomic mv; pristine
backups to the build dir).

Judgment calls: flag-don't-fix adjacents; ambiguities get an in-session David ruling recorded
for ratification.

## Verification bar (all required before the report)

- `bash -n` every touched script; `python3 -m py_compile` every touched `.py`.
- Extend `_meta/test_worker_timeout.sh` (or a new `test_worker_requeue.sh` section) with
  fixtures reproducing the incident end-to-end: processing file missing + outbox copy +
  deliverable present → `done-out-of-band`, no requeue, attempt not burned; processing file
  missing + no outbox copy → parked to hold/, one FLAG; requeue round-trip refuses to write a
  frontmatterless file (drive it with the real `hold/` fragments); unparseable inbox file →
  dead-letter after ONE reject, ledger gains exactly one FLAG line (assert the count);
  same-id-4th-claim-in-one-wake → dead-letter; forensics message suppressed on project-dir
  mismatch. Full suite ALL PASS; existing 31 (+ later additions) unchanged.
- A dry standing-start check: with empty inbox/processing, one manual worker wake produces a
  clean `no-op` and zero new FLAGs.
- No commits (the nightly Stage-5 sweep owns them).

## Close-out (guardrails §5 — supervised, so §5 applies in full, including the §5.4 status flip)

Report to `~/Documents/Projects/cowork-evolution/Design/CLD-00088-worker-requeue-fix-report-20260727.md`
(What was done / Artifacts / Findings incl. in-session rulings for ratification / Verification).
No OI exists for this build; no memory-file edits — the consultation chat folds outcomes onto
CLD-00088. State in-session where everything landed and list ratification items.
