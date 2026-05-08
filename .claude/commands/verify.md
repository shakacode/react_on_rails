# Verify Command

Run a local verification loop for the current branch before creating or updating a PR.

## Instructions

1. Read `AGENTS.md` first. It is the canonical source for required commands, formatting, boundaries, and ask-first areas.
2. Inspect the current branch diff with `git status --short` and `git diff --stat origin/main...HEAD`.
3. Decide the smallest verification set that covers the changed surface area.
4. Keep repo-wide commit gates from `AGENTS.md` in the set when you will create a commit, even if the changed surface is narrow.
5. Run each command in order and stop on the first failure. Report the failing command, the relevant error output, and the next fix to attempt.
6. For formatting failures, run `rake autofix` before manually editing formatting-only changes.
7. After a fix, restart at the failed command and continue forward. Do not claim a failure is fixed until the failed command passes locally.
8. Finish with the exact commands run and their pass/fail status.

## Default Verification Order

Use this order unless the changed files make a narrower or broader set clearly appropriate:

1. Formatting and whitespace:
   - `git diff --check origin/main...HEAD` for committed branch content before creating or updating a PR
   - `pnpm start format.listDifferent`
2. Ruby:
   - `bundle exec rubocop` before every commit as required by `AGENTS.md`; it lints Ruby, not Markdown or YAML
   - `bundle exec rake rbs:validate` when Ruby signatures or public Ruby APIs changed
   - targeted `bundle exec rspec ...` for changed Ruby behavior
3. JavaScript and TypeScript:
   - `pnpm run build`
   - `pnpm run lint`
   - `pnpm run type-check`
   - targeted `pnpm run test -- ...` for changed package behavior
4. Docs:
   - `script/check-docs-sidebar origin/main HEAD` when docs under `docs/` changed
   - `bin/check-links` when Markdown URLs were added or edited; do not substitute an ad hoc link checker unless this branch changes the canonical command
5. CI workflows and YAML:
   - Confirm the workflow edit itself was approved because `AGENTS.md` marks changes to `.github/workflows/` as ask-first
   - `actionlint` when any `.github/workflows/` file changed
   - `yamllint .github/` when any `.github/workflows/` file changed
   - Do not run RuboCop on `.yml` files
6. Broad suite:
   - `rake` when shared runtime behavior, generators, cross-package contracts, or release-critical paths changed

## Scope Guide

- Ruby gem changes: run targeted RSpec, `bundle exec rubocop`, and RBS validation when signatures or public APIs changed.
- Dummy app or integration changes: run `rake run_rspec:dummy` or a targeted dummy spec such as `cd react_on_rails/spec/dummy && bundle exec rspec spec/path/to/spec.rb`.
- TypeScript package changes: run `pnpm run build`, package tests, `pnpm run lint`, and `pnpm run type-check`.
- Generated examples or scripts: run the relevant generator/script command plus formatting and linting.
- Documentation-only changes: run `pnpm start format.listDifferent`, sidebar validation for `docs/`, and `bin/check-links` for new or changed URLs. If committing, still run the repo-wide `bundle exec rubocop` gate from `AGENTS.md`, but do not treat it as a Markdown validator.
- GitHub Actions workflow changes: confirm the edit was approved per the `AGENTS.md` ask-first rule, then run `actionlint` and `yamllint .github/`. Do not run RuboCop on `.yml` files.

## Output Format

Use this concise summary:

```text
Verification:
- PASS git diff --check origin/main...HEAD
- PASS pnpm start format.listDifferent
- FAIL bundle exec rspec path/to/spec.rb

Next fix:
- ...
```

If a command is intentionally skipped, explain why in one line. Prefer local verification over waiting for CI.
