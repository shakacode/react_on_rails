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

exclude_type_only_dangerously_set_inner_html() {
  # React types dangerouslySetInnerHTML as `{ __html: string | TrustedHTML }`. A TypeScript
  # type/interface member such as `type Props = { dangerouslySetInnerHTML: { __html: string } };`
  # is a declaration, not a runtime raw-HTML sink, so drop object-property matches whose __html
  # value is a bare TypeScript type token rather than a runtime expression. Real sinks assign a
  # variable/expression (e.g. `{ __html: userHtml }`), never the literal identifier
  # `string`/`TrustedHTML`. (Destructuring aliases like `{ dangerouslySetInnerHTML: forwarded }`
  # are already excluded upstream because the sink pattern requires a `{ ... __html` object value.)
  local match
  local source_line
  while IFS= read -r match; do
    source_line="${match#*:}"
    if printf '%s\n' "$source_line" \
      | grep -Eq -- 'dangerouslySetInnerHTML[[:space:]]*:[[:space:]]*\{[[:space:]]*__html[[:space:]]*:[[:space:]]*(string|TrustedHTML)([[:space:]]*\|[[:space:]]*(string|TrustedHTML))*[[:space:]]*\}'; then
      continue
    fi
    printf '%s\n' "$match"
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

# The single-line sink scan requires `dangerouslySetInnerHTML` and its `{ ... __html }` object value
# on the same physical line. Prettier commonly splits real object-property/JSX sinks across lines, e.g.
#   const props = { dangerouslySetInnerHTML: {
#     __html: userHtml,
#   } };
# leaving the property line without `__html`, so the single-line scan misses it. This bounded detector
# catches that shape: for a property/JSX line that opens an object literal (ends with `{`/`{{`) and has
# no `__html` yet, it scans a few following lines for the `__html:` value and warns only when that value
# is a real raw-HTML sink — a variable/expression — while honoring the same exemptions as the single-line
# path (TypeScript type tokens like `string`/`TrustedHTML`, and non-interpolated string/template literals,
# which are not user-controlled). Kept intentionally shallow to avoid false positives.
detect_multiline_dangerously_set_inner_html() {
  local file="$1"
  local -r max_lookahead=5
  local -a lines=()
  local line la val first_char found leading n i j

  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done < "$file"

  n=${#lines[@]}
  for ((i = 0; i < n; i++)); do
    line="${lines[i]}"
    leading="${line#"${line%%[![:space:]]*}"}"
    case "$leading" in //* | \** | /\**) continue ;; esac
    # Only opener lines: mention the prop, no same-line __html (single-line scan owns that), and the
    # object literal starts here (line ends with `: {`, `={` or `={{`).
    [[ "$line" == *dangerouslySetInnerHTML* ]] || continue
    [[ "$line" == *__html* ]] && continue
    printf '%s' "$line" \
      | grep -Eq -- 'dangerouslySetInnerHTML[[:space:]]*(:[[:space:]]*\{|=[[:space:]]*\{\{?)[[:space:]]*$' \
      || continue

    found=0
    for ((j = i + 1; j < n && j <= i + max_lookahead; j++)); do
      la="${lines[j]}"
      leading="${la#"${la%%[![:space:]]*}"}"
      case "$leading" in //* | \** | /\**) continue ;; esac
      if printf '%s' "$la" | grep -Eq -- '__html[[:space:]]*:'; then
        val="$(printf '%s' "$la" | sed -E 's/.*__html[[:space:]]*:[[:space:]]*//; s/[[:space:]]*[,;}].*$//; s/[[:space:]]+$//')"
        # TypeScript type-only member (e.g. `__html: string | TrustedHTML`) — a declaration, not a sink.
        if printf '%s' "$val" | grep -Eq -- '^(string|TrustedHTML)([[:space:]]*\|[[:space:]]*(string|TrustedHTML))*$'; then
          break
        fi
        first_char="${val:0:1}"
        # Plain quoted string literal — not user-controlled.
        if [ "$first_char" = "'" ] || [ "$first_char" = '"' ]; then
          break
        fi
        # Template literal with no `${...}` interpolation — also not user-controlled.
        # shellcheck disable=SC2016  # literal ${ is intentional; we are searching for the token, not expanding it
        if [ "$first_char" = '`' ] && ! printf '%s' "$val" | grep -qF -- '${'; then
          break
        fi
        # Anything else (variable, member access, call, interpolated template) is a real raw-HTML sink.
        found=1
        break
      fi
      # Inner object closed before any `__html` appeared — nothing identifiable to flag.
      [[ "$la" == *"}"* ]] && break
    done

    if [ "$found" -eq 1 ]; then
      printf '%d:%s\n' "$((i + 1))" "$line"
    fi
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
Never interpolate RSC payload or prop values into the inline script without those escaping helpers.
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
#
# MAINTENANCE CONTRACT: the SAFE_*_LINE constants below are exact, byte-for-byte copies of specific
# lines in packages/react-on-rails-pro/src/injectRSCPayload.ts. They MUST be kept in sync with that
# source — a prettier re-wrap, a rename, or a trailing comment on any of these lines will stop the
# exemption from matching, and this advisory (never-blocking) hook will then emit a false-positive
# warning the next time the file is edited. Exact-match is deliberate over a looser structural
# signature (e.g. "escapeScript( before </script>"): for a security guardrail, a slightly noisy
# false positive on sanctioned code is far safer than a structural pattern that could silently
# exempt a genuinely unsafe emitter that happens to resemble the sanctioned shape. If you reformat
# injectRSCPayload.ts, update these strings (the focused hook regression suite will catch drift).
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
  */packages/react-on-rails-pro/src/injectRSCPayload.ts)
    SCRIPT_MATCHES="$(printf '%s\n' "$SCRIPT_MATCHES" \
      | exclude_exact_source_line "$SAFE_CREATE_SCRIPT_TAG_LINE" || true)"
    ;;
esac

# Raw-HTML sinks are never allowlisted. Keep this scan independent from script/parser filtering.
# The dangerouslySetInnerHTML branch matches a JSX assignment (`={...}`) or an object-property sink
# whose value is a `{ ... __html }` object literal. Requiring the object value excludes destructuring
# aliases (`{ dangerouslySetInnerHTML: forwarded }`) and property reads/forwarding, which emit no HTML.
DANGEROUSLY_SET_INNER_HTML_PATTERN="dangerouslySetInnerHTML[[:space:]]*(=([^=]|\$)|:[[:space:]]*\\{[^}]*__html)"
RAW_HTML_PROPERTY_PATTERN="(\\.(inner|outer)HTML|\\[[[:space:]]*['\"](inner|outer)HTML['\"][[:space:]]*\\])"
ASSIGNMENT_OPERATOR_PATTERN='([-+*/%&|^?]|[*][*]|<<|>>|>>>|&&|[|][|]|[?][?])?='
SINK_PATTERN="${DANGEROUSLY_SET_INNER_HTML_PATTERN}|${RAW_HTML_PROPERTY_PATTERN}[[:space:]]*${ASSIGNMENT_OPERATOR_PATTERN}([^=]|\$)|insertAdjacentHTML|document\\.write\\("
SINK_MATCHES="$(grep -nE -- "$SINK_PATTERN" "$FILE" 2>/dev/null \
  | grep -vE '^[0-9]+:[[:space:]]*(\*|//|/\*)' \
  | exclude_type_only_dangerously_set_inner_html || true)"

# Catch prettier-split object/JSX dangerouslySetInnerHTML sinks the line-oriented scan cannot see.
MULTILINE_SINK_MATCHES="$(detect_multiline_dangerously_set_inner_html "$FILE" || true)"

# A line may match multiple scans; merge in line order and remove exact duplicates.
MATCHES="$(printf '%s\n%s\n%s\n' "$SCRIPT_MATCHES" "$SINK_MATCHES" "$MULTILINE_SINK_MATCHES" \
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
