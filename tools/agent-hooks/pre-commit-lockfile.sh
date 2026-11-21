#!/usr/bin/env bash
# Claude Code PreToolUse hook, wired in .claude/settings.json for `git commit *`.
#
# pubspec.lock and .flutter-plugins-dependencies regenerate on every
# `flutter pub get` / `flutter run` / `build_runner build`, so they often show
# up modified without any dependency change. This blocks a commit that would
# include either file unless the dependency set changed:
#   - pubspec.yaml is part of the same commit, or
#   - the commit command carries a `(deps)` scope (e.g. `chore(deps): ...`),
#     for lock-only upgrades inside the existing version ranges.
#
# Exit 2 blocks the call and shows stderr to the agent; exit 0 allows it.
set -uo pipefail

cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null || true)

# The settings.json `if` filter is best-effort: Claude Code also runs the hook
# when it cannot parse a command. Only gate commands that really run git commit.
if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|({[:space:]])git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

files=$(git diff --cached --name-only 2>/dev/null)
# `git commit -a` / `--all` / `-am ...` also commits tracked, unstaged changes.
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(-[[:alpha:]]*a[[:alpha:]]*|--all)([[:space:]]|$)'; then
  files=$(printf '%s\n%s\n' "$files" "$(git diff --name-only 2>/dev/null)")
fi

lockfiles=$(printf '%s\n' "$files" | grep -Ex 'pubspec\.lock|\.flutter-plugins-dependencies' | sort -u)
[ -z "$lockfiles" ] && exit 0

if printf '%s\n' "$files" | grep -qx 'pubspec\.yaml'; then
  exit 0
fi
if printf '%s' "$cmd" | grep -q '(deps)'; then
  exit 0
fi

{
  echo "Commit blocked: it includes regenerated lock files without a dependency change:"
  printf '  %s\n' $lockfiles
  echo "Drop them with: git restore --staged pubspec.lock .flutter-plugins-dependencies && git checkout pubspec.lock .flutter-plugins-dependencies"
  echo "If the dependency set really changed without a pubspec.yaml edit (lock-only upgrade), use a '(deps)' commit scope, e.g. 'chore(deps): ...'."
} >&2
exit 2
