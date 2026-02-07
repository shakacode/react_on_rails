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
- `/analysis/v8-crash-retry-solution.md` - Analysis of V8 crash retry solution

Top-level documentation (like README.md, CONTRIBUTING.md) should remain at the root.

### Documentation Files (`docs/`)

The `docs/` directory is published to the [ShakaCode website](https://www.shakacode.com/react-on-rails/docs/). **Never place new docs at the `docs/` root** — they must go in the appropriate subdirectory:

| Content type | Directory |
|---|---|
| User getting-started guides | `docs/getting-started/` |
| Core architecture/concepts | `docs/core-concepts/` |
| Feature implementation guides | `docs/building-features/` |
| API/config reference | `docs/api-reference/` |
| Deployment & troubleshooting | `docs/deployment/` |
| Migration guides | `docs/migrating/` |
| Upgrade notes & release notes | `docs/upgrading/` |
| Internal/contributor docs (NOT published) | `docs/contributor-info/` |
| Miscellaneous | `docs/misc/` |

Files placed at the `docs/` root appear as uncategorized items at the top of the website sidebar, which looks broken.

## Critical Requirements

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**
4. **ALWAYS let Prettier and RuboCop handle ALL formatting - never manually format**
5. **NEVER claim a test is "fixed" without running it locally first:**
   - Use "This fixes..." or "Fixed" ONLY after local verification
   - Use "This SHOULD fix..." or "Proposed fix (UNTESTED)" when you haven't verified
   - Use "Analysis suggests..." or "Root cause appears to be..." for investigation without fixes
   - If you cannot test locally, clearly state why (workspace restrictions, missing services, etc.)
   - Include test commands in commit messages for complex fixes; note in PR descriptions which fixes were tested locally vs. hypothetical
6. **Prefer local testing over CI iteration** — don't push "hopeful" fixes

These requirements are non-negotiable. CI will fail if not followed.

**See also**: `.claude/docs/pr-splitting-strategy.md` for guidance on splitting complex PRs.

---

## Commit and Push by Default

**When confident in your changes, commit and push without asking for permission.**

- After completing a task successfully, commit and push immediately
- Run relevant tests locally first to verify changes work
- Don't wait for explicit user approval if you've tested and are confident
- **ALWAYS monitor CI after pushing** - check status and address any failures proactively
- Keep monitoring until CI passes or issues are resolved

---

## Avoiding CI Failure Cycles

Before pushing ANY commit, apply the **15-minute rule**: "If I spent 15 more minutes testing locally, would I discover this issue before CI does?" If yes, spend the 15 minutes.

For infrastructure/config changes (directory structure, package.json, webpack, CI workflows), **STOP and read** `.claude/docs/avoiding-ci-failure-cycles.md` before pushing.

---

**Git hooks are installed automatically during setup** and run linting on all changed files before each commit:
- **RuboCop** (auto-fix Ruby code style)
- **ESLint** (auto-fix JS/TS code style)
- **Prettier** (auto-format all supported files)
- **Trailing newline checks** (ensure all files end with newlines)

Git hooks are for React on Rails gem developers only, not for users who install the gem.

## Development Commands

### Essential Commands

- **Install dependencies**: `bundle && pnpm install`
- **Run tests**:
  - Ruby tests: `rake run_rspec`
  - JavaScript tests: `pnpm run test` or `rake js_tests`
  - Playwright E2E tests: `cd react_on_rails/spec/dummy && pnpm test:e2e` (see `.claude/docs/playwright-e2e-testing.md`)
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
  - Check formatting without fixing: `pnpm start format.listDifferent`
- **Build**: `pnpm run build` (compiles TypeScript to JavaScript in packages/react-on-rails/lib)
- **Type checking**: `pnpm run type-check`
- **RBS Type Checking**: `bundle exec rake rbs:validate` (see `.claude/docs/rbs-type-checking.md` for full guide)
- **MANDATORY BEFORE GIT PUSH**: `bundle exec rubocop` and fix ALL violations + ensure trailing newlines
- Never run `npm` commands, only equivalent pnpm ones

### Replicating CI Failures Locally

**NEVER wait for CI to verify fixes.** Always replicate failures locally first. See `.claude/docs/replicating-ci-failures.md` for CI config switching, re-running failed jobs, and running only failed examples.

### Development Setup Commands

- **Initial setup**: `bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake`
- **Prepare examples**: `rake shakapacker_examples:gen_all`
- **Generate node package**: `rake node_package`
- **Run single test example**: `rake run_rspec:shakapacker_examples_basic`

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

## Changelog

**IMPORTANT: This is a monorepo with a SINGLE unified changelog:**
- **`/CHANGELOG.md`** - for both react_on_rails (open source) and react_on_rails_pro

When making changes, update `/CHANGELOG.md`:
- Open-source features/fixes → Add to the regular category sections (#### Added, #### Fixed, etc.)
- Pro-only features/fixes → Add to the `#### Pro` section under the appropriate subcategory (##### Added, ##### Fixed, etc.)
- Changes affecting both → Add to the regular sections; Pro-specific details go in the Pro section

Each release version has an optional `#### Pro` section at the end that contains Pro-specific entries organized by the same categories.

### Changelog Guidelines

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Version management after releases**: `bundle exec rake update_changelog`
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples
- **Beta release curation**: See `.claude/commands/update-changelog.md` for beta-to-stable consolidation process

## Formatting Rules

**Prettier is the SOLE authority for formatting non-Ruby files, and RuboCop for formatting Ruby files. NEVER manually format code.**

### Standard Workflow
1. Make code changes
2. Run `rake autofix` or `pnpm start format`
3. Commit changes

### Merge Conflict Resolution Workflow
**CRITICAL**: When resolving merge conflicts, follow this exact sequence:

1. **Resolve logical conflicts only** - don't worry about formatting
2. **VERIFY FILE PATHS** - if the conflict involved directory structure:
   - Check if any hardcoded paths need updating
   - Run: `grep -r "old/path" . --exclude-dir=node_modules`
   - Pay special attention to package.json, webpack configs
   - **Test affected scripts:** If package.json changed, run `pnpm start build.prepack`
3. **Add resolved files**: `git add .` (or specific files)
4. **Auto-fix everything**: `rake autofix`
5. **Add any formatting changes**: `git add .`
6. **Continue rebase/merge**: `git rebase --continue` or `git commit`
7. **TEST CRITICAL SCRIPTS if build configs changed:**
   ```bash
   pnpm start build.prepack  # Test prepack script
   pnpm run yalc:publish     # Test yalc publish if package structure changed
   rake run_rspec:gem        # Run relevant test suites
   ```

**NEVER manually format during conflict resolution** - this causes formatting wars between tools.
**NEVER blindly accept path changes** - verify they're correct for current structure.
**NEVER skip testing after resolving conflicts in build configs** - silent failures are dangerous.

### Debugging Formatting Issues
- Check current formatting: `pnpm start format.listDifferent`
- Fix all formatting: `rake autofix`
- If CI fails on formatting, always run automated fixes, never manual fixes

## Project Architecture

### Monorepo Structure

This is a monorepo containing both the open-source package and the Pro package:

- **Open Source**: Root directory contains the main React on Rails gem and package
- **Pro Package**: `react_on_rails_pro/` contains the Pro features (separate linting/formatting config). See `react_on_rails_pro/CLAUDE.md` for Pro-specific development guidance.
- **Ruby gem**: Located in `react_on_rails/lib/`, provides Rails integration and server-side rendering
- **NPM package**: Located in `packages/react-on-rails/src/`, provides client-side React integration

**IMPORTANT**: The `react_on_rails_pro/` directory has its own Prettier/ESLint configuration. When CI runs, it lints both directories separately. The pre-commit hooks will catch issues in both directories.

### Core Components

#### Ruby Side (`react_on_rails/lib/react_on_rails/`)

- **`helper.rb`**: Rails view helpers for rendering React components
- **`server_rendering_pool.rb`**: Manages Node.js processes for server-side rendering
- **`configuration.rb`**: Global configuration management
- **`engine.rb`**: Rails engine integration
- **Generators**: Located in `react_on_rails/lib/generators/react_on_rails/`

#### JavaScript/TypeScript Side (`packages/react-on-rails/src/`)

- **`ReactOnRails.client.ts`**: Client-only entry point
- **`ReactOnRails.full.ts`**: Full entry point (client + server-side rendering support)
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
- **Rake tasks**: Development tasks in `react_on_rails/rakelib/`; monorepo-level tasks in root `rakelib/`

## Important Notes

- Use `yalc` for local development when testing with external apps
- Server-side rendering uses isolated Node.js processes
- React Server Components support available in Pro version
- Generated examples are in `gen-examples/` (ignored by git)
- Only use `pnpm` as the JS package manager, never `npm` or `yarn`

## Webpack Debugging

For debugging Webpack/Shakapacker configuration issues (components not rendering, CSS modules failing), see `.claude/docs/debugging-webpack.md`.

## Playwright E2E Testing

Run E2E tests: `cd react_on_rails/spec/dummy && pnpm test:e2e`. Tests do NOT run automatically on PRs — you must run locally or trigger manually. See `.claude/docs/playwright-e2e-testing.md` for setup, writing tests, and CI integration.

## Rails Engine Development

React on Rails is a Rails Engine. For important implications (automatic rake task loading, engine initializers, common pitfalls), see `.claude/docs/rails-engine-nuances.md`.

## IDE Configuration

Exclude these directories to prevent IDE slowdowns:

- `/coverage`, `/tmp`, `/gen-examples`, `/packages/react-on-rails/lib`
- `/node_modules`, `/react_on_rails/spec/dummy/node_modules`, `/react_on_rails/spec/dummy/tmp`
- `/react_on_rails/spec/dummy/app/assets/webpack`, `/react_on_rails/spec/dummy/log`
- `/react_on_rails/spec/dummy/e2e/playwright-report`, `/react_on_rails/spec/dummy/test-results`

## Conductor Compatibility

If using Conductor (non-interactive shell), use `bin/conductor-exec` wrapper for all commands to ensure correct mise/tool versions. See `.claude/docs/conductor-compatibility.md` for details.
