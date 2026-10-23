#!/bin/bash
# Fetch the awesome-llm-apps submodule, install the ECC, superpowers, mattpocock-skills, karpathy-skills and ponytail plugins, the graphify CLI and set ECC's hook profile to standard in cloud sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

git submodule update --init --depth 1

command -v graphify >/dev/null || uv tool install graphifyy

if ! claude plugin list --json 2>/dev/null | grep -q '"id": "ecc@ecc"'; then
  claude plugin marketplace add affaan-m/ECC
  claude plugin install ecc@ecc --scope project
fi

for entry in obra/superpowers-marketplace:superpowers@superpowers-marketplace \
             mattpocock/skills:mattpocock-skills@mattpocock \
             multica-ai/andrej-karpathy-skills:andrej-karpathy-skills@karpathy-skills \
             DietrichGebert/ponytail:ponytail@ponytail; do
  repo=${entry%%:*}
  plugin=${entry#*:}
  if ! claude plugin list --json 2>/dev/null | grep -q "\"id\": \"$plugin\""; then
    claude plugin marketplace add "$repo"
    claude plugin install "$plugin" --scope project
  fi
done

ECC_ROOT=$(ls -d "$HOME"/.claude/plugins/cache/ecc/ecc/*/ | sort -V | tail -1)
node "$ECC_ROOT/scripts/setup.js" --mode claude-plugin --scope project --hooks standard --yes --json
