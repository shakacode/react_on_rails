---
name: run-ci
description: Analyze current branch changes with the repo CI detector and run user-selected local CI jobs. Use when the user asks to run, reproduce, or choose local CI checks.
argument-hint: ''
---

# Run CI Command

Analyze the current branch changes and run appropriate CI checks locally.

## Base Handling

`bin/ci-local` auto-detects the current PR base branch and falls back to
`origin/main` or `main`. Do not pass a base-ref argument to `bin/ci-local`.
Use `script/ci-changes-detector origin/main` only when you need to inspect the
routing decision directly.

## Instructions

1. First, run `script/ci-changes-detector origin/main` to inspect what changed when the user asks for the routing details; otherwise use `bin/ci-local` directly
2. Show the user what the detector recommends
3. Ask the user if they want to:
   - Run the recommended CI jobs (`bin/ci-local`)
   - Run all CI jobs (`bin/ci-local --all`)
   - Run a fast subset (`bin/ci-local --fast`)
   - Run specific jobs manually
4. Execute the chosen option and report results
5. If any jobs fail, offer to help fix the issues

## Options

- `bin/ci-local` - Run CI based on detected changes
- `bin/ci-local --changed` - Explicit alias for the default optimized changed-files mode
- `bin/ci-local --all` - Run broad local CI where practical
- `bin/ci-local --fast` - Run only fast checks, skip slow integration tests
