#!/bin/bash
# test_orchestrator.sh — CLD-00073 coordinator suite. Exercises the REAL
# orchestrator.sh + oilib.py + screen.py --intake + notify.sh + attention.sh
# against a STUB `claude` in a throwaway root, so the real OI lifecycle runs
# end-to-end without any model call or network.
#
# Covers (task-11 assertion list): OI mint atomicity; intake quarantine
# immutability (byte-compare); consultation-claim-without-anchors hard reject;
# V/D findings appended to the CORRECT spine (and only it); class-b full-read
# selection; obvious-false-alarm dispose (born-closed + archived + indexed);
# escalation packaging (sidecar + notify stub + NO executor write); decision
# re-entry (continuation, no new OI) + routing; completion round
# (reviewed→delivered→archived pair); dedupe-vs-items; notify_david graceful
# degradation with the token absent.
#
# Usage: bash _meta/test_orchestrator.sh   (exit 0 = all pass)
set -u
SRC="${AGENT_WORKFLOW_SRC:-$HOME/Documents/Agent_Workflow}"
TMP="${TMPDIR:-/tmp}/aw-orch-test.$$"
T="$TMP/root"
STUB="$TMP/stub-claude.sh"
PASS=0; FAIL=0
ok(){ if eval "$2"; then echo "  [PASS] $1"; PASS=$((PASS+1)); else echo "  [FAIL] $1"; FAIL=$((FAIL+1)); fi; }
OL(){ python3 "$SRC/_meta/oilib.py" "$@"; }
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP"
cat > "$STUB" <<'STUB'
#!/bin/bash
prompt=""
while [ $# -gt 0 ]; do case "$1" in -p) prompt="$2"; shift 2;; --model|--permission-mode) shift 2;; *) shift;; esac; done
if printf '%s' "$prompt" | grep -q 'PROVENANCE ATTESTER'; then
  echo "attester done (stub)"
  echo "ATT-VERDICT: substantiated=${ATT_STUB:-yes}"
  exit 0
fi
if printf '%s' "$prompt" | grep -q 'VERIFICATION/DESIGN'; then
  # optional prompt capture (task 016 delta-3 test): dump the real generated V/D
  # prompt when the harness asks, so a test can assert on its actual text.
  [ -n "${VD_PROMPT_CAPTURE:-}" ] && printf '%s' "$prompt" > "$VD_PROMPT_CAPTURE"
  spine="$(printf '%s' "$prompt" | awk '/The OI spine/{getline; gsub(/^[ ]+/,""); print; exit}')"
  hdr="V/D Findings"; printf '%s' "$prompt" | grep -q 'V/D Re-verification' && hdr="V/D Re-verification"
  { printf '\n## %s\n\n- **provenance:** %s\n- **recommendation:** %s\n- **variation:** %s\n- **questions:** %s\n' \
      "$hdr" "${VD_STUB_PROV:-verified}" "${VD_STUB_REC:-route}" "${VD_STUB_VAR:-significant}" "${VD_STUB_Q:-1. q}"
    # CLD-00085 fixture: a reviewer's OWN findings NAMING a red-line token while
    # explaining the boundary the work must respect. Append-only spine => permanent.
    if [ -n "${VD_STUB_REDLINE:-}" ]; then
      printf -- '- **provenance detail:** the build must respect the 3.6b no-COWORK-DECISIONS boundary (it may read that record, never write it).\n'
    fi
    if [ -n "${VD_STUB_LONG:-}" ]; then i=1; while [ "$i" -le 20 ]; do printf -- '- detail line %s of a long analysis\n' "$i"; i=$((i+1)); done; fi
    # SPINE_ONLY mode reproduces the live OI-000002 behavior: the model writes the bare
    # VD-VERDICT line into the SPINE section and only PROSE to stdout (below).
    if [ -n "${VD_STUB_SPINE_ONLY:-}" ]; then
      printf 'VD-VERDICT: provenance=%s recommend=%s variation=%s dispose_class=%s questions=%s\n' \
        "${VD_STUB_PROV:-verified}" "${VD_STUB_REC:-route}" "${VD_STUB_VAR:-significant}" "${VD_STUB_DISP:-none}" "${VD_STUB_QN:-1}"
    fi
  } >> "$spine"
  echo "vd done (stub)"
  if [ -n "${VD_STUB_SPINE_ONLY:-}" ]; then
    echo "**Verdict:** \`provenance=${VD_STUB_PROV:-verified} recommend=${VD_STUB_REC:-route} ...\` (prose only, not the bare line)"
  else
    echo "VD-VERDICT: provenance=${VD_STUB_PROV:-verified} recommend=${VD_STUB_REC:-route} variation=${VD_STUB_VAR:-significant} dispose_class=${VD_STUB_DISP:-none} questions=${VD_STUB_QN:-1}"
  fi
  exit 0
fi
if printf '%s' "$prompt" | grep -q 'escalation pass'; then
  esc="$(printf '%s' "$prompt" | awk '/Write .* with this shape/{print $2; exit}')"
  { printf '# Escalation — stub\n\n- **recommendation:** route\n\n'
    printf '```task\n---\nid: NNN-slug\nstatus: queued\npriority: 3\ntimeout_minutes: 30\nmax_attempts: 2\nattempts: 0\nmodel: sonnet\nrequested_by: david\ncreated: 2026-07-20\nrelated: []\n---\n# Stub routable task\nDo the stub thing. Deliverable: none.\n```\n'; } > "$esc"
  echo "esc done (stub)"; echo "ESC-SUMMARY: stub headline"; echo "ESC-QUESTIONS: 1"; exit 0
fi
echo "stub: unrecognized"; exit 0
STUB
chmod +x "$STUB"

setup(){
  rm -rf "$T"; mkdir -p "$T"/{orchestrator/{inbox,items,archive},code/{inbox,processing,outbox,artifacts,logs}}
  ln -s "$SRC/_meta" "$T/_meta"; ln -s "$SRC/_lib" "$T/_lib"
  cp "$SRC/orchestrator/_index.md" "$T/orchestrator/_index.md"; : > "$T/ledger.md"
}
run(){ AGENT_WORKFLOW_ROOT="$T" CLAUDE_BIN="$STUB" ORCH_NO_STANDDOWN=1 \
       COWORK_TELEGRAM_TOKEN_FILE="$T/none.token" ORCH_DELIVER_ROOTS="$T" \
       bash "$SRC/orchestrator/orchestrator.sh" >/dev/null 2>&1; }

echo "A. oilib mint atomicity + intake immutability (byte-compare)"
setup
printf -- '---\nid: a-one\nstatus: queued\npriority: 1\norigin: system-alert\nrequested_by: system/x\ncreated: 2026-07-20\n---\n# one\nbody one\n' > "$T/orchestrator/inbox/a-one.md"
cp "$T/orchestrator/inbox/a-one.md" "$TMP/orig-one.md"
printf -- '---\nid: a-two\nstatus: queued\npriority: 1\norigin: system-alert\nrequested_by: system/x\ncreated: 2026-07-20\n---\n# two\nbody two\n' > "$T/orchestrator/inbox/a-two.md"
o1=$(OL mint "$T/orchestrator/inbox/a-one.md" "$T/orchestrator/items" "$T/orchestrator/_index.md" --date 2026-07-20)
o2=$(OL mint "$T/orchestrator/inbox/a-two.md" "$T/orchestrator/items" "$T/orchestrator/_index.md" --date 2026-07-20)
ok "sequential ids (OI-000001, OI-000002)" "[ '$o1' = 'OI-000001' ] && [ '$o2' = 'OI-000002' ]"
ok "quarantined intake byte-identical to original" "diff -q '$TMP/orig-one.md' '$T/orchestrator/items/OI-000001.intake.md' >/dev/null"
ok "quarantined intake is 0444 (immutable)" "[ ! -w '$T/orchestrator/items/OI-000001.intake.md' ]"

echo "B. system-alert intake -> escalated (route); no executor write"
setup
printf -- '---\nid: attention-20260720-dl\nstatus: queued\npriority: 1\norigin: system-alert\nrequested_by: system/reviewer\ncreated: 2026-07-20\nrelated: [CLD-00073]\nsource: dead-letter\n---\n# ⚠️ Attention — dl\n1 dead-letter.\n' > "$T/orchestrator/inbox/attention-20260720-dl.md"
VD_STUB_REC=route run
sp="$T/orchestrator/items/OI-000001.md"
ok "V/D findings on the correct spine" "grep -q '## V/D Findings' '$sp'"
ok "ONLY that spine has findings (intake sidecar untouched)" "! grep -q 'V/D Findings' '$T/orchestrator/items/OI-000001.intake.md'"
ok "status escalated" "OL get '$sp' status | grep -q escalated"
ok "escalation sidecar written" "[ -f '$T/orchestrator/items/OI-000001.escalation.md' ]"
ok "notify FLAG (desktop-only, token absent — graceful degradation)" "grep -q 'notify .*FLAG .*OI-000001' '$T/ledger.md'"
ok "NO write into code/inbox" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"

echo "C. obvious false alarm -> autonomous dispose + archive"
setup
printf -- '---\nid: attention-20260720-f\nstatus: queued\npriority: 1\norigin: system-alert\nrequested_by: system/reviewer\ncreated: 2026-07-20\nsource: dead-letter\n---\n# ⚠️ Attention — f\nresolved.\n' > "$T/orchestrator/inbox/attention-20260720-f.md"
VD_STUB_REC=dispose VD_STUB_DISP=resolved VD_STUB_PROV=no-claim run
ok "born-closed disposed OI archived" "[ -f '$T/orchestrator/archive/2026/OI-000001.md' ] && OL get '$T/orchestrator/archive/2026/OI-000001.md' status | grep -q disposed"
ok "dispose ledger OK" "grep -q 'dispose .*OK .*OI-000001 disposed autonomously' '$T/ledger.md'"
ok "NO executor write" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"

echo "D. consultation claim without resolvable anchor -> hard reject (no model)"
setup
printf -- '---\nid: 030-bogus\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-99999]\n---\n# Bogus\nx\n' > "$T/orchestrator/inbox/030-bogus.md"
run
ok "screen-reject disposed + archived" "[ -f '$T/orchestrator/archive/2026/OI-000001.md' ]"
ok "V/D NOT invoked (no findings)" "! grep -q 'V/D Findings' '$T/orchestrator/archive/2026/OI-000001.md'"
ok "screen-reject ledger FLAG" "grep -q 'screen-reject .*FLAG .*OI-000001' '$T/ledger.md'"

echo "E. class-b (real consultation anchor) -> V/D reads intake -> escalated"
setup
printf -- '---\nid: 031-real\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# Real\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/031-real.md"
VD_STUB_REC=route run
ok "escalated" "OL get '$T/orchestrator/items/OI-000001.md' status | grep -q escalated"
ok "provenance set from V/D verdict" "OL get '$T/orchestrator/items/OI-000001.md' provenance | grep -q verified"

echo "F. decision re-entry (approve) -> continuation (no new OI) -> routed, deliver_to from decision"
DEST="$T/dest"
cat > "$T/orchestrator/inbox/OI-000001-approve.md" <<EOF
---
id: OI-000001-approve
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: approve
deliver_to: $DEST
---
# Approve
Go.
EOF
run
ok "no new OI minted" "[ ! -f '$T/orchestrator/items/OI-000002.md' ]"
ok "decision sidecar quarantined (immutable)" "ls '$T/orchestrator/items/'OI-000001.decision-*.md >/dev/null 2>&1 && [ ! -w \"\$(ls '$T/orchestrator/items/'OI-000001.decision-*.md | head -1)\" ]"
ok "OI routed" "OL get '$T/orchestrator/items/OI-000001.md' status | grep -q routed"
ok "routable task in code/inbox (screened)" "ls '$T/code/inbox/'*.md >/dev/null 2>&1"
ok "deliver_to carried from decision onto spine" "OL get '$T/orchestrator/items/OI-000001.md' deliver_to | grep -q dest"

echo "G. completion round: reviewed -> delivered -> archived"
task="$(ls "$T/code/inbox/"*.md | head -1)"; tb="$(basename "$task")"; tid="${tb%.md}"
mkdir -p "$T/code/artifacts/$tid"; echo deliverable > "$T/code/artifacts/$tid/report.md"
{ cat "$task"; printf '\n## Result\n- **status:** done\n\n## Review\n- **verdict:** meets-deliverable\n'; } > "$T/code/outbox/$tb"; rm -f "$task"
run
ok "artifact delivered to dest path (deliver_to flowed from the decision)" "[ -f '$DEST/report.md' ]"
ok "OI delivered + archived" "[ -f '$T/orchestrator/archive/2026/OI-000001.md' ] && OL get '$T/orchestrator/archive/2026/OI-000001.md' status | grep -q delivered"

echo "J. david-decision referencing a nonexistent/closed OI -> flagged, not reopened"
setup
cat > "$T/orchestrator/inbox/stale-decision.md" <<'EOF'
---
id: stale-decision
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-999999]
decision: approve
---
# Decision for a nonexistent OI
Go.
EOF
run
ok "flagged: no open OI -> treated as fresh intake" "grep -q 'decision-flag .*FLAG .*no open OI' '$T/ledger.md'"
ok "did NOT reopen a closed/absent OI (fresh OI minted instead)" "[ -f '$T/orchestrator/items/OI-000001.md' ] || [ -f '$T/orchestrator/archive/2026/OI-000001.md' ]"

echo "H. dedupe-vs-items: open OI suppresses a recurring alert"
setup
printf -- '---\nid: OI-000009\nstatus: escalated\nintake_original_name: attention-20260720-dupe.md\n---\n# spine\n' > "$T/orchestrator/items/OI-000009.md"
found="$(OL find-open "$T/orchestrator/items" dupe)"
ok "find-open matches open OI by slug" "[ '$found' = 'OI-000009' ]"
OL set "$T/orchestrator/items/OI-000009.md" status=disposed >/dev/null
ok "terminal OI does NOT match (find-open empty)" "[ -z \"\$(OL find-open '$T/orchestrator/items' dupe)\" ]"

echo "I. notify_david graceful degradation (token absent -> desktop-only FLAG)"
: > "$T/ledger.md"
( ROOT="$T"; LEDGER="$T/ledger.md"; TZP="America/Los_Angeles"; COWORK_TELEGRAM_TOKEN_FILE="$T/none.token"
  . "$SRC/_lib/notify.sh"; notify_david OI-000001 escalated "test" 1 "items/OI-000001.md" )
ok "token-absent -> desktop-only ledger FLAG" "grep -q 'notify .*FLAG .*token absent' '$T/ledger.md'"

# --- DEC-0082 / DEC-0083 deltas (OI-000001) --------------------------------
# A reusable class-b consultation intake carrying a fenced ```task block + a
# Suggested deliver_to; $1 = extra frontmatter line (e.g. execution: supervised).
write_autoroute_intake(){  # $1=dest-file  $2=extra-fm-line
  { printf -- '---\nid: %s\nstatus: queued\npriority: 2\norigin: david-consultation\n' "$(basename "${1%.md}")"
    printf -- 'requested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n'
    [ -n "${2:-}" ] && printf -- '%s\n' "$2"
    printf -- '---\n# Auto-route candidate\n\n## What\nDo the auto-route thing per CLD-00073.\n\n'
    printf -- '```task\n---\nid: NNN-slug\nstatus: queued\npriority: 3\ntimeout_minutes: 20\n'
    printf -- 'max_attempts: 2\nattempts: 0\nmodel: sonnet\nrequested_by: cowork\ncreated: 2026-07-20\n'
    printf -- 'related: [CLD-00073]\n---\n# Auto-routed task\nDo the routed work. Deliverable: none.\n```\n\n'
    printf -- '## Suggested deliver_to\ndaily-log\n'; } > "$1"
}

echo "K. verified-consultation AUTO-ROUTE (variation=none + attester=yes) -> code/inbox, no escalation"
setup
write_autoroute_intake "$T/orchestrator/inbox/040-autoroute.md"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
sp="$T/orchestrator/items/OI-000001.md"
ok "auto-routed: status routed" "OL get '$sp' status | grep -q routed"
ok "decision=auto-route on spine" "OL get '$sp' decision | grep -q auto-route"
ok "routable task in code/inbox (screened)" "ls '$T/code/inbox/'*.md >/dev/null 2>&1"
ok "NOT escalated (no escalation sidecar)" "[ ! -f '$T/orchestrator/items/OI-000001.escalation.md' ]"
ok "deliver_to from intake suggestion (daily-log)" "OL get '$sp' deliver_to | grep -q daily-log"
ok "auto-route ledger OK" "grep -q 'auto-route .*OK .*OI-000001 auto-routed' '$T/ledger.md'"

echo "L. auto-route BLOCKED by attester (substantiated=no) -> escalated, nothing routed"
setup
write_autoroute_intake "$T/orchestrator/inbox/040-autoroute.md"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=no run
ok "escalated (attester said no)" "OL get '$sp' status | grep -q escalated"
ok "auto-route FLAG (attester) in ledger" "grep -q 'auto-route .*FLAG .*attester' '$T/ledger.md'"
ok "no code/inbox task written" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"

echo "M. significant variation -> escalated (not auto-routed), attester never consulted"
setup
write_autoroute_intake "$T/orchestrator/inbox/040-autoroute.md"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=significant ATT_STUB=yes run
ok "escalated on significant variation" "OL get '$sp' status | grep -q escalated"
ok "no auto-route (empty code/inbox)" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"

echo "N. SUPERVISED auto-route -> code/supervised + supervised-mode block; not code/inbox"
setup
write_autoroute_intake "$T/orchestrator/inbox/041-sup.md" "execution: supervised"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
ok "supervised: status routed" "OL get '$sp' status | grep -q routed"
ok "task in code/supervised (NOT code/inbox)" "ls '$T/code/supervised/'*.md >/dev/null 2>&1 && [ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"
ok "supervised-mode bookkeeping block injected" "grep -q 'Supervised-mode execution' \"\$(ls '$T/code/supervised/'*.md | head -1)\""
# task 016 delta 4: the injected block points at the standing guardrails (DEC-0084)
ok "supervised block carries DEC-0084 guardrails pointer" "grep -q 'supervised-build-guardrails.md.*standing guardrails, DEC-0084' \"\$(ls '$T/code/supervised/'*.md | head -1)\""
ok "guardrails pointer names the scope-fence framing" "grep -q 'this task file carries your scope fence\\|task.*file carries your scope fence' \"\$(ls '$T/code/supervised/'*.md | head -1)\""
ok "execution=supervised on spine" "OL get '$sp' execution | grep -q supervised"
ok "executor=supervised on spine" "OL get '$sp' executor | grep -q supervised"

echo "N2. supervised end-to-end: David runs it (Result) + reviewer (Review) -> delivered + archived"
stask="$(ls "$T/code/supervised/"*.md | head -1)"; stb="$(basename "$stask")"; stid="${stb%.md}"
mkdir -p "$T/code/artifacts/$stid"; echo out > "$T/code/artifacts/$stid/report.md"
# emulate the supervised session: append ## Result, move the task file to code/outbox/
{ cat "$stask"; printf '\n## Result\n- **status:** done (supervised)\n\n## Review\n- **verdict:** meets-deliverable\n'; } > "$T/code/outbox/$stb"; rm -f "$stask"
run
ok "supervised OI delivered + archived (same completion round as headless)" "[ -f '$T/orchestrator/archive/2026/OI-000001.md' ] && OL get '$T/orchestrator/archive/2026/OI-000001.md' status | grep -q delivered"
ok "supervised task file left code/supervised" "[ -z \"\$(ls -A '$T/code/supervised' 2>/dev/null | grep -v .keep)\" ]"

echo "O. rewrite re-verification: clean (variation=none) -> routed with a V/D Re-verification section"
setup
printf -- '---\nid: 050-rw\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# Rw\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/050-rw.md"
VD_STUB_VAR=significant run          # escalate first
ok "OI escalated (pre-rewrite)" "OL get '$sp' status | grep -q escalated"
cat > "$T/orchestrator/inbox/OI-000001-rewrite.md" <<'EOF'
---
id: OI-000001-rewrite
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: rewrite
deliver_to: daily-log
---
# Rewrite
```task
---
id: NNN-slug
status: queued
priority: 3
timeout_minutes: 20
max_attempts: 2
attempts: 0
model: sonnet
requested_by: david
created: 2026-07-20
related: [OI-000001]
---
# Rewritten task
Do the rewritten work. Deliverable: none.
```
EOF
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none run
ok "rewrite re-verified + routed" "OL get '$sp' status | grep -q routed"
ok "V/D Re-verification section on spine" "grep -q '## V/D Re-verification' '$sp'"
ok "rewritten task in code/inbox" "ls '$T/code/inbox/'*.md >/dev/null 2>&1"

echo "O2. rewrite re-verification: significant variation -> escalated back, not routed"
setup
printf -- '---\nid: 051-rw2\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# Rw2\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/051-rw2.md"
VD_STUB_VAR=significant run
cat > "$T/orchestrator/inbox/OI-000001-rewrite2.md" <<'EOF'
---
id: OI-000001-rewrite2
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: rewrite
---
# Rewrite2
```task
---
id: NNN-slug
status: queued
priority: 3
timeout_minutes: 20
max_attempts: 2
attempts: 0
model: sonnet
requested_by: david
created: 2026-07-20
related: [OI-000001]
---
# Rewritten task 2
Do it. Deliverable: none.
```
EOF
VD_STUB_VAR=significant run
ok "re-verification escalated back (status escalated)" "OL get '$sp' status | grep -q escalated"
ok "reverify FAIL in ledger" "grep -q 'reverify .*FAIL .*OI-000001' '$T/ledger.md'"
ok "nothing routed to code/inbox" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"

echo "P. deliver_to outside allowed roots -> completion held (FLAG), not delivered"
setup
BAD="${TMPDIR:-/tmp}/aw-notallowed.$$"; rm -rf "$BAD"
printf -- '---\nid: 052-p\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# P\nBuild.\n' > "$T/orchestrator/inbox/052-p.md"
VD_STUB_VAR=significant run          # escalate -> escalation.md has a ```task block
cat > "$T/orchestrator/inbox/OI-000001-approve-bad.md" <<EOF
---
id: OI-000001-approve-bad
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: approve
deliver_to: $BAD
---
# Approve to a disallowed path
Go.
EOF
run
task="$(ls "$T/code/inbox/"*.md | head -1)"; tb="$(basename "$task")"; tid="${tb%.md}"
mkdir -p "$T/code/artifacts/$tid"; echo out > "$T/code/artifacts/$tid/report.md"
{ cat "$task"; printf '\n## Result\n- **status:** done\n\n## Review\n- **verdict:** meets-deliverable\n'; } > "$T/code/outbox/$tb"; rm -f "$task"
run
ok "NOT delivered to disallowed path" "[ ! -e '$BAD/report.md' ]"
ok "completion FLAG: outside sanctioned roots" "grep -q 'completion .*FLAG .*outside sanctioned roots' '$T/ledger.md'"
ok "OI held, not archived" "[ ! -f '$T/orchestrator/archive/2026/OI-000001.md' ]"
rm -rf "$BAD"

echo "Q. V/D findings overflow -> OI-NNNNNN.vd.md sidecar + bounded spine summary"
setup
printf -- '---\nid: attention-20260720-of\nstatus: queued\npriority: 1\norigin: system-alert\nrequested_by: system/reviewer\ncreated: 2026-07-20\nrelated: [CLD-00073]\nsource: dl\n---\n# Attention — of\nlong.\n' > "$T/orchestrator/inbox/attention-20260720-of.md"
VD_STUB_LONG=1 VD_STUB_REC=route run
ok "vd sidecar written (OI-000001.vd.md)" "[ -f '$T/orchestrator/items/OI-000001.vd.md' ]"
ok "spine points at sidecar (vd: field)" "OL get '$sp' vd | grep -q 'OI-000001.vd.md'"
ok "spine V/D section bounded (pointer line)" "grep -q 'full findings:' '$sp'"
ok "sidecar carries the full findings" "grep -q 'detail line 20' '$T/orchestrator/items/OI-000001.vd.md'"

echo "R. verdict on the SPINE only (not stdout) is still parsed -> auto-route fires (OI-000002 live-smoke fix)"
setup
write_autoroute_intake "$T/orchestrator/inbox/042-spineonly.md"
VD_STUB_SPINE_ONLY=1 VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
ok "spine-only verdict parsed: auto-routed (not rung-down to escalate)" "OL get '$sp' status | grep -q routed"
ok "provenance captured from spine verdict (verified, not the unverified fallback)" "OL get '$sp' provenance | grep -q verified"

echo "S. V/D prompt carries the verdict-authoring contract (task 016 delta 3)"
setup
printf -- '---\nid: 060-vdc\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# VDC\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/060-vdc.md"
VDCAP="$T/last-vd-prompt.txt"
VD_PROMPT_CAPTURE="$VDCAP" AGENT_WORKFLOW_ROOT="$T" CLAUDE_BIN="$STUB" ORCH_NO_STANDDOWN=1 \
  COWORK_TELEGRAM_TOKEN_FILE="$T/none.token" ORCH_DELIVER_ROOTS="$T" \
  bash "$SRC/orchestrator/orchestrator.sh" >/dev/null 2>&1
ok "V/D prompt was captured" "[ -s '$VDCAP' ]"
ok "prompt states the VERDICT-AUTHORING CONTRACT" "grep -q 'VERDICT-AUTHORING CONTRACT' '$VDCAP'"
ok "contract: FINAL line of the spine section MUST be the VD-VERDICT line" "grep -q 'FINAL line of the section you append to the spine MUST be that VD-VERDICT line' '$VDCAP'"
ok "contract: FINAL line of STDOUT MUST be the identical VD-VERDICT line" "grep -q 'FINAL line of your STDOUT MUST be the IDENTICAL VD-VERDICT line' '$VDCAP'"
ok "the VD-VERDICT shape line is still present in the prompt" "grep -q 'VD-VERDICT: provenance=' '$VDCAP'"

echo "U. david-decision deliver_to read from '## deliver_to' BODY section, frontmatter fallback (task 016 delta 5)"
setup
# escalate a class-b item first so the escalation.md carries a ```task block
printf -- '---\nid: 061-dt\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# DT\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/061-dt.md"
VD_STUB_VAR=significant run
ok "escalated (pre-decision)" "OL get '$sp' status | grep -q escalated"
# decision doc carrying deliver_to ONLY in a '## deliver_to' BODY section (the real
# decision-doc shape) — NO frontmatter deliver_to. Pre-fix this routed deliver_to=none.
cat > "$T/orchestrator/inbox/OI-000001-approve-body.md" <<'EOF'
---
id: OI-000001-approve-body
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: approve
---
# Decision — approve; deliver_to in the body
David approves routing as-is.

## deliver_to

daily-log
EOF
run
ok "routed" "OL get '$sp' status | grep -q routed"
ok "deliver_to read from the '## deliver_to' body section (daily-log), not the none default" "OL get '$sp' deliver_to | grep -q daily-log"

echo "U2. frontmatter deliver_to still works as fallback when no body section (regression)"
setup
printf -- '---\nid: 062-dt2\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# DT2\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/062-dt2.md"
VD_STUB_VAR=significant run
cat > "$T/orchestrator/inbox/OI-000001-approve-fm.md" <<'EOF'
---
id: OI-000001-approve-fm
status: queued
priority: 1
origin: david-decision
requested_by: david
created: 2026-07-20
related: [OI-000001]
decision: approve
deliver_to: daily-log
---
# Decision — approve; deliver_to in frontmatter only
Go.
EOF
run
ok "frontmatter deliver_to still carried onto spine (fallback path intact)" "OL get '$sp' deliver_to | grep -q daily-log"

# --- CLD-00085 / CLD-00087 deltas (2026-07-26 supervised pass) --------------
# A rewrite decision sidecar carrying a fenced ```task block; $2 = extra body text
# (e.g. a red-line token IN THE ARTIFACT UNDER JUDGMENT).
write_rewrite_decision(){  # $1=dest-file  $2=extra-body-line
  { printf -- '---\nid: %s\nstatus: queued\npriority: 1\norigin: david-decision\n' "$(basename "${1%.md}")"
    printf -- 'requested_by: david\ncreated: 2026-07-20\nrelated: [OI-000001]\ndecision: rewrite\n---\n'
    printf -- '# Rewrite\n%s\n' "${2:-Proceed as scoped.}"
    printf -- '```task\n---\nid: NNN-slug\nstatus: queued\npriority: 3\ntimeout_minutes: 20\n'
    printf -- 'max_attempts: 2\nattempts: 0\nmodel: sonnet\nrequested_by: david\ncreated: 2026-07-20\n'
    printf -- 'related: [OI-000001]\n---\n# Rewritten task\nDo the rewritten work. Deliverable: none.\n```\n'; } > "$1"
}

echo "V. A1 (CLD-00085): the red-line gate scans the ARTIFACT, never the OI spine"
setup
printf -- '---\nid: 070-rl\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# RL\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/070-rl.md"
# V/D writes a red-line token into its OWN findings on the spine (the OI-000003 shape)
VD_STUB_VAR=significant VD_STUB_REDLINE=1 run
sp="$T/orchestrator/items/OI-000001.md"
ok "spine carries a red-line token in V/D's own findings (fixture precondition)" "grep -q 'COWORK-DECISIONS' '$sp'"
ok "escalated pre-rewrite" "OL get '$sp' status | grep -q escalated"
# David returns a CLEAN rewrite (no red-line token anywhere in the sidecar)
write_rewrite_decision "$T/orchestrator/inbox/OI-000001-rewrite-clean.md"
ok "decision sidecar is clean of red-line tokens (fixture precondition)" "! grep -q 'COWORK-DECISIONS' '$T/orchestrator/inbox/OI-000001-rewrite-clean.md'"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none VD_STUB_QN=0 VD_STUB_REDLINE=1 run
ok "A1: spine token does NOT trip the gate — clean rewrite ROUTES" "OL get '$sp' status | grep -q routed"
ok "A1: routable task actually written to code/inbox" "ls '$T/code/inbox/'*.md >/dev/null 2>&1"
ok "A1: no reverify FAIL in the ledger" "! grep -q 'reverify .*FAIL .*OI-000001' '$T/ledger.md'"

echo "W. A1/A2/A3: a red line IN THE ARTIFACT still escalates, diagnosed + FLAGged"
setup
printf -- '---\nid: 071-rl2\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# RL2\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/071-rl2.md"
VD_STUB_VAR=significant run
write_rewrite_decision "$T/orchestrator/inbox/OI-000001-rewrite-dirty.md" \
  "This rewrite edits COWORK-DECISIONS directly."
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none VD_STUB_QN=0 run
ok "artifact token DOES trip the gate — escalated, not routed" "OL get '$sp' status | grep -q escalated"
ok "nothing routed to code/inbox" "[ -z \"\$(ls -A '$T/code/inbox' 2>/dev/null | grep -v .keep)\" ]"
ok "A2: ledger names the matched token, file and line" "grep -qE 'red-line .*FLAG .*OI-000001 red-line gate matched .COWORK-DECISIONS. in OI-000001.decision-01.md line [0-9]+' '$T/ledger.md'"
ok "A3: contradiction FLAG on a clean auto-route match that escalated" "grep -q 'contradiction .*FLAG .*OI-000001 escalated despite a CLEAN auto-route match' '$T/ledger.md'"
ok "A3: the FLAG names the blocking gate" "grep -q 'contradiction .*FLAG .*blocked by: red-line gate' '$T/ledger.md'"
ok "reverify FAIL line names the blocking gate too" "grep -q 'reverify .*FAIL .*blocked by: red-line gate' '$T/ledger.md'"

echo "W2. A3: an ordinary escalation (variation=significant) emits NO contradiction FLAG"
setup
printf -- '---\nid: 072-ord\nstatus: queued\npriority: 2\norigin: david-consultation\nrequested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\n---\n# Ord\nBuild per CLD-00073.\n' > "$T/orchestrator/inbox/072-ord.md"
VD_STUB_VAR=significant run
ok "escalated" "OL get '$sp' status | grep -q escalated"
ok "no contradiction FLAG (nothing self-contradictory here)" "! grep -q 'contradiction .*FLAG' '$T/ledger.md'"

# --- CLD-00087: supervised deliverable path ---------------------------------
# Same auto-route intake, but the fenced task block declares a custom `deliverable:`.
write_deliverable_intake(){  # $1=dest-file  $2=deliverable-line (may be empty)
  { printf -- '---\nid: %s\nstatus: queued\npriority: 2\norigin: david-consultation\n' "$(basename "${1%.md}")"
    printf -- 'requested_by: cowork\ncreated: 2026-07-20\nrelated: [CLD-00073]\nexecution: supervised\n---\n'
    printf -- '# Deliverable-path candidate\n\n## What\nDo the thing per CLD-00073.\n\n'
    printf -- '```task\n---\nid: NNN-slug\nstatus: queued\npriority: 3\ntimeout_minutes: 20\n'
    printf -- 'max_attempts: 2\nattempts: 0\nmodel: sonnet\nrequested_by: cowork\ncreated: 2026-07-20\n'
    [ -n "${2:-}" ] && printf -- '%s\n' "$2"
    printf -- 'related: [CLD-00073]\n---\n# Supervised task\nDo the supervised work.\n```\n\n'
    printf -- '## Suggested deliver_to\n%s\n' "$T/dest87"; } > "$1"
}

# The INJECTED block only — the task's own frontmatter also names the deliverable,
# so a whole-file grep would pass even when the block still says artifacts/<tid>/.
supblock(){ awk '/^## Supervised-mode execution/,0' "$1"; }

echo "X. B1 (CLD-00087): supervised block honors the declared deliverable: dir"
setup
write_deliverable_intake "$T/orchestrator/inbox/080-dp.md" "deliverable: artifacts/consult-custom-dir/report.md"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
stask="$(ls "$T/code/supervised/"*.md 2>/dev/null | head -1)"
ok "supervised task routed" "[ -n '$stask' ] && [ -f '$stask' ]"
ok "injected block instructs the DECLARED deliverable path" "supblock '$stask' | grep -q 'artifacts/consult-custom-dir/report.md'"
ok "other artifacts point at the declared dir" "supblock '$stask' | grep -q 'Put any other artifacts in .artifacts/consult-custom-dir/'"
ok "injected block does NOT instruct the task-id folder" "! supblock '$stask' | grep -q 'artifacts/0[0-9][0-9]-'"

echo "X2. B1: no declared deliverable -> the task-id artifacts folder (regression)"
setup
write_deliverable_intake "$T/orchestrator/inbox/081-dp2.md" ""
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
stask2="$(ls "$T/code/supervised/"*.md 2>/dev/null | head -1)"; stid2="$(basename "${stask2%.md}")"
ok "supervised task routed" "[ -n '$stask2' ] && [ -f '$stask2' ]"
ok "injected block instructs artifacts/<tid>/report.md" "supblock '$stask2' | grep -q 'artifacts/$stid2/report.md'"

echo "X3. B1: the completion round resolves the SAME path (no dual write)"
setup
write_deliverable_intake "$T/orchestrator/inbox/082-dp3.md" "deliverable: artifacts/consult-custom-dir/report.md"
VD_STUB_PROV=verified VD_STUB_REC=route VD_STUB_VAR=none ATT_STUB=yes run
stask3="$(ls "$T/code/supervised/"*.md | head -1)"; stb3="$(basename "$stask3")"; stid3="${stb3%.md}"
# the supervised session writes ONLY where the block told it to
mkdir -p "$T/code/artifacts/consult-custom-dir"; echo "the deliverable" > "$T/code/artifacts/consult-custom-dir/report.md"
ok "task-id artifacts folder is empty (the dual-write stopgap is not needed)" "[ ! -d '$T/code/artifacts/$stid3' ]"
{ cat "$stask3"; printf '\n## Result\n- **status:** done (supervised)\n\n## Review\n- **verdict:** meets-deliverable\n'; } > "$T/code/outbox/$stb3"; rm -f "$stask3"
run
ok "deliverable check passed + artifact delivered from the declared dir" "[ -f '$T/dest87/report.md' ]"
ok "OI delivered + archived" "[ -f '$T/orchestrator/archive/2026/OI-000001.md' ] && OL get '$T/orchestrator/archive/2026/OI-000001.md' status | grep -q delivered"
ok "no completion FLAG in the ledger" "! grep -q 'completion .*FLAG' '$T/ledger.md'"

echo
if [ "$FAIL" -eq 0 ]; then echo "ALL PASS ($PASS)"; exit 0; else echo "$FAIL FAILED ($PASS passed)"; exit 1; fi
