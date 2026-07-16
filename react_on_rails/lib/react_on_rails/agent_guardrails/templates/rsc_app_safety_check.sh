#!/usr/bin/env bash
# Claude Code PostToolUse hook — installed by `rake react_on_rails:install_rsc_agent_guardrails`.
# NON-BLOCKING advisory (always exits 0). Warns when React on Rails Pro RSC endpoints are wired
# without visible authentication. The RSC payload route renders any registered server component
# with caller-supplied props and has NO built-in auth — see the `rsc-app-safety` skill.
#
# Claude Code pipes a JSON object on stdin with tool_input.file_path. Falls back to $1 for manual
# testing (e.g. `echo '' | .claude/hooks/rsc-app-safety-check.sh config/routes.rb`).
set -euo pipefail

if [ -t 0 ]; then
  FILE="${1:-}"
else
  INPUT="$(cat)"
  FILE="$(printf '%s' "$INPUT" | ruby -rjson -e \
    'puts(JSON.parse($stdin.read).dig("tool_input", "file_path").to_s)' 2>/dev/null || true)"
  [ -z "$FILE" ] && FILE="${1:-}"
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Best-effort relative path for display; matching below anchors on the absolute path so it is
# robust to symlinked checkouts and path canonicalization (e.g. /var vs /private/var on macOS).
ROOT="$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
REL="${FILE#"$ROOT/"}"

warn() {
  local message
  message="$(printf '%s\n' \
    "⚠️  rsc-app-safety: $REL" \
    "$1" \
    "The React on Rails Pro RSC payload route renders any registered server component with" \
    "caller-supplied props and has NO built-in authentication. Confirm this endpoint is behind your" \
    "app's auth via config.rsc_payload_authorizer or an app-owned controller's before_action, and" \
    "that server components derive identity from the session, not props. Read the rsc-app-safety" \
    "skill before shipping.")"
  ruby -rjson -e 'puts JSON.generate(
    "hookSpecificOutput" => { "hookEventName" => "PostToolUse", "additionalContext" => ARGV.fetch(0) }
  )' "$message"
}

has_authentication_evidence() {
  ruby - "$FILE" <<'RUBY'
auth_name = /(?:authenticate\w*[!?]?|authorize\w*[!?]?|require_(?:login|user)\w*[!?]?)/
lines = File.readlines(ARGV.fetch(0))
uncommented = lines.map { |line| line.sub(/#.*/, "") }
scope_syntax = /(?:%[iw](?:\[[^\]]*\]|\([^)]*\)|\{[^}]*\})|\[[^\]]*\]|:[A-Za-z_]\w*[!?]?|["'][^"']+["'])/
authenticated_callbacks = []

uncommented.each_with_index do |line, index|
  next unless line.match?(/^\s*before_action\b/)

  statement = line.dup
  while index + 1 < uncommented.length &&
        (statement.rstrip.end_with?(",", "\\") ||
         statement.count("(") > statement.count(")") ||
         statement.count("[") > statement.count("]"))
    index += 1
    statement << uncommented[index]
  end

  statement = statement.gsub(/\s+/, " ").strip
  callback = statement.match(
    /\Abefore_action\s*(?<parenthesized>\()?\s*:?(?<auth>#{auth_name})(?<rest>.*)\z/
  )
  next unless callback

  rest = callback[:rest].strip
  rest = rest.sub(/\)\z/, "").strip if callback[:parenthesized]
  if rest.empty?
    authenticated_callbacks << callback[:auth]
  elsif (scope = rest.match(/\A,\s*only:\s*(#{scope_syntax})\z/))
    authenticated_callbacks << callback[:auth] if scope[1].match?(/\brsc_payload\b/)
  elsif (scope = rest.match(/\A,\s*except:\s*(#{scope_syntax})\z/))
    authenticated_callbacks << callback[:auth] unless scope[1].match?(/\brsc_payload\b/)
  end
end

uncommented.each_with_index do |line, index|
  next unless line.match?(/^\s*skip_before_action\b/)

  statement = line.dup
  while index + 1 < uncommented.length &&
        (statement.rstrip.end_with?(",", "\\") ||
         statement.count("(") > statement.count(")") ||
         statement.count("[") > statement.count("]"))
    index += 1
    statement << uncommented[index]
  end

  statement = statement.gsub(/\s+/, " ").strip
  callback = statement.match(
    /\Askip_before_action\s*(?<parenthesized>\()?\s*:?(?<auth>#{auth_name})(?<rest>.*)\z/
  )
  next unless callback && authenticated_callbacks.include?(callback[:auth])

  rest = callback[:rest].strip
  rest = rest.sub(/\)\z/, "").strip if callback[:parenthesized]
  skip_applies = if rest.empty?
                   true
                 elsif (scope = rest.match(/\A,\s*only:\s*(#{scope_syntax})\z/))
                   scope[1].match?(/\brsc_payload\b/)
                 elsif (scope = rest.match(/\A,\s*except:\s*(#{scope_syntax})\z/))
                   !scope[1].match?(/\brsc_payload\b/)
                 else
                   true
                 end
  authenticated_callbacks.delete(callback[:auth]) if skip_applies
end

exit(authenticated_callbacks.empty? ? 1 : 0)
RUBY
}

case "$FILE" in
  config/routes.rb | */config/routes.rb | config/routes/*.rb | */config/routes/*.rb)
    if ruby -e 'exit(File.foreach(ARGV.fetch(0)).any? { |line| line.sub(/#.*/, "").include?("rsc_payload_route") } ? 0 : 1)' \
      "$FILE"; then
      warn "This routes file mounts rsc_payload_route (a public RSC endpoint)."
    fi
    ;;
  app/controllers/*.rb | */app/controllers/*.rb)
    if grep -qE 'RSCPayloadRenderer|rsc_payload' "$FILE" 2> /dev/null &&
      ! has_authentication_evidence; then
      warn "This controller wires an RSC payload renderer but shows no before_action/authentication."
    fi
    ;;
esac

exit 0
