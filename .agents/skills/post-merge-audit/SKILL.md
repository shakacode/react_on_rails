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

Use `.agents/workflows/post-merge-audit.md` for reusable copy-paste prompts, including independent Codex/Claude audits, comparison, approved issue creation, and Claude PR review handoff prompts.

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
- Approval semantics: flag any merge that treated an AI reviewer approval, positive issue comment, or "no actionable comments" summary as required maintainer approval or a special approval gate. Also flag any AI finding that was ignored even though it identified a confirmed blocker such as a correctness regression, failing test, security issue, API contract break, data-loss risk, or missing required maintainer approval.
- Adversarial review: flag any requested adversarial review that finished after merge, reviewed an older head SHA, or left untriaged `BLOCKING` or `DISCUSS` findings.
- Changelog: if the diff or PR body indicates a user-visible behavior, API, error message, configuration, performance, security, or breaking change, verify `CHANGELOG.md` has a matching entry. When entries are missing, recommend running `/update-changelog`.
- Validation: compare changed areas with the validation evidence in the PR body or comments.
- Cross-PR interactions: compare changed files, shared behavior, assumptions, and release-sensitive areas across the batch.
- Decision log: inspect any `Codex Decision Log` or equivalent section and verify the decisions still hold after the merge.

## Codex And Claude Coordination

When using both Codex and Claude:

1. Give each agent the same audit id, base, head, and independent audit prompt.
2. Do not share one agent's report with the other until both reports are complete.
3. Instruct both agents to draft issue entries only. They must not create issues, comments, labels, branches, fixes, reverts, or PRs during the independent audit.
4. Use one coordinator to compare both reports, verify disagreements against git/GitHub evidence, dedupe findings, and propose the issue plan.
5. Create GitHub issues only after the user approves the deduped issue plan.

## Finding Classification

Classify each PR:

- **OK**: no credible release risk found.
- **Needs maintainer question**: a decision cannot be made safely from evidence.
- **Needs changelog update**: user-visible change is missing from `CHANGELOG.md`; recommend `/update-changelog`.
- **Needs follow-up issue**: non-blocking work remains valuable and is actionable after release.
- **Needs fix PR**: a real defect, missing test, missing compatibility note, or bad interaction should be fixed before release.
- **Needs revert consideration**: the merge appears risky enough that reverting may be safer than patching.

## Issue Plan

The audit should usually produce an issue plan for non-OK findings, but not create issues until approval.

- **No issue**: for `OK`, duplicate findings, or findings fully resolved by the audit evidence.
- **Changelog only**: for missing changelog entries; prefer one bundled changelog issue or a recommendation to run `/update-changelog`, not one issue per entry.
- **One child issue**: for each independently actionable fix PR, revert consideration, maintainer question, or follow-up task.
- **Parent issue**: create one parent issue when there are two or more related child issues from the same audit or when the audit spans a release-candidate readiness decision.

Before creating an approved issue, search existing open issues for the affected PR number and hidden fingerprint:

```markdown
<!-- post-merge-audit-finding v1
audit: <AUDIT_ID>
fingerprint: pr-3724:changelog-server-bundle-load-error
affected_prs: 3724
-->
```

Only the coordinator should create issues. Independent Codex and Claude audits should draft issue entries with fingerprints so the coordinator can compare and dedupe them.

## Output

Return high-risk findings first, then:

1. Review-gate violations, including PRs merged before requested reviews finished, before actionable review findings were triaged, or with AI review systems incorrectly counted as approval gates.
2. Missing changelog candidates, with a single recommendation to run `/update-changelog` when any are found.
3. Cross-PR interaction risks.
4. A deduped issue plan with parent/child recommendations and fingerprints.
5. A PR-by-PR table.
6. Exact commands and data sources used.

Do not create fixes, comments, labels, issues, changelog edits, reverts, or PRs until the user approves the audit report.
