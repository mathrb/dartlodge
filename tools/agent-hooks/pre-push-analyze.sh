#!/usr/bin/env bash
# Claude Code PreToolUse hook, wired in .claude/settings.json for `git push *`.
#
# Blocks the push (exit 2, reason on stderr) while a project-wide
# `flutter analyze --no-fatal-infos` reports warnings or errors, the same
# check test.yml runs in CI. Infos are tolerated, as in CI.
#
# Exit codes follow the hook contract: 0 = allow, 2 = block and show stderr
# to the agent, anything else = non-blocking error (push goes ahead).
set -uo pipefail

# The settings.json `if` filter is best-effort: Claude Code also runs the hook
# when it cannot parse a command. Only gate commands that really run git push.
cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null || true)
if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|({[:space:]])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$)'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v flutter >/dev/null 2>&1; then
  echo "pre-push-analyze: flutter is not on PATH; analyze gate skipped." >&2
  exit 1
fi

out=$(flutter analyze --no-fatal-infos 2>&1)
status=$?
issues=$(printf '%s\n' "$out" | grep -E '^\s*(warning|error) •')

if [ -n "$issues" ]; then
  {
    echo "Push blocked: flutter analyze --no-fatal-infos reports warnings/errors (CI would fail):"
    printf '%s\n' "$issues"
  } >&2
  exit 2
fi

if [ "$status" -ne 0 ]; then
  {
    echo "Push blocked: flutter analyze --no-fatal-infos exited $status. Last lines:"
    printf '%s\n' "$out" | tail -n 15
  } >&2
  exit 2
fi

exit 0
