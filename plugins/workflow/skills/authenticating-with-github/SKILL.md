---
name: authenticating-with-github
description: How to give git access to GitHub over HTTPS from the GITHUB_PERSONAL_ACCESS_TOKEN environment variable when no GitHub authentication is set up. Use when a git fetch, pull, push or clone against github.com fails with an authentication error ("could not read Username", "terminal prompts disabled", "Authentication failed", HTTP 401 or 403), or before the first push in an environment where GitHub credentials have not been configured.
---

# Authenticating with GitHub

Set this up only when git has no working GitHub authentication. If something already works (an SSH key, `gh auth setup-git`, a credential manager), leave it alone.

Never print the token: do not `echo` the variable, run `env`, or show the output of `git credential fill`.

## 1. Check whether setup is needed

1. Look at the remote: `git remote get-url origin`.

   If it is an SSH URL (`git@github.com:...` or `ssh://...`), this skill does not apply. Do not rewrite the remote to HTTPS; report the SSH error to the user instead.
2. Ask git whether it can already find a credential for `https://github.com`, discarding the output because it contains the secret:

   ```shell
   printf 'protocol=https\nhost=github.com\n\n' \
     | GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= SSH_ASKPASS= git credential fill >/dev/null 2>&1 \
     && echo "credential available" || echo "no credential"
   ```

   If a credential is available, stop here: authentication is already set up. If git still fails with it, the existing credential is wrong or lacks permission, which is for the user to fix.
3. Check that the token is in the environment:

   ```shell
   [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ] && echo "token set" || echo "token missing"
   ```

   If it is missing, stop and ask the user to provide `GITHUB_PERSONAL_ACCESS_TOKEN` in the session's environment. Do not configure the helper without it: it would answer with an empty password, and git would treat that as a credential and fail.

## 2. Configure the credential helper

Run both commands in the repository, exactly as written. The single quotes matter: `$GITHUB_PERSONAL_ACCESS_TOKEN` must reach the config unexpanded.

```shell
git config --local --replace-all credential.https://github.com.helper ""
git config --local --add credential.https://github.com.helper '!f() { echo "username=x-access-token"; echo "password=$GITHUB_PERSONAL_ACCESS_TOKEN"; }; f'
```

- The first line is an empty helper, which clears any helper inherited from the global or system config for `https://github.com`. Without it, a storing helper such as `store` or a keychain would be handed the token after the first successful request and write it to disk.
- The second line adds a shell function that git runs whenever it needs credentials for `https://github.com`. It answers with the placeholder username `x-access-token` and the token, read from the environment of the git process at that moment.

The config holds only the variable name, so the token is never written to disk. `--local` keeps the change to this repository; linked worktrees share it. Do not use `--global`, and do not put the token in the remote URL.

## 3. Verify

```shell
GIT_TERMINAL_PROMPT=0 git ls-remote --heads origin >/dev/null && echo "read access works"
```

A public repository answers this without credentials, so before relying on a push, check write access too. This contacts GitHub with the token but changes nothing:

```shell
GIT_TERMINAL_PROMPT=0 git push --dry-run origin HEAD
```

Then retry the command that failed.

## If it still fails

- **401 or "Authentication failed"**: the token is invalid or expired. Ask the user for a new one.
- **403, or "Repository not found" for a repository that exists**: the token is valid but lacks access. What git can do is bounded by the token's scopes: a fine-grained token needs the repository selected and `Contents: Read and write` to push; a classic token needs the `repo` scope. Tell the user which operation was refused.
- **The variable is set in your shell but git still fails**: the helper reads the environment of the git process, so the variable must be exported, not just set.

Do not work around a failure by trying other credentials or storing the token somewhere else.
