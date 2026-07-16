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

exclude_exact_source_line() {
  local safe_line="$1"
  local match
  local source_line

  while IFS= read -r match; do
    source_line="${match#*:}"
    source_line="${source_line#"${source_line%%[![:space:]]*}"}"
    source_line="${source_line%"${source_line##*[![:space:]]}"}"
    if [ "$source_line" != "$safe_line" ]; then
      printf '%s\n' "$match"
    fi
  done
}

exclude_parser_only_replace_line() {
  local match
  local script_token_count
  local source_line

  while IFS= read -r match; do
    source_line="${match#*:}"
    if printf '%s\n' "$source_line" \
      | grep -Eq -- "\.replace\(/\^<script\[\^>\]\*>/i, ''\);?[[:space:]]*$"; then
      script_token_count="$(printf '%s\n' "$source_line" | grep -oiF -- '<script' | wc -l)"
      if [ "$script_token_count" -eq 1 ]; then
        continue
      fi
    fi
    printf '%s\n' "$match"
  done
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

# Scan script-tag text separately so parser-only and exact sanctioned shapes can be excluded without
# ever suppressing a raw-HTML sink that happens to share the same line.
SAFE_LAST_INDEX_LINE="const scriptStartIndex = htmlString.lastIndexOf('<script', revealCallIndex);"
SAFE_DOUBLE_ESCAPE_PATTERN_LINE='const SCRIPT_DOUBLE_ESCAPE_OPEN_PATTERN = /<script(?=[\s>/])/gi;'
SAFE_SCAN_OVERLAP_LINE="const SCRIPT_SCAN_OVERLAP_LENGTH = Math.max('<!--'.length, '-->'.length, '<script'.length, '</script'.length);"
SAFE_CREATE_SCRIPT_TAG_LINE="return \`<script\${rscPayloadScriptMarkerAttribute(markAsRSCPayload)}\${nonceAttribute(sanitizedNonce)}>\${escapeScript(script)}</script>\`;"
SCRIPT_MATCHES="$(grep -niF -- '<script' "$FILE" 2>/dev/null \
  | grep -vE '^[0-9]+:[[:space:]]*(\*|//|/\*)' \
  | exclude_parser_only_replace_line \
  | exclude_exact_source_line "$SAFE_LAST_INDEX_LINE" \
  | exclude_exact_source_line "$SAFE_DOUBLE_ESCAPE_PATTERN_LINE" \
  | exclude_exact_source_line "$SAFE_SCAN_OVERLAP_LINE" || true)"

# This exact emitter is sanctioned only at its definition site. Applying the exemption to another
# file would trust a potentially shadowed escapeScript implementation.
case "$FILE" in
  */injectRSCPayload.ts)
    SCRIPT_MATCHES="$(printf '%s\n' "$SCRIPT_MATCHES" \
      | exclude_exact_source_line "$SAFE_CREATE_SCRIPT_TAG_LINE" || true)"
    ;;
esac

# Raw-HTML sinks are never allowlisted. Keep this scan independent from script/parser filtering.
SINK_PATTERN='dangerouslySetInnerHTML|\.innerHTML[[:space:]]*=|insertAdjacentHTML|document\.write\('
SINK_MATCHES="$(grep -nE -- "$SINK_PATTERN" "$FILE" 2>/dev/null \
  | grep -vE '^[0-9]+:[[:space:]]*(\*|//|/\*)' || true)"

# A line may match both scans; merge in line order and remove exact duplicates.
MATCHES="$(printf '%s\n%s\n' "$SCRIPT_MATCHES" "$SINK_MATCHES" \
  | grep -vE '^$' \
  | LC_ALL=C sort -t: -k1,1n -u || true)"

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
