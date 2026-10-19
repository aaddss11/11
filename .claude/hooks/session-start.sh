#!/bin/bash
# Install the ECC plugin and set its hook profile to standard in cloud sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

if ! claude plugin list --json 2>/dev/null | grep -q '"id": "ecc@ecc"'; then
  claude plugin marketplace add affaan-m/ECC
  claude plugin install ecc@ecc --scope project
fi

ECC_ROOT=$(ls -d "$HOME"/.claude/plugins/cache/ecc/ecc/*/ | sort -V | tail -1)
node "$ECC_ROOT/scripts/setup.js" --mode claude-plugin --scope project --hooks standard --yes --json
