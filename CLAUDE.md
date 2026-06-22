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

- When confident in your changes, **commit and push without asking for permission**. Always monitor CI after pushing, and use the `+ci-*` PR comment commands from `AGENTS.md` when asking maintainers to run, stop, or waive hosted CI.
- **When `merge_authority` is `auto_merge_when_gates_pass` and the release-mode gate is satisfied, merge; do not stop at a recommendation.** `ask` requires one confirmation before merging, and `none` grants no merge authority. See `AGENTS.md` → Confidence notes for the full tri-state rule, confidence threshold, and required PR-description evidence.
- Check `main` CI status at session start (injected by `.claude/hooks/main-ci-status.sh`) and again before `gh pr create` or pushing to `main`. See `AGENTS.md` → "Main branch health" for the decision framework when `main` is red.

## Git Safety

- **Clean rebase → `git push --force-with-lease` without asking.** When `git rebase origin/main` (or `git pull --rebase`) reports no conflicts, every commit is preserved — republishing is the expected workflow. Just push and report the result.
- **Ask first when force-pushing in these cases:** you resolved rebase conflicts, you dropped/squashed/reordered commits, or the remote branch has commits you don't have locally.
- **NEVER `git reset --hard`** on a branch with existing commits (yours or others'). This destroys work. Use a worktree or a new branch instead.
- **NEVER force-push to `main` or `master`.**
- If a rebase has conflicts you can't resolve cleanly, abort and ask the user how to proceed.

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
- `.claude/docs/main-health-monitoring.md`
- `.claude/docs/managing-file-paths.md`
- `.claude/docs/docs-competitive-landscape.md`
- `.claude/docs/docs-templates.md`
- `.claude/docs/manual-dev-environment-testing.md`
- `.claude/docs/validating-node-renderer-changes.md`

For Pro-package specifics, also read `react_on_rails_pro/CLAUDE.md`.
