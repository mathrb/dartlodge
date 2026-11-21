#!/usr/bin/env python3
"""Claude Code PreToolUse hook for Bash, wired in .claude/settings.json.

Usage: git_guard.py push|commit   (hook JSON on stdin)

push   — blocks `git push` from a dartlodge checkout while a project-wide
         `flutter analyze --no-fatal-infos` reports warnings or errors (the
         check test.yml runs in CI; infos are tolerated, as in CI).
commit — blocks a `git commit` that would include pubspec.lock or
         .flutter-plugins-dependencies (they regenerate on every pub get /
         flutter run / build_runner) unless the dependency set changed:
         pubspec.yaml is in the same commit, or the command carries a `(deps)`
         scope (e.g. `chore(deps): ...`) for lock-only upgrades.

A PreToolUse hook runs BEFORE the command, so the script reads the command
itself: it strips heredoc bodies, splits on ; && || | & and newlines, follows
`cd <dir>` and `git -C <dir>` per segment, and counts paths that a `git add`
earlier in the same command is about to stage. The settings.json `if` filter
is best-effort (it also fires on commands Claude Code cannot parse), so a
command without a real `git push` / `git commit` segment is allowed at once.

Exit codes follow the hook contract: 0 = allow, 2 = block and show stderr to
the agent, anything else = non-blocking error (the command goes ahead). These
are guard rails, not a security boundary.
"""

import json
import os
import re
import shlex
import subprocess
import sys

LOCKFILES = {"pubspec.lock", ".flutter-plugins-dependencies"}
SEPARATORS = {";", "&&", "||", "|", "&", "|&", "(", ")", "{", "}"}
# Short options of `git commit` that take a value (the rest of the cluster or
# the next token is that value, so letters after them are not flags).
COMMIT_VALUE_SHORT = set("mFCctS")
# Global git options that take a separate value.
GIT_VALUE_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}

HEREDOC_RE = re.compile(r"<<-?\s*(['\"]?)(\w+)\1")


def strip_heredocs(command):
    """Drop heredoc bodies (they are data, often with unbalanced quotes)."""
    out, lines, i = [], command.split("\n"), 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        delims = [m.group(2) for m in HEREDOC_RE.finditer(line)]
        i += 1
        for delim in delims:
            while i < len(lines) and lines[i].strip() != delim:
                i += 1
            i += 1  # skip the delimiter line
    return "\n".join(out)


def strip_comments(command):
    """Drop shell comments the way bash does: a `#` that starts a word,
    outside quotes, up to the end of its line. (shlex's own comment handling
    also fires mid-word, and after the newline join below a comment would
    swallow the rest of the whole command.)"""
    out, quote, i, n = [], None, 0, len(command)
    while i < n:
        ch = command[i]
        if quote:
            out.append(ch)
            if ch == "\\" and quote == '"' and i + 1 < n:
                out.append(command[i + 1])
                i += 1
            elif ch == quote:
                quote = None
        elif ch == "\\" and i + 1 < n:
            out.append(ch + command[i + 1])
            i += 1
        elif ch in "'\"":
            quote = ch
            out.append(ch)
        elif ch == "#" and (i == 0 or command[i - 1] in " \t\n;&|(){}"):
            while i < n and command[i] != "\n":
                i += 1
            continue
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def segments(command):
    """Yield token lists, one per simple command."""
    text = strip_comments(strip_heredocs(command)).replace("\n", " ; ")
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|(){}")
    lex.commenters = ""
    lex.whitespace_split = True
    current = []
    for tok in lex:
        if tok in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(tok)
    if current:
        yield current


def git_call(tokens, cwd):
    """Return (dir, subcommand, args) if tokens are a git call, else None."""
    i = 0
    while i < len(tokens) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[i]):
        i += 1  # env assignments: FOO=1 git ...
    if i >= len(tokens) or os.path.basename(tokens[i]) != "git":
        return None
    i += 1
    d = cwd
    while i < len(tokens) and tokens[i].startswith("-"):
        opt = tokens[i]
        if opt in GIT_VALUE_OPTS and i + 1 < len(tokens):
            if opt == "-C":
                d = os.path.join(d, os.path.expanduser(tokens[i + 1]))
            i += 2
        else:
            i += 1
    if i >= len(tokens):
        return None
    return d, tokens[i], tokens[i + 1:]


def git(d, *args):
    r = subprocess.run(["git", "-C", d, *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def toplevel(d):
    return git(d, "rev-parse", "--show-toplevel").strip()


def commit_all_flag(args):
    for a in args:
        if a == "--":
            break
        if a == "--all":
            return True
        if a.startswith("-") and not a.startswith("--"):
            for ch in a[1:]:
                if ch == "a":
                    return True
                if ch in COMMIT_VALUE_SHORT:
                    break
    return False


def add_paths(d, args):
    """Repo-relative paths a `git add` with these args is about to stage."""
    flags = [a for a in args if a.startswith("-") and a != "--"]
    specs = [a for a in args if not a.startswith("-")]
    if any(f in ("-u", "--update", "-A", "--all") for f in flags):
        specs = specs or [":/"]
    if not specs:
        return set()
    return set(git(d, "diff", "--name-only", "--", *specs).split())


def check_commit(command, cwd):
    staged_by_add = {}  # toplevel -> paths
    d = cwd
    for tokens in segments(command):
        if tokens[0] == "cd" and len(tokens) > 1:
            d = os.path.join(d, os.path.expanduser(tokens[1]))
            continue
        call = git_call(tokens, d)
        if not call:
            continue
        gd, sub, args = call
        top = toplevel(gd)
        if not top:
            continue
        if sub == "add":
            staged_by_add.setdefault(top, set()).update(add_paths(gd, args))
        elif sub == "commit":
            files = set(git(top, "diff", "--cached", "--name-only").split())
            files |= staged_by_add.get(top, set())
            if commit_all_flag(args):
                files |= set(git(top, "diff", "--name-only").split())
            locks = sorted(files & LOCKFILES)
            if locks and "pubspec.yaml" not in files and "(deps)" not in command:
                print("Commit blocked: it includes regenerated lock files "
                      "without a dependency change:", file=sys.stderr)
                for f in locks:
                    print(f"  {f}", file=sys.stderr)
                print("Drop them with: git restore --staged pubspec.lock "
                      ".flutter-plugins-dependencies && git checkout "
                      "pubspec.lock .flutter-plugins-dependencies",
                      file=sys.stderr)
                print("If the dependency set really changed without a "
                      "pubspec.yaml edit (lock-only upgrade), use a '(deps)' "
                      "commit scope, e.g. 'chore(deps): ...'.", file=sys.stderr)
                return 2
    return 0


def is_dartlodge(top):
    try:
        with open(os.path.join(top, "pubspec.yaml"), encoding="utf-8") as f:
            return re.search(r"^name:\s*dart_lodge\s*$", f.read(), re.M) is not None
    except OSError:
        return False


def check_push(command, cwd):
    d = cwd
    tops = []
    for tokens in segments(command):
        if tokens[0] == "cd" and len(tokens) > 1:
            d = os.path.join(d, os.path.expanduser(tokens[1]))
            continue
        call = git_call(tokens, d)
        if call and call[1] == "push":
            top = toplevel(call[0])
            if top and is_dartlodge(top) and top not in tops:
                tops.append(top)
    for top in tops:
        try:
            r = subprocess.run(["flutter", "analyze", "--no-fatal-infos"],
                               cwd=top, capture_output=True, text=True)
        except FileNotFoundError:
            print("git_guard: flutter is not on PATH; analyze gate skipped.",
                  file=sys.stderr)
            return 1
        out = r.stdout + r.stderr
        issues = [l for l in out.splitlines()
                  if re.match(r"^\s*(warning|error) •", l)]
        if issues:
            print("Push blocked: flutter analyze --no-fatal-infos reports "
                  "warnings/errors (CI would fail):", file=sys.stderr)
            print("\n".join(issues), file=sys.stderr)
            return 2
        if r.returncode != 0:
            print(f"Push blocked: flutter analyze --no-fatal-infos exited "
                  f"{r.returncode}. Last lines:", file=sys.stderr)
            print("\n".join(out.splitlines()[-15:]), file=sys.stderr)
            return 2
    return 0


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    command = (data.get("tool_input") or {}).get("command") or ""
    if not re.search(r"\b(push|commit)\b", command):
        return 0
    cwd = data.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    try:
        if mode == "commit":
            return check_commit(command, cwd)
        if mode == "push":
            return check_push(command, cwd)
    except ValueError as e:  # shlex could not tokenize the command
        print(f"git_guard: could not parse the command ({e}); gate skipped.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
