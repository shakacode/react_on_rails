---
name: run-ci
description: Analyze current branch changes with the repo CI detector and run user-selected local CI jobs. Use when the user asks to run, reproduce, or choose local CI checks.
argument-hint: ''
---

# Run CI Command

Analyze the current branch changes and run appropriate CI checks locally.

## Base Handling

The repo's pre-push local validation command (see `AGENTS.md` → **Agent Workflow
Configuration**) auto-detects the current PR base branch and falls back to the base
branch. Do not pass a base-ref argument to it. Use the repo's CI change detector only
when you need to inspect the routing decision directly.

Before running commands, resolve these values from `AGENTS.md` → **Agent Workflow
Configuration**:

- Pre-push local validation command, including default, changed-files, broad, and fast modes
- CI change detector command

## Instructions

1. First, run the repo's CI change detector to inspect what changed when the user asks for the routing details; otherwise use the local validation command directly
2. Show the user what the detector recommends
3. Ask the user if they want to:
   - Run the recommended CI jobs (the local validation command in its default optimized mode)
   - Run all CI jobs (the local validation command's broad/`--all` mode)
   - Run a fast subset (the local validation command's fast-checks mode, if it provides one)
   - Run specific jobs manually
4. Execute the chosen option and report results
5. If any jobs fail, offer to help fix the issues

## Options

- Local validation command, default mode - Run CI based on detected changes
- Local validation command, explicit changed-files mode (`--changed` or equivalent) - Explicit alias for the default optimized changed-files mode
- Local validation command, broad mode (`--all` or equivalent) - Run broad local CI where practical
- Local validation command, fast mode (`--fast` or equivalent, if provided) - Run only fast checks, skip slow integration tests
