#!/usr/bin/env bash
# SessionStart hook: when a new session starts in a linked git worktree whose branch
# has no work of its own yet, fast-forward it to the latest origin/main.
#
# New worktrees branch from the local main, which is often stale. This only ever
# fast-forwards, so a branch with its own commits, or local changes that would be
# overwritten, is left untouched. Anything printed to stdout is added to Claude's context.

main() {
  set -uo pipefail
  export GIT_TERMINAL_PROMPT=0

  # Only act inside a linked worktree (git dir differs from the common dir).
  local git_dir common_dir
  git_dir=$(git rev-parse --path-format=absolute --git-dir 2>/dev/null) || exit 0
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
  [[ "$git_dir" != "$common_dir" ]] || exit 0

  # Skip detached HEADs and repos without an origin.
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD) || exit 0
  git remote get-url origin >/dev/null 2>&1 || exit 0

  if ! git fetch --quiet origin main 2>/dev/null; then
    echo "Could not fetch origin/main; worktree branch '$branch' may be based on a stale main."
    exit 0
  fi

  # Nothing to do if already up to date; leave branches with their own commits alone.
  if git merge-base --is-ancestor origin/main HEAD; then
    exit 0
  fi
  if ! git merge-base --is-ancestor HEAD origin/main; then
    exit 0
  fi

  local old new
  old=$(git rev-parse --short HEAD)
  if git merge --quiet --ff-only origin/main >/dev/null 2>&1; then
    new=$(git rev-parse --short HEAD)
    echo "Fast-forwarded worktree branch '$branch' from $old to the latest origin/main ($new)."
  else
    echo "Worktree branch '$branch' is behind origin/main but could not be fast-forwarded (local changes would be overwritten). Run 'git merge --ff-only origin/main' once they are committed or stashed."
  fi
}

main "$@"
