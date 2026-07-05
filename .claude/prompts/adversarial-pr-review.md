# Adversarial PR Review Prompt

The canonical reusable prompt is
[.agents/workflows/adversarial-pr-review.md](../../.agents/workflows/adversarial-pr-review.md).

For Claude Code slash-command usage, use the installed/shared
`$adversarial-pr-review` skill from the shared `agent-workflows` pack. The
`.claude/skills` symlink only exposes repo-local skills and explicit overrides
such as `$stress-test`, `$optimize-rsc-performance`, and
`$react-on-rails-update-changelog`.

Keep this file as a pointer so the Claude prompt alias cannot drift from the
shared Codex/Claude workflow.
