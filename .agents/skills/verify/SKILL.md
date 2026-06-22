---
name: verify
description: Run a local verification loop for the current branch before creating or updating a PR, selecting checks from AGENTS.md and changed files. Use when asked to verify, test, or prepare PR changes.
---

# Verify Command

Run a local verification loop for the current branch before creating or updating a PR.

Use `/verify` for local pre-PR checks. Use `/run-ci` when you need the repo's CI change detector (see `AGENTS.md` →
**Agent Workflow Configuration**) or want to reproduce CI job selection locally.

## Instructions

1. Read `AGENTS.md` first. It is the canonical source for required commands, formatting, boundaries, and repository safety rules.
2. Resolve `BASE_BRANCH` from `AGENTS.md` -> **Agent Workflow Configuration**, then inspect the current branch diff
   with `git status --short`, `git diff --name-only "origin/${BASE_BRANCH}...HEAD"`, and
   `git diff --stat "origin/${BASE_BRANCH}...HEAD"`.
3. Decide the required verification set that covers the changed surface area using the **Scope Guide** below. Always
   include the repo's mandatory pre-commit lint gate (see `AGENTS.md` → **Agent Workflow Configuration**) before
   creating a commit, even when the changed surface is documentation-only, because that gate can scan all files of its
   language, not just changed or staged ones, so docs-only commits can still expose pre-existing offenses that CI will
   catch.
4. Run each command in order and stop on the first failure. Report the failing command, the relevant error output, and the next fix to attempt.
5. For formatting failures (auto-fixable formatter or lint offenses), run the repo's format/autofix command (see `AGENTS.md` → **Agent Workflow Configuration**); do not manually edit formatting-only changes.
6. After one or more edits for a failure, restart at the failed command and continue forward. Track a loop counter per
   command:
   - Increment the counter when the same command fails on the same first item (test name, lint offense, or formatter
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
   - `git diff --check "origin/${BASE_BRANCH}...HEAD"` for committed branch content before creating or updating a PR; detects trailing whitespace and conflict markers, not source formatting
   - the repo's formatter check (see `AGENTS.md` → **Agent Workflow Configuration**)
2. Mandatory pre-commit gate:
   - the repo's mandatory pre-commit lint gate - **mandatory gate before every commit**; see Instructions step 3 for why this still applies to documentation-only commits; it lints the source languages it covers, not Markdown or YAML
3. Ruby (or the repo's equivalent backend language):
   - the repo's type/signature validation command when signatures or public APIs changed
   - the repo's targeted unit-test command for the changed backend behavior
4. JavaScript and TypeScript (or the repo's equivalent frontend/package language):
   - the repo's package build command
   - the repo's package lint command
   - the repo's type-check command
   - the repo's targeted package-test command for the changed package, or a targeted single-test-file run scoped to the
     changed package
   - the repo's full package-test command when broad package behavior changed or the touched files are not covered by a narrower package test
   - the repo's end-to-end/browser test command when the branch changes performance- or framework-sensitive areas such
     as SSR rendering, client hydration, or browser-visible integration behavior; on fresh Linux environments, install
     the e2e browser dependencies first per the repo's e2e setup
5. Docs:
   - the repo's docs-sidebar/coverage check when docs under the repo's documented docs directories changed
   - the repo's link checker when Markdown URLs were added or edited; do not substitute an ad hoc link checker unless the
     branch changes the link checker, its config, or the documented link-check workflow itself
6. CI workflows and YAML:
   - `actionlint` when any `.github/workflows/` file changed
   - `yamllint .github/` when any `.github/workflows/` file changed
   - Do not run the repo's source linter on `.yml` files
7. Broad suite — pick the narrowest command that covers the change:
   - the repo's broad-but-fast suite command for broad coverage without the slowest generated/example suites
   - the repo's full suite command when shared runtime behavior, generators, cross-package contracts, or release-critical paths changed
   - the repo's complete lint gate when a branch intentionally needs the full lint pass across all source languages and
     formatting; otherwise keep using the narrower lint commands above

## Scope Guide

- Core library/backend changes: run the repo's targeted unit tests, the mandatory pre-commit lint gate, and type/signature validation when signatures or public APIs changed.
- Integration or test-app changes: run the repo's integration test command or a targeted integration spec scoped to the changed surface. For changes that affect performance- or framework-sensitive areas such as SSR rendering or client-side behavior, also run the repo's end-to-end/browser test command.
- Frontend/package changes: run the repo's package build, package tests, package lint, and type-check commands.
- Generated examples or scripts: run the relevant generator/script command plus formatting and linting.
- Documentation-only changes: run the repo's formatter check, the docs-sidebar/coverage check for the documented docs directories, and the link checker for new or changed URLs. If committing, still run the mandatory pre-commit lint gate; see Instructions step 3 for why this applies even to docs-only commits. The lint gate does not validate Markdown.
- Package-specific frontend changes (for example a separately-packaged area with its own scripts, per `AGENTS.md`): run that package's own local formatter check via its own scripts plus any focused tests for the changed surface.
- Package-specific backend changes: run that package's own lint command (with any package-scoped flags it documents) and any targeted unit tests.
- GitHub Actions workflow changes: run `actionlint` and `yamllint .github/`. Do not run the repo's source linter on `.yml` files.
- Anything not listed above (for example, build-script edits, generator templates, signature-only changes, or build scripts): apply the narrowest set of checks that covers the changed surface and explain the choice in the output.

## Output Format

Use this concise summary:

```text
Verification:
- PASS git diff --check "origin/${BASE_BRANCH}...HEAD"
- FAIL <repo formatter check>

Next fix:
- Run the repo's format/autofix command to fix formatting, then rerun the formatter check.
```

If a command is intentionally skipped, explain why in one line. Prefer local verification over waiting for CI.
