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
tmp=$(mktemp -d)
idx=$tmp/index
trap 'rm -rf "$tmp"' EXIT
GIT_INDEX_FILE=$idx git read-tree "$base"

# Merge each local note with main's copy so two sessions editing the same note keep both sides' lines.
# The merge base is the main commit this clone's notes last matched, recorded after each sync.
state=$(git rev-parse --git-path memory-synced)
synced=$(cat "$state" 2>/dev/null || git rev-parse HEAD)
# Add and update notes only: a note missing from this clone may come from another session, so never delete it from main.
while IFS= read -r -d '' f; do
  if ! git cat-file -e "$base:$f" 2>/dev/null && git show "$synced:$f" 2>/dev/null | cmp -s - "$f"; then
    # Deleted on main and unchanged here since the last sync: drop it rather than adding it back.
    rm -f -- "$f"
    continue
  fi
  if git show "$base:$f" > "$tmp/theirs" 2>/dev/null && ! cmp -s "$f" "$tmp/theirs"; then
    git show "$synced:$f" > "$tmp/base" 2>/dev/null || : > "$tmp/base"
    if cmp -s "$f" "$tmp/base"; then
      cp "$tmp/theirs" "$f"
    elif ! cmp -s "$tmp/theirs" "$tmp/base"; then
      git merge-file -q --union "$f" "$tmp/base" "$tmp/theirs"
    fi
  fi
  GIT_INDEX_FILE=$idx git update-index --add -- "$f"
done < <(find memory -type f -print0)
# The local notes now hold main's changes, so later runs merge against base even if the push below fails.
echo "$base" > "$state"
tree=$(GIT_INDEX_FILE=$idx git write-tree)
[ "$tree" = "$(git rev-parse "$base^{tree}")" ] && exit 0

commit=$(git commit-tree "$tree" -p "$base" -m "Update Basic Memory notes")
if ! timeout 30 git push -q origin "$commit:refs/heads/main"; then
  echo "commit-memory: push to main failed; will retry after the next response" >&2
  exit 0
fi
echo "$commit" > "$state"

# When main itself is checked out, move it to the pushed commit too.
if [ "$(git symbolic-ref -q HEAD)" = refs/heads/main ] && [ "$(git rev-parse HEAD)" = "$base" ]; then
  git update-ref refs/heads/main "$commit" && git reset -q -- memory
fi
exit 0
