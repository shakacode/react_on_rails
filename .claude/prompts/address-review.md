# Address Review Prompt

The canonical reusable prompt is [.agents/workflows/address-review.md](../../.agents/workflows/address-review.md).

Use that shared workflow when pasting an address-review prompt into Codex CLI, ChatGPT, or another coding assistant. This file intentionally stays as a short compatibility pointer so it cannot drift from the canonical `MUST-FIX` / `DISCUSS` / `OPTIONAL` / `SKIPPED` policy, `autopilot` initiation mode, `a` apply action, and deferred-work tracking rules.

For Claude Code slash-command usage, use [.agents/skills/address-review/SKILL.md](../../.agents/skills/address-review/SKILL.md). The `.claude/skills` symlink exposes it as `/address-review`.

When copying these workflows into another repository:

- Copy `.agents/workflows/address-review.md` as the reusable prompt.
- Copy `.agents/skills/address-review/SKILL.md` when the target repo uses agent skills or Claude Code.
- Add `.claude/skills -> ../.agents/skills` when the target repo uses Claude Code.
- Copy this file only if the target repo keeps a `.claude/prompts/` alias, and keep it as a pointer rather than duplicating the full workflow.
