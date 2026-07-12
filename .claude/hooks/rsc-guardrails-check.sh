#!/usr/bin/env bash
# Claude Code PostToolUse hook: advisory RSC security guardrail check for a single file
# after Edit/Write. NON-BLOCKING (always exits 0) — it only prints a reminder.
#
# It warns when a React on Rails Pro RSC/streaming source file introduces a hand-built inline
# <script> string or a raw-HTML sink that bypasses the sanctioned escaping helpers. RSC payloads
# and props are user-controlled, so inline <script> emission must go through
# createScriptTag()/escapeScript() (see the `rsc-guardrails` skill, invariant 1).
#
# Claude Code pipes a JSON object on stdin with tool_input.file_path. Falls back to $1 for
# manual testing (e.g. `echo '' | .claude/hooks/rsc-guardrails-check.sh path/to/file.ts`).
set -euo pipefail

if [ -t 0 ]; then
  FILE="${1:-}"
else
  INPUT="$(cat)"
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
  # Manual fallback if stdin carried no usable path.
  [ -z "$FILE" ] && FILE="${1:-}"
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REL_PATH="${FILE#"$REPO_ROOT/"}"

# Only React on Rails Pro RSC/streaming TypeScript sources.
case "$REL_PATH" in
  packages/react-on-rails-pro/src/*.ts | packages/react-on-rails-pro/src/*.tsx) ;;
  *) exit 0 ;;
esac

# Sanctioned emitters that are allowed (and regression-tested) to build inline script tags.
case "$REL_PATH" in
  */injectRSCPayload.ts | */browserPerformanceMarks.ts | */browserPerformanceMarks.tsx) exit 0 ;;
esac

# Anti-patterns: a string/template literal that opens a <script> tag, or a raw-HTML sink.
PATTERN='[`'"'"'"]<script|dangerouslySetInnerHTML|\.innerHTML[[:space:]]*=|insertAdjacentHTML|document\.write\('

# Match, then drop comment lines (JSDoc `*`, `//`, `/*`) to keep the signal high.
MATCHES="$(grep -nE "$PATTERN" "$REL_PATH" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*(\*|//|/\*)' || true)"

if [ -n "$MATCHES" ]; then
  cat >&2 <<EOF
⚠️  rsc-guardrails: $REL_PATH appears to build inline <script>/HTML directly.
RSC payloads and props are user-controlled. Route inline <script> emission through
createScriptTag()/escapeScript() (and nonces through sanitizeNonce) — never hand-built strings.
Read the \`rsc-guardrails\` skill (invariant 1) before shipping. Matched:
$MATCHES
EOF
fi

exit 0
