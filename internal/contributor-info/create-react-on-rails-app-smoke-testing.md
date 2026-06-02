# create-react-on-rails-app Smoke Testing

Use this flow to test CLI changes against the local monorepo gem code (not the currently published gem versions).

## Why This Flow

`npx create-react-on-rails-app@latest ...` always resolves the published npm package, not your local branch.
When working on unreleased generator changes (for example `--rsc`), smoke tests should use local gem paths so the generated app reflects the branch being tested.

## One-Command Smoke Test

From the monorepo root:

```bash
packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh
```

The script:

1. Builds `create-react-on-rails-app`
2. Generates TypeScript, JavaScript, and Rspack OSS apps using local `react_on_rails`
3. Generates Pro and RSC apps using local `react_on_rails` + local `react_on_rails_pro`
4. Verifies key outputs (`Gemfile` path gems, routes, demo files, package manager normalization, and git history)

It prints the temp directory path so you can inspect generated apps.

## OSS-Only Smoke Test

Run the OSS scope when you are working on standard generated apps and do not need
to verify Pro or RSC output:

```bash
CREATE_ROR_SMOKE_SCOPE=oss packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh
```

The OSS scope does not require `react_on_rails_pro`. It generates and verifies:

1. TypeScript + Webpack
2. JavaScript + Webpack
3. TypeScript + Rspack

The default scope is `full`, which keeps running the Pro and RSC generated-app
checks for maintainers with the Pro gem checked out.

## Manual Variant: Fastest Local Branch Path

If you want to run the local branch code directly without publishing or packing a tarball:

```bash
export CI=true
export REACT_ON_RAILS_GEM_PATH="$(pwd)/react_on_rails"
export REACT_ON_RAILS_PRO_GEM_PATH="$(pwd)/react_on_rails_pro"

node packages/create-react-on-rails-app/bin/create-react-on-rails-app.js my-app --template javascript --package-manager pnpm
node packages/create-react-on-rails-app/bin/create-react-on-rails-app.js my-rsc-app --rsc --template javascript --package-manager pnpm
```

Build the package first if `packages/create-react-on-rails-app/lib/` is not current:

```bash
corepack pnpm --filter create-react-on-rails-app run build
```

`CI=true` suppresses the generator's uncommitted-changes warning in fresh apps.

## Manual Variant: Test the Actual `npx` Experience Locally

If you specifically want to test the same install path users get from `npx`, pack the current branch and execute that tarball through `npx`.

From the monorepo root:

```bash
corepack pnpm --filter create-react-on-rails-app run build
mkdir -p /tmp/ror-local-pack
corepack pnpm --dir packages/create-react-on-rails-app pack --pack-destination /tmp/ror-local-pack
```

Then run the packed CLI from a temp directory:

```bash
export CI=true
export REACT_ON_RAILS_GEM_PATH="$(pwd)/react_on_rails"
export REACT_ON_RAILS_PRO_GEM_PATH="$(pwd)/react_on_rails_pro"

tmpdir="$(mktemp -d /tmp/ror-local-cli-XXXXXX)"
cd "$tmpdir"

npx --yes --package=/tmp/ror-local-pack/create-react-on-rails-app-*.tgz \
  create-react-on-rails-app my-rsc-app --rsc --package-manager pnpm
```

This is the closest local equivalent to:

```bash
npx create-react-on-rails-app@latest my-rsc-app --rsc
```

Use the direct `node .../bin/create-react-on-rails-app.js` path for faster iteration, and use the packed `npx` path when you need to verify the npm package entrypoint itself.
