---
name: post-merge-audit
description: Use when auditing merged PRs after concurrent agent work, before a release candidate, after a suspected bad merge, or when checking for missed reviews, missing changelog entries, cross-PR interactions, or release risk.
argument-hint: '[base tag/commit or range]'
---

# Post-Merge Audit

Audit merged PRs as a batch before the next release step. Use git and GitHub ground truth, not chat memory.

Memorable invocation:

```text
$post-merge-audit
Audit merged PRs since the last release candidate
```

## Scope Gate

Start by resolving the exact audit range:

1. Base: the user-supplied tag/commit, or the most recent release candidate tag when the user says "since the last RC".
2. Head: usually `origin/main` or the current release branch.
3. Merged PR list: every PR merged between base and head.
4. Batch subset: PRs that appear to be from agent batch work by branch name, PR body, labels, comments, author, merge timing, or linked issues.

Show included PRs, excluded near-matches, base/head SHAs, and assumptions. Ask for confirmation before deep audit unless the user explicitly asks to proceed without confirmation.

## Audit Checks

For each included PR:

- Review completion: find reviews, review comments, issue comments, and review/check runs from Claude, Codex, CodeRabbit, Greptile, Cursor Bugbot, and other configured reviewers.
- Review timing: flag any reviewer check, review, or comment that was still queued/in-progress at merge time or landed after merge.
- Review triage: flag any pre-merge review/comment with `Must Fix`, `MUST-FIX`, `Should Fix`, `DISCUSS`, `Changes Requested`, `blocking`, or similar actionable language when there is no later evidence it was fixed, waived, or explicitly classified.
- Changelog: if the diff or PR body indicates a user-visible behavior, API, error message, configuration, performance, security, or breaking change, verify `CHANGELOG.md` has a matching entry. When entries are missing, recommend running `/update-changelog`.
- Validation: compare changed areas with the validation evidence in the PR body or comments.
- Cross-PR interactions: compare changed files, shared behavior, assumptions, and release-sensitive areas across the batch.
- Decision log: inspect any `Codex Decision Log` or equivalent section and verify the decisions still hold after the merge.

## Finding Classification

Classify each PR:

- **OK**: no credible release risk found.
- **Needs maintainer question**: a decision cannot be made safely from evidence.
- **Needs changelog update**: user-visible change is missing from `CHANGELOG.md`; recommend `/update-changelog`.
- **Needs follow-up issue**: non-blocking work remains valuable and is actionable after release.
- **Needs fix PR**: a real defect, missing test, missing compatibility note, or bad interaction should be fixed before release.
- **Needs revert consideration**: the merge appears risky enough that reverting may be safer than patching.

## Output

Return high-risk findings first, then:

1. Review-gate violations, including PRs merged before requested reviews finished or before actionable review findings were triaged.
2. Missing changelog candidates, with a single recommendation to run `/update-changelog` when any are found.
3. Cross-PR interaction risks.
4. A PR-by-PR table.
5. Exact commands and data sources used.

Do not create fixes, comments, labels, issues, changelog edits, reverts, or PRs until the user approves the audit report.
