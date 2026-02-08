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
- Apply the **15-minute rule**: "If I spent 15 more minutes testing locally, would I discover this issue before CI does?" If yes, spend the 15 minutes.
- **Never claim a test is "fixed" without running it locally first.** Use "This SHOULD fix..." or "Proposed fix (UNTESTED)" for unverified changes.
- **Prefer local testing over CI iteration** — don't push "hopeful" fixes.

## Claude-Specific Workflow

Use these docs for Claude-oriented operational guidance:

- `.claude/docs/avoiding-ci-failure-cycles.md`
- `.claude/docs/replicating-ci-failures.md`
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
