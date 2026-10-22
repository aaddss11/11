#!/bin/bash
# Commit Basic Memory notes in memory/ onto main and push them after each Claude response, whatever branch is checked out.
set -uo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

[ -d memory ] || exit 0
timeout 30 git fetch -q origin main || exit 0
base=$(git rev-parse origin/main)

# Build the commit in a temporary index so the checked-out branch and its staged changes are untouched.
idx=$(mktemp -d)/index
trap 'rm -rf "$(dirname "$idx")"' EXIT
GIT_INDEX_FILE=$idx git read-tree "$base"
GIT_INDEX_FILE=$idx git rm -r -q --cached --ignore-unmatch memory
GIT_INDEX_FILE=$idx git add memory
tree=$(GIT_INDEX_FILE=$idx git write-tree)
[ "$tree" = "$(git rev-parse "$base^{tree}")" ] && exit 0

commit=$(git commit-tree "$tree" -p "$base" -m "Update Basic Memory notes")
if ! timeout 30 git push -q origin "$commit:refs/heads/main"; then
  echo "commit-memory: push to main failed; will retry after the next response" >&2
  exit 0
fi

# When main itself is checked out, move it to the pushed commit too.
if [ "$(git symbolic-ref -q HEAD)" = refs/heads/main ] && [ "$(git rev-parse HEAD)" = "$base" ]; then
  git update-ref refs/heads/main "$commit" && git reset -q -- memory
fi
exit 0
