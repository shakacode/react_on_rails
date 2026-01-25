# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure Guidelines

### Analysis Documents

When creating analysis documents (deep dives, investigations, historical context):
- **Location**: Place in `/analysis` directory
- **Format**: Use Markdown (.md)
- **Naming**: Use descriptive kebab-case names (e.g., `rake-task-duplicate-analysis.md`)
- **Purpose**: Keep detailed analyses separate from top-level project files

Examples:
- `/analysis/rake-task-duplicate-analysis.md` - Historical analysis of duplicate rake task bug
- `/analysis/feature-investigation.md` - Investigation of a specific feature or issue

Top-level documentation (like README.md, CONTRIBUTING.md) should remain at the root.

## ⚠️ CRITICAL REQUIREMENTS

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**
4. **ALWAYS let Prettier and RuboCop handle ALL formatting - never manually format**

These requirements are non-negotiable. CI will fail if not followed.

**CRITICAL - LOCAL TESTING REQUIREMENTS:**

1. **NEVER claim a test is "fixed" without running it locally first**
   - If working in Conductor workspace or similar isolated environment, clearly state: "Cannot test locally in isolated workspace"
   - If test requires specific environment (database, Redis, etc.), state: "Requires [X] setup not available in current environment"

2. **Distinguish hypothetical fixes from confirmed fixes:**
   - ✅ Use "This fixes..." or "Fixed" ONLY after local verification
   - ⚠️ Use "This SHOULD fix..." or "Proposed fix (UNTESTED)" when you haven't verified
   - 📋 Use "Analysis suggests..." or "Root cause appears to be..." for investigation without fixes

3. **When analyzing CI failures:**
   - Clearly mark all analysis as "UNTESTED - requires local reproduction" unless verified
   - Provide exact commands to reproduce and test the fix locally
   - State why you cannot test if applicable (workspace restrictions, missing services, etc.)

4. **Prefer local testing over CI iteration:**
   - Don't push "hopeful" fixes and wait for CI feedback
   - Test locally first whenever technically possible
   - Document what you tested and what results you got

5. **Document your testing:**
   - Include test commands in commit messages for complex fixes
   - Note in PR descriptions which fixes were tested locally vs. which are hypothetical
   - Explain any testing limitations encountered

**See also**: When facing complex PRs with multiple CI failures, refer to `.claude/docs/pr-splitting-strategy.md` for guidance on splitting large PRs into smaller, more manageable pieces.

---

## 🚀 COMMIT AND PUSH BY DEFAULT

**When confident in your changes, commit and push without asking for permission.**

- After completing a task successfully, commit and push immediately
- Run relevant tests locally first to verify changes work
- Don't wait for explicit user approval if you've tested and are confident
- **ALWAYS monitor CI after pushing** - check status and address any failures proactively
- Keep monitoring until CI passes or issues are resolved

This saves time and keeps the workflow moving efficiently.

---

## 🚨 AVOIDING CI FAILURE CYCLES

**CRITICAL**: Large-scale changes (directory structure, configs, workflows) require comprehensive local testing BEFORE pushing.

**⚠️ If you're making changes that affect**:
- Directory structure or file paths
- Build configurations (package.json, webpack, etc.)
- CI workflows (.github/workflows/*.yml)
- Multiple files across the codebase

**STOP and read** → [`.claude/docs/avoiding-ci-failure-cycles.md`](.claude/docs/avoiding-ci-failure-cycles.md)

### The 15-Minute Rule

Before pushing ANY commit, ask yourself:

> "If I spent 15 more minutes testing locally, would I discover this issue before CI does?"

If **YES**, spend the 15 minutes. CI iteration is expensive (10-30 min/cycle). Local testing is fast (seconds to minutes).

### Red Flags - You're Using CI as a Test Environment

🚩 Multiple "Fix" commits in a row
🚩 CI keeps failing on different tests each push
🚩 Commit messages like "This should fix it" without local verification
🚩 Changing configs without testing build scripts
🚩 Path changes without comprehensive grep

**If you see these patterns**: STOP pushing, test comprehensively locally, then push once.

### Mandatory Local Testing Checklist

**For infrastructure/config changes**:

```bash
# 1. Find all affected files FIRST
grep -r "old/path" . --exclude-dir=node_modules --exclude-dir=.git

# 2. Test build pipeline
rm -rf node_modules && pnpm install -r --frozen-lockfile
pnpm run build
pnpm run yalc:publish

# 3. Test relevant specs
bundle exec rake run_rspec:gem          # If you changed gem code
bundle exec rake run_rspec:dummy        # If you changed configs
bundle exec rake run_rspec:shakapacker_examples  # If you changed generators

# 4. Lint everything
bundle exec rubocop
pnpm run lint
```

**See full guide**: [`.claude/docs/avoiding-ci-failure-cycles.md`](.claude/docs/avoiding-ci-failure-cycles.md)

---

**🚀 AUTOMATIC: Git hooks are installed automatically during setup**

Git hooks will automatically run linting on **all changed files (staged + unstaged + untracked)** before each commit - making it fast while preventing CI failures!

Pre-commit hooks automatically run:
- **RuboCop** (auto-fix Ruby code style)
- **ESLint** (auto-fix JS/TS code style)
- **Prettier** (auto-format all supported files)
- **Trailing newline checks** (ensure all files end with newlines)

**Note:** Git hooks are for React on Rails gem developers only, not for users who install the gem.

## Development Commands

### Essential Commands

- **Install dependencies**: `bundle && pnpm install`
- **Run tests**:
  - Ruby tests: `rake run_rspec`
  - JavaScript tests: `pnpm run test` or `rake js_tests`
  - Playwright E2E tests: See Playwright section below
  - All tests: `rake` (default task runs lint and all tests except examples)
- **Linting** (MANDATORY BEFORE EVERY COMMIT):
  - **REQUIRED**: `bundle exec rubocop` - Must pass with zero offenses
  - All linters: `rake lint` (runs ESLint and RuboCop)
  - ESLint only: `pnpm run lint` or `rake lint:eslint`
  - RuboCop only: `rake lint:rubocop`
  - GitHub Action files (workflows, reusable actions, etc.): `actionlint`
  - YAML files: `yamllint` (or validate the syntax with Ruby if it isn't installed). Do _not_ try to run RuboCop on `.yml` files.
- **Code Formatting**:
  - Format code with Prettier: `rake autofix`
  - Check formatting without fixing: `pnpm run format.listDifferent`
- **Build**: `pnpm run build` (compiles TypeScript to JavaScript in packages/react-on-rails/lib)
- **Type checking**: `pnpm run type-check`
- **RBS Type Checking**:
  - Validate RBS signatures: `bundle exec rake rbs:validate`
  - Run Steep type checker: `bundle exec rake rbs:steep`
  - Run both: `bundle exec rake rbs:all`
  - List RBS files: `bundle exec rake rbs:list`
- **⚠️ MANDATORY BEFORE GIT PUSH**: `bundle exec rubocop` and fix ALL violations + ensure trailing newlines
- Never run `npm` commands, only equivalent pnpm ones

### Replicating CI Failures Locally

**CRITICAL: NEVER wait for CI to verify fixes. Always replicate failures locally first.**

**When Analyzing CI Failures:**

1. **First, reproduce the failure locally** using the tools below
2. **If you cannot reproduce locally**, clearly state why:
   - "Working in Conductor isolated workspace - cannot run full Rails app"
   - "Requires Docker/Redis/PostgreSQL not available in current environment"
   - "Integration tests need full webpack build pipeline not set up locally"
3. **Mark all proposed fixes as UNTESTED** until they can be verified:
   - ❌ DON'T: "This fixes the integration test failures"
   - ✅ DO: "This SHOULD fix the integration test failures (UNTESTED - requires local Rails app with webpack)"
4. **Provide reproduction steps** even if you can't execute them:
   - Include exact commands to run
   - Document environment requirements
   - Explain what success looks like

#### Switch Between CI Configurations

The project tests against two configurations:
- **Latest**: Ruby 3.4, Node 22, Shakapacker 9.3.0, React 19 (runs on all PRs)
- **Minimum**: Ruby 3.2, Node 20, Shakapacker 8.2.0, React 18 (runs only on master)

```bash
# Check your current configuration
bin/ci-switch-config status

# Switch to minimum dependencies (for debugging minimum CI failures)
bin/ci-switch-config minimum

# Switch back to latest dependencies
bin/ci-switch-config latest
```

**See `SWITCHING_CI_CONFIGS.md` for detailed usage and troubleshooting.**

**See `react_on_rails/spec/dummy/TESTING_LOCALLY.md` for local testing tips and known issues.**

#### Re-run Failed CI Jobs

```bash
# Automatically detects and re-runs only the failed CI jobs
bin/ci-rerun-failures

# Search recent commits for failures (when current commit is clean/in-progress)
bin/ci-rerun-failures --previous

# Or for a specific PR number
bin/ci-rerun-failures 1964
```

This script:
- ✨ **Fetches actual CI failures** from GitHub using `gh` CLI
- 🎯 **Runs only what failed** - no wasted time on passing tests
- ⏳ **Waits for in-progress CI** - offers to poll until completion
- 🔍 **Searches previous commits** - finds failures before your latest push
- 📋 **Shows you exactly what will run** before executing
- 🚀 **Maps CI jobs to local commands** automatically

#### Run Only Failed Examples

When RSpec tests fail, run just those specific examples:

```bash
# Copy failure output from GitHub Actions, then:
pbpaste | bin/ci-run-failed-specs        # macOS
# xclip -o | bin/ci-run-failed-specs     # Linux (requires: apt install xclip)
# wl-paste | bin/ci-run-failed-specs     # Wayland (requires: apt install wl-clipboard)

# Or pass spec paths directly:
bin/ci-run-failed-specs './spec/system/integration_spec.rb[1:1:1:1]'

# Or from a file:
bin/ci-run-failed-specs < failures.txt
```

This script:
- 🎯 **Runs only failing examples** - not the entire test suite
- 📋 **Parses RSpec output** - extracts spec paths automatically
- 🔄 **Deduplicates** - removes duplicate specs
- 📁 **Auto-detects directory** - runs from react_on_rails/spec/dummy when needed

## RBS Type Checking

React on Rails uses RBS (Ruby Signature) for static type checking with Steep.

### Quick Start

- **Validate signatures**: `bundle exec rake rbs:validate` (run by CI)
- **Run type checker**: `bundle exec rake rbs:steep` (currently disabled in CI due to existing errors)
- **Runtime checking**: Enabled by default in tests when `rbs` gem is available

### Runtime Type Checking

Runtime type checking is **ENABLED BY DEFAULT** during test runs for:
- `rake run_rspec:gem` - Unit tests
- `rake run_rspec:dummy` - Integration tests
- `rake run_rspec:dummy_no_turbolinks` - Integration tests without Turbolinks

**Performance Impact**: Runtime type checking adds overhead (typically 5-15%) to test execution. This is acceptable during development and CI as it catches type errors in actual execution paths that static analysis might miss.

To disable runtime checking (e.g., for faster test iterations during development):
```bash
DISABLE_RBS_RUNTIME_CHECKING=true rake run_rspec:gem
```

**When to disable**: Consider disabling during rapid test-driven development cycles where you're running tests frequently. Re-enable before committing to catch type violations.

### Adding Type Signatures

When creating new Ruby files in `lib/react_on_rails/`:

1. **Create RBS signature**: Add `sig/react_on_rails/filename.rbs`
2. **Add to Steepfile**: Include `check "lib/react_on_rails/filename.rb"` in Steepfile
3. **Validate**: Run `bundle exec rake rbs:validate`
4. **Type check**: Run `bundle exec rake rbs:steep`
5. **Fix errors**: Address any type errors before committing

### Files Currently Type-Checked

See `Steepfile` for the complete list. Core files include:
- `lib/react_on_rails.rb`
- `lib/react_on_rails/configuration.rb`
- `lib/react_on_rails/helper.rb`
- `lib/react_on_rails/packer_utils.rb`
- `lib/react_on_rails/server_rendering_pool.rb`
- And 5 more (see Steepfile for full list)

### Pro Package Type Checking

The Pro package has its own RBS signatures in `react_on_rails_pro/sig/`.

Validate Pro signatures:
```bash
cd react_on_rails_pro && bundle exec rake rbs:validate
```
## Changelog

**IMPORTANT: This is a monorepo with TWO separate changelogs:**
- **Open Source**: `/CHANGELOG.md` - for react_on_rails gem and npm package
- **Pro**: `/CHANGELOG_PRO.md` - for react_on_rails_pro gem and npm packages

When making changes, update the **appropriate changelog(s)**:
- Open-source features/fixes → Update `/CHANGELOG.md`
- Pro-only features/fixes → Update `/CHANGELOG_PRO.md`
- Changes affecting both → Update **BOTH** changelogs

### Changelog Guidelines

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Version management after releases**:
  - Open source: `bundle exec rake update_changelog`
  - Pro: `bundle exec rake update_changelog CHANGELOG=CHANGELOG_PRO.md`
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples

### Beta Release Changelog Curation

When consolidating beta versions into a stable release, carefully curate entries to include only user-facing changes:

**Remove these types of entries:**

1. **Developer-only tooling**:
   - yalc publish fixes (local development tool)
   - Git dependency support (contributor workflow)
   - CI/build script improvements
   - Internal tooling changes

2. **Beta-specific fixes**:
   - Bugs introduced during the beta cycle (not present in last stable)
   - Fixes for new beta-only features (e.g., bin/dev in 16.2.0.beta)
   - Generator handling of beta/RC version formats

3. **Pro-specific features** (move to Pro changelog):
   - Node renderer fixes/improvements
   - Streaming-related changes
   - Async loading features (Pro-exclusive)

**Keep these types of entries:**

1. **User-facing fixes**:
   - Bugs that existed in previous stable release (e.g., 16.1.x)
   - Compatibility fixes (Rails version support, etc.)
   - Performance improvements affecting all users

2. **Breaking changes**:
   - API changes requiring migration
   - Removed methods/features
   - Configuration changes

**Investigation process:**

For each suspicious entry:
1. Check git history: `git log --oneline <last_stable>..<current_beta> -- <file>`
2. Determine when bug was introduced (stable vs beta cycle)
3. Verify whether fix applies to stable users or only beta users
4. Check PR description for context about what was broken

**Example reference:** See [PR #2072](https://github.com/shakacode/react_on_rails/pull/2072) for a complete example of beta changelog curation with detailed investigation notes.

## ⚠️ FORMATTING RULES

**Prettier is the SOLE authority for formatting non-Ruby files, and RuboCop for formatting Ruby files. NEVER manually format code.**

### Standard Workflow
1. Make code changes
2. Run `rake autofix` or `pnpm run format`
3. Commit changes

### Merge Conflict Resolution Workflow
**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **VERIFY FILE PATHS** - if the conflict involved directory structure:
   - Check if any hardcoded paths need updating
   - Run: `grep -r "old/path" . --exclude-dir=node_modules`
   - Pay special attention to package.json, webpack configs
   - **Test affected scripts:** If package.json changed, run `pnpm run prepack`
3. **Add resolved files**: `git add .` (or specific files)
4. **Auto-fix everything**: `rake autofix`
5. **Add any formatting changes**: `git add .`
6. **Continue rebase/merge**: `git rebase --continue` or `git commit`
7. **TEST CRITICAL SCRIPTS if build configs changed:**
   ```bash
   pnpm run prepack          # Test prepack script
   pnpm run yalc:publish     # Test yalc publish if package structure changed
   rake run_rspec:gem        # Run relevant test suites
   ```

**❌ NEVER manually format during conflict resolution** - this causes formatting wars between tools.
**❌ NEVER blindly accept path changes** - verify they're correct for current structure.
**❌ NEVER skip testing after resolving conflicts in build configs** - silent failures are dangerous.

### Debugging Formatting Issues
- Check current formatting: `pnpm run format.listDifferent`
- Fix all formatting: `rake autofix`
- If CI fails on formatting, always run automated fixes, never manual fixes

### Development Setup Commands

- **Initial setup**: `bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake`
- **Prepare examples**: `rake shakapacker_examples:gen_all`
- **Generate node package**: `rake node_package`
- **Run single test example**: `rake run_rspec:example_basic`

### Test Environment Commands

- **Dummy app tests**: `rake run_rspec:dummy`
- **Gem-only tests**: `rake run_rspec:gem`
- **All tests except examples**: `rake all_but_examples`

## Testing Build and Package Scripts

@.claude/docs/testing-build-scripts.md

## Master Branch Health Monitoring

@.claude/docs/master-health-monitoring.md

## Managing File Paths in Configuration Files

@.claude/docs/managing-file-paths.md

## Project Architecture

### Monorepo Structure

This is a monorepo containing both the open-source package and the Pro package:

- **Open Source**: Root directory contains the main React on Rails gem and package
- **Pro Package**: `react_on_rails_pro/` contains the Pro features (separate linting/formatting config)
- **Ruby gem**: Located in `lib/`, provides Rails integration and server-side rendering
- **NPM package**: Located in `packages/react-on-rails/src/`, provides client-side React integration

**IMPORTANT**: The `react_on_rails_pro/` directory has its own Prettier/ESLint configuration. When CI runs, it lints both directories separately. The pre-commit hooks will catch issues in both directories.

### Core Components

#### Ruby Side (`lib/react_on_rails/`)

- **`helper.rb`**: Rails view helpers for rendering React components
- **`server_rendering_pool.rb`**: Manages Node.js processes for server-side rendering
- **`configuration.rb`**: Global configuration management
- **`engine.rb`**: Rails engine integration
- **Generators**: Located in `lib/generators/react_on_rails/`

#### JavaScript/TypeScript Side (`packages/react-on-rails/src/`)

- **`ReactOnRails.ts`**: Main entry point for client-side functionality
- **`serverRenderReactComponent.ts`**: Server-side rendering logic
- **`ComponentRegistry.ts`**: Manages React component registration
- **`StoreRegistry.ts`**: Manages Redux store registration

### Build System

- **Ruby**: Standard gemspec-based build
- **JavaScript**: TypeScript compilation to `packages/react-on-rails/lib/`
- **Testing**: Jest for JS, RSpec for Ruby
- **Linting**: ESLint for JS/TS, RuboCop for Ruby

### Examples and Testing

- **Dummy app**: `react_on_rails/spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Defined in `rakelib/` for various development operations

## Debugging Webpack Configuration Issues

When encountering issues with Webpack/Shakapacker configuration (e.g., components not rendering, CSS modules failing), use this debugging approach:

### 1. Create Debug Scripts

Create temporary debug scripts in the dummy app root to inspect the actual webpack configuration:

```javascript
// debug-webpack-rules.js - Inspect all webpack rules
const { generateWebpackConfig } = require('shakapacker');

const config = generateWebpackConfig();

console.log('=== Webpack Rules ===');
console.log(`Total rules: ${config.module.rules.length}\n`);

config.module.rules.forEach((rule, index) => {
  console.log(`\nRule ${index}:`);
  console.log('  test:', rule.test);
  console.log('  use:', Array.isArray(rule.use) ? rule.use.map(u => typeof u === 'string' ? u : u.loader) : rule.use);

  if (rule.test) {
    console.log('  Matches .scss:', rule.test.test && rule.test.test('example.scss'));
    console.log('  Matches .module.scss:', rule.test.test && rule.test.test('example.module.scss'));
  }
});
```

```javascript
// debug-webpack-with-config.js - Inspect config AFTER modifications
const commonWebpackConfig = require('./config/webpack/commonWebpackConfig');

const config = commonWebpackConfig();

console.log('=== Webpack Rules AFTER commonWebpackConfig ===');
config.module.rules.forEach((rule, index) => {
  if (rule.test && rule.test.test('example.module.scss')) {
    console.log(`\nRule ${index} (CSS Modules):`);
    if (Array.isArray(rule.use)) {
      rule.use.forEach((loader, i) => {
        if (loader.loader && loader.loader.includes('css-loader')) {
          console.log(`  css-loader options:`, loader.options);
        }
      });
    }
  }
});
```

### 2. Run Debug Scripts

```bash
cd react_on_rails/spec/dummy  # or react_on_rails_pro/spec/dummy
NODE_ENV=test RAILS_ENV=test node debug-webpack-rules.js
NODE_ENV=test RAILS_ENV=test node debug-webpack-with-config.js
```

### 3. Analyze Output

- Verify the rules array structure matches expectations
- Check that loader options are correctly set
- Confirm rules only match intended file patterns
- Ensure modifications don't break existing loaders

### 4. Common Issues & Solutions

**CSS Modules breaking after Shakapacker upgrade:**
- Shakapacker 9.0+ defaults to `namedExport: true` for CSS Modules
- Existing code using `import styles from './file.module.css'` will fail
- Override in webpack config:
  ```javascript
  loader.options.modules.namedExport = false;
  loader.options.modules.exportLocalsConvention = 'camelCase';
  ```

**Rules not matching expected files:**
- Use `.test.test('example.file')` to check regex matching
- Shakapacker may combine multiple file extensions in single rules
- Test with actual filenames from your codebase

### 5. Clean Up

Always remove debug scripts before committing:
```bash
rm debug-*.js
```

## Important Notes

- Use `yalc` for local development when testing with external apps
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)
- Only use `pnpm` as the JS package manager, never `npm` or `yarn`

## Playwright E2E Testing

### Overview
Playwright E2E testing is integrated via the `cypress-on-rails` gem (v1.19+), which provides seamless integration between Playwright and Rails. This allows you to control Rails application state during tests, use factory_bot, and more.

### Setup
The gem and Playwright are already configured. To install Playwright browsers:

```bash
cd react_on_rails/spec/dummy
pnpm playwright install --with-deps
```

### Running Playwright Tests

**Note:** Playwright will automatically start the Rails server on port 5017 before running tests. You don't need to manually start the server.

```bash
cd react_on_rails/spec/dummy

# Run all tests (Rails server auto-starts)
pnpm test:e2e

# Run tests in UI mode (interactive debugging)
pnpm test:e2e:ui

# Run tests with visible browser
pnpm test:e2e:headed

# Debug a specific test
pnpm test:e2e:debug

# View test report
pnpm test:e2e:report

# Run specific test file
pnpm test:e2e e2e/playwright/e2e/react_on_rails/basic_components.spec.js
```

### Writing Tests

Tests are located in `react_on_rails/spec/dummy/e2e/playwright/e2e/`. The gem provides helpful commands for Rails integration:

```javascript
import { test, expect } from "@playwright/test";
import { app, appEval, appFactories } from '../../support/on-rails';

test.describe("My React Component", () => {
  test.beforeEach(async ({ page }) => {
    // Clean database before each test
    await app('clean');
  });

  test("should interact with component", async ({ page }) => {
    // Create test data using factory_bot
    await appFactories([['create', 'user', { name: 'Test User' }]]);

    // Or run arbitrary Ruby code
    await appEval('User.create!(email: "test@example.com")');

    // Navigate and test
    await page.goto("/");
    const component = page.locator('#MyComponent-react-component-0');
    await expect(component).toBeVisible();
  });
});
```

### Available Rails Helpers

The `cypress-on-rails` gem provides these helpers (imported from `support/on-rails.js`):

- `app('clean')` - Clean database
- `appEval(code)` - Run arbitrary Ruby code
- `appFactories(options)` - Create records via factory_bot
- `appScenario(name)` - Load predefined scenario
- See `e2e/playwright/app_commands/` for available commands

### Creating App Commands

Add custom commands in `e2e/playwright/app_commands/`:

```ruby
# e2e/playwright/app_commands/my_command.rb
CypressOnRails::SmartFactoryWrapper.configure(
  always_reload: !Rails.configuration.cache_classes,
  factory: :factory_bot,
  dir: "{#{FactoryBot.definition_file_paths.join(',')}}"
)

command 'my_command' do |options|
  # Your custom Rails code
  { success: true, data: options }
end
```

### Test Organization

```
react_on_rails/spec/dummy/e2e/
├── playwright.config.js          # Playwright configuration
├── playwright/
│   ├── support/
│   │   ├── index.js              # Test setup
│   │   └── on-rails.js           # Rails helper functions
│   ├── e2e/
│   │   ├── react_on_rails/       # React on Rails specific tests
│   │   │   └── basic_components.spec.js
│   │   └── rails_examples/       # Example tests
│   │       └── using_scenarios.spec.js
│   └── app_commands/             # Rails helper commands
│       ├── clean.rb
│       ├── factory_bot.rb
│       ├── eval.rb
│       └── scenarios/
│           └── basic.rb
```

### Best Practices

- Use `app('clean')` in `beforeEach` to ensure clean state
- Leverage Rails helpers (`appFactories`, `appEval`) instead of UI setup
- Test React on Rails specific features: SSR, hydration, component registry
- Use component IDs like `#ComponentName-react-component-0` for selectors
- Monitor console errors during tests
- Test across different browsers with `--project` flag

### Debugging

- Run in UI mode: `pnpm test:e2e:ui`
- Use `page.pause()` to pause execution
- Check `playwright-report/` for detailed results after test failures
- Enable debug logging in `playwright.config.js`

### CI Integration

Playwright E2E tests run via GitHub Actions (`.github/workflows/playwright.yml`). The workflow:
- **Only runs on pushes to master and manual dispatch (workflow_dispatch)**
- Does NOT automatically run on PRs
- Uses GitHub Actions annotations for test failures
- Uploads HTML reports as artifacts (available for 30 days)
- Auto-starts Rails server before running tests

### Ensuring E2E Tests Pass Before Merging

**CRITICAL: Playwright E2E tests do NOT run automatically on PRs. You must run them locally or trigger manually.**

1. **Run tests locally BEFORE pushing your PR:**
   ```bash
   cd react_on_rails/spec/dummy
   pnpm test:e2e
   ```

2. **If you need to verify on CI, manually trigger the workflow:**
   ```bash
   # Trigger workflow on your branch
   gh workflow run "Playwright E2E Tests" --ref your-branch-name

   # Monitor the run
   gh run watch
   ```

3. **Download test artifacts if tests fail:**
   ```bash
   # List artifacts from a failed run
   gh run view <run-id> --json jobs

   # Download playwright report
   gh run download <run-id> -n playwright-report
   ```

**DO NOT merge PRs without running Playwright tests.** The CI does not automatically run these tests on PRs - you must verify locally or trigger manually.

## Rails Engine Development Nuances

React on Rails is a **Rails Engine**, which has important implications for development:

### Automatic Rake Task Loading

**CRITICAL**: Rails::Engine automatically loads all `.rake` files from `lib/tasks/` directory. **DO NOT** use a `rake_tasks` block to explicitly load them, as this causes duplicate task execution.

```ruby
# ❌ WRONG - Causes duplicate execution
module ReactOnRails
  class Engine < ::Rails::Engine
    rake_tasks do
      load File.expand_path("../tasks/generate_packs.rake", __dir__)
      load File.expand_path("../tasks/assets.rake", __dir__)
      load File.expand_path("../tasks/locale.rake", __dir__)
    end
  end
end

# ✅ CORRECT - Rails::Engine loads lib/tasks/*.rake automatically
module ReactOnRails
  class Engine < ::Rails::Engine
    # Rake tasks are automatically loaded from lib/tasks/*.rake by Rails::Engine
    # No explicit loading needed
  end
end
```

**When to use `rake_tasks` block:**
- Tasks are in a **non-standard location** (not `lib/tasks/`)
- You need to **programmatically generate** tasks
- You need to **pass context** to the tasks

**Historical Context**: PR #1770 added explicit rake task loading, causing webpack builds and pack generation to run twice during `rake assets:precompile`. This was fixed in PR #2052. See `analysis/rake-task-duplicate-analysis.md` for full details.

### Engine Initializers and Hooks

Engines have specific initialization hooks that run at different times:

```ruby
module ReactOnRails
  class Engine < ::Rails::Engine
    # Runs after Rails initializes but before routes are loaded
    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    # Runs during Rails initialization, use for validations
    initializer "react_on_rails.validate_version" do
      config.after_initialize do
        # Validation logic here
      end
    end
  end
end
```

### Engine vs Application Code

- **Engine code** (`lib/react_on_rails/`): Runs in the gem context, has limited access to host application
- **Host application code**: The Rails app that includes the gem
- **Generators** (`lib/generators/react_on_rails/`): Run in host app context during setup

### Testing Engines

- **Dummy app** (`react_on_rails/spec/dummy/`): Full Rails app for integration testing
- **Unit tests** (`react_on_rails/spec/react_on_rails/`): Test gem code in isolation
- Always test both contexts: gem code alone and gem + host app integration

### Common Pitfalls

1. **Assuming host app structure**: Don't assume `app/javascript/` exists—it might not in older apps
2. **Path resolution**: Use `Rails.root` for host app paths, not relative paths
3. **Autoloading**: Engine code follows Rails autoloading rules but with a different load path
4. **Configuration**: Engine config is separate from host app config—use `ReactOnRails.configure`

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/packages/react-on-rails/lib`
- `/node_modules`, `/react_on_rails/spec/dummy/node_modules`, `/react_on_rails/spec/dummy/tmp`
- `/react_on_rails/spec/dummy/app/assets/webpack`, `/react_on_rails/spec/dummy/log`
- `/react_on_rails/spec/dummy/e2e/playwright-report`, `/react_on_rails/spec/dummy/test-results`

## Conductor Compatibility (mise Version Manager)

### Problem

Conductor runs commands in a non-interactive shell that doesn't source `.zshrc`. This means mise's shell hook (which reorders PATH based on `.tool-versions`) never runs. Commands will use system Ruby/Node instead of project-specified versions.

**Symptoms:**
- `ruby --version` returns system Ruby (e.g., 2.6.10) instead of project Ruby (e.g., 3.3.4)
- Pre-commit hooks fail with wrong tool versions
- `bundle` commands fail due to incompatible Ruby versions
- Node/pnpm commands use wrong Node version

### Solution

Use the `bin/conductor-exec` wrapper to ensure commands run with correct tool versions:

```bash
# Instead of:
ruby --version
bundle exec rubocop
pnpm install
git commit -m "message"

# Use:
bin/conductor-exec ruby --version
bin/conductor-exec bundle exec rubocop
bin/conductor-exec pnpm install
bin/conductor-exec git commit -m "message"  # Pre-commit hooks work correctly
```

### Reference

See [react_on_rails-demos#105](https://github.com/shakacode/react_on_rails-demos/issues/105) for detailed problem analysis and solution development.
