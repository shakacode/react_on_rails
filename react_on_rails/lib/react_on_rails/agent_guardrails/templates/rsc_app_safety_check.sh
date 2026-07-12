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
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
  [ -z "$FILE" ] && FILE="${1:-}"
fi

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

# Best-effort relative path for display; matching below anchors on the absolute path so it is
# robust to symlinked checkouts and path canonicalization (e.g. /var vs /private/var on macOS).
ROOT="$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
REL="${FILE#"$ROOT/"}"

warn() {
  cat >&2 <<EOF
⚠️  rsc-app-safety: $REL
$1
The React on Rails Pro RSC payload route renders any registered server component with
caller-supplied props and has NO built-in authentication. Confirm this endpoint is behind your
app's auth (a before_action) and that server components derive identity from the session, not
props. Read the \`rsc-app-safety\` skill before shipping.
EOF
}

case "$FILE" in
  */config/routes.rb | */config/routes/*.rb)
    if grep -qE 'rsc_payload_route' "$FILE" 2> /dev/null; then
      warn "This routes file mounts rsc_payload_route (a public RSC endpoint)."
    fi
    ;;
  */app/controllers/*.rb)
    if grep -qE 'RSCPayloadRenderer|rsc_payload' "$FILE" 2> /dev/null &&
      ! grep -qE 'before_action|authenticate|authorize|require_(login|user)' "$FILE" 2> /dev/null; then
      warn "This controller wires an RSC payload renderer but shows no before_action/authentication."
    fi
    ;;
esac

exit 0
