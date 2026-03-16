# CLAUDE.md

Tool-specific guidance for Claude Code in this repository.

## Source of Truth

`AGENTS.md` is the canonical policy for:

- Commands, tests, and lint workflow
- Formatting and style requirements
- Git/PR safety boundaries
- Project directory boundaries

If this file conflicts with `AGENTS.md`, follow `AGENTS.md`.

## Behavioral Defaults

- When confident in your changes, **commit and push without asking for permission**. Always monitor CI after pushing.

## Git Safety

- **NEVER force-push** (`--force`, `--force-with-lease`) unless the user explicitly requests it. Force-pushing destroys commit history that may represent significant prior work.
- **NEVER `git reset --hard`** on a branch that has existing commits (yours or others'). This destroys work.
- When you need to start fresh or test something without affecting an existing branch, **use a git worktree** (`git worktree add`) or **create a new branch** instead of resetting the current one.
- If a rebase has conflicts, abort and ask the user how to proceed rather than force-pushing a rewritten history.

## Claude-Specific Workflow

Use these docs for Claude-oriented operational guidance:

- `.claude/docs/avoiding-ci-failure-cycles.md`
- `.claude/docs/replicating-ci-failures.md`
- `.claude/docs/playwright-e2e-testing.md`
- `.claude/docs/merge-conflict-workflow.md`
- `.claude/docs/pr-splitting-strategy.md`
- `.claude/docs/changelog-guidelines.md`
- `.claude/docs/project-architecture.md`
- `.claude/docs/rails-engine-nuances.md`
- `.claude/docs/debugging-webpack.md`
- `.claude/docs/rbs-type-checking.md`
- `.claude/docs/conductor-compatibility.md`
- `.claude/docs/testing-build-scripts.md`
- `.claude/docs/master-health-monitoring.md`
- `.claude/docs/managing-file-paths.md`

For Pro-package specifics, also read `react_on_rails_pro/CLAUDE.md`.
