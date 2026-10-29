# Sycamore Claude Plugins

Shared [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins for the Sycamore organization: common workflow instructions, skills, commands, agents, and hooks that keep how we work with Claude consistent across teams and repositories.

## Available plugins

| Plugin       | Description                                                                                                                                                                           |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `workflow`   | Common Sycamore workflow instructions, e.g. the `finishing-work` skill for wrapping up tasks, and a `SessionStart` hook that bases new worktree branches on the latest `origin/main`. |
| `typescript` | Sycamore TypeScript coding conventions, provided as the `typescript-conventions` skill that Claude applies when creating or updating `.ts`/`.tsx` files.                              |

## Setup

### 1. Configure the project

Add the `sycamore` marketplace and enable the plugins you want in the project's `.claude/settings.json`, and commit it so everyone on the project gets the same configuration:

```json
{
  "extraKnownMarketplaces": {
    "sycamore": {
      "source": {
        "source": "github",
        "repo": "the-sycamore-lab/claude-plugins"
      },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "workflow@sycamore": true,
    "typescript@sycamore": true
  }
}
```

Plugins are referenced as `<plugin>@<marketplace>`, so every plugin from this repo ends in `@sycamore`.

When someone trusts the project folder in Claude Code, they are prompted to install the marketplace and enabled plugins. To skip that manual step, use the init helper below.

### 2. Install automatically (optional)

The [init.sh](init.sh) script reads `.claude/settings.json`, registers every marketplace in `extraKnownMarketplaces`, and installs every plugin set to `true` in `enabledPlugins` at project scope. Anything already installed is skipped, so it is safe to run on every session.

To run it for everyone, add a `SessionStart` hook to the same `.claude/settings.json`:

```json
"hooks": {
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "curl -fsSL https://raw.githubusercontent.com/the-sycamore-lab/claude-plugins/main/init.sh | bash",
          "statusMessage": "Initializing plugins..."
        }
      ]
    }
  ]
}
```
