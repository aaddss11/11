#!/bin/bash
# Commit Basic Memory notes in memory/ onto main and push them after each Claude response, whatever branch is checked out.
set -uo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Keep memory/ out of git status on the checked-out branch: these notes go to main, not to the branch.
exclude=$(git rev-parse --git-path info/exclude)
grep -qxF '/memory/' "$exclude" 2>/dev/null || echo '/memory/' >> "$exclude"
git ls-files -z memory | xargs -0 -r git update-index --skip-worktree

[ -d memory ] || exit 0
timeout 30 git fetch -q origin main || exit 0
base=$(git rev-parse origin/main)

# Build the commit in a temporary index so the checked-out branch and its staged changes are untouched.
idx=$(mktemp -d)/index
trap 'rm -rf "$(dirname "$idx")"' EXIT
GIT_INDEX_FILE=$idx git read-tree "$base"
# The main commit this clone last synced its notes with; before the first sync, the checked-out commit they came from.
synced=$(git rev-parse -q --verify refs/memory/synced || git rev-parse HEAD)
blob() { git rev-parse -q --verify "$1:$2" 2>/dev/null; }
empty=$(git hash-object -w --stdin </dev/null)
# Add and update notes only: a note missing from this clone may come from another session, so never delete it from main.
while IFS= read -r -d '' f; do
  old=$(blob "$synced" "$f"); theirs=$(blob "$base" "$f"); ours=$(git hash-object -w -- "$f")
  if [ "$ours" = "$old" ]; then
    # Not changed here since the last sync: take main's version rather than pushing a stale copy over it.
    if [ -z "$theirs" ]; then rm -f -- "$f"
    elif [ "$theirs" != "$ours" ]; then git cat-file blob "$theirs" > "$f"; fi
    continue
  fi
  if [ -n "$theirs" ] && [ "$theirs" != "$old" ] && [ "$theirs" != "$ours" ]; then
    # Changed on both sides: merge, keeping both sides' lines where they overlap.
    ours=$(git merge-file --object-id --union "$ours" "${old:-$empty}" "$theirs")
    git cat-file blob "$ours" > "$f"
  fi
  GIT_INDEX_FILE=$idx git update-index --add --cacheinfo "100644,$ours,$f"
done < <(find memory -type f -print0)
# The working tree now holds main's notes plus this clone's changes, so later runs merge against base.
git update-ref refs/memory/synced "$base"
tree=$(GIT_INDEX_FILE=$idx git write-tree)
[ "$tree" = "$(git rev-parse "$base^{tree}")" ] && exit 0

commit=$(git commit-tree "$tree" -p "$base" -m "Update Basic Memory notes")
if ! timeout 30 git push -q origin "$commit:refs/heads/main"; then
  echo "commit-memory: push to main failed; will retry after the next response" >&2
  exit 0
fi
git update-ref refs/memory/synced "$commit"

# When main itself is checked out, move it to the pushed commit too.
if [ "$(git symbolic-ref -q HEAD)" = refs/heads/main ] && [ "$(git rev-parse HEAD)" = "$base" ]; then
  git update-ref refs/heads/main "$commit" && git reset -q -- memory
fi
exit 0
