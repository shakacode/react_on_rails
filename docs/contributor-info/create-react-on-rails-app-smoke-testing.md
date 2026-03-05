# create-react-on-rails-app Smoke Testing

Use this flow to test CLI changes against the local monorepo gem code (not the currently published gem versions).

## Why This Flow

`create-react-on-rails-app` installs Ruby gems from RubyGems by default. When working on unreleased generator changes (for example `--rsc`), smoke tests should use local gem paths so the generated app reflects the branch being tested.

## One-Command Smoke Test

From the monorepo root:

```bash
packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh
```

The script:

1. Builds `create-react-on-rails-app`
2. Generates a JavaScript app using local `react_on_rails`
3. Generates an RSC app using local `react_on_rails` + local `react_on_rails_pro`
4. Verifies key outputs (`Gemfile` path gems, routes, and `hello_server` files)

It prints the temp directory path so you can inspect generated apps.

## Manual Variant

If you want to run manually:

```bash
export CI=true
export REACT_ON_RAILS_GEM_PATH="$(pwd)/react_on_rails"
export REACT_ON_RAILS_PRO_GEM_PATH="$(pwd)/react_on_rails_pro"

node packages/create-react-on-rails-app/bin/create-react-on-rails-app.js my-app --template javascript --package-manager pnpm
node packages/create-react-on-rails-app/bin/create-react-on-rails-app.js my-rsc-app --rsc --template javascript --package-manager pnpm
```

`CI=true` suppresses the generator's uncommitted-changes warning in fresh apps.
