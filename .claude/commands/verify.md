# Verify Command

Run a local verification loop for the current branch before creating or updating a PR.

## Instructions

1. Read `AGENTS.md` first. It is the canonical source for required commands, formatting, boundaries, and ask-first areas.
2. Inspect the current branch diff with `git status --short` and `git diff --stat origin/main...HEAD`.
3. Decide the smallest verification set that covers the changed surface area.
4. Run each command in order and stop on the first failure. Report the failing command, the relevant error output, and the next fix to attempt.
5. After a fix, restart at the failed command and continue forward. Do not claim a failure is fixed until the failed command passes locally.
6. Finish with the exact commands run and their pass/fail status.

## Default Verification Order

Use this order unless the changed files make a narrower or broader set clearly appropriate:

1. Formatting and whitespace:
   - `git diff --check`
   - `pnpm start format.listDifferent`
2. Ruby:
   - `bundle exec rubocop`
   - `bundle exec rake rbs:validate` when Ruby signatures or public Ruby APIs changed
   - targeted `bundle exec rspec ...` for changed Ruby behavior
3. JavaScript and TypeScript:
   - `pnpm run lint`
   - `pnpm run type-check`
   - targeted `pnpm run test -- ...` for changed package behavior
4. Docs:
   - `script/check-docs-sidebar origin/main HEAD` when docs under `docs/` changed
   - markdown link checks if links were added or edited
5. Broad suite:
   - `rake` when shared runtime behavior, generators, cross-package contracts, or release-critical paths changed

## Scope Guide

- Ruby gem changes: run targeted RSpec, `bundle exec rubocop`, and RBS validation when signatures or public APIs changed.
- Dummy app or integration changes: run the relevant dummy RSpec command from `react_on_rails/spec/dummy`.
- TypeScript package changes: run package tests, `pnpm run lint`, and `pnpm run type-check`.
- Generated examples or scripts: run the relevant generator/script command plus formatting and linting.
- Documentation-only changes: run Prettier, sidebar validation for `docs/`, and link checks for new or changed URLs.

## Output Format

Use this concise summary:

```text
Verification:
- PASS git diff --check
- PASS pnpm start format.listDifferent
- FAIL bundle exec rspec path/to/spec.rb

Next fix:
- ...
```

If a command is intentionally skipped, explain why in one line. Prefer local verification over waiting for CI.
