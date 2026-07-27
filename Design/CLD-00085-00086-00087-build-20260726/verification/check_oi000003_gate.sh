#!/bin/bash
# Function-level, READ-ONLY evaluation of the fixed red-line gate against the REAL
# OI-000003 artifacts (CLD-00085 verification bar item 4). Nothing is enacted: the
# gate function is extracted from the orchestrator and called directly; no OI is
# minted, routed, written or notified.
#
# Usage: bash check_oi000003_gate.sh [<orchestrator.sh>]
set -u
ORCH="${1:-$HOME/Documents/Agent_Workflow/orchestrator/orchestrator.sh}"
ITEMS="$HOME/Documents/Agent_Workflow/orchestrator/items"
SPINE="$ITEMS/OI-000003.md"
SIDECAR="$ITEMS/OI-000003.decision-02.md"

TMPF="$(mktemp -t rlgate)"
# extract RED_LINE_RE + red_line_hit() only (no top-level orchestrator code runs)
awk '/^RED_LINE_RE=/{grab=1} grab{print} grab && /^}$/{exit}' "$ORCH" > "$TMPF"
if ! grep -q 'red_line_hit()' "$TMPF"; then
  # pristine shape: the pattern lives inside the function
  awk '/^red_line_hit\(\)/{grab=1} grab{print} grab && /^}$/{exit}' "$ORCH" > "$TMPF"
fi
# shellcheck source=/dev/null
. "$TMPF"
rm -f "$TMPF"

echo "orchestrator: $ORCH"
echo "spine       : $SPINE"
echo "sidecar     : $SIDECAR"
echo

if grep -q 'RED_LINE_RE' <<< "$(declare -f red_line_hit)"; then
  echo "== FIXED gate (artifact under judgment only) =="
  if red_line_hit "$SIDECAR"; then
    echo "RESULT: red_line_hit(sidecar) = TRUE  — matched ${RED_LINE_WHERE:-?}"
  else
    echo "RESULT: red_line_hit(sidecar) = FALSE — CLEAN (auto-route path not blocked)"
  fi
  echo
  echo "-- control: the SPINE alone would still match (why the surface mattered) --"
  if red_line_hit "$SPINE"; then
    echo "  spine matches: ${RED_LINE_WHERE:-?}"
    echo "  context: ${RED_LINE_CONTEXT:0:110}"
  else
    echo "  spine has no red-line token"
  fi
else
  echo "== PRISTINE gate (spine + sidecar) =="
  if red_line_hit "$SPINE" "$SIDECAR"; then
    echo "RESULT: red_line_hit(spine,sidecar) = TRUE — BLOCKED (the OI-000003 defect)"
  else
    echo "RESULT: red_line_hit(spine,sidecar) = FALSE"
  fi
fi
