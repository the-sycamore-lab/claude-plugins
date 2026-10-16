#!/usr/bin/env bash
# Install the marketplaces and plugins declared in a project's .claude/settings.json.
#
# Usage (from the project root):
#   curl -fsSL <url>/init.sh | bash
#   curl -fsSL <url>/init.sh | bash -s -- path/to/.claude/settings.json

# Everything lives in main(), which is only called on the last line. This keeps a
# truncated download from running a partial script, and since bash reads this script
# from stdin under `curl | bash`, every child command below has stdin redirected so it
# can't swallow the rest of the script.
main() {
  set -uo pipefail

  local settings="${1:-.claude/settings.json}"

  local cmd
  for cmd in jq claude; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: '$cmd' is required but not found in PATH." >&2
      exit 1
    fi
  done

  if [[ ! -f "$settings" ]]; then
    echo "Settings file not found: $settings" >&2
    echo "Run this from your project root, or pass the path: curl ... | bash -s -- path/to/settings.json" >&2
    exit 1
  fi

  if ! jq empty "$settings" </dev/null 2>/dev/null; then
    echo "Error: $settings is not valid JSON." >&2
    exit 1
  fi

  # --scope project installs are tied to the directory containing .claude/
  settings="$(cd "$(dirname "$settings")" && pwd -P)/$(basename "$settings")"
  local project_root
  project_root=$(cd "$(dirname "$settings")/.." && pwd -P)
  cd "$project_root" || exit 1

  # `claude plugin ... --scope project` writes to the settings file. Back it up and
  # restore it on exit so running this script leaves the file untouched. The trap is
  # expanded now because main's locals are gone by the time it fires.
  local backup
  backup=$(mktemp) || exit 1
  cp -p "$settings" "$backup" || exit 1
  # shellcheck disable=SC2064
  trap "cmp -s $(printf %q "$backup") $(printf %q "$settings") \
    || cp $(printf %q "$backup") $(printf %q "$settings"); \
    rm -f $(printf %q "$backup")" EXIT

  local plugins
  plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$settings" </dev/null)

  if [[ -z "$plugins" ]]; then
    echo "No enabled plugins found in $settings"
    exit 0
  fi

  local installed_marketplaces installed_plugins
  installed_marketplaces=$(claude plugin marketplace list --json </dev/null 2>/dev/null | jq -r '.[].name' 2>/dev/null)
  # Only count user-scope installs or ones for this project; project-scope installs
  # for other projects show up in the list too.
  installed_plugins=$(claude plugin list --json </dev/null 2>/dev/null \
    | jq -r --arg root "$project_root" \
      '.[] | select(.scope == "user" or .projectPath == $root) | .id' 2>/dev/null)

  local failed=()

  # Map each marketplace source to something `claude plugin marketplace add` accepts.
  local extra_marketplaces
  extra_marketplaces=$(jq -r '
    .extraKnownMarketplaces // {} | to_entries[]
    | [.key, (.value.source | .repo // .url // .path // "")] | @tsv
  ' "$settings" </dev/null)

  if [[ -n "$extra_marketplaces" ]]; then
    echo "Registering extra marketplaces..."
    local name source
    while IFS=$'\t' read -r name source; do
      if grep -qxF "$name" <<< "$installed_marketplaces"; then
        echo "→ $name (already registered)"
        continue
      fi
      if [[ -z "$source" ]]; then
        echo "→ $name (unsupported source type, skipping)"
        failed+=("marketplace $name")
        continue
      fi
      echo "→ $name ($source)"
      if ! claude plugin marketplace add --scope project "$source" </dev/null; then
        failed+=("marketplace $name")
      fi
    done <<< "$extra_marketplaces"
  fi

  echo "Installing plugins from $settings..."
  local plugin
  while IFS= read -r plugin; do
    if grep -qxF "$plugin" <<< "$installed_plugins"; then
      echo "→ $plugin (already installed)"
      continue
    fi
    echo "→ $plugin"
    if ! claude plugin install --scope project "$plugin" </dev/null; then
      failed+=("$plugin")
    fi
  done <<< "$plugins"

  if [[ ${#failed[@]} -gt 0 ]]; then
    echo ""
    echo "⚠ The following could not be installed:"
    local p
    for p in "${failed[@]}"; do
      echo "  - $p"
    done
    exit 1
  fi

  echo "Done."
}

main "$@"
