#!/bin/bash
# Commit and push Basic Memory notes in memory/ after each Claude response, so they survive cloud sessions.
set -uo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

[ -d memory ] || exit 0
git add memory
git diff --cached --quiet -- memory && exit 0

branch=$(git symbolic-ref --short -q HEAD) || exit 0
git commit -q -m "Update Basic Memory notes" -- memory || exit 0
timeout 30 git push -q -u origin "$branch" || echo "commit-memory: push failed; notes are committed locally" >&2
exit 0
