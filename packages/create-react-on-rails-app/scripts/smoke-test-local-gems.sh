#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
CLI_BIN="$ROOT_DIR/packages/create-react-on-rails-app/bin/create-react-on-rails-app.js"
RUBY_GEM_DIR="$ROOT_DIR/react_on_rails"
RUBY_PRO_GEM_DIR="$ROOT_DIR/react_on_rails_pro"

if [[ ! -d "$RUBY_PRO_GEM_DIR" ]]; then
  echo "react_on_rails_pro not found at $RUBY_PRO_GEM_DIR. Check out the Pro gem before running RSC smoke tests." >&2
  exit 1
fi

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
APP_TS="smoke-ts-$(date +%s)"
APP_JS="smoke-js-$(date +%s)"
APP_RSPACK="smoke-rspack-$(date +%s)"
APP_RSC_JS="smoke-rsc-js-$(date +%s)"
APP_RSC_TS="smoke-rsc-ts-$(date +%s)"
APP_RSC_RSPACK="smoke-rsc-rspack-$(date +%s)"

cleanup_on_error() {
  local status=$?

  if [[ "${KEEP_WORKDIR_ON_FAILURE:-0}" == "1" ]]; then
    echo "Smoke test failed. Generated apps left in: $WORKDIR" >&2
  else
    rm -rf "$WORKDIR"
    echo "Smoke test failed. Removed temp dir: $WORKDIR" >&2
  fi

  exit "$status"
}

trap cleanup_on_error ERR

export CI=true
export REACT_ON_RAILS_GEM_PATH="$RUBY_GEM_DIR"
export REACT_ON_RAILS_PRO_GEM_PATH="$RUBY_PRO_GEM_DIR"

echo "Workdir: $WORKDIR"
echo "Generating TypeScript app: $APP_TS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_TS" --package-manager pnpm)

echo "Generating JavaScript app: $APP_JS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_JS" --template javascript --package-manager pnpm)

echo "Generating Rspack app: $APP_RSPACK"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSPACK" --rspack --package-manager pnpm)

echo "Generating JavaScript RSC app with local Pro gem: $APP_RSC_JS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_JS" --rsc --template javascript --package-manager pnpm)

echo "Generating TypeScript RSC app with local Pro gem: $APP_RSC_TS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_TS" --rsc --template typescript --package-manager pnpm)

echo "Generating Rspack + RSC app with local Pro gem: $APP_RSC_RSPACK"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_RSPACK" --rspack --rsc --package-manager pnpm)

APP_TS_DIR="$WORKDIR/$APP_TS"
APP_JS_DIR="$WORKDIR/$APP_JS"
APP_RSPACK_DIR="$WORKDIR/$APP_RSPACK"
APP_RSC_JS_DIR="$WORKDIR/$APP_RSC_JS"
APP_RSC_TS_DIR="$WORKDIR/$APP_RSC_TS"
APP_RSC_RSPACK_DIR="$WORKDIR/$APP_RSC_RSPACK"

echo "Verifying generated files..."
grep -q "gem \"react_on_rails\"" "$APP_TS_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_TS_DIR/Gemfile"
grep -q "hello_world" "$APP_TS_DIR/config/routes.rb"
test -f "$APP_TS_DIR/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
test -f "$APP_TS_DIR/pnpm-lock.yaml"
! test -f "$APP_TS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_TS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_TS_DIR/bin/setup"

grep -q "gem \"react_on_rails\"" "$APP_JS_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_JS_DIR/Gemfile"
grep -q "hello_world" "$APP_JS_DIR/config/routes.rb"
! grep -q "gem \"react_on_rails_pro\"" "$APP_JS_DIR/Gemfile"
test -f "$APP_JS_DIR/pnpm-lock.yaml"
! test -f "$APP_JS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_JS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_JS_DIR/bin/setup"

grep -q "gem \"react_on_rails\"" "$APP_RSPACK_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_RSPACK_DIR/Gemfile"
grep -q "hello_world" "$APP_RSPACK_DIR/config/routes.rb"
test -f "$APP_RSPACK_DIR/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
grep -q '"@rspack/core"' "$APP_RSPACK_DIR/package.json"
test -f "$APP_RSPACK_DIR/pnpm-lock.yaml"
! test -f "$APP_RSPACK_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSPACK_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSPACK_DIR/bin/setup"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_JS_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_JS_DIR/Gemfile"
grep -q "hello_server" "$APP_RSC_JS_DIR/config/routes.rb"
test -f "$APP_RSC_JS_DIR/app/controllers/hello_server_controller.rb"
test -f "$APP_RSC_JS_DIR/app/views/hello_server/index.html.erb"
test -f "$APP_RSC_JS_DIR/app/javascript/src/HelloServer/components/HelloServer.jsx"
grep -q "stream_react_component('HelloServer'" "$APP_RSC_JS_DIR/app/views/hello_server/index.html.erb"
test -f "$APP_RSC_JS_DIR/pnpm-lock.yaml"
! test -f "$APP_RSC_JS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_JS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_JS_DIR/bin/setup"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_TS_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_TS_DIR/Gemfile"
grep -q "hello_server" "$APP_RSC_TS_DIR/config/routes.rb"
test -f "$APP_RSC_TS_DIR/app/javascript/src/HelloServer/components/HelloServer.tsx"
test -f "$APP_RSC_TS_DIR/pnpm-lock.yaml"
! test -f "$APP_RSC_TS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_TS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_TS_DIR/bin/setup"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_RSPACK_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_RSPACK_DIR/Gemfile"
grep -q "hello_server" "$APP_RSC_RSPACK_DIR/config/routes.rb"
test -f "$APP_RSC_RSPACK_DIR/app/controllers/hello_server_controller.rb"
test -f "$APP_RSC_RSPACK_DIR/app/views/hello_server/index.html.erb"
test -f "$APP_RSC_RSPACK_DIR/app/javascript/src/HelloServer/components/HelloServer.tsx"
grep -q "stream_react_component('HelloServer'" "$APP_RSC_RSPACK_DIR/app/views/hello_server/index.html.erb"
grep -q "\"@rspack/core\"" "$APP_RSC_RSPACK_DIR/package.json"
test -f "$APP_RSC_RSPACK_DIR/pnpm-lock.yaml"
! test -f "$APP_RSC_RSPACK_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_RSPACK_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_RSPACK_DIR/bin/setup"

echo "Smoke test passed."
if [[ "${KEEP_WORKDIR:-0}" == "1" ]]; then
  echo "Generated apps left in: $WORKDIR"
else
  rm -rf "$WORKDIR"
  echo "Cleaned up temp dir: $WORKDIR"
fi
