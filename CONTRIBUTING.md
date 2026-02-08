# Tips for Contributors

**🏗️ Important: Monorepo Merger in Progress**

We are currently working on merging the `react_on_rails` and `react_on_rails_pro` repositories into a unified monorepo. This will provide better development experience while maintaining separate package identities and licensing. See [analysis/contributor-info/monorepo-merger-plan-reference.md](./analysis/contributor-info/monorepo-merger-plan-reference.md) for details.

During this transition:

- Continue contributing to the current structure
- License compliance remains critical - ensure no Pro code enters MIT-licensed areas
- Major structural changes may be coordinated with the merger plan
- Keep documentation boundaries strict: end-user docs in `docs/` (public), internal planning/tracking docs in `analysis/contributor-info/` or `analysis/`

---

- [analysis/contributor-info/Releasing](./analysis/contributor-info/releasing.md) for instructions on releasing.
- [analysis/contributor-info/pull-requests](./analysis/contributor-info/pull-requests.md)
- [analysis/contributor-info/rbs-type-signatures](./analysis/contributor-info/rbs-type-signatures.md) for information on RBS type signatures
- See other internal docs in [analysis/contributor-info](./analysis/contributor-info)

## Prerequisites

**Note for users**: End users of react_on_rails can continue using their preferred package manager (npm, yarn, pnpm, or bun). The generators automatically detect your package manager. The pnpm commands below are for contributors working on the react_on_rails codebase itself.

- [Yalc](https://github.com/whitecolor/yalc) must be installed globally for most local development.
- **Git hooks setup** (automatic during normal setup):

Git hooks are installed automatically when you run the standard setup commands. They will run automatic linting on **all changed files (staged + unstaged + untracked)** - making commits fast while preventing CI failures.

- After cloning the repo, run `bin/setup` from the root directory to install all dependencies.

- After updating code via Git, to prepare all examples:

```sh
bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake
```

See [Dev Initial Setup](#dev-initial-setup) below for initial setup details,
and [Running tests](#running-tests) for more details on running tests.

# IDE/IDE SETUP

It's critical to configure your IDE/editor to ignore certain directories. Otherwise, your IDE might slow to a crawl!

- /coverage
- /tmp
- /gen-examples
- /packages/react-on-rails/lib
- /node_modules
- /react_on_rails/spec/dummy/app/assets/webpack
- /react_on_rails/spec/dummy/log
- /react_on_rails/spec/dummy/node_modules
- /react_on_rails/spec/dummy/client/node_modules
- /react_on_rails/spec/dummy/tmp
- /react_on_rails/spec/react_on_rails/dummy-for-generators

# Example apps

The [`react_on_rails/spec/dummy` app](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails/spec/dummy) is an example of the various setup techniques you can use with the gem.

There are also two such apps for React on Rails Pro: [one using the Node renderer](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/spec/dummy) and [one using ExecJS](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/spec/execjs-compatible-dummy).

When you add a new feature, consider adding an example demonstrating it to the example apps.

# Testing your changes in an external application

You may also want to test your React on Rails changes with your own application.
There are three main ways to do it: using local dependencies, Git dependencies, or tarballs.

## Local version

### Ruby

To make your Rails app use a local version of our gems, use

```ruby
gem "react_on_rails", path: "<React on Rails root>"
```

and/or

```ruby
gem "react_on_rails_pro", path: "<React on Rails root>/react_on_rails_pro"
```

Note that you will need to run `bundle install` after making this change, but also that **you will need to restart your Rails application if you make any changes to the gem**.

### JS

First, be **sure** to build the NPM package:

```sh
cd <React on Rails root>
pnpm install

# Update the lib directory with babel compiled files
pnpm run build-watch
```

You need to do this once to make sure your app depends on our package:

```shell
cd <React on Rails root>/packages/react-on-rails
yalc publish
cd <your project root>
yalc add react-on-rails
```

The workflow is:

1. Make changes to the node package.
2. **CRITICAL**: Run `yalc push` to send updates to all linked apps:

```shell
cd <React on Rails root>/packages/react-on-rails
# Will send the updates to other folders - MUST DO THIS AFTER ANY CHANGES
yalc push
cd <your project root>

# Will update from yalc
pnpm install
```

**⚠️ Common Mistake**: Forgetting to run `yalc push` after making changes to React on Rails source code will result in test apps not receiving updates, making it appear that your changes have no effect.

When you run `yalc push`, you'll get an informative message

```terminaloutput
$ yalc push
react-on-rails@12.0.0-12070fd1 published in store.
Pushing react-on-rails@12.0.0 in /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy
Package react-on-rails@12.0.0-12070fd1 added ==> /Users/justin/shakacode/react-on-rails/react_on_rails/spec/dummy/node_modules/react-on-rails.
Don't forget you may need to run pnpm install after adding packages with yalc to install/update dependencies/bin scripts.
```

Of course, you can do the same with `react-on-rails-pro` and `react-on-rails-pro-node-renderer` packages.

This is the approach `react_on_rails/spec/dummy` apps use, so you can also look at their implementation.

### Example: Testing NPM changes with the dummy app

1. Add `console.log('Hello!')` to [clientStartup.ts, function render](https://github.com/shakacode/react_on_rails/blob/master/packages/react-on-rails/src/clientStartup.ts) in `/packages/react-on-rails/src/clientStartup.ts` to confirm we're getting an update to the node package client-side. Do the same for function `serverRenderReactComponent` in [/packages/react-on-rails/src/serverRenderReactComponent.ts](https://github.com/shakacode/react_on_rails/blob/master/packages/react-on-rails/src/serverRenderReactComponent.ts).
2. Refresh the browser if the server is already running or start the server using `foreman start` from `react_on_rails/spec/dummy` and navigate to `http://localhost:3000/`. You will now see the `Hello!` message printed in the browser's console. If you did not see that message, then review the steps above for the workflow of making changes and pushing them via yalc.

## Git dependencies

If you push your local changes to Git, you can use them as dependencies as follows:

### Ruby

Adjust depending on the repo you pushed to and commit/branch you want to use, see [Bundler documentation](https://bundler.io/guides/git.html):

```ruby
gem 'react_on_rails',
  git: 'https://github.com/shakacode/react_on_rails',
  branch: 'master'
gem 'react_on_rails_pro',
  git: 'https://github.com/shakacode/react_on_rails',
  glob: 'react_on_rails_pro/react_on_rails_pro.gemspec',
  branch: 'master'
```

### JS

Unfortunately, not all package managers allow depending on a single subfolder of a Git repo.
The examples below are for the `master` branch of `react-on-rails` package.

#### PNPM (recommended, v9+)

See [this issue](https://github.com/pnpm/pnpm/issues/4765).

```shell
pnpm add "github:shakacode/react_on_rails/repo#master&path:packages/react-on-rails"
```

#### Yarn Berry

See [Yarn Git protocol documentation](https://yarnpkg.com/protocol/git#workspaces-support).

```shell
yarn add "git@github.com:shakacode/react_on_rails.git#workspace=react-on-rails&head=master"
```

#### NPM

[Explicitly doesn't want to support it.](https://github.com/npm/cli/issues/6253)

## Tarball

This method works only for JS packages, not for Ruby gems.

Run `pnpm pack` in the package you modified, copy the generated file into your app or upload it somewhere, and run

```shell
npm install <tarball path/URL>
```

or the equivalent command for your package manager.

# Development Setup for Gem and Node Package Contributors

## Dev Initial Setup

### Quick Setup (Recommended)

After checking out the repo and ensuring you have Ruby and Node version managers set up (such as rvm and nvm, or rbenv and nodenv, etc.) with the correct versions active, run:

```sh
# First, verify your versions match the project requirements
ruby -v  # Should show 3.4.x or version in .ruby-version
node -v  # Should show 22.x or version in .node-version

# Then run the setup script
bin/setup

# Or skip Pro setup (for contributors without Pro access)
bin/setup --skip-pro
```

This single command installs all dependencies across the monorepo:

- Root pnpm and bundle dependencies
- Builds the node package
- Sets up `react_on_rails/spec/dummy`
- Sets up `react_on_rails_pro` (if present)
- Sets up `react_on_rails_pro/spec/dummy` (if present)
- Sets up `react_on_rails_pro/spec/execjs-compatible-dummy` (if present)

### Manual Setup (Alternative)

If you prefer to set up manually or need more control:

1. Install root dependencies:

```sh
bundle install
pnpm install
```

2. Build the node package:

```sh
rake node_package
```

3. Set up the dummy app:

```sh
cd react_on_rails/spec/dummy
bundle install
pnpm install
```

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Local Node Package

Note, the example and dummy apps will use your local `packages/react-on-rails` folder as the `react-on-rails` node package. This will also be done automatically for you via the `rake examples:gen_all` rake task.

_Side note: It's critical to use the alias section of the Webpack config to avoid a double inclusion error. This has already been done for you in the example and dummy apps, but for reference:_

```js
  resolve: {
    alias: {
      react: path.resolve('./node_modules/react'),
      'react-dom': path.resolve('./node_modules/react-dom'),
    },
  },
```

### Install NPM dependencies and build the NPM package for react-on-rails

```sh
cd react_on_rails/
pnpm install
pnpm run build
```

Or run this, which builds the package, then the Webpack files for `react_on_rails/spec/dummy`, and runs tests in
`react_on_rails/spec/dummy`.

```sh
# Optionally change default capybara driver
export DRIVER=selenium_firefox
cd react_on_rails/
pnpm run dummy:spec
```

To convert the development environment over to Shakapacker v6 instead of the default Shakapacker v8:

```sh
# Optionally change default capybara driver
export DRIVER=selenium_firefox
cd react_on_rails/
script/convert
pnpm run dummy:spec
```

## Running tests

### JS tests

```sh
cd react_on_rails/
pnpm run test
```

### react_on_rails/spec/dummy tests

```sh
cd react_on_rails/spec/dummy
rspec
```

### Linting, type checking and JS tests together

```sh
cd react_on_rails/
pnpm run check
```

## Development Commands

### Code Formatting

To format JavaScript/TypeScript files with Prettier:

```sh
pnpm run format
```

To check formatting without fixing:

```sh
pnpm run format.listDifferent
```

### Linting

Run all linters (ESLint and RuboCop):

```sh
rake lint
```

Run only RuboCop:

```sh
rake lint:rubocop
```

Run only ESLint:

```sh
pnpm run lint
```

### Bundle Size Checks

React on Rails monitors bundle sizes in CI to prevent unexpected size increases. The CI compares your PR's bundle sizes against the base branch and fails if any package increases by more than 0.5KB.

#### Running Locally

Check current bundle sizes:

```sh
pnpm run size
```

Get JSON output for programmatic use:

```sh
pnpm run size:json
```

Compare your branch against the base branch:

```sh
bin/compare-bundle-sizes
```

This script automatically:

1. Stashes any uncommitted changes
2. Checks out and builds the base branch (default: `master`)
3. Checks out and builds your current branch
4. Compares the size and total execution time (loading + running) and shows a detailed report

Options:

```sh
bin/compare-bundle-sizes main        # Compare against 'main' instead of 'master'
bin/compare-bundle-sizes --hierarchical  # Group results by package
```

#### Bypassing the Check

If your PR intentionally increases bundle size (e.g., adding a new feature), you can skip the bundle size check:

```sh
# Run from your PR branch
bin/skip-bundle-size-check
git add .bundle-size-skip-branch
git commit -m "Skip bundle size check for intentional size increase"
git push
```

This sets your branch to skip the size check. The skip only applies to the specific branch name written to `.bundle-size-skip-branch`.

**Important**: Only skip the check when the size increase is justified. Document why the increase is acceptable in your PR description.

#### What Gets Measured

The CI measures sizes for:

- **react-on-rails**: Raw, gzip, and brotli compressed sizes
- **react-on-rails-pro**: Raw, gzip, and brotli compressed sizes
- **react-on-rails-pro-node-renderer**: Raw, gzip, and brotli compressed sizes
- **Webpack bundled imports**: Client-side bundle sizes when importing via webpack

### Starting the Dummy App

To run the dummy app, it's **CRITICAL** to not just run `rails s`. You have to run `foreman start` with one of the Procfiles. If you don't do this, then `webpack` will not generate a new bundle, and you will be seriously confused when you change JavaScript and the app does not change. If you change the Webpack configs, then you need to restart Foreman. If you change the JS code for react-on-rails, you need to run `pnpm run build` in the project root.

### RSpec Testing

Run `rake` for testing the gem and `react_on_rails/spec/dummy`. Otherwise, the `rspec` command only works for testing within the sample apps, like `react_on_rails/spec/dummy`.

If you run `rspec` at the top level, you'll see this message: `require': cannot load such file -- rails_helper (LoadError)`

After running a test, you can view the coverage results SimpleCov reports by opening `coverage/index.html`.

Turbolinks 5 is included in the test app, unless "DISABLE_TURBOLINKS" is set to YES in the environment.

Run `rake -T` or `rake -D` to see testing options.

`rake all_but_examples` is typically best for developers, except if any generators changed.

See below for verifying changes to the generators.

## CI Testing and Optimization

React on Rails uses an optimized CI pipeline that runs faster on branches while maintaining full coverage on `master`. Contributors have access to local CI tools to validate changes before pushing.

### CI Behavior

- **On PRs/Branches**: Runs reduced test matrix (latest Ruby/Node versions only) for faster feedback (~12 min vs ~45 min)
- **On Master**: Runs full test matrix (all Ruby/Node/dependency combinations) for complete coverage
- **Docs-only changes**: CI skips entirely when only `.md` files or `docs/` directory change

### Local CI Tools

#### `bin/ci-local` - Smart Local CI Runner

Analyzes your changes and runs appropriate tests locally before pushing:

```bash
# Auto-detect what to test based on changed files
bin/ci-local

# Run all CI checks (same as master branch)
bin/ci-local --all

# Quick check - only fast tests, skip slow integration tests
bin/ci-local --fast

# Compare against a different branch
bin/ci-local origin/develop
```

**Benefits:**

- Catches CI failures before pushing
- Skips irrelevant tests (e.g., Ruby tests when only JS changed)
- Provides clear summary of what passed/failed

#### `script/ci-changes-detector` - Change Analysis

Analyzes git changes and recommends which CI jobs to run:

```bash
# Check what changed since master
script/ci-changes-detector origin/master

# JSON output for scripting (requires jq)
CI_JSON_OUTPUT=1 script/ci-changes-detector origin/master
```

**Output example:**

```
=== CI Changes Analysis ===
Changed file categories:
  • Ruby source code
  • JavaScript/TypeScript code

Recommended CI jobs:
  ✓ Lint (Ruby + JS)
  ✓ RSpec gem tests
  ✓ JS unit tests
```

#### `/run-ci` - Claude Code Command

If using Claude Code, run `/run-ci` for interactive CI execution that:

1. Analyzes your changes
2. Shows recommended CI jobs
3. Asks which tests to run
4. Executes and reports results

### CI Best Practices

✅ **DO:**

- Run `bin/ci-local` before pushing to catch issues early
- Use `bin/ci-local --fast` during rapid iteration
- Trust the reduced matrix on PRs - master validates everything
- Separate docs-only changes into dedicated commits/PRs when possible

❌ **DON'T:**

- Push without running local tests first
- Mix code and docs changes if you want docs to skip CI
- Expect PR CI to catch minimum Ruby/Node version issues (use `bin/ci-local --all` for that)

### Understanding CI Optimizations

The CI system intelligently skips unnecessary work:

| Change Type                | CI Behavior           | Time Saved |
| -------------------------- | --------------------- | ---------- |
| Docs only (`.md`, `docs/`) | Skips all CI          | 100%       |
| Ruby code only             | Skips JS tests        | ~30%       |
| JS code only               | Skips Ruby-only tests | ~30%       |
| Workflow changes           | Runs lint only        | ~75%       |

For more details, see [`analysis/contributor-info/ci-optimization.md`](./analysis/contributor-info/ci-optimization.md).

### CI Control Commands

React on Rails provides PR comment commands to control CI behavior:

#### `/run-skipped-ci` (or `/run-skipped-tests`) - Enable Full CI Mode

Runs all skipped CI checks and enables full CI mode for the PR:

```
/run-skipped-ci
# or use the shorter alias:
/run-skipped-tests
```

**What it does:**

- Triggers all CI workflows that were skipped due to unchanged code
- Adds the `full-ci` label to the PR
- **Persists across future commits** - all subsequent pushes will run the full test suite
- Runs minimum dependency tests (Ruby 3.2, Node 20, Shakapacker 8.2.0, React 18)

**When to use:**

- You want comprehensive testing across all configurations
- Testing changes that might affect minimum supported versions
- Validating generator changes or core functionality
- Before merging PRs that touch critical paths

#### `/stop-run-skipped-ci` - Disable Full CI Mode

Removes the `full-ci` label and returns to standard CI behavior:

```
/stop-run-skipped-ci
```

**What it does:**

- Removes the `full-ci` label from the PR
- Future commits will use the optimized CI suite (tests only changed code)
- Does not stop currently running workflows

**When to use:**

- You've validated changes with full CI and want to return to faster feedback
- Reducing CI time during rapid iteration on a PR

**Note:** The `full-ci` label is preserved on merged PRs as a historical record of which PRs ran with comprehensive testing.

#### Important Notes

- **Force-pushes:** The `/run-skipped-ci` command adds the `full-ci` label to your PR. If you force-push after commenting, the initial workflow run will test the old commit, but subsequent pushes will automatically run full CI because the label persists.
- **Branch operations:** Avoid deleting or force-pushing branches while workflows are running, as this may cause failures.

### Benchmarking

React on Rails includes a performance benchmark workflow that measures RPS (requests per second) and latency for both Core and Pro versions.

#### When Benchmarks Run

- **Automatically on master**: Benchmarks run on every push to master
- **On PRs with labels**: Add the `benchmark` or `full-ci` label to your PR to run benchmarks
- **Manual trigger**: Use `gh workflow run` to run benchmarks with custom parameters (see [https://github.com/cli/cli#installation](https://github.com/cli/cli#installation) if you don't have `gh`):

  ```bash
  # Run with default parameters
  gh workflow run benchmark.yml

  # Run with custom parameters
  gh workflow run benchmark.yml \
    -f rate=100 \
    -f duration=60s \
    -f connections=20 \
    -f app_version=core_only
  ```

#### Regression Detection

When benchmarks run, the [github-action-benchmark](https://github.com/benchmark-action/github-action-benchmark) action compares results against historical data. If performance regresses by more than 50%, the workflow will:

1. **Fail the CI check** with `fail-on-alert: true`
2. **Post a comment on the PR** explaining the regression
3. **Tag reviewers** for attention

This helps catch performance regressions before they reach production.

#### Running Benchmarks Locally

**Prerequisites:** Install [k6](https://k6.io/docs/get-started/installation/) and [Vegeta](https://github.com/tsenart/vegeta#install).

You can also run the server in a separate terminal instead of backgrounding it.

**Core benchmarks:**

```bash
cd react_on_rails/spec/dummy
bin/prod-assets  # Build production assets
bin/prod &       # Start production server on port 3001
SERVER_PID=$!
cd ../..
ruby benchmarks/bench.rb
kill $SERVER_PID
```

**Pro benchmarks:**

```bash
cd react_on_rails_pro/spec/dummy
bin/prod-assets
bin/prod &       # Starts Rails server and node renderer
SERVER_PID=$!
cd ../..
PRO=true ruby benchmarks/bench.rb         # Rails benchmarks
ruby benchmarks/bench-node-renderer.rb    # Node renderer benchmarks
kill $SERVER_PID
```

**Configuration:** Both scripts support environment variables for customization (rate, duration, connections, etc.). See the script headers in [`benchmarks/bench.rb`](benchmarks/bench.rb) and [`benchmarks/bench-node-renderer.rb`](benchmarks/bench-node-renderer.rb) for available options. For debugging, you may want lower `DURATION` and/or specific `ROUTES`:

```bash
DURATION=5s ROUTES=/ ruby benchmarks/bench.rb
```

### Install Generator

In your Rails app add this gem with a path to your fork.

```ruby
gem 'react_on_rails', path: '../relative/path/to/react_on_rails'
```

Then run `bundle`.

The main installer can be run with `./bin/rails generate react_on_rails:install`

Then use yalc to add the npm module.

Be sure that your ran this first at the top level of React on Rails

```
yalc publish
```

Then add the node package to your test app:

```
yalc add react-on-rails
```

### Testing the Generator

The generators are covered by generator tests using Rails's generator testing helpers, but it never hurts to do a sanity check and explore the API. See [generator-testing.md](analysis/contributor-info/generator-testing.md) for a script on how to run the generator on a fresh project.

`rake run_rspec:shakapacker_examples_basic` is a great way to run tests on one generator. Once that works, you should run `rake run_rspec:shakapacker_examples`. Be aware that this will create a huge number of files under a `/gen-examples` directory. You should be sure to exclude this directory from your IDE and delete it once your testing is done.

#### Manual Generator Testing Workflow

For comprehensive testing of generator changes, use this manual testing workflow with dedicated test applications:

**1. Set up test application with clean baseline:**

```bash
# Create a test Rails app
mkdir -p {project_dir}/test-app
cd {project_dir}/test-app
rails new . --skip-javascript

# Set up for testing the generator
echo 'gem "react_on_rails", path: "../react_on_rails"' >> Gemfile
yalc add react-on-rails

# Create a clean baseline tag for testing
git init && git add . && git commit -m "Initial commit"
git tag generator_testing_base
bundle install

# Clean reset to baseline state
git clean -fd && git reset --hard && git clean -fd
```

**2. Test generator commits systematically:**

When testing specific generator improvements or fixes, test both Shakapacker scenarios:

**Scenario A: No Shakapacker installed (fresh Rails app)**

```bash
# Reset to clean baseline before each test
git clean -fd && git reset --hard generator_testing_base && git clean -fd

# Ensure no Shakapacker in Gemfile (remove if present)
# Edit Gemfile to update gem path: gem 'react_on_rails', path: '../path/to/main/repo'
bundle install

# Run generator - should install Shakapacker automatically
./bin/rails generate react_on_rails:install

# Verify Shakapacker was added to Gemfile and installed correctly
```

**Scenario B: Shakapacker already installed**

```bash
# Reset to clean baseline
git clean -fd && git reset --hard generator_testing_base && git clean -fd

# Add Shakapacker to Gemfile
bundle add shakapacker --strict

# Run Shakapacker installer first
./bin/rails shakapacker:install

# Edit Gemfile to update gem path: gem 'react_on_rails', path: '../path/to/main/repo'
bundle install

# Run generator - should detect existing Shakapacker
./bin/rails generate react_on_rails:install

# Verify generator adapts to existing Shakapacker setup
```

**3. Document testing results:**

For each commit tested, document:

- Generator execution success/failure for both scenarios
- Shakapacker installation/detection behavior
- Component rendering in browser
- Console output and warnings
- File generation differences between scenarios
- Specific issues found

This systematic approach ensures generator changes work correctly whether Shakapacker is pre-installed or needs to be installed by the generator.

#### Testing Generator with Yalc for React Component Functionality

When testing the install generator with new Rails apps, you need to use **yalc** for the JavaScript package to ensure React components work correctly. The Ruby gem path reference is insufficient for client-side rendering.

**Problem**: Using only the gem path (`gem "react_on_rails", path: "../path"`) in a new Rails app results in React components not mounting on the client side, even though server-side rendering works fine.

**Solution**: Use both gem path and yalc for complete testing:

```ruby
# In test app's Gemfile
gem 'react_on_rails', path: '../relative/path/to/react_on_rails'
```

```bash
# After running the install generator AND after making any changes to the React on Rails source code
cd /path/to/react_on_rails
npm run build
npx yalc publish
# CRITICAL: Push changes to all linked apps
npx yalc push

cd /path/to/test_app
npm install

# Restart development server
bin/dev
```

**⚠️ CRITICAL DEBUGGING NOTE:**
Always run `yalc push` after making changes to React on Rails source code. Without this step, your test app won't receive the updated package, leading to confusing behavior where changes appear to have no effect.

**Alternative to Yalc: npm pack (More Reliable)**
For a more reliable alternative that exactly mimics real package installation:

```bash
# In react_on_rails directory
npm run build
npm pack  # Creates react-on-rails-15.0.0.tgz

# In test app directory
npm install ../path/to/react_on_rails/react-on-rails-15.0.0.tgz
```

This approach:

- ✅ Exactly mimics real package installation
- ✅ No symlink issues across different filesystems
- ✅ More reliable for CI/CD testing
- ⚠️ Requires manual step after each change (can be scripted)

**Why this is needed**:

- The gem provides Rails integration and server-side rendering
- Yalc provides the complete JavaScript client library needed for component mounting
- Without yalc, you'll see empty divs where React components should render

**Verification**:

- Visit the hello_world page in browser
- Check browser console for "RENDERED HelloWorld to dom node" success message
- Confirm React component is interactive (input field updates name display)

**Development Mode Console Output**:

- `bin/dev` (HMR): Shows HMR warnings and resource preload warnings (expected)
- `bin/dev static`: Shows only resource preload warnings (cleaner output)
- `bin/dev prod`: Cleanest output with minimal warnings (production-like environment)

**Note**: Resource preload warnings in development modes are normal and can be ignored. They occur because Shakapacker generates preload tags but scripts load asynchronously. Production mode eliminates most of these warnings.

#### Generator Testing Troubleshooting

**Common Issues and Solutions:**

1. **React components not rendering (empty divs)**
   - **Cause**: Missing yalc setup for JavaScript package
   - **Solution**: Follow yalc setup steps above after running generator

2. **Generator fails with Shakapacker errors**
   - **Cause**: Conflicting Shakapacker versions or incomplete installation
   - **Solution**: Clean reset and ensure consistent Shakapacker version across tests

3. **Babel configuration conflicts during yalc development**
   - **Cause**: Both `babel.config.js` and `package.json` "babel" section defining presets
   - **Solution**: Remove "babel" section from `package.json`, keep only `babel.config.js`

4. **"Package.json not found" errors**
   - **Cause**: Generator trying to access non-existent package.json files
   - **Solution**: Test with commits that fix this specific issue (e.g., bc69dcd0)

5. **Port conflicts during testing**
   - **Cause**: Multiple development servers running
   - **Solution**: Run `bin/dev kill` before starting new test servers

**Testing Best Practices:**

- Always use the double clean command: `git clean -fd && git reset --hard && git clean -fd`
- Test both Shakapacker scenarios for comprehensive coverage
- Document exact error messages and steps to reproduce
- Verify React component interactivity, not just rendering
- Test all development modes: `bin/dev`, `bin/dev static`, `bin/dev prod`

## Pre-Commit Requirements

**AUTOMATED**: If you've set up Lefthook (see Prerequisites), linting runs automatically on changed files before each commit.

**MANUAL OPTION**: If you need to run linting manually:

```bash
# Navigate to the main react_on_rails directory
cd react_on_rails/

# Run Prettier for JavaScript/TypeScript formatting
pnpm run format

# Run ESLint for JavaScript/TypeScript linting
pnpm run lint

# Run RuboCop for Ruby linting and formatting
rake lint:rubocop

# Or run all linters together
rake lint
```

**Git hooks automatically run:**

- Format JavaScript/TypeScript files with Prettier (on changed files only)
- Check and fix linting issues with ESLint
- Check and fix Ruby style issues with RuboCop (on all changed files)
- Ensure trailing newlines on all files

**Setup**: Automatic during normal development setup

## 🤖 Best Practices for AI Coding Agents

**CRITICAL WORKFLOW** to prevent CI failures:

### 1. **After Making Code Changes**

```bash
# Auto-fix all linting violations after code changes
rake autofix
```

### 2. **Common AI Agent Mistakes**

❌ **DON'T:**

- Commit code that hasn't been linted locally
- Ignore formatting rules when creating new files
- Add manual formatting that conflicts with Prettier/RuboCop

✅ **DO:**

- Run `rake lint` after any code changes
- Use `rake autofix` to automatically fix all linting violations
- Create new files that follow existing patterns
- Test locally before committing

### 4. **Template File Best Practices**

When creating new template files (`.jsx`, `.rb`, etc.):

1. Copy existing template structure and patterns
2. Run `pnpm run eslint . --fix` immediately after creation
3. Verify with `rake lint` before committing

### 5. **RuboCop Complexity Issues**

For methods with high ABC complexity (usually formatting/display methods):

```ruby
# rubocop:disable Metrics/AbcSize
def complex_formatting_method
  # ... method with lots of string interpolation/formatting
end
# rubocop:enable Metrics/AbcSize
```

**Remember**: Failing CI wastes time and resources. Always lint locally first!

### Linting

All linting is performed from the docker container for CI. You will need docker and docker-compose installed locally to lint code changes via the lint container. You can lint locally by running `pnpm run lint`

- [Install Docker Toolbox for Mac](https://www.docker.com/toolbox)
- [Install Docker Compose for Linux](https://docs.docker.com/compose/install/)

Once you have docker and docker-compose running locally, run `docker-compose build lint`. This will build the `reactonrails_lint` docker image and docker-compose `lint` container. The initial build is slow, but after the install, startup is very quick.

### Linting Commands

Run `rake lint`.

Alternately with Docker:

Run `rake -D docker` to see all docker linting commands for rake. `rake docker:lint` will run all linters. For individual rake linting commands please refer to `rake -D docker` for the list.

You can run specific linting for directories or files by using `docker-compose run lint rubocop (file path or directory)`, etc.

`docker-compose run lint bash` sets you up to run from the container command line.

### Updating Rubocop

2 files require updating to update the Rubocop version:

1. `react_on_rails.gemspec`
2. `react_on_rails/spec/dummy/Gemfile`

### Docker CI - Test and Linting

Docker CI and Tests containers have a xvfd server automatically started for headless browser testing with selenium and Firefox.

Run `docker-compose build ci` to build the CI container. Run `docker-compose run ci` to start all rspec tests and linting. `docker-compose run --entrypoint=/bin/bash` will override the default CI action and place you inside the CI container in a bash session. This is what is run on Travis-CI.

Run `docker-compose build tests` to build the tests container. Run `docker-compose run tests` to start all RSpec tests.

# Advice for Project Maintainers and Contributors

What do project maintainers do? What sort of work is involved? [sstephenson](https://github.com/sstephenson) wrote in the [turbolinks](https://github.com/turbolinks/turbolinks) repo:

> [Why this is not still fully merged?](https://github.com/turbolinks/turbolinks/pull/124#issuecomment-239826060)

# 📦 Demo Naming and README Standards

To keep our React on Rails demos clear, discoverable, and SEO-friendly, all demo repos follow a standardized naming and documentation structure.

---

## ✅ Repository Naming Convention

Use the format:

```
react_on_rails-demo-v[REACT_ON_RAILS_VERSION]-[key-topics]
```

**Examples:**

- `react_on_rails-demo-v15-ssr-auto-registration-bundle-splitting`
- `react_on_rails-demo-v15-react-server-components`
- `react_on_rails-demo-v15-typescript-setup`
- `react_on_rails-demo-v15-cypress-setup`

**Why this format?**

- Clear versioning and purpose
- Easy to discover in GitHub, search engines, and documentation
- Consistent prefix for grouping demos together

---

## 📝 README Title Format

```
# React on Rails Demo: [Topics] with v[VERSION] and Rails [VERSION]
```

**Example:**

```
# React on Rails Demo: SSR, Auto-Registration & Bundle Splitting with v15 and Rails 8
```

---

## 📄 README Description Template

```
A fully working demo of React on Rails v[VERSION] on Rails [VERSION], showcasing [topics].

✅ Includes:
- [Topic 1]
- [Topic 2]
- [Topic 3]

📂 Repo name: `react_on_rails-demo-v[VERSION]-[topics]`

📚 Part of the [React on Rails Demo Series](https://github.com/shakacode?tab=repositories&q=react_on_rails-demo)
```

**Example:**

```
A fully working demo of React on Rails v15 on Rails 8, showcasing server-side rendering, file-system-based auto-registration, and intelligent bundle splitting.

✅ Includes:
- Server-Side Rendering (SSR)
- Auto-discovered components based on file structure
- Lightweight vs. heavy component splitting
- Fix for “package.json not found” install bug

📂 Repo name: `react_on_rails-demo-v15-ssr-auto-registration-bundle-splitting`

📚 Part of the [React on Rails Demo Series](https://github.com/shakacode?tab=repositories&q=react_on_rails-demo)
```
