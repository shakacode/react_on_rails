---
name: run-ci
description: Analyze current branch changes with the repo CI detector and run user-selected local CI jobs. Use when the user asks to run, reproduce, or choose local CI checks.
argument-hint: '[base-ref]'
---

# Run CI Command

Analyze the current branch changes and run appropriate CI checks locally.

## Argument Handling

This skill accepts an optional base-ref argument. If provided, use it instead of `origin/main` for both `script/ci-changes-detector` and `bin/ci-local`; otherwise default to `origin/main`.

## Instructions

1. First, run `script/ci-changes-detector origin/main` to analyze what changed, substituting the optional base-ref argument when supplied
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
- `bin/ci-local --all` - Run all CI checks (same as CI on main)
- `bin/ci-local --fast` - Run only fast checks, skip slow integration tests
- `bin/ci-local [base-ref]` - Compare against a specific ref instead of origin/main
