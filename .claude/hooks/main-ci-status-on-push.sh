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
#   - explicit `git push ... origin main`, `HEAD`, or `refs/heads/main`
#   - refspecs that update main (e.g. `HEAD:main`,
#     `HEAD:refs/heads/main`, `feature:refs/heads/main`)
#   - multi-ref pushes that may update main (`--all`, `--mirror`)
#   - `git -C <path> push ...` forms, via intentionally broad `git ... push`
#     detection
#   - ANY `git push` invocation while currently checked out on `main` —
#     covers the common shortcuts: `git push`, `git push origin`,
#     `git push -u`, etc.
#
# We deliberately over-trigger rather than try to enumerate every form
# of `git push`. The 5-minute SHA-keyed cache makes the cost negligible,
# and a false negative ("agent silently pushed to main without seeing
# CI status") is much worse than a false positive ("status shown
# before a feature-branch push").
matched=0
if [[ "${cmd}" =~ (^|[[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$) ]]; then
  matched=1
elif [[ "${cmd}" =~ (^|[[:space:]])git([[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$) ]]; then
  if [[ "${cmd}" =~ (^|[[:space:]])--(all|mirror)([[:space:]]|$) ]]; then
    matched=1
  elif [[ "${cmd}" =~ (^|[[:space:]:/])refs/heads/main([[:space:]]|$) ]]; then
    matched=1
  elif [[ "${cmd}" =~ (^|[[:space:]:])main([[:space:]]|$) ]]; then
    matched=1
  elif [[ "${cmd}" =~ (^|[[:space:]])HEAD(:refs/heads/main|:main)?([[:space:]]|$) ]]; then
    matched=1
  fi

  # Any other `git push` — check whether the current branch is main.
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
