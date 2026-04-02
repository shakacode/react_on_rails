# Napkin Runbook

## Curation Rules

1. **[2026-04-01] Keep only reusable repo guidance**
   Do instead: prune one-off session notes and keep short instructions that will matter in future sessions.

## Execution & Validation (Highest Priority)

1. **[2026-04-01] Update both address-review surfaces together**
   Do instead: when changing review-agent behavior, patch both `.claude/commands/address-review.md` and `.agents/workflows/address-review.md` in the same pass.

## Shell & Command Reliability

1. **[2026-04-01] Stay inside the Conductor worktree**
   Do instead: run commands only under `/Users/justin/conductor/react_on_rails/.conductor/moab` and never touch `/Users/justin/conductor/react_on_rails`.

## User Directives

1. **[2026-04-01] Rename the branch immediately in Conductor workspaces**
   Do instead: use `git branch -m jg/<specific-name>` before other tool work when the workspace instructions require it.
