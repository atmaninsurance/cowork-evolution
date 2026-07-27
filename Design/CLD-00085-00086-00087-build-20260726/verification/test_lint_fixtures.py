#!/usr/bin/env python3
"""
Controlled fixtures for the CLD-00086 lint fixes — pristine vs fixed, side by side.

Builds a throwaway transcript tree reproducing the evidence shapes, then runs BOTH
the pristine `lint-transcripts.py` (backups/) and the fixed one (work/ or the live
nightly copy) against it with their module constants pointed at the fixtures.

    python3 test_lint_fixtures.py [--fixed <path-to-lint-transcripts.py>]
                                  [--pristine <path>]

Exit 0 = all assertions pass.
"""
import argparse
import importlib.util
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.dirname(HERE)
NIGHTLY = os.path.expanduser("~/Claude/Scheduled/nightly")

TODAY = "2026-07-26"
YESTERDAY = "2026-07-25"

PASS = FAIL = 0


def ok(label, cond):
    global PASS, FAIL
    if cond:
        print("  [PASS] %s" % label)
        PASS += 1
    else:
        print("  [FAIL] %s" % label)
        FAIL += 1


def load(path, name):
    """Import a lint-transcripts.py copy under its own module name."""
    d = tempfile.mkdtemp(prefix="lintmod-")
    shutil.copy(path, os.path.join(d, "lint_mod.py"))
    # the module inserts its own dir on sys.path and imports _transcript_common
    shutil.copy(os.path.join(NIGHTLY, "_transcript_common.py"),
                os.path.join(d, "_transcript_common.py"))
    spec = importlib.util.spec_from_file_location(name, os.path.join(d, "lint_mod.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def header(chat_id, started, tool_owned=True, capture=None):
    cap = capture or ("Deterministic reconstruction by export-code-transcripts.py "
                      "(reconstructed-by-nightly-tooling)")
    return (
        "# Transcript: fixture %s\n\n"
        "**Chat ID:** %s\n"
        "**Surface:** fixture\n"
        "**Cowork UI title:** N/A\n"
        "**Live capture started:** %s\n"
        "**Capture mode:** %s\n"
        "**Lossiness note:** fixture\n"
        "**Append protocol:** append-sentinel marker (HTML comment at file foot)\n\n"
        "---\n\n" % (chat_id[:8], chat_id, started, cap))


def turn(n, ts, body="body"):
    return "## Turn %d — %s (fixture turn %d)\n[user]\n%s\n\n" % (n, ts, n, body)


def sentinel(cid, n):
    return "<!-- APPEND_%s_AFTER_TURN_%d -->\n" % (cid, n)


def build_fixtures(root):
    code = os.path.join(root, "code")
    cowork = os.path.join(root, "cowork")
    os.makedirs(code)
    os.makedirs(cowork)

    # 1. The 6d5a2d18 shape: one OWN turn, a fully quoted foreign transcript
    #    (header + turns 1..5 + FOREIGN foot sentinel), own foot sentinel = 1.
    own = "aaaaaaaa-1111-4111-8111-111111111111"
    foreign = "bbbbbbbb-2222-4222-8222-222222222222"
    quoted = (header(foreign, "2026-07-25T22:00Z")
              + "".join(turn(i, "2026-07-25T22:0%dZ" % i) for i in range(1, 6))
              + sentinel(foreign[:8], 5))
    text = (header(own, "%sT18:00Z" % TODAY)
            + turn(1, "%sT18:00Z" % TODAY, "read the other transcript")
            + "[tool: Bash]\n{\"command\": \"cat other.md\"}\n→ " + quoted
            + "\n[assistant]\ndone\n\n"
            + sentinel(own[:8], 1))
    open(os.path.join(code, own + ".md"), "w").write(text)

    # 2. REAL truncation: own turns 1..5 (no quoted content), sentinel says 3.
    tr = "cccccccc-3333-4333-8333-333333333333"
    open(os.path.join(code, tr + ".md"), "w").write(
        header(tr, "%sT18:00Z" % TODAY)
        + "".join(turn(i, "%sT18:0%dZ" % (TODAY, i)) for i in range(1, 6))
        + sentinel(tr[:8], 3))

    # 3. Zero-append (CLD-00049 class): header + sentinel AFTER_TURN_0, no turns.
    za = "dddddddd-4444-4444-8444-444444444444"
    open(os.path.join(code, za + ".md"), "w").write(
        header(za, "%sT18:00Z" % TODAY) + sentinel(za[:8], 0))

    # 4. C3 — stale header-only remote from a PAST day, no close marker.
    st = "remote_eeeeeeee-5555-4555-8555-555555555555"
    open(os.path.join(cowork, st + ".md"), "w").write(
        header(st, "%sT18:00Z" % YESTERDAY, capture="Live-deterministic (remote)")
        + sentinel(st[len("remote_"):], 0))

    # 5. C3 negative — same shape but WITH a soft-close marker at the foot.
    mk = "remote_ffffffff-6666-4666-8666-666666666666"
    open(os.path.join(cowork, mk + ".md"), "w").write(
        header(mk, "%sT18:00Z" % YESTERDAY, capture="Live-deterministic (remote)")
        + "[SOFT-CLOSE %s 22:45 PDT — one incomplete turn; nothing to flush]\n\n" % YESTERDAY
        + sentinel(mk[len("remote_"):], 0))

    # 6. C4 — a remote transcript for the TARGET day with no ledger line, no marker.
    td = "remote_99999999-7777-4777-8777-777777777777"
    open(os.path.join(cowork, td + ".md"), "w").write(
        header(td, "%sT17:00Z" % TODAY, capture="Live-deterministic (remote)")
        + turn(1, "%sT17:05Z" % TODAY) + sentinel(td[len("remote_"):], 1))

    # 7. C4 negative — target day WITH a ledger data line (written by the caller).
    lg = "remote_88888888-8888-4888-8888-888888888888"
    open(os.path.join(cowork, lg + ".md"), "w").write(
        header(lg, "%sT17:00Z" % TODAY, capture="Live-deterministic (remote)")
        + turn(1, "%sT17:05Z" % TODAY) + sentinel(lg[len("remote_"):], 1))
    return {"quoted": own, "truncated": tr, "zero": za,
            "stale": st, "marked": mk, "today_noledger": td, "today_ledger": lg}


def ledger_file(root, ids):
    """A ledger whose PROSE names the un-fired chat and whose DATA line names another
    (the mention-vs-use guard: prose must not count as a fire)."""
    p = os.path.join(root, "remote-contingency-ledger.md")
    open(p, "w").write(
        "# Remote-chat contingency ledger\n\n"
        "Instrumentation added %s (chat `%s`, David-directed) — this prose NAMES a chat\n"
        "but records no fire for it.\n\n---\n\n"
        "%s 22:45 PT | %s | jsonl=present | converter=ok | appended=1 | mode=SOFT-CLOSE | push=ok\n"
        % (TODAY, ids["today_noledger"], TODAY, ids["today_ledger"]))
    return p


def run(mod, root, ledger, date):
    mod.TRANSCRIPTS = root
    if hasattr(mod, "CONTINGENCY_LEDGER"):
        mod.CONTINGENCY_LEDGER = ledger
    out = mod.check_transcripts(date)
    blocking, legacy = out[0], out[1]
    flags = out[7] if len(out) > 7 else []
    return blocking, legacy, flags


def joined(items):
    return " || ".join(items)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fixed", default=os.path.join(BUILD, "work", "lint-transcripts.py"))
    ap.add_argument("--pristine", default=os.path.join(
        BUILD, "backups", "lint-transcripts.py.pristine-20260726"))
    args = ap.parse_args()

    root = tempfile.mkdtemp(prefix="lint-fixtures-")
    ids = build_fixtures(root)
    ledger = ledger_file(root, ids)

    pristine = load(args.pristine, "lint_pristine")
    fixed = load(args.fixed, "lint_fixed")

    pb, pl, pf = run(pristine, root, ledger, TODAY)
    fb, fl, ff = run(fixed, root, ledger, TODAY)

    print("PRISTINE blocking: %s" % joined(pb))
    print("FIXED    blocking: %s" % joined(fb))
    print("FIXED    flags:    %s" % joined(ff))
    print()

    print("C1 — quoted-content false positive (the 6d5a2d18 / 2d767e01 shape)")
    ok("pristine reports the spurious continuity failure",
       any(ids["quoted"] in v and "highest turn header is 5" in v for v in pb))
    ok("fixed reports NOTHING for that transcript",
       not any(ids["quoted"] in v for v in fb + fl))

    print("C1 — a REAL truncation still fires (own headers exceed the sentinel)")
    ok("pristine catches it", any(ids["truncated"] in v for v in pb))
    ok("fixed catches it too", any(ids["truncated"] in v for v in fb))
    ok("fixed names the OWN count (5) and the sentinel (3)",
       any(ids["truncated"] in v and "AFTER_TURN_3" in v and "is 5" in v for v in fb))

    print("C1 — zero-append (CLD-00049) unchanged")
    ok("pristine flags zero-append", any(ids["zero"] in v and "ZERO-APPEND" in v for v in pb))
    ok("fixed still flags zero-append", any(ids["zero"] in v and "ZERO-APPEND" in v for v in fb))

    print("C2 — diagnosis on the finding")
    ok("fixed reports the max-turn header's LINE number",
       any(ids["truncated"] in v and "(line " in v for v in fb))

    print("C3 — seed-staleness / missed flush")
    ok("stale header-only remote FLAGs (missed flush)",
       any(ids["stale"] in v and "missed flush" in v for v in ff))
    ok("marker-bearing header-only remote does NOT flag",
       not any(ids["marked"] in v for v in ff))
    ok("pristine had no such check", not pf)

    print("C4 — contingency-ledger cross-check")
    ok("target-day remote with no ledger line FLAGs (fire never ran)",
       any(ids["today_noledger"] in v and "fire never ran" in v for v in ff))
    ok("distinct message text from the C3 flag",
       not any(ids["today_noledger"] in v and "missed flush" in v for v in ff))
    ok("target-day remote WITH a ledger data line does not flag",
       not any(ids["today_ledger"] in v for v in ff))
    ok("ledger PROSE naming a chat is not read as a fire (mention-is-not-use)",
       any(ids["today_noledger"] in v for v in ff))

    print("\nfixtures: %s" % root)
    if FAIL:
        print("%d FAILED (%d passed)" % (FAIL, PASS))
        return 1
    print("ALL PASS (%d)" % PASS)
    shutil.rmtree(root, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
