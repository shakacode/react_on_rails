#!/usr/bin/env bash
# PreToolUse:Bash wrapper that surfaces main CI status only when the next Bash
# command is about to push to main or open a PR. Fail-open: any unexpected
# input or tooling error exits 0 without output so we never block a tool call.

set -u

# Claude Code passes tool input as JSON on stdin. Extract the command string.
# If jq is missing or the input is malformed, exit silently.
command -v jq >/dev/null 2>&1 || exit 0
input=$(cat 2>/dev/null) || exit 0
cmd=$(printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "${cmd}" ] || exit 0

# Match:
#   - `gh pr create` (any args)
#   - explicit `git push ... origin main` or `git push ... origin HEAD`
#   - ANY `git push` invocation while currently checked out on `main` — this
#     covers the common shortcuts that would otherwise slip past us:
#       `git push`              (bare, with upstream tracking main)
#       `git push origin`       (no refspec — pushes matching branches)
#       `git push -u origin main` (already covered by explicit match)
#     The current-branch check keeps over-triggering minimal on feature work.
matched=0
if [[ "${cmd}" =~ (^|[[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$) ]]; then
  matched=1
elif [[ "${cmd}" =~ (^|[[:space:]])git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+origin[[:space:]]+(main|HEAD)([[:space:]]|$) ]]; then
  matched=1
elif [[ "${cmd}" =~ (^|[[:space:]])git[[:space:]]+push([[:space:]]|$) ]]; then
  # Any `git push` — check whether the current branch is main.
  script_repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  current_branch=$(git -C "${script_repo_root}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [ "${current_branch}" = "main" ]; then
    matched=1
  fi
fi

[ "${matched}" -eq 1 ] || exit 0

# Run the underlying status script. Its output goes to stdout, which Claude
# Code injects into context.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${script_dir}/main-ci-status.sh"
