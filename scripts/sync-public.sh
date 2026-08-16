#!/bin/bash
# Syncs the current state of main onto the public branch as a new
# snapshot commit, then pushes public (which Forgejo's push mirror picks
# up and forwards to GitHub automatically).
#
# Deliberately does NOT merge main into public - public is an orphan
# branch with no shared history with main on purpose (main's early
# history briefly had personal paths/hostnames/a webhook ID inline,
# before the lib/config.local.sh + Keychain split; merging would splice
# that history into public). Since all current tracked files are already
# clean, copying the current tree over is enough - no per-commit review
# needed.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
    echo "Working tree not clean - commit or stash first." >&2
    exit 1
fi

MAIN_SHA=$(git rev-parse --short main)

git checkout public
# Full replace, not a plain "checkout main -- .": that alone would leave
# behind any file public has and main has since deleted. Clear public's
# tracked tree first, then restore exactly main's.
git rm -rq --ignore-unmatch -- .
git checkout main -- .
git add -A

if git diff --cached --quiet; then
    echo "public is already up to date with main@$MAIN_SHA - nothing to sync."
    git checkout main
    exit 0
fi

git commit -m "Sync to main@$MAIN_SHA"
git checkout main

echo "Synced. Push with:"
echo "  git push forgejo public"
