# Address Review Prompt

The canonical reusable prompt is [.agents/workflows/address-review.md](../../.agents/workflows/address-review.md).

Use that shared workflow when pasting an address-review prompt into Codex CLI, ChatGPT, or another coding assistant. This file intentionally stays as a short compatibility pointer so it cannot drift from the canonical `MUST-FIX` / `DISCUSS` / `OPTIONAL` / `SKIPPED` policy, `autopilot` initiation mode, `a` apply action, and deferred-work tracking rules.

For Claude Code slash-command usage, use the installed/shared `$address-review`
skill from the shared `agent-workflows` pack. The `.claude/skills` symlink only
exposes repo-local skills and explicit overrides such as `$stress-test` and
`$optimize-rsc-performance`, plus release-branch changelog handling through
`$react-on-rails-update-changelog`.

When copying these workflows into another repository:

- Copy `.agents/workflows/address-review.md` as the reusable prompt.
- Install the shared `agent-workflows` skill pack when the target repo uses agent
  skills or Claude Code.
- Add `.claude/skills -> ../.agents/skills` only when the target repo keeps
  repo-local skills or explicit overrides.
- Copy this file only if the target repo keeps a `.claude/prompts/` alias, and keep it as a pointer rather than duplicating the full workflow.
