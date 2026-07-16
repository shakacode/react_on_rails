#!/usr/bin/env bash
# Claude Code PostToolUse hook: advisory RSC security guardrail check for a single file
# after Edit/Write. NON-BLOCKING (always exits 0) — it only adds reminder context.
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
  # Without jq, JSON hook invocations intentionally skip; the manual $1 fallback still works.
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
  # Manual fallback if stdin carried no usable path.
  [ -z "$FILE" ] && FILE="${1:-}"
fi

[ -z "$FILE" ] && exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# Claude supplies an absolute file_path, while the documented manual fallback may be repo-relative.
case "$FILE" in
  /*) ;;
  *) FILE="$REPO_ROOT/$FILE" ;;
esac

[ ! -f "$FILE" ] && exit 0

emit_warning() {
  local warning="$1"

  if command -v jq >/dev/null 2>&1; then
    # Successful PostToolUse hooks must use additionalContext to surface feedback to Claude.
    jq -n --arg warning "$warning" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: $warning
      }
    }'
  else
    # Only manual $1 invocations can reach this branch; JSON hook input cannot be parsed without jq.
    printf '%s\n' "$warning"
  fi
}

# The Ruby streaming concern has one sanctioned inline observability script. Editing that file
# should still surface the escaping contract because its safety relies on Rails escaping helpers,
# not createScriptTag()/escapeScript().
case "$FILE" in
  */react_on_rails_pro/lib/react_on_rails_pro/concerns/stream.rb)
    RUBY_MATCHES="$(grep -nE -- '<script|response\.stream\.write.*script' "$FILE" 2>/dev/null \
      | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
    if [ -n "$RUBY_MATCHES" ]; then
      RUBY_MATCH_LINES="$(printf '%s\n' "$RUBY_MATCHES" | cut -d: -f1 | paste -sd, -)"
      WARNING="$(cat <<EOF
⚠️  rsc-guardrails: the edited Ruby RSC stream source contains script emission.
Preserve ERB::Util.json_escape for JavaScript values and ERB::Util.html_escape for CSP nonces.
Keep the Ruby stream specs aligned with the TypeScript browser-performance-mark helper.
Matched line(s): $RUBY_MATCH_LINES
EOF
)"
      emit_warning "$WARNING"
    fi
    exit 0
    ;;
  */packages/react-on-rails-pro/src/*.ts | */packages/react-on-rails-pro/src/*.tsx) ;;
  *) exit 0 ;;
esac

# Sanctioned emitters that are allowed (and regression-tested) to build inline script tags.
case "$FILE" in
  */injectRSCPayload.ts | */browserPerformanceMarks.ts | */browserPerformanceMarks.tsx) exit 0 ;;
esac

# Anti-patterns: a string/template literal that opens a <script> tag, or a raw-HTML sink.
PATTERN='<script|dangerouslySetInnerHTML|\.innerHTML[[:space:]]*=|insertAdjacentHTML|document\.write\('

# Match, then drop comment lines (JSDoc `*`, `//`, `/*`) to keep the signal high.
MATCHES="$(grep -nE -- "$PATTERN" "$FILE" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*(\*|//|/\*)' || true)"

if [ -n "$MATCHES" ]; then
  MATCH_LINES="$(printf '%s\n' "$MATCHES" | cut -d: -f1 | paste -sd, -)"
  WARNING="$(cat <<EOF
⚠️  rsc-guardrails: the edited RSC source appears to build inline <script>/HTML directly.
RSC payloads and props are user-controlled. Route inline <script> emission through
createScriptTag()/escapeScript() (and nonces through sanitizeNonce) — never hand-built strings.
Read the \`rsc-guardrails\` skill (invariant 1) before shipping. Matched line(s): $MATCH_LINES
EOF
)"
  emit_warning "$WARNING"
fi

exit 0
