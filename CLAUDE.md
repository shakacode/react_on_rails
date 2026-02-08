# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Critical Requirements

**BEFORE EVERY COMMIT/PUSH:**

1. **ALWAYS run `bundle exec rubocop` and fix ALL violations**
2. **ALWAYS ensure files end with a newline character**
3. **NEVER push without running full lint check first**
4. **ALWAYS let Prettier and RuboCop handle ALL formatting - never manually format**
5. **NEVER claim a test is "fixed" without running it locally first** — use "This SHOULD fix..." for unverified changes
6. **Prefer local testing over CI iteration** — don't push "hopeful" fixes

When confident in your changes, commit and push without asking for permission. **ALWAYS monitor CI after pushing.**

## Avoiding CI Failure Cycles

Apply the **15-minute rule**: "If I spent 15 more minutes testing locally, would I discover this issue before CI does?" If yes, spend the 15 minutes. For infrastructure/config changes, read `.claude/docs/avoiding-ci-failure-cycles.md` first.

## Development Commands

- **Install dependencies**: `bundle && pnpm install`
- **Run tests**: `rake run_rspec` (Ruby), `pnpm run test` (JS), `rake` (all)
- **Playwright E2E**: `cd react_on_rails/spec/dummy && pnpm test:e2e` (see `.claude/docs/playwright-e2e-testing.md`)
- **Linting**: `bundle exec rubocop` (Ruby), `rake lint` (all), `pnpm run lint` (ESLint)
- **GitHub Actions**: `actionlint`; YAML: `yamllint`. Do _not_ run RuboCop on `.yml` files.
- **Formatting**: `rake autofix` or `pnpm start format`
- **Build**: `pnpm run build`
- **Type checking**: `pnpm run type-check`; RBS: `bundle exec rake rbs:validate` (see `.claude/docs/rbs-type-checking.md`)
- **Setup**: `bundle && pnpm install && rake shakapacker_examples:gen_all && rake node_package && rake`
- **Test subsets**: `rake run_rspec:dummy` (integration), `rake run_rspec:gem` (unit), `rake all_but_examples`
- **Single example**: `rake run_rspec:shakapacker_examples_basic`
- Never run `npm` commands, only `pnpm`

**Replicating CI failures**: See `.claude/docs/replicating-ci-failures.md` for config switching and re-running failed jobs.

## Formatting Rules

**Prettier owns non-Ruby formatting; RuboCop owns Ruby formatting. NEVER manually format.**

1. Make code changes → 2. Run `rake autofix` → 3. Commit

For merge conflicts, see `.claude/docs/merge-conflict-workflow.md`.

## Project Structure

- **Internal docs**: Place in `/internal/` directory (coordination, planning, contributor runbooks; kebab-case `.md` files).
- **Published docs** (`docs/`): Must go in subdirectories (`getting-started/`, `core-concepts/`, `building-features/`, `api-reference/`, `deployment/`, `migrating/`, `upgrading/`, `misc/`). Never place internal/process docs at `docs/` root.
- **Architecture**: See `.claude/docs/project-architecture.md` for monorepo layout, core components, and build system
- **Pro package**: See `react_on_rails_pro/CLAUDE.md` for Pro-specific guidance

## Changelog

Update `/CHANGELOG.md` for user-visible changes only. Use `/update-changelog` for guided updates. See `.claude/docs/changelog-guidelines.md` for format, rules, and Pro section conventions.

## Reference Docs

These guides are loaded on-demand when relevant:

- **Build/package scripts**: `.claude/docs/testing-build-scripts.md`
- **Master branch health**: `.claude/docs/master-health-monitoring.md`
- **File path management**: `.claude/docs/managing-file-paths.md`
- **Webpack debugging**: `.claude/docs/debugging-webpack.md`
- **Rails engine nuances**: `.claude/docs/rails-engine-nuances.md`
- **PR splitting**: `.claude/docs/pr-splitting-strategy.md`
- **Conductor compatibility**: Use `bin/conductor-exec` wrapper for correct mise/tool versions (see `.claude/docs/conductor-compatibility.md`)
