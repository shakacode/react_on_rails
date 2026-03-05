#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
CLI_BIN="$ROOT_DIR/packages/create-react-on-rails-app/bin/create-react-on-rails-app.js"
RUBY_GEM_DIR="$ROOT_DIR/react_on_rails"
RUBY_PRO_GEM_DIR="$ROOT_DIR/react_on_rails_pro"

if ! command -v rails >/dev/null 2>&1; then
  if bundle exec which rails >/dev/null 2>&1; then
    RAILS_BIN_DIR="$(dirname "$(bundle exec which rails)")"
    export PATH="$RAILS_BIN_DIR:$PATH"
  else
    echo "Rails not found. Install Rails or ensure 'bundle exec which rails' works." >&2
    exit 1
  fi
fi

PNPM_CMD=()
if command -v corepack >/dev/null 2>&1; then
  PNPM_CMD=(corepack pnpm)
elif command -v pnpm >/dev/null 2>&1; then
  PNPM_CMD=(pnpm)
else
  echo "pnpm (or corepack) is required for this smoke test." >&2
  exit 1
fi

echo "Building create-react-on-rails-app..."
"${PNPM_CMD[@]}" --filter create-react-on-rails-app run build >/dev/null

WORKDIR="$(mktemp -d /tmp/create-ror-local-smoke-XXXXXX)"
APP_JS="smoke-js-$(date +%s)"
APP_RSC="smoke-rsc-$(date +%s)"

export CI=true
export REACT_ON_RAILS_GEM_PATH="$RUBY_GEM_DIR"
export REACT_ON_RAILS_PRO_GEM_PATH="$RUBY_PRO_GEM_DIR"

echo "Workdir: $WORKDIR"
echo "Generating JavaScript app: $APP_JS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_JS" --template javascript --package-manager pnpm)

echo "Generating RSC app with local Pro gem: $APP_RSC"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC" --rsc --template javascript --package-manager pnpm)

APP_JS_DIR="$WORKDIR/$APP_JS"
APP_RSC_DIR="$WORKDIR/$APP_RSC"

echo "Verifying generated files..."
grep -q "gem \"react_on_rails\"" "$APP_JS_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_JS_DIR/Gemfile"
grep -q "hello_world" "$APP_JS_DIR/config/routes.rb"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_DIR/Gemfile"
grep -q "hello_server" "$APP_RSC_DIR/config/routes.rb"
grep -q "rsc_payload_route" "$APP_RSC_DIR/config/routes.rb"
test -f "$APP_RSC_DIR/app/controllers/hello_server_controller.rb"
test -f "$APP_RSC_DIR/app/views/hello_server/index.html.erb"

echo "Smoke test passed."
echo "Generated apps left in: $WORKDIR"
