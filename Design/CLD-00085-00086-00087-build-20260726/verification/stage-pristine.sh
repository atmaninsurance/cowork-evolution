#!/bin/bash
# Recreate a PRISTINE Agent_Workflow source tree (pre-CLD-00085/00087 orchestrator)
# so the extended suite can be re-run against it — the pristine-vs-fixed evidence.
#
#   bash stage-pristine.sh                       # stages to a temp dir, prints the path
#   AGENT_WORKFLOW_SRC=<that path> bash ~/Documents/Agent_Workflow/_meta/test_orchestrator.sh
#
# Expect: the 11 new-behavior assertions (sections V, W, X, X3) FAIL there and pass
# against the live tree. Nothing here touches the live orchestrator.
set -eu
BUILD="$(cd "$(dirname "$0")/.." && pwd)"
AW="$HOME/Documents/Agent_Workflow"
DEST="${1:-$(mktemp -d -t aw-pristine)}"
mkdir -p "$DEST/orchestrator"
ln -sfn "$AW/_meta" "$DEST/_meta"
ln -sfn "$AW/_lib"  "$DEST/_lib"
cp "$AW/orchestrator/_index.md" "$DEST/orchestrator/_index.md"
cp "$BUILD/backups/orchestrator.sh.pristine-20260726" "$DEST/orchestrator/orchestrator.sh"
echo "$DEST"
