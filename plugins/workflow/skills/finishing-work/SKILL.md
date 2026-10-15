---
name: finishing-work
description: How to wrap up after completing a coding task in a git repository. Use whenever you have finished making code changes, before reporting back to the user.
---

# Finishing work

Before you report that a task is done, check which kind of worktree you are in:

```shell
git rev-parse --git-dir --git-common-dir
```

If the two paths differ, you are in a **linked worktree**. If they are the same, you are in the **main worktree**.

## In a linked worktree

1. Commit your work on the current branch under your own name, not the user's:

   ```shell
   git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit
   ```

   Pass the same `-c` options to any other command that creates commits, such as `git rebase --continue`. Do not change the repository's git config.
2. Check for merge conflicts against the **latest** main branch:

   ```shell
   git fetch origin main
   git merge-tree --write-tree --name-only origin/main HEAD
   ```

   A non-zero exit code means there are conflicts; the conflicting files are listed after the tree ID. In that case, rebase on the main branch and resolve the conflicts:

   ```shell
   git rebase origin/main
   # for each conflict: edit the files, then
   git add <resolved-files>
   git rebase --continue
   ```
3. Push the branch: `git push -u origin HEAD`.
4. Tell the user the branch name and a URL to open a GitHub pull request for it:

   ```
   https://github.com/<owner>/<repo>/pull/new/<branch>
   ```

   Take `<owner>/<repo>` from `git remote get-url origin`.

## In the main worktree

Do not commit. Leave your changes in the working tree as they are, and wait for the user to inspect and commit them.
