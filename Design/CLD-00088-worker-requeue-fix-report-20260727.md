---
id: CLD-00088-worker-requeue-fix
related: [CLD-00088, CLD-00072, CLD-00082, CLD-00073, DEC-0083, DEC-0084]
execution: supervised
created: 2026-07-27
deliver_to: ~/Documents/Projects/cowork-evolution/Design/
---
# CLD-00088 — worker requeue-loop fix pass (four deltas)

**Mode:** David-supervised Code session (hand-bootstrapped; DEC-0081 supervised-work exception).
**Prompt:** `~/Documents/Projects/cowork-evolution/Prompts/CLD-00088-worker-requeue-fix-20260727.md`
**Authorizing record:** CLD-00088 (incident + rulings, 2026-07-27), consultation chat `remote_5720882c`.
**Guardrails:** `_meta/supervised-build-guardrails.md` (DEC-0084), §5 close-out applies in full.

---

## What was done

The four deltas the mandate enumerates, and nothing else. The defect chain was a **cascade**, so
each delta closes one link and none of them alone would have prevented the flood.

### A — the done-check never crashes, and never mis-fails an out-of-band completion

`queuelib check-deliverable` no longer reads the processing file inside an unguarded `open()`.
A missing task file is now a **first-class verdict** (new exit code **3**, "task file absent"),
not an exception that surfaced in the ledger as `internal error: [Errno 2]` and was then read as
"produced no deliverable". `queuelib get` and `queuelib set` were hardened the same way — an
absent file is a legitimate state for both, not a crash.

`worker.sh` settles the missing file **once**, immediately after the run and before any accounting
can misread it (every step below that point reads `code/processing/<id>.md`):

- **outbox copy present AND the declared deliverable present** → ledger `done-out-of-band` **FLAG**,
  one line, naming the cause ("session performed its own close-out"). No requeue. The attempt is
  not burned. Handoff bookkeeping is cleared as for any delivery.
  Per **David's in-session ruling** the worker also repairs the outbox copy's frontmatter
  `status:` to `done` — the session's own close-out leaves it at `processing`, and
  `queuelib._dep_done` reads exactly that field, so a stale value silently starves every dependent
  task (guardrails §5.4, the 016→017 miss). The repair, or its failure, is named in the same line.
- **otherwise** → ledger `orphaned-claim` **FLAG**, and whatever survives is parked in
  `hold/<id>-orphaned-outbox-<date>.md` for human review. Never requeued.

### B — a requeue can never emit garbage

New `queuelib requeue <src> <inbox> <hold>`. It composes the full file, re-parses it with
`screen.parse_frontmatter` — the same parser every reader uses — writes it to a `.tmp` inside the
destination directory (deliberately *not* `.md`, so a half-written requeue is invisible to
`next-eligible`), re-reads and re-parses **that** file, and only then `os.rename`s it into place
and releases the claim. Anything that fails to round-trip (frontmatter unparseable, no `id`,
source content missing — the incident's own file-splitting case) is parked in `hold/` with a
single FLAG instead.

`mv "$claimed" "$INBOX/$fname"` no longer appears anywhere in `worker.sh`. All three write-backs
into the inbox — screen-reject refile, continuation requeue, failed-attempt requeue — go through
one `requeue_or_hold` helper. The invariant is now total: **nothing enters `code/inbox/` that has
not round-tripped through the readers' own parser.**

### C — loop guard, dead-letter, and honest forensics

- `cmd_next_eligible`'s claimable-so-the-screen-rejects-loudly design is **unchanged** (a silently
  ignored file really is worse). What changed is that rejection is now **terminal for the class
  that cannot be made inert**: a reject on a *parseable* file still gets `status: failed` and goes
  back to the inbox inert, but a reject on an *unparseable* one (identified by the new
  `queuelib parseable`, the same parser again) moves to **`code/dead-letter/`** with **one** ledger
  FLAG and never returns to the inbox. That is the exact loop that produced 20,376 lines.
- **Per-wake claim guard** (belt and braces, for whatever future variant of this class appears):
  the 4th **non-executing** claim of one id in a single wake dead-letters it regardless of cause
  (`WORKER_MAX_CLAIMS_PER_WAKE`, default 3). Per **David's in-session ruling** the tally counts only
  claims that ended *without running a session*; a claim that proceeds to execution gives its tally
  back. Counting executing claims would dead-letter a task legitimately spending its continuation
  budget — with stock knobs (`max_attempts: 2`, `max_continuations: 3`) a healthy long task is
  claimed up to 5 times in one drain. Regression-tested at the default cap.
- **Forensics** (`run_claude.sh`, the `claude_project_dir()` one-reachable-branch class from
  CLD-00072, again): `[forensics] NO session JSONL … died before session start` may now only print
  when the directory actually searched is both **present** and **the one this cwd's session would
  have used**. Otherwise it says `forensics inconclusive (project dir mismatch)` and explains which
  directory was checked. The incident's handoff log asserted a cause of death for a run that had
  demonstrably worked for 36 minutes and delivered.

### D — close-out instructions become execution-mode-aware

- **`_meta/prompt-template.md`** gains a visible `## Close-out` section carrying **both** blocks,
  explicitly labelled, with "keep the one that matches this task's `execution:`". Headless: *write
  the report/artifacts; the WORKER owns Result, status and the outbox move — do not move this task
  file, do not edit its frontmatter, do not write your own `## Result`.* Supervised: guardrails §5
  as today. An author note explains why, naming this incident.
- **`_meta/intake-consultation-template.md`**: the same split as authoring guidance immediately
  above the fenced ```task block (exact-copy means whatever is written there is what the executing
  session obeys), plus the headless close-out paragraph inside the template task body itself, plus
  the incident rationale in the author notes.
- **`orchestrator/orchestrator.sh`** — the *only* change permitted and the only one made: the V/D
  prompt's VARIATION item gains a CHECK clause. An `execution: headless` task (or one with the
  field absent — headless is the default) whose body instructs self-close-out is a **significant
  variation**, to be named explicitly in the one-sentence why. Verified by diff: nothing else in
  that file moved.

---

## Artifacts

Build directory: `~/Documents/Agent_Workflow/code/artifacts/CLD-00088-worker-requeue-fix/`

| Path | What |
|---|---|
| `backups/` | Pristine pre-edit copies of all six modified files (guardrails §3, durable location) |
| `staging/` | The full edited tree the suites were run against before install |
| `incident-corpus/` | Durable copy of the two mangled fragments + a README on the one truncation (see F6) |
| `build-diff.txt` | Unified diff of every change, all six files |
| `repro-prefix.sh` | Bounded reproduction harness (pre-fix vs post-fix, same fixture) |
| `prefix-reproduction.txt` | Pre-fix run output — the flood, reproduced |
| `postfix-reproduction.txt` | Post-fix run output — same fixture, clean |
| `worker-timeout-suite.txt`, `orchestrator-suite.txt` | Full existing-suite output |

Files changed in place (control-plane edit discipline: copy → edit → verify → atomic `mv`):

| File | Lines |
|---|---|
| `_meta/queuelib.py` | +148 / −4 |
| `code/worker.sh` | +130 / −8 |
| `_lib/run_claude.sh` | +16 / −1 |
| `_meta/prompt-template.md` | +29 / −0 |
| `_meta/intake-consultation-template.md` | +24 / −1 |
| `orchestrator/orchestrator.sh` | +8 / −1 |
| `_meta/test_worker_requeue.sh` | new, 57 assertions |

New runtime directory: **`code/dead-letter/`** (created by the worker at each wake; not gitignored,
so the nightly Stage-5 sweep will track its contents as audit trail).

---

## Verification

All of it ran before this report was written, and the suites were run twice: once against
`staging/`, then again against the installed live tree.

### Static

| Check | Result |
|---|---|
| `bash -n` — `code/worker.sh`, `orchestrator/orchestrator.sh`, `_lib/run_claude.sh`, `_meta/test_worker_requeue.sh` | OK (also `code/reviewer.sh`, untouched) |
| `python3 -m py_compile` — `_meta/queuelib.py`, `_meta/screen.py` | OK |
| Secret scan over the full diff | 0 hits |
| `screen.py --phi` over the full diff | clean (exit 0) |
| Installed files byte-identical to the verified staging copies | confirmed for all 7 |
| `git log` — no commits | HEAD unchanged at `3a6fdc3`; everything left uncommitted for the nightly Stage-5 sweep |

### New suite — `_meta/test_worker_requeue.sh`: **ALL PASS (57)**

Every case the mandate's bar names, each mapped to its assertion group:

| Bar item | Section | Result |
|---|---|---|
| processing file missing + outbox copy + deliverable present → `done-out-of-band`, no requeue, attempt not burned | R1 (10) | PASS — plus asserts no `internal error`, no `no-deliverable`, and the ruled status repair |
| processing file missing + no outbox copy → parked to `hold/`, one FLAG | R2 (6), R2b (5) | PASS — R2 parks the unconfirmable outbox copy; R2b covers nothing-left-to-park |
| requeue round-trip refuses a frontmatterless file, driven by the real `hold/` fragments | R3 (16) | PASS — both real fragments refused and parked, missing-source refused, plus a positive control proving a well-formed file still round-trips with its annotation intact |
| unparseable inbox file → dead-letter after ONE reject; ledger gains exactly one FLAG (count asserted) | R4 (6) | PASS — `screen-reject` count **== 1**, `no YAML frontmatter` count **== 1**, no run log |
| same-id 4th claim in one wake → dead-letter | R5 (8) | PASS — see the caveat below |
| forensics message suppressed on project-dir mismatch | R6 (6) | PASS — absent dir and wrong dir both inconclusive; the genuine verdict still prints for the right dir |

**Caveat, stated plainly (R5).** After delta C every non-executing claim path is terminal or
inert, so a *natural* 4-claims-in-one-wake loop is unreachable by construction — that is the
point of the fix, but it means the tally cannot be driven to 4 organically. R5a therefore
exercises the guard's disposal path through the cap knob (`WORKER_MAX_CLAIMS_PER_WAKE=0` → first
claim trips it → dead-letter, one FLAG, never executed), and **R5b tests the property the ruling
turns on**: four *executing* claims of one id in a single wake (three progress continuations,
then delivery) at the stock cap of 3 must not trip it — asserted `claim OK` × 4, `continuation
OK` × 3, no `claim-cap` line, final `status: done`.

### Existing suites — unchanged

| Suite | Result |
|---|---|
| `_meta/test_worker_timeout.sh` (CLD-00072) | **ALL PASS (31)** — the existing 31, unchanged |
| `_meta/test_orchestrator.sh` | **ALL PASS (173)** |
| `_meta/test_screen.py` | **ALL PASS** |

### End-to-end reproduction — the strongest evidence

Same fixture (a headless session that delivers, then moves its own task file to `outbox/`),
same harness, one pre-fix tree and one post-fix tree (`repro-prefix.sh`, 45-second window):

| | **Pre-fix** | **Post-fix** |
|---|---|---|
| worker terminates | **no** — still running at 45s, killed | yes, **1s** |
| ledger lines | 371 | **3** |
| `screen-reject` FLAGs | **367** | **0** |
| `no YAML frontmatter` lines | 367 | 0 |
| `internal error` in ledger | 1 | **0** |
| inbox file has frontmatter | **NO** | n/a — nothing requeued |
| outbox `920-selfclose` status left at | `processing` | **`done`** |

The pre-fix ledger's first line is the incident's own, verbatim in shape:
`no-deliverable FLAG — … (queuelib check-deliverable: internal error: [Errno 2] No such file or
directory: …/code/processing/920-selfclose.md); treating as failed`.
Post-fix the same run produces `wake OK` → `claim OK` → `done-out-of-band FLAG — … outbox copy +
deliverable present …; recorded done-out-of-band, not requeued, attempt not burned; outbox status
repaired processing→done`.

Running the **new suite against the pristine pre-fix tree** does not merely fail — it never
terminates (killed at 600s), because the pre-fix worker enters the infinite loop on R1's very
first fixture. These are real regression tests, not tests written to pass.

### Dry standing-start check

Empty `code/inbox/` and `code/processing/`, one manual worker wake on the live tree:

- ledger 1620 → 1622 lines: `wake OK` + `no-op OK`, nothing else
- **FLAG count 61 → 61 — zero new FLAGs**
- lock released cleanly; no residue in `inbox/`, `processing/`, `dead-letter/`; `hold/` unchanged

---

## Findings, in-session rulings, and ratification items

### In-session rulings (David, live — ratification items)

**RULING 1 — `done-out-of-band` repairs the outbox copy's `status:`.** The mandate said FLAG and
don't requeue; it did not settle whether to touch the file the session left behind. Leaving it at
`status: processing` reproduces the guardrails §5.4 starvation hole (`_dep_done` reads the OUTBOX
frontmatter, so `no eligible prompts` reads as an empty queue and nothing FLAGs — the 016→017
miss, and exactly what needed a hand correction for 017 this morning). David ruled: repair to
`done` when the outbox copy AND the declared deliverable are both present, and name the repair in
the same FLAG line. Implemented and tested (R1).

**RULING 2 — the per-wake claim cap counts non-executing claims only.** A literal all-claims cap
of 3 would dead-letter healthy work: with stock knobs (`max_attempts: 2`, `max_continuations: 3`)
a task that legitimately uses its continuation budget is claimed 4–5 times in one drain. David
ruled the tally counts only claims that ended without running a session — still "regardless of
cause" within that class. Implemented (the tally is given back at the accept point) and
regression-tested at the stock cap (R5b).

### Findings — flagged, not fixed (guardrails §2)

**F1 — `code/dead-letter/` was not an existing mechanism.** The mandate called it one; the
existing dead-letter mechanism is a `status: dead-letter` *value* on a file that stays in
`outbox/`. That cannot serve here — an unparseable file has no frontmatter to write a status
into, which is the entire problem. Implemented as a new directory at the path the mandate names,
with a `.keep` matching the `inbox/`/`processing/` convention, not gitignored so its contents
become audit trail. **Ratification item:** the name and location are now load-bearing in
`worker.sh`.

**F2 — `code/reviewer.sh` carries the identical un-round-tripped requeue.** Its stale-claim
reclaim does `printf … >> "$cf"` then `mv "$cf" "$INBOX/$fname"` (line 125) — the same shape as
the defect delta B just closed, in a script on this build's DO-NOT-TOUCH list. Not fixed. The
window is narrower (the loop tests `-e "$cf"` immediately before), and **the flood cannot recur
through it** — delta C dead-letters an unparseable inbox file after ONE reject — but the reviewer
can still author a fragment. **Recommend a follow-up pass** routing it through `queuelib requeue`;
the helper is already there and takes three arguments.

**F3 — `worker.sh`'s no-JSONL log line still asserts a cause of death.** Line 654:
`"$id: no session JSONL for attempt $attempt (died before session start)"` — the same
unwarranted-certainty class delta C fixed in `run_claude.sh`, but a different message in a
different file, and it goes to the run log rather than the ledger. Left alone because the mandate
named the handoff-writer forensic specifically. One-line follow-up.

**F4 — `README.md` does not know about any of this.** Its queue-lifecycle section (§ around
line 91–108) and the retention section do not mention `code/dead-letter/`, root-level `hold/`
parking, `done-out-of-band`, or `orphaned-claim`. Not updated — "four deltas, nothing else."
**Recommend a doc pass** before the README drifts further from the machinery.

**F5 — pre-existing test residue in `~/.claude/projects/`.** Seven leaked stub-session directories
matching `-var-folders-…-root-code`, dated 2026-07-16/17 — from the CLD-00072 test era, before the
CLD-00075 fixture redirect. Verified *not* produced by today's runs (this session's suites leaked
nothing). Not touched: they sit in Claude Code's own store, outside this repo and outside the
mandate.

**F6 — TIME-SENSITIVE: `hold/` is untracked, not gitignored, and tonight's Stage-5 sweep will
commit it — including the 3.5 MB fragment A.** CLD-00088 open disposition 3 rules the fragments
"keep for the fix pass, then trash"; the fix pass is now complete. Because the mandate made those
fragments the test corpus, I did **not** trash them (that is David's call and they are forensic
evidence), but I removed the suite's dependency on them: a durable copy now lives at
`code/artifacts/CLD-00088-worker-requeue-fix/incident-corpus/` — fragment B verbatim, fragment A
truncated to its first 8 KB with the truncation and the original size documented in a README
(the original is ~20,000 repetitions of one 5-line block; every property under test lives in the
first 300 bytes). `test_worker_requeue.sh` prefers `hold/` and falls back to the archive;
**both paths verified ALL PASS (57)**. So `hold/` can be trashed whenever David rules, with no
effect on the suite.

> **Update, 2026-07-27 ~12:10 — `hold/` is now empty.** All three preserved files
> (`017-inbox-mangled-requeue-20260727.md`, `…-b-…`, `zz-brake-20260727.md`) were removed at
> ~11:58, directly after this finding was raised in-session; the directory itself remains.
> Nothing in the machinery sweeps the root `hold/` (the reviewer's retention exemption is
> `code/logs/hold/`, and no reviewer pass ran today), and no command in this build wrote there —
> consistent with a deliberate disposal under disposition 3, but recorded here as an observation,
> not an attribution. **Verified after the fact: the suite still passes ALL PASS (57) off the
> archived corpus**, which is precisely the dependency this finding removed.
>
> **Consequence to note:** the archive keeps fragment B verbatim but only the first 8 KB of
> fragment A, so the full 3,525,573-byte original no longer exists on disk — it was never
> committed (the flood never reached git and `hold/` was untracked), and `zz-brake-20260727.md`
> is likewise gone. Nothing under test is affected; if the full fragment A was wanted as a
> permanent forensic record, it would have to come from a backup snapshot.

### Not done, and why

Nothing in the mandate's scope was left out. The `DO NOT touch` list was honoured in full:
`reviewer.sh`, `screen.py`'s deny/red-line lists, `oilib.py`, the plists, the task-017 telegram
code paths, and everything under `~/Claude/` (read-only) are all unmodified. `orchestrator.sh`
received exactly the one permitted change, confirmed by diff.

**On guardrails §5.3–§5.4 (the `## Result` append and the status flip).** This build was
hand-bootstrapped from a prompt file, not instantiated as a queue task — there is no task file in
`code/supervised/` and none in `code/outbox/`. §5.3 and §5.4 therefore have no target here, and
skipping them is correct rather than an omission: this report plus the in-session statement is the
close-out, and the consultation chat folds outcomes onto CLD-00088. §5.5 is honoured by
construction — no OI exists for this build, so nothing was closed, archived, or delivered.
