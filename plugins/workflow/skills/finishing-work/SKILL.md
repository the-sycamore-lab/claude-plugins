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

1. Commit your work on the current branch.
2. Push the branch: `git push -u origin HEAD`.
3. Tell the user the branch name and a URL to open a GitHub pull request for it:

   ```
   https://github.com/<owner>/<repo>/pull/new/<branch>
   ```

   Take `<owner>/<repo>` from `git remote get-url origin`.

## In the main worktree

Do not commit. Leave your changes in the working tree as they are, and wait for the user to inspect and commit them.
