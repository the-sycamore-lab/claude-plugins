# Sycamore Claude Plugins

Shared [Claude Code](https://docs.claude.com/en/docs/claude-code) plugins for the Sycamore organization: common workflow instructions, skills, commands, agents, and hooks that keep how we work with Claude consistent across teams and repositories.

## Init Helper

To set plugins up for everyone without a manual step, add a `SessionStart` hook to the project's `.claude/settings.json`:

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
