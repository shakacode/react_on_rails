# Napkin Runbook

## Curation Rules

- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)

1. **[2026-04-08] Review PRs with local verification, not CI optimism**
   Do instead: inspect the diff against `origin/main`, classify only correctness/regression issues as blocking, and run the narrowest local tests that exercise the changed area before declaring merge readiness.
2. **[2026-04-08] Protect unrelated work in dirty trees**
   Do instead: check `git status --short` up front and avoid editing or reverting any pre-existing changes unless the user explicitly asks.

## Shell & Command Reliability

1. **[2026-04-08] Prefer parallel read-only inspection**
   Do instead: use `multi_tool_use.parallel` for independent reads like `git status`, `git diff --name-only`, `sed`, and `gh pr view` to gather review context quickly.
2. **[2026-04-08] Use repo-native command wrappers**
   Do instead: run Ruby commands with `bundle exec`, JS commands with `pnpm`, and prefer `rg` for repository search.

## Domain Behavior Guardrails

1. **[2026-04-08] Keep React on Rails bundle placement and RSC role separate**
   Do instead: evaluate `.client.` / `.server.` suffix behavior independently from `'use client'` when reviewing component loading or registration changes.
2. **[2026-04-08] Treat Pro changes as restricted**
   Do instead: ask first before modifying `react_on_rails_pro/`, and when only reviewing, keep findings focused on regressions, tests, and compatibility risks.

## User Directives

1. **[2026-04-08] Stay inside the workspace clone**
   Do instead: read and write only under `/Users/justin/conductor/react_on_rails/.conductor/bangalore-v2` and never touch `/Users/justin/conductor/react_on_rails`.
