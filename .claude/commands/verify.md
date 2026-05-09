# Verify Command

Run a local verification loop for the current branch before creating or updating a PR.

Use `/verify` for local pre-PR checks. Use `/run-ci` when you need the CI change detector or want to
reproduce CI job selection locally.

For each failing command, limit the loop to three reruns after edits unless the user explicitly asks to keep debugging. If a
later fix reintroduces an earlier failure, stop and report the cycle instead of continuing indefinitely.

## Instructions

1. Read `AGENTS.md` first. It is the canonical source for required commands, formatting, boundaries, and ask-first areas.
2. Inspect the current branch diff with `git status --short`, `git diff --name-only origin/main...HEAD`, and
   `git diff --stat origin/main...HEAD`.
3. Decide the minimal sufficient verification set that covers the changed surface area.
4. Always include `bundle exec rubocop` before creating a commit, even when the changed surface is documentation-only, because `AGENTS.md` marks it mandatory before every commit.
5. Run each command in order and stop on the first failure. Report the failing command, the relevant error output, and the next fix to attempt.
6. For formatting failures (Prettier or rubocop auto-fixable offenses), run `rake autofix`; do not manually edit formatting-only changes.
7. After one or more edits for a failure, restart at the failed command and continue forward. For a single failing command, count each rerun after edits as one loop cycle and stop after three reruns for that same failure unless the user explicitly asks you to keep debugging. Do not claim a failure is fixed until the failed command passes locally. If the same command fails again after a fix attempt, or a later fix reintroduces an earlier failure, stop and report the cycle instead of retrying.
8. Finish with the exact commands run and their pass/fail status.

## Default Verification Order

Use this order unless the changed files make a narrower or broader set clearly appropriate:

1. Formatting and whitespace:
   - `git diff --check origin/main...HEAD` for committed branch content before creating or updating a PR; detects trailing whitespace and conflict markers, not Prettier formatting
   - `pnpm start format.listDifferent`
2. Ruby:
   - `bundle exec rubocop` - **mandatory gate before every commit, including documentation-only commits** (per `AGENTS.md`); it lints Ruby, not Markdown or YAML
   - `bundle exec rake rbs:validate` when Ruby signatures or public Ruby APIs changed
   - targeted `bundle exec rspec ...` for changed Ruby behavior
3. JavaScript and TypeScript:
   - `pnpm run build`
   - `pnpm run lint`
   - `pnpm run type-check`
   - `pnpm run test` when broad package behavior changed or the touched files are not covered by a narrower package test
   - targeted `pnpm --filter react-on-rails run test` for react-on-rails package tests, or
     `pnpm --filter react-on-rails exec jest -- <path>` for targeted test file runs
   - `cd react_on_rails/spec/dummy && pnpm test:e2e` when the branch changes SSR rendering, client hydration, or
     browser-visible integration behavior
4. Docs:
   - `script/check-docs-sidebar` when docs under `docs/` changed
   - `bin/check-links` when Markdown URLs were added or edited; do not substitute an ad hoc link checker unless the
     branch changes `bin/check-links`, `.lychee.toml`, or the documented link-check workflow itself
5. CI workflows and YAML:
   - Confirm the workflow edit itself was approved because `AGENTS.md` marks changes to `.github/workflows/` as ask-first
   - `actionlint` when any `.github/workflows/` file changed
   - `yamllint .github/` when any `.github/workflows/` file changed
   - Do not run RuboCop on `.yml` files
6. Broad suite — pick the narrowest command that covers the change:
   - `rake all_but_examples` for broad coverage without the slow generated-examples suite
   - `rake` when shared runtime behavior, generators, cross-package contracts, or release-critical paths changed
   - `rake lint` when a branch intentionally needs the complete lint gate across Ruby, JavaScript/TypeScript, and
     formatting; otherwise keep using the narrower lint commands above

## Scope Guide

- Ruby gem changes: run targeted RSpec, `bundle exec rubocop`, and RBS validation when signatures or public APIs changed.
- Dummy app or integration changes: run `rake run_rspec:dummy` or a targeted dummy spec such as `cd react_on_rails/spec/dummy && bundle exec rspec spec/path/to/spec.rb`. For changes that affect SSR rendering or client-side behavior, also run `cd react_on_rails/spec/dummy && pnpm test:e2e`.
- TypeScript package changes: run `pnpm run build`, package tests, `pnpm run lint`, and `pnpm run type-check`.
- Generated examples or scripts: run the relevant generator/script command plus formatting and linting.
- Documentation-only changes: run `pnpm start format.listDifferent`, sidebar validation for `docs/`, and `bin/check-links` for new or changed URLs. If committing, still run the repo-wide `bundle exec rubocop` gate from `AGENTS.md`, but do not treat it as a Markdown validator.
- `react_on_rails_pro/**/*.{js,ts,tsx,jsx,json,css,md}` changes: confirm the Pro package edit was approved per the `AGENTS.md` ask-first rule, then run `cd react_on_rails_pro && pnpm start format.listDifferent`; in the Pro package, `pnpm start` delegates to that package's `nps` script, so this uses the package-local Prettier check.
- `react_on_rails_pro/**/*.rb` changes: confirm the Pro package edit was approved per the `AGENTS.md` ask-first rule, then run `bundle exec rubocop react_on_rails_pro/` and any targeted RSpec.
- GitHub Actions workflow changes: confirm the edit was approved per the `AGENTS.md` ask-first rule, then run `actionlint` and `yamllint .github/`. Do not run RuboCop on `.yml` files.

## Output Format

Use this concise summary:

```text
Verification:
- PASS git diff --check origin/main...HEAD
- PASS pnpm start format.listDifferent
- FAIL bundle exec rspec react_on_rails/spec/react_on_rails/path/to/spec.rb

Next fix:
- ...
```

If a command is intentionally skipped, explain why in one line. Prefer local verification over waiting for CI.
