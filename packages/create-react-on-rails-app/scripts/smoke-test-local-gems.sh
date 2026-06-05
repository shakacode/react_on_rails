#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
CLI_BIN="$ROOT_DIR/packages/create-react-on-rails-app/bin/create-react-on-rails-app.js"
RUBY_GEM_DIR="$ROOT_DIR/react_on_rails"
RUBY_PRO_GEM_DIR="$ROOT_DIR/react_on_rails_pro"
SMOKE_SCOPE="${CREATE_ROR_SMOKE_SCOPE:-full}"

case "$SMOKE_SCOPE" in
  full | oss) ;;
  *)
    echo "Unsupported CREATE_ROR_SMOKE_SCOPE=$SMOKE_SCOPE. Use 'full' or 'oss'." >&2
    exit 1
    ;;
esac

if [[ "$SMOKE_SCOPE" == "full" ]]; then
  if [[ ! -d "$RUBY_PRO_GEM_DIR" ]]; then
    echo "react_on_rails_pro not found at $RUBY_PRO_GEM_DIR. Check out the Pro gem before running RSC smoke tests." >&2
    echo "Set CREATE_ROR_SMOKE_SCOPE=oss to run only OSS generated-app smoke tests." >&2
    exit 1
  fi
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
APP_PRO="smoke-pro-$(date +%s)"
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
if [[ "$SMOKE_SCOPE" == "full" ]]; then
  export REACT_ON_RAILS_PRO_GEM_PATH="$RUBY_PRO_GEM_DIR"
fi

echo "Workdir: $WORKDIR"
echo "Smoke scope: $SMOKE_SCOPE"
echo "Generating TypeScript Webpack app: $APP_TS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_TS" --standard --webpack --package-manager pnpm)

echo "Generating JavaScript Webpack app: $APP_JS"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_JS" --standard --template javascript --webpack --package-manager pnpm)

echo "Generating Rspack app: $APP_RSPACK"
(cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSPACK" --standard --rspack --package-manager pnpm)

if [[ "$SMOKE_SCOPE" == "full" ]]; then
  echo "Generating Pro Webpack app: $APP_PRO"
  (cd "$WORKDIR" && node "$CLI_BIN" "$APP_PRO" --pro --webpack --package-manager pnpm)

  echo "Generating JavaScript RSC Webpack app with local Pro gem: $APP_RSC_JS"
  (cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_JS" --rsc --template javascript --webpack --package-manager pnpm)

  echo "Generating TypeScript RSC Webpack app with local Pro gem: $APP_RSC_TS"
  (cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_TS" --rsc --template typescript --webpack --package-manager pnpm)

  echo "Generating Rspack + RSC app with local Pro gem: $APP_RSC_RSPACK"
  (cd "$WORKDIR" && node "$CLI_BIN" "$APP_RSC_RSPACK" --rspack --rsc --package-manager pnpm)
fi

APP_TS_DIR="$WORKDIR/$APP_TS"
APP_JS_DIR="$WORKDIR/$APP_JS"
APP_RSPACK_DIR="$WORKDIR/$APP_RSPACK"
if [[ "$SMOKE_SCOPE" == "full" ]]; then
  APP_PRO_DIR="$WORKDIR/$APP_PRO"
  APP_RSC_JS_DIR="$WORKDIR/$APP_RSC_JS"
  APP_RSC_TS_DIR="$WORKDIR/$APP_RSC_TS"
  APP_RSC_RSPACK_DIR="$WORKDIR/$APP_RSC_RSPACK"
fi

expect_git_history() {
  local app_dir="$1"
  shift

  local expected
  expected="$(printf '%s\n' "$@")"
  local actual
  actual="$(git -C "$app_dir" log --pretty=format:%s --reverse)"

  if [[ "$actual" != "$expected" ]]; then
    echo "Unexpected git history for $app_dir" >&2
    echo "Expected:" >&2
    printf '%s\n' "$expected" >&2
    echo "Actual:" >&2
    printf '%s\n' "$actual" >&2
    return 1
  fi

  git -C "$app_dir" ls-files --error-unmatch .gitignore .gitattributes >/dev/null 2>&1 || {
    echo "Missing tracked Rails git scaffold files in $app_dir" >&2
    git -C "$app_dir" ls-files --error-unmatch .gitignore .gitattributes 2>&1 || true
    return 1
  }
  if git -C "$app_dir" ls-files | grep -q '^tmp/cache/'; then
    echo "tmp/cache/ should not be tracked in $app_dir" >&2
    return 1
  fi
  if git -C "$app_dir" ls-files | grep -q '^node_modules/'; then
    echo "node_modules/ should not be tracked in $app_dir" >&2
    return 1
  fi
}

verify_rails_route() {
  local app_dir="$1"
  local route_path="$2"
  local expected_text="$3"

  echo "Verifying $(basename "$app_dir") renders $route_path..."
  (
    cd "$app_dir"
    SMOKE_ROUTE_PATH="$route_path" SMOKE_EXPECTED_TEXT="$expected_text" \
      RAILS_ENV=test NODE_ENV=test bin/rails runner '
        path = ENV.fetch("SMOKE_ROUTE_PATH")
        expected_text = ENV.fetch("SMOKE_EXPECTED_TEXT")
        session = ActionDispatch::Integration::Session.new(Rails.application)
        session.host!("localhost")
        session.get(path)

        unless session.response.status == 200
          warn "Expected #{path} to render 200, got #{session.response.status}"
          warn session.response.body[0, 1000]
          exit 1
        end

        unless session.response.body.include?(expected_text)
          warn "Expected #{path} response to include #{expected_text.inspect}"
          warn session.response.body[0, 1000]
          exit 1
        end
      '
  )
}

verify_generated_app_runtime() {
  local app_dir="$1"
  local app_name
  local build_output
  local build_status

  app_name="$(basename "$app_dir")"
  echo "Building test bundles for $app_name..."
  if ! pushd "$app_dir" >/dev/null; then
    echo "Cannot cd to generated app directory for $app_name: $app_dir" >&2
    return 1
  fi

  build_status=0
  build_output="$("${PNPM_CMD[@]}" run build:test 2>&1)" || build_status=$?
  popd >/dev/null || {
    echo "popd failed after building test bundles for $app_name" >&2
    return 1
  }
  if [ "$build_status" -ne 0 ]; then
    echo "pnpm run build:test failed for $app_name. Output:" >&2
    printf '%s\n' "$build_output" >&2
    return "$build_status"
  fi

  verify_rails_route "$app_dir" "/" "OSS vs Pro"
  verify_rails_route "$app_dir" "/hello_world" "Say hello to:"
}

assert_file_absent() {
  local file_path="$1"

  if test -f "$file_path"; then
    echo "Expected file to be absent: $file_path" >&2
    return 1
  fi
}

assert_grep_absent() {
  local pattern="$1"
  local file_path="$2"

  if grep -q -- "$pattern" "$file_path"; then
    echo "Expected $file_path not to contain: $pattern" >&2
    return 1
  fi
}

echo "Verifying generated files..."
grep -q "gem \"react_on_rails\"" "$APP_TS_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_TS_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_TS_DIR/config/routes.rb"
grep -q "hello_world" "$APP_TS_DIR/config/routes.rb"
test -f "$APP_TS_DIR/app/controllers/home_controller.rb"
test -f "$APP_TS_DIR/app/views/home/index.html.erb"
grep -q "OSS vs Pro" "$APP_TS_DIR/app/views/home/index.html.erb"
grep -q "Pro quick start" "$APP_TS_DIR/app/views/home/index.html.erb"
grep -q "react-on-rails-demo-marketplace-rsc" "$APP_TS_DIR/app/views/home/index.html.erb"
test -f "$APP_TS_DIR/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_TS_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_TS_DIR/bin/dev"
grep -q -- '--open-browser-once' "$APP_TS_DIR/bin/dev"
test -f "$APP_TS_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_TS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_TS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_TS_DIR/bin/setup"
expect_git_history "$APP_TS_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Install React on Rails with TypeScript and Webpack" \
  "Normalize the generated app for pnpm"

grep -q "gem \"react_on_rails\"" "$APP_JS_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_JS_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_JS_DIR/config/routes.rb"
grep -q "hello_world" "$APP_JS_DIR/config/routes.rb"
assert_grep_absent "gem \"react_on_rails_pro\"" "$APP_JS_DIR/Gemfile"
test -f "$APP_JS_DIR/app/views/home/index.html.erb"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_JS_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_JS_DIR/bin/dev"
test -f "$APP_JS_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_JS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_JS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_JS_DIR/bin/setup"
expect_git_history "$APP_JS_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Install React on Rails with JavaScript and Webpack" \
  "Normalize the generated app for pnpm"

grep -q "gem \"react_on_rails\"" "$APP_RSPACK_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_RSPACK_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_RSPACK_DIR/config/routes.rb"
grep -q "hello_world" "$APP_RSPACK_DIR/config/routes.rb"
test -f "$APP_RSPACK_DIR/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
test -f "$APP_RSPACK_DIR/app/views/home/index.html.erb"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_RSPACK_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_RSPACK_DIR/bin/dev"
grep -q '"@rspack/core"' "$APP_RSPACK_DIR/package.json"
test -f "$APP_RSPACK_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_RSPACK_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSPACK_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSPACK_DIR/bin/setup"
expect_git_history "$APP_RSPACK_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Install React on Rails with TypeScript and Rspack" \
  "Normalize the generated app for pnpm"

verify_generated_app_runtime "$APP_TS_DIR"
verify_generated_app_runtime "$APP_JS_DIR"
verify_generated_app_runtime "$APP_RSPACK_DIR"

if [[ "$SMOKE_SCOPE" == "full" ]]; then
grep -q "gem \"react_on_rails\"" "$APP_PRO_DIR/Gemfile"
grep -q "path: \"$RUBY_GEM_DIR\"" "$APP_PRO_DIR/Gemfile"
grep -q "gem \"react_on_rails_pro\"" "$APP_PRO_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_PRO_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_PRO_DIR/config/routes.rb"
grep -q "hello_world" "$APP_PRO_DIR/config/routes.rb"
test -f "$APP_PRO_DIR/app/views/home/index.html.erb"
test -f "$APP_PRO_DIR/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_PRO_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_PRO_DIR/bin/dev"
test -f "$APP_PRO_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_PRO_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_PRO_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_PRO_DIR/bin/setup"
expect_git_history "$APP_PRO_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Add react_on_rails_pro gem" \
  "Install React on Rails Pro with TypeScript and Webpack" \
  "Normalize the generated app for pnpm"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_JS_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_JS_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_RSC_JS_DIR/config/routes.rb"
grep -q "hello_server" "$APP_RSC_JS_DIR/config/routes.rb"
test -f "$APP_RSC_JS_DIR/app/controllers/hello_server_controller.rb"
test -f "$APP_RSC_JS_DIR/app/views/hello_server/index.html.erb"
grep -q "/hello_server" "$APP_RSC_JS_DIR/app/views/home/index.html.erb"
test -f "$APP_RSC_JS_DIR/app/javascript/src/HelloServer/components/HelloServer.jsx"
grep -Eq "stream_react_component\\(['\\\"]HelloServer['\\\"]" "$APP_RSC_JS_DIR/app/views/hello_server/index.html.erb"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_RSC_JS_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_RSC_JS_DIR/bin/dev"
test -f "$APP_RSC_JS_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_RSC_JS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_JS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_JS_DIR/bin/setup"
expect_git_history "$APP_RSC_JS_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Add react_on_rails_pro gem" \
  "Install React Server Components with JavaScript and Webpack" \
  "Normalize the generated app for pnpm"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_TS_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_TS_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_RSC_TS_DIR/config/routes.rb"
grep -q "hello_server" "$APP_RSC_TS_DIR/config/routes.rb"
grep -q "/hello_server" "$APP_RSC_TS_DIR/app/views/home/index.html.erb"
test -f "$APP_RSC_TS_DIR/app/javascript/src/HelloServer/components/HelloServer.tsx"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_RSC_TS_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_RSC_TS_DIR/bin/dev"
test -f "$APP_RSC_TS_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_RSC_TS_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_TS_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_TS_DIR/bin/setup"
expect_git_history "$APP_RSC_TS_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Add react_on_rails_pro gem" \
  "Install React Server Components with TypeScript and Webpack" \
  "Normalize the generated app for pnpm"

grep -q "gem \"react_on_rails_pro\"" "$APP_RSC_RSPACK_DIR/Gemfile"
grep -q "path: \"$RUBY_PRO_GEM_DIR\"" "$APP_RSC_RSPACK_DIR/Gemfile"
grep -q 'root to: "home#index"' "$APP_RSC_RSPACK_DIR/config/routes.rb"
grep -q "hello_server" "$APP_RSC_RSPACK_DIR/config/routes.rb"
test -f "$APP_RSC_RSPACK_DIR/app/controllers/hello_server_controller.rb"
test -f "$APP_RSC_RSPACK_DIR/app/views/hello_server/index.html.erb"
grep -q "/hello_server" "$APP_RSC_RSPACK_DIR/app/views/home/index.html.erb"
test -f "$APP_RSC_RSPACK_DIR/app/javascript/src/HelloServer/components/HelloServer.tsx"
grep -Eq "stream_react_component\\(['\\\"]HelloServer['\\\"]" "$APP_RSC_RSPACK_DIR/app/views/hello_server/index.html.erb"
grep -q "\"@rspack/core\"" "$APP_RSC_RSPACK_DIR/package.json"
grep -q 'DEFAULT_ROUTE = "/"' "$APP_RSC_RSPACK_DIR/bin/dev"
grep -q 'AUTO_OPEN_BROWSER_ONCE = true' "$APP_RSC_RSPACK_DIR/bin/dev"
test -f "$APP_RSC_RSPACK_DIR/pnpm-lock.yaml"
assert_file_absent "$APP_RSC_RSPACK_DIR/package-lock.json"
grep -q '"packageManager": "pnpm@' "$APP_RSC_RSPACK_DIR/package.json"
grep -q 'system!("pnpm install")' "$APP_RSC_RSPACK_DIR/bin/setup"
expect_git_history "$APP_RSC_RSPACK_DIR" \
  "Create Rails app with PostgreSQL" \
  "Add react_on_rails gem" \
  "Add react_on_rails_pro gem" \
  "Install React Server Components with TypeScript and Rspack" \
  "Normalize the generated app for pnpm"
fi

echo "Smoke test passed."
if [[ "${KEEP_WORKDIR:-0}" == "1" ]]; then
  echo "Generated apps left in: $WORKDIR"
else
  rm -rf "$WORKDIR"
  echo "Cleaned up temp dir: $WORKDIR"
fi
