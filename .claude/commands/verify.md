# Verify Command

Run a local verification loop for the current branch before creating or updating a PR.

Use `/verify` for local pre-PR checks. Use `/run-ci` when you need the CI change detector or want to
reproduce CI job selection locally. See also `.claude/docs/avoiding-ci-failure-cycles.md` for the failure patterns this
command is designed to prevent.

## Instructions

1. Read `AGENTS.md` first. It is the canonical source for required commands, formatting, boundaries, and ask-first areas.
2. Inspect the current branch diff with `git status --short`, `git diff --name-only origin/main...HEAD`, and
   `git diff --stat origin/main...HEAD`.
3. Decide the required verification set that covers the changed surface area using the **Scope Guide** below. Always
   include `bundle exec rubocop` before creating a commit, even when the changed surface is documentation-only, because
   RuboCop scans all Ruby files, not just changed or staged ones, so docs-only commits can still expose pre-existing
   Ruby offenses that CI will catch.
4. Run each command in order and stop on the first failure. Report the failing command, the relevant error output, and the next fix to attempt.
5. For formatting failures (Prettier or rubocop auto-fixable offenses), run `rake autofix`; do not manually edit formatting-only changes.
6. After one or more edits for a failure, restart at the failed command and continue forward. Track a loop counter per
   command:
   - Increment the counter when the same command fails on the same first item (test name, RuboCop offense, or Prettier
     file) as the previous run.
   - Reset the counter when the first failing item changes or when you advance to a different command.
   - Stop and report after three consecutive cycles on the same item, unless the user asks you to keep going.
   - Stop immediately and report a regression if a later fix causes a command that previously passed to fail again on
     the same file, symbol, or test item. Ask the user how to proceed rather than attempting a blind revert.
   - Do not claim a failure is fixed until the command passes locally.
7. Finish with the exact commands run and their pass/fail status.

## Default Verification Order

Use this order unless the changed files make a narrower or broader set clearly appropriate:

1. Formatting and whitespace:
   - `git diff --check origin/main...HEAD` for committed branch content before creating or updating a PR; detects trailing whitespace and conflict markers, not Prettier formatting
   - `pnpm start format.listDifferent`
2. Mandatory pre-commit gate:
   - `bundle exec rubocop` - **mandatory gate before every commit**; see Instructions step 3 for why this still applies to documentation-only commits; it lints Ruby, not Markdown or YAML
3. Ruby:
   - `bundle exec rake rbs:validate` when Ruby signatures or public Ruby APIs changed
   - targeted `bundle exec rspec ...` for changed Ruby behavior
4. JavaScript and TypeScript:
   - `pnpm run build`
   - `pnpm run lint`
   - `pnpm run type-check`
   - targeted `pnpm --filter react-on-rails run test` for react-on-rails package tests, or
     `pnpm --filter react-on-rails exec jest <relative-test-file-path>` for targeted test file runs; the path is
     relative to `packages/react-on-rails/`, for example `tests/ReactOnRailsClient.test.ts`
   - `pnpm run test` when broad package behavior changed or the touched files are not covered by a narrower package test
   - `cd react_on_rails/spec/dummy && pnpm test:e2e` when the branch changes SSR rendering, client hydration, or
     browser-visible integration behavior; on fresh Linux environments, run `pnpm playwright install --with-deps` in
     that directory first, or run `pnpm playwright install` when only browser binaries are missing
5. Docs:
   - `script/check-docs-sidebar` when docs under `docs/oss/` or `docs/pro/` changed
   - `bin/check-links` when Markdown URLs were added or edited; do not substitute an ad hoc link checker unless the
     branch changes `bin/check-links`, `.lychee.toml`, or the documented link-check workflow itself
6. CI workflows and YAML:
   - Confirm the workflow edit itself was approved because `AGENTS.md` marks changes to `.github/workflows/` as ask-first
   - `actionlint` when any `.github/workflows/` file changed
   - `yamllint .github/` when any `.github/workflows/` file changed
   - Do not run RuboCop on `.yml` files
7. Broad suite — pick the narrowest command that covers the change:
   - `rake all_but_examples` for broad coverage without the slow generated-examples suite
   - `rake` when shared runtime behavior, generators, cross-package contracts, or release-critical paths changed
   - `rake lint` when a branch intentionally needs the complete lint gate across Ruby, JavaScript/TypeScript, and
     formatting; otherwise keep using the narrower lint commands above

## Scope Guide

- Ruby gem changes: run targeted RSpec, `bundle exec rubocop`, and RBS validation when signatures or public APIs changed.
- Dummy app or integration changes: run `rake run_rspec:dummy` or a targeted dummy spec such as `cd react_on_rails/spec/dummy && bundle exec rspec spec/path/to/spec.rb`. For changes that affect SSR rendering or client-side behavior, also run `cd react_on_rails/spec/dummy && pnpm test:e2e`.
- TypeScript package changes: run `pnpm run build`, package tests, `pnpm run lint`, and `pnpm run type-check`.
- Generated examples or scripts: run the relevant generator/script command plus formatting and linting.
- Documentation-only changes: run `pnpm start format.listDifferent`, sidebar validation for `docs/oss/` or `docs/pro/`, and `bin/check-links` for new or changed URLs. If committing, still run `bundle exec rubocop`; see Instructions step 3 for why this applies even to docs-only commits. RuboCop does not validate Markdown.
- `react_on_rails_pro/**/*.{js,ts,tsx,jsx,json,css,md}` changes: run `cd react_on_rails_pro && pnpm start format.listDifferent` (the Pro package's local Prettier check via its `nps` script) plus any focused tests for the changed surface.
- `react_on_rails_pro/**/*.rb` changes: run `(cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion)` and any targeted RSpec.
- GitHub Actions workflow changes: confirm the edit was approved per the `AGENTS.md` ask-first rule, then run `actionlint` and `yamllint .github/`. Do not run RuboCop on `.yml` files.
- Anything not listed above (for example, Rakefile edits, generator templates, RBS-only changes, or build scripts): apply the narrowest set of checks that covers the changed surface and explain the choice in the output.

## Output Format

Use this concise summary:

```text
Verification:
- PASS git diff --check origin/main...HEAD
- FAIL pnpm start format.listDifferent

Next fix:
- Run `rake autofix` to fix Prettier formatting, then rerun `pnpm start format.listDifferent`.
```

If a command is intentionally skipped, explain why in one line. Prefer local verification over waiting for CI.
