#!/usr/bin/env python3
"""
lint-transcripts.py — transcript & memory integrity lint (Stage 2, CLD-00062).

Mechanical checks, no LLM. Catches the CLD-00049 zero-append failure class and
related drift. Emits a machine-readable summary (+ optional ledger line) and,
when violations are found, appends a single `[COMPACTION-ISSUE] ...` line to
today's daily log so EOD/startup can't miss it.

Checks:
  1. Sentinel continuity  — every transcript's foot sentinel AFTER_TURN_N must
     match its highest OWN `## Turn N` header (turn headers inside quoted/embedded
     transcript content are excluded — CLD-00086; both sides of the comparison are
     now scoped to the document itself). Header-present-but-N=0 or no-sentinel is
     the CLD-00049 zero-append class.
  2. Header well-formedness — required header fields present.
  3. <pending> census      — count unresolved Tier-2 assistant bodies.
  4. Daily-log ↔ transcript cross-check — transcripts modified on <date> whose
     UUID is not referenced anywhere in today's daily log (one direction; the
     reverse is reported as an FYI count since chat sections are named, not UUID'd).
  5. Action-items index drift — files on disk vs links in _index.md (ported from
     the retired graph-agent eod-refresh-and-commit.sh step 6).
  6. Remote seed-staleness (FLAG) — a `remote_` transcript still at AFTER_TURN_0
     with no [SOFT-CLOSE]/[SWEEP] marker whose session day has passed: the 10:45 PT
     contingency fire never delivered (CLD-00086 design note / CLD-00067).
  7. Contingency-ledger cross-check (FLAG) — a `remote_` transcript for the target
     day with neither a ledger data line nor a close marker: the fire never ran or
     the bridge was down. Both FLAGs report and write to the daily log; they do not
     set the exit code (see the 2026-07-26 build report — pending David's ruling).

Usage:
    lint-transcripts.py [--date YYYY-MM-DD] [--json] [--write-daily-issue]
Exit 0 if clean; 2 if any violation (non-fatal to the chain; wrapper reads it).
"""

import argparse
import glob
import json
import os
import re
import subprocess
import sys
from urllib.parse import unquote

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _transcript_common as tc

HOME = os.path.expanduser("~")
TRANSCRIPTS = os.path.join(HOME, "Claude/transcripts")
DAILY_DIR = os.path.join(HOME, "Claude/memory/daily")
ACTION_ITEMS = os.path.join(HOME, "Claude/memory/action-items")

TURN_RE = re.compile(r"^## Turn (\d+) ", re.MULTILINE)
REQUIRED_HEADER = ["**Chat ID:**", "**Capture mode:**", "**Append protocol:**"]
UUID_RE = re.compile(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
# 8-hex short-id token. Daily-log `## Chat:` headers reference code sessions by
# short id, so the cross-check must accept the prefix form, not only the full UUID
# (CLD-00075: fixes the 39e396f4 false positive where a real, logged chat was flagged
# unreferenced). Left edge is a lookbehind excluding only hex chars and hyphen — NOT
# a `\b` word boundary: underscore is a regex word char, so `\b` never fired after our
# own sanctioned surface prefixes like `remote_`/`local_`/`dispatch_`, silently failing
# on `remote_62d4de81` (CLD-00081). Hyphen is excluded so the pattern still cannot fire
# mid-UUID (a full UUID's own 8-hex prefix is caught by its own left neighbor, not here).
SHORTID_RE = re.compile(r"(?<![0-9a-fA-F-])[0-9a-fA-F]{8}\b")

# CLD-00075 informational leak detector: a single-turn transcript with almost no
# turn content is very likely a fixture/probe that leaked into code/ (the unscoped
# glob's failure mode). INFORMATIONAL only — a legitimately tiny real chat must
# never block the chain; it feeds the nightly leak-to-inbox hook (cowork-nightly.sh).
TRIVIAL_TURN_CONTENT_MAX = 200  # bytes of turn body below which a 1-turn file is "trivial"

PROJECTS_DIR = os.path.join(HOME, ".claude/projects")

# ---------------------------------------------------------------------------
# Remote-surface delivery checks (CLD-00086 design note, 2026-07-26)
# ---------------------------------------------------------------------------
# The 10:45 PM PT contingency fire (DEC-0074) appends one line per fire here
# (instrumentation installed 2026-07-26, CLD-00067). Absence of a line for a
# remote chat whose day has passed is the "fire never ran / bridge down" signal.
CONTINGENCY_LEDGER = os.path.join(HOME, "Claude/Scheduled/nightly/remote-contingency-ledger.md")
# A soft-close / sweep marker the firing session stamps at the FOOT of the file.
CLOSE_MARKER_RE = re.compile(r"\[(?:SOFT-CLOSE|SWEEP)\b", re.IGNORECASE)
# One ledger DATA line: `<YYYY-MM-DD HH:MM PT> | <chat id> | jsonl=… | …`.
LEDGER_LINE_RE = re.compile(r"^\s*(\d{4}-\d{2}-\d{2})[^|\n]*\|([^|\n]*)\|", re.MULTILINE)
# Foot region for marker/sentinel tests. Scope discipline (the whole point of
# CLD-00086): these tests read the document's OWN foot — never a whole-text grep —
# or they inherit the quoted-content false positives they sit next to.
FOOT_REGION_CHARS = 4000


def build_src_map(projects_dir=PROJECTS_DIR):
    """{uuid: encoded-project-dir-basename} from the exporter-visible depth-3 JSONLs.
    Lets the lint resolve a transcript's source cwd (for the deny-list exemption and
    for reporting the leak's origin) while the JSONL is still within retention."""
    m = {}
    for p in glob.glob(os.path.join(projects_dir, "*", "*.jsonl")):
        m.setdefault(os.path.splitext(os.path.basename(p))[0],
                     os.path.basename(os.path.dirname(p)))
    return m


def turn_content_len(text):
    """Bytes of turn content (first `## Turn ` through the foot sentinel), i.e. the
    transcript minus its fixed header — the signal for 'trivial'."""
    i = text.find("\n## Turn ")
    if i == -1:
        return 0
    body = text[i:]
    mm = tc.SENTINEL_RE.search(body)
    if mm:
        body = body[:mm.start()]
    return len(body.strip())


# ---------------------------------------------------------------------------
# Own-turn scoping (CLD-00086)
# ---------------------------------------------------------------------------
# `parse_sentinel()` is scoped to the document's OWN marker; `TURN_RE` was not —
# it matched every line-start `## Turn N` header ANYWHERE in the file, including
# headers inside quoted content, where a session read some other transcript and the
# deterministic exporter (DEC-0076) reconstructed that tool output verbatim. One
# side of the comparison meant "this document's own turns" and the other meant
# "every turn header any document mentioned anywhere in this file", so a transcript
# that legitimately QUOTES another transcript was reported as structurally broken
# (6d5a2d18: own sentinel and own header both 1; max_turn=5 came entirely from a
# quoted 54363bdc). The asymmetry was the bug; the fix belongs in the check, never
# in the thing being quoted. See The_Wiki/concepts/mention-is-not-use.md.
#
# The exporter controls the shape of the files it generates, so for those we can
# scope structurally — two independent signals, applied conservatively:
#
#   1. Embedded-transcript spans. A quoted transcript announces itself with a
#      document header (`# Transcript:` / `**Chat ID:**`) below the file's own
#      header block, and ends at a FOREIGN foot sentinel. Headers inside a CLOSED
#      span are embedded. An UNCLOSED span is ignored (fail-open) — an open-ended
#      exclusion could swallow the document's own later turns and invert the
#      finding, which is the one failure this fix must not introduce.
#   2. Own-sequence contiguity. The exporter numbers a document's own turns
#      1..N with no gaps, so a header only counts as own if it continues that
#      run. Quoted turns restart at 1 or jump (11..15) and are dropped.
#
# Fail-open everywhere: if the scoping yields nothing while headers exist (a
# legacy or hand-adopted file that starts at Turn 2), the unscoped count is used,
# exactly as before. Hand-authored transcripts are NOT scoped at all — their turn
# numbering is legitimately sparse (backfilled closing turns, partial captures),
# and they do not carry reconstructed tool output.
SCOPED_OWNERSHIP = ("tool-owned", "live-deterministic")
FOREIGN_DOC_PREFIXES = ("**Chat ID:**", "# Transcript:")
OWN_HEADER_BLOCK_LINES = 12   # the file's own header sits above this


def _own_sentinel_id(text, path):
    """The document's own id, for telling its foot sentinel from a quoted one."""
    m = re.search(r"^\*\*Chat ID:\*\*\s*(\S+)", text[:1500], re.MULTILINE)
    v = m.group(1).strip() if m else os.path.splitext(os.path.basename(path))[0]
    for pfx in ("local_", "remote_", "dispatch_"):
        if v.startswith(pfx):
            v = v[len(pfx):]
    return v.lower()


def turn_headers(text):
    """[(turn_number, line_number)] for every line-start `## Turn N` in the file."""
    return [(int(m.group(1)), text.count("\n", 0, m.start()) + 1)
            for m in TURN_RE.finditer(text)]


def embedded_spans(text, path):
    """[(start_line, end_line)] of CLOSED quoted-transcript regions (see above)."""
    own_id = _own_sentinel_id(text, path)
    spans, opened = [], None
    for lineno, line in enumerate(text.split("\n"), 1):
        if (lineno > OWN_HEADER_BLOCK_LINES and opened is None
                and line.startswith(FOREIGN_DOC_PREFIXES)):
            opened = lineno
            continue
        m = tc.SENTINEL_RE.search(line)
        if m and opened is not None:
            sid = m.group(1).lower()
            if not (own_id.startswith(sid) or sid.startswith(own_id)):
                spans.append((opened, lineno))   # a foreign foot closes the quote
                opened = None
    return spans


def in_spans(lineno, spans):
    return any(a <= lineno <= b for a, b in spans)


def own_turn_headers(text, path):
    """(own_headers, embedded_headers, spans) — the document's OWN turn headers."""
    hdrs = turn_headers(text)
    spans = embedded_spans(text, path)
    if not hdrs or tc.classify_ownership(text, path) not in SCOPED_OWNERSHIP:
        return hdrs, [], spans
    expected, own = 1, []
    for n, lineno in hdrs:
        if in_spans(lineno, spans):
            continue
        if n == expected:
            own.append((n, lineno))
            expected += 1
    if not own:
        return hdrs, [], spans        # fail open — behave exactly as before
    embedded = [h for h in hdrs if h not in own]
    return own, embedded, spans


def pacific_date():
    return subprocess.check_output(
        ["date", "+%Y-%m-%d"], env={**os.environ, "TZ": "America/Los_Angeles"}
    ).decode().strip()


import datetime
try:
    from zoneinfo import ZoneInfo
    _PACIFIC = ZoneInfo("America/Los_Angeles")
except Exception:  # pragma: no cover
    _PACIFIC = None

# Capture the full header stamp incl. optional UTC time+Z, so we can convert
# UTC→Pacific before comparing to a Pacific `TODAY` (bare-string compare across
# two calendars silently drops evening chats — CLD-00062 Phase 2 dry-run finding).
STARTED_RE = re.compile(
    r"\*\*Live capture started:\*\*\s*(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2})(Z)?)?")


def session_date(text, path):
    """
    The Pacific date the SESSION happened, from the header's 'Live capture
    started' stamp — NOT the file mtime (a backfill has today's mtime but an old
    session date). UTC stamps (…THH:MMZ) are converted to Pacific first.
    """
    m = STARTED_RE.search(text[:1500])
    if not m:
        return _pacific_mtime(path)  # fallback for pre-convention headers
    y, mo, d, hh, mi, z = m.groups()
    if hh is None:  # date-only header — take as-is
        return "%s-%s-%s" % (y, mo, d)
    dt = datetime.datetime(int(y), int(mo), int(d), int(hh), int(mi),
                           tzinfo=datetime.timezone.utc)
    if z and _PACIFIC is not None:  # explicit UTC → convert to Pacific
        dt = dt.astimezone(_PACIFIC)
    return dt.strftime("%Y-%m-%d")


def lint_transcript(path, text, is_today):
    """
    Return (blocking, legacy, pending_count, ownership) for one transcript.

    A transcript whose SESSION happened today is held to the full standard.
    Older sessions: only the CLD-00049 zero-append class blocks; a missing
    closing sentinel / pre-convention header is expected legacy noise.

    Ownership mode (CLD-00063 Phase 3) tempers the checks for remote
    'live-deterministic' files: their Mac copy is only updated at flush points
    (bootstrap / close-out / the pre-nightly soft-close), so a header-only
    AFTER_TURN_0 state is the EXPECTED pre-flush condition — turns live in the
    container — NOT the CLD-00049 zero-append failure class. The nightly is
    verifier-only for these (DEC-0070 item 5); it never sources or regenerates them.
    """
    blocking, legacy = [], []
    name = os.path.basename(path)
    bucket_missing = blocking if is_today else legacy
    ownership = tc.classify_ownership(text, path)
    live_det = ownership == "live-deterministic"

    for field in REQUIRED_HEADER:
        if field not in text[:1500]:
            bucket_missing.append("%s: missing header field %s" % (name, field))

    # Count the document's OWN turn headers only — the same scoping parse_sentinel()
    # already applies to the marker it reads (CLD-00086).
    own_hdrs, embedded_hdrs, spans = own_turn_headers(text, path)
    max_turn = max([n for n, _ in own_hdrs]) if own_hdrs else 0
    _, sent_n = tc.parse_sentinel(text)

    if sent_n is None:
        bucket_missing.append("%s: no append-sentinel marker at foot" % name)
    elif sent_n == 0 and max_turn == 0:
        if live_det:
            # Expected pre-flush state for a remote converter-maintained file:
            # the container working copy holds the turns until a flush point.
            # Informational only — NOT the CLD-00049 zero-append failure class.
            legacy.append("%s: header-only (AFTER_TURN_0) — remote live-deterministic, "
                          "awaiting first Mac flush (expected, not zero-append)" % name)
        else:
            # zero-append always blocks — it's the CLD-00049 failure class regardless of age
            blocking.append("%s: ZERO-APPEND (CLD-00049 class) — header present, no turns captured" % name)
    elif sent_n != max_turn:
        # Diagnosis (CLD-00086): say WHERE the number came from. Both investigations
        # behind this item were spent reconstructing which line produced an integer.
        where = ""
        if own_hdrs:
            top = max(own_hdrs, key=lambda h: h[0])
            where = " (line %d%s)" % (
                top[1], ", inside a quoted/embedded region" if in_spans(top[1], spans) else "")
        excluded = ("; %d embedded turn header(s) excluded as quoted content"
                    % len(embedded_hdrs)) if embedded_hdrs else ""
        bucket_missing.append(
            "%s: sentinel AFTER_TURN_%d but highest OWN turn header is %d%s%s"
            % (name, sent_n, max_turn, where, excluded))

    return blocking, legacy, text.count("<pending>"), ownership


def read_contingency_ledger(path=None):
    """Text of the remote-contingency ledger (empty string if absent)."""
    path = path or CONTINGENCY_LEDGER   # resolved at call time (fixture-overridable)
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


def check_remote_delivery(path, text, sdate, date, ledger_text):
    """
    FLAGs for the remote surface (CLD-00086 design note, 2026-07-26). Both read
    STRUCTURAL state — filename prefix, own foot sentinel, own header date, marker
    in the OWN foot region — never a whole-text grep.

      C3 seed-staleness / missed flush: the remote bootstrap seeds the Mac copy at
      chat open (header + AFTER_TURN_0). classify_ownership() exempts that state
      from the CLD-00049 zero-append class — correct DURING the chat's day, overbroad
      after it. A remote file still at AFTER_TURN_0, with no close marker, whose
      session day has passed, means the 10:45 fire never delivered and the container
      is by now likely gone. The marker condition is what keeps a one-incomplete-turn
      chat whose SUCCESSFUL soft-close pushed a header-only file (WITH a marker) from
      false-positiving here.

      C4 ledger cross-check: a remote transcript for the lint's target day with
      neither a contingency-ledger line nor a close marker means the fire never ran
      or the bridge was down — distinct from C3's "fire ran, delivered nothing".
    """
    name = os.path.basename(path)
    if not name.startswith("remote_"):
        return []
    _, sent_n = tc.parse_sentinel(text)
    foot = text[-FOOT_REGION_CHARS:]
    has_marker = bool(CLOSE_MARKER_RE.search(foot))
    flags = []
    if sent_n == 0 and not has_marker and sdate and sdate < date:
        flags.append(
            "%s: FLAG missed flush — contingency fire never delivered (still "
            "AFTER_TURN_0, no [SOFT-CLOSE]/[SWEEP] marker, session day %s has passed; "
            "container likely reclaimed)" % (name, sdate))
    if sdate == date and not has_marker and not _ledger_line_for(ledger_text, name, date):
        flags.append(
            "%s: FLAG fire never ran or bridge down — remote transcript for %s with no "
            "contingency-ledger line and no close marker" % (name, date))
    return flags


def _ledger_line_for(ledger_text, transcript_name, date):
    """
    True if the contingency ledger carries a DATA line for this chat on `date`.

    Scoped to data lines — `<YYYY-MM-DD HH:MM PT> | <chat id> | …` — on purpose:
    the ledger's own prose NAMES chats (its installation note cites the chat that
    directed it), so a whole-text substring match reports a fire that never happened.
    That is precisely the mention-vs-use error this item exists to kill; it fired
    here during the build and is fixed by reading the field, not the file.
    """
    if not ledger_text:
        return False
    chat_id = os.path.splitext(transcript_name)[0]          # remote_<uuid>
    bare = chat_id[len("remote_"):] if chat_id.startswith("remote_") else chat_id
    for m in LEDGER_LINE_RE.finditer(ledger_text):
        if m.group(1) != date:
            continue
        field = m.group(2).strip().strip("`")
        if field in (chat_id, bare) or field.startswith(bare[:8]) or bare[:8] in field:
            return True
    return False


def _pacific_mtime(path):
    try:
        return subprocess.check_output(
            ["date", "-r", str(int(os.path.getmtime(path))), "+%Y-%m-%d"],
            env={**os.environ, "TZ": "America/Los_Angeles"}).decode().strip()
    except Exception:
        return ""


def check_transcripts(date):
    blocking, legacy = [], []
    flags = []            # CLD-00086 remote-delivery FLAGs (C3/C4)
    pending_total = 0
    ownership_counts = {"hand": 0, "tool-owned": 0, "live-deterministic": 0}
    files = glob.glob(os.path.join(TRANSCRIPTS, "*", "*.md"))
    todays_sessions = []  # transcripts whose SESSION happened today (by content date)
    trivial = []          # CLD-00075 informational: possible fixture/probe leaks
    src_map = build_src_map()
    ledger_text = read_contingency_ledger()
    for path in files:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        sdate = session_date(text, path)
        flags.extend(check_remote_delivery(path, text, sdate, date, ledger_text))
        is_today = sdate == date
        if is_today:
            todays_sessions.append(path)
        b, l, pend, ownership = lint_transcript(path, text, is_today)
        blocking.extend(b)
        legacy.extend(l)
        pending_total += pend
        ownership_counts[ownership] = ownership_counts.get(ownership, 0) + 1

        # Trivial-single-turn leak check (informational). Exempt sanctioned chain/
        # queue machinery (CHAIN_INTERNAL_RE — incl. the marked worker preflight)
        # and any transcript whose source cwd is a deny-listed ephemeral root
        # (marker + deny-listed source, per David's CLD-00075 decision — NOT a
        # whole-root exemption, so an anonymous stub from the queue root still trips).
        turn_nums = TURN_RE.findall(text)
        if (len(turn_nums) == 1 and turn_content_len(text) < TRIVIAL_TURN_CONTENT_MAX
                and not is_chain_internal(text)):
            uuid = os.path.splitext(os.path.basename(path))[0]
            src = src_map.get(uuid)
            if not (src and tc.is_denylisted_root(src)):
                trivial.append({"file": os.path.basename(path),
                                "source_dir": src or "(aged-out)"})
    return (blocking, legacy, pending_total, files, todays_sessions,
            ownership_counts, trivial, flags)


# The nightly chain spawns its own `claude -p` sessions (EOD, git-sweep) and we
# spawn preflight/dry-run ones; the Agent Workflow queue (CLD-00069) spawns one
# `claude -p` per task (worker) plus a reviewer pass. The exporter reconstructs
# all of them into code/. They are chain/queue internals, NOT user chats — EOD
# excludes them from discovery, so the daily-log cross-check must too, else it
# flags them forever and raises a nightly false ATTENTION (CLD-00062 Phase 2
# dry-run finding). The Agent Workflow markers are the delegated first lines the
# worker/reviewer/orchestrator prepend to every session.
#
# The Agent Workflow alternative matches on the LANE SUFFIX ("not a user chat") rather
# than enumerating each pass kind (CLD-00081). Every delegated first line is shaped
# `Agent Workflow <pass kind> … — delegated {execution,audit}, not a user chat.` — so
# this one alternative covers worker preflight/queue-task, reviewer, AND the orchestrator
# V/D + escalation passes (and any future pass kind), which the enumerate-each-kind form
# demonstrably did not (it silently missed the V/D + escalation passes: five spurious
# 2026-07-23 findings). The other alternatives (EOD, git sweep, DRY RUN, PREFLIGHT) are
# unchanged.
CHAIN_INTERNAL_RE = re.compile(
    r"End-of-Day \(EOD\) compaction agent|nightly Git Sweep agent|"
    r"DRY RUN — PLAN ONLY|PREFLIGHT_OK|preflight smoke test|"
    r"Agent Workflow\b[^\n]*not a user chat", re.IGNORECASE)


def is_chain_internal(text):
    return bool(CHAIN_INTERNAL_RE.search(text[:4000]))


def check_daily_crosscheck(date, modified_today):
    """Today's-session transcripts whose UUID isn't referenced in today's daily log."""
    issues = []
    daily = os.path.join(DAILY_DIR, date + ".md")
    if not os.path.exists(daily):
        return ["daily log %s.md missing" % date], 0
    with open(daily, "r", encoding="utf-8", errors="replace") as fh:
        dtext = fh.read()
    daily_uuids = set(UUID_RE.findall(dtext))
    # Also accept short-id (8-hex prefix) references: daily-log `## Chat:` headers
    # name code sessions by short id, not full UUID (CLD-00075 — fixes the
    # 39e396f4 false positive). A full UUID's own 8-hex prefix is word-boundaried
    # (followed by "-"), so this set naturally includes those too.
    daily_shortids = set(SHORTID_RE.findall(dtext))
    for path in modified_today:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            ttext = fh.read()
        if is_chain_internal(ttext):
            continue  # nightly-chain machinery, not a user chat to log
        m = UUID_RE.search(os.path.basename(path))
        if m and m.group(0) not in daily_uuids and m.group(0)[:8] not in daily_shortids:
            issues.append("transcript modified today not referenced in daily log: %s"
                          % os.path.basename(path))
    chat_sections = dtext.count("\n## Chat:")
    return issues, chat_sections


def check_action_items_index():
    """Ported drift check: files on disk vs links in _index.md."""
    index = os.path.join(ACTION_ITEMS, "_index.md")
    if not os.path.isdir(ACTION_ITEMS) or not os.path.exists(index):
        return ["action-items _index.md missing"]
    disk = {f for f in os.listdir(ACTION_ITEMS)
            if f.endswith(".md") and f != "_index.md"}
    with open(index, "r", encoding="utf-8", errors="replace") as fh:
        content = fh.read()
    linked = {unquote(m) for m in re.findall(r"\[(?:ALF-\d+|CLD-\d+)\]\(([^)]+)\)", content)}
    linked = {os.path.basename(x) for x in linked}
    out = []
    for f in sorted(disk - linked):
        out.append("action-item on disk, not in _index.md: %s" % f)
    for f in sorted(linked - disk):
        out.append("action-item linked in _index.md, not on disk: %s" % f)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--date", default=None)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write-daily-issue", action="store_true")
    args = ap.parse_args()
    date = args.date or pacific_date()

    (tblock, tlegacy, pending, allfiles, modtoday, ownership_counts,
     trivial, flags) = check_transcripts(date)
    xissues, chat_sections = check_daily_crosscheck(date, modtoday)
    aidrift = check_action_items_index()

    # Blocking = actionable today: today's transcript problems, zero-append,
    # daily-log cross-check gaps, and action-items index drift.
    blocking = tblock + xissues + aidrift
    legacy = tlegacy
    summary = {
        "tool": "lint-transcripts", "date": date,
        "transcripts_scanned": len(allfiles),
        "modified_today": len(modtoday),
        "daily_chat_sections": chat_sections,
        "pending_blocks": pending,
        "ownership": ownership_counts,
        "blocking": blocking,
        "blocking_count": len(blocking),
        # CLD-00086 remote-delivery FLAGs (C3/C4). Reported and written to the daily
        # log, but they do NOT set the exit code: they describe the remote DELIVERY
        # pipeline's state, not an integrity violation of the file being linted.
        # (Blocking-vs-not is a David ruling — see the 2026-07-26 build report.)
        "flags": flags,
        "flags_count": len(flags),
        "legacy_count": len(legacy),
        "legacy_sample": legacy[:10],
        # CLD-00075 informational — never blocks. The nightly wrapper reads this
        # count to decide whether to file a leak-to-inbox ATTENTION item.
        "trivial_single_turn_count": len(trivial),
        "trivial_single_turn": trivial,
        "clean": not blocking,
    }

    if (blocking or flags) and args.write_daily_issue:
        daily = os.path.join(DAILY_DIR, date + ".md")
        if os.path.exists(daily):
            parts = []
            if blocking:
                parts.append("%d blocking issue(s): %s" % (
                    len(blocking), "; ".join(blocking[:8]) + (" …" if len(blocking) > 8 else "")))
            if flags:
                parts.append("%d remote-delivery FLAG(s): %s" % (
                    len(flags), "; ".join(flags[:4]) + (" …" if len(flags) > 4 else "")))
            line = ("\n[COMPACTION-ISSUE] %s lint-transcripts found %s\n"
                    % (date, " | ".join(parts)))
            with open(daily, "a", encoding="utf-8") as fh:
                fh.write(line)

    if args.json:
        print(json.dumps(summary, indent=2))
    else:
        print("lint-transcripts %s: %d transcripts (%d hand, %d tool-owned, %d live-det), "
              "%d modified today, %d pending | %d BLOCKING, %d legacy%s" % (
                  date, len(allfiles), ownership_counts.get("hand", 0),
                  ownership_counts.get("tool-owned", 0),
                  ownership_counts.get("live-deterministic", 0),
                  len(modtoday), pending,
                  len(blocking), len(legacy),
                  (" — CLEAN" if not blocking and not flags else
                   (" — %d remote-delivery FLAG(s)" % len(flags) if not blocking else ""))))
        for v in blocking:
            print("  ! " + v)
        for v in flags:
            print("  ! FLAG " + v)
        if legacy:
            print("  (%d legacy/informational findings — census only, not alarmed)" % len(legacy))
        if trivial:
            print("  (%d trivial-single-turn — possible fixture leak, informational): %s"
                  % (len(trivial), ", ".join(t["file"] for t in trivial[:8])
                     + (" …" if len(trivial) > 8 else "")))
    return 0 if not blocking else 2


if __name__ == "__main__":
    sys.exit(main())
