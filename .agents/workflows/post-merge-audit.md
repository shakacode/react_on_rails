# Post-Merge Audit Prompts

Use these prompts with `.agents/skills/post-merge-audit/SKILL.md` when auditing merged agent batch work, comparing Codex and Claude findings, or turning audit findings into GitHub issues.

## Coordination Rules

- Use one exact audit id, base, and head for every agent, for example `audit: <YYYY-MM-DD>-post-rc`.
- Format `<AUDIT_ID>` as `<YYYY-MM-DD>-<short-purpose>`, for example `<YYYY-MM-DD>-post-rc` or `<YYYY-MM-DD>-agent-batch-audit`.
- Run Codex and Claude independently first. Do not give either agent the other agent's report until both reports are complete.
- During independent audits, agents may draft issue bodies but must not create issues, comments, labels, fixes, reverts, branches, or PRs.
- Use one coordinator to compare reports, dedupe findings, and propose the issue plan.
- Create GitHub issues only after the user approves the deduped issue plan.
- If multiple child issues are needed, create one parent issue for the audit and one child issue per independently actionable fix/revert/question.
- Before creating any issue, search existing open issues for the affected PR number and the hidden fingerprint.

Suggested hidden fingerprint:

```markdown
<!-- post-merge-audit-finding v1
audit: <AUDIT_ID>
fingerprint: pr-3724:changelog-server-bundle-load-error
affected_prs: 3724
-->
```

## Completed Batch Handoff Prompt

Paste this into completed batch chats. This is for memory extraction only, not ground truth.

```text
Please produce a post-batch audit handoff. Do not make code changes or GitHub writes.

List every issue/PR you worked on in this batch, with:
- issue number
- PR number and URL
- final state: merged, open, blocked, no-PR
- files changed
- validation actually run
- any non-blocking decisions you made while continuing
- any assumptions that were not written into the PR description
- any risk you would want a maintainer to re-check after merge
- anything that might interact badly with other PRs from the same batch

If you do not know or cannot verify an item from GitHub/local git, say UNKNOWN rather than guessing.
```

## Independent Audit Prompt

Run this separately in Codex and Claude. Do not share one agent's output with the other until both are done.

```text
Run an independent post-merge audit of merged PRs since the last release candidate.

Use git and GitHub ground truth. Do not rely on prior chat memory.

Scope:
- Repository: <OWNER>/<REPO>
- Base: resolve the most recent release candidate tag/commit unless I provide one explicitly
- Head: current main
- Focus: PRs that appear to be from recent high-concurrency agent/Codex/Claude batch work
- Audit id: <AUDIT_ID>

First, produce the exact merged-PR range and batch-subset list:
- merged PR number and URL
- merge commit
- branch name
- author
- linked issue
- included or excluded from the batch subset
- why you think it is or is not part of the batch

List every PR merged between base and head, not only the PRs that look like
batch work. Ask me to confirm the included and excluded PRs before deep audit.

After confirmation, audit each included PR for:
- risky behavior change
- missing or weak validation
- cross-PR interactions
- overlapping files or assumptions
- undocumented non-blocking decisions
- review-agent checks/reviews/comments that were late, pending, stale, or untriaged at merge time
- AI reviewer approvals, positive issue comments, or "no actionable comments" summaries that were incorrectly treated as required maintainer approval or special approval gates
- AI review findings that were ignored even though they identified a confirmed blocker such as a correctness regression, failing test, security issue, API contract break, data-loss risk, or missing required maintainer approval
- requested adversarial reviews that were late, stale, missing, or left untriaged `BLOCKING`/`DISCUSS` findings
- untriaged Must Fix, SHOULD-FIX, DISCUSS, Changes Requested, compatibility, security, regression, or missing-changelog review findings
- changes touching CI, Pro, build config, generators, SSR, RSC, shared types, or release-sensitive docs
- anything that could have bad consequences after merge

Classify each PR:
- OK
- needs maintainer question
- needs changelog update
- needs follow-up issue
- needs fix PR
- needs revert consideration

For every non-OK finding, include a draft issue entry but do not create it:
- proposed title
- parent/child recommendation
- fingerprint
- affected PRs
- evidence
- recommended owner/action
- suggested labels if they already exist in the repo

Return high-risk findings first, then a PR-by-PR table. Include exact commands and data sources used. Do not make code changes, comments, labels, issues, reverts, or PRs without approval.
```

## Comparison Prompt

Use this in a fresh coordinator chat after both independent reports are complete.

```text
Compare these two independent post-merge audit reports.

Do not assume either report is correct. Reconcile them against git/GitHub evidence where possible.

For each finding:
- whether Codex found it, Claude found it, or both found it
- severity
- affected PRs
- evidence
- duplicate/overlap analysis against the other report
- whether this needs manual maintainer review, a fix PR, a follow-up issue, a changelog update, revert consideration, or no action

Pay special attention to disagreements:
- one agent flags risk and the other misses it
- different PR inclusion lists
- different release-candidate base
- different interpretation of validation evidence
- different interpretation of whether AI review evidence was advisory, blocking, or incorrectly counted as approval
- cross-PR interactions only one agent noticed
- issue drafts that duplicate the same underlying fix

Return:
1. consensus high-risk findings
2. disputed findings needing human review
3. PRs both agents consider OK
4. deduped issue plan
5. recommended next actions

Do not create issues or PRs yet.
```

## Approved Issue Creation Prompt

Use only after the user approves the deduped issue plan.

```text
Create GitHub issues from this approved post-merge audit issue plan.

Rules:
- Search existing open issues for each fingerprint and affected PR number before creating anything.
- Do not create duplicate child issues. If an issue already exists, link it in the parent issue plan instead.
- If there are two or more related child issues, create one parent issue first.
- Create one child issue per independently actionable fix PR, revert consideration, maintainer question, or follow-up task.
- For missing changelog findings, prefer one bundled changelog issue or recommend `/update-changelog`; do not create one issue per missing entry unless explicitly approved.
- Include the hidden `post-merge-audit-finding` fingerprint in every child issue body.
- Link child issues from the parent issue and link the parent from each child issue.
- Use existing repo labels only. If a suggested label does not exist, omit it and mention that omission in the summary.

After creation, return:
- parent issue URL, if created
- child issue URLs
- skipped duplicates with existing issue URLs
- changelog recommendation
- any issue from the approved plan that could not be created
```

## Claude PR Review Handoff Prompt

Use this when Codex is coordinating a PR and the user wants an independent Claude review before final readiness.

```text
Please run an adversarial PR review before this PR is marked ready or merged:

<PR_URL>

If this Claude Code environment provides the repo-local skill, run:

/adversarial-pr-review <PR_URL>

Otherwise, use `.agents/workflows/adversarial-pr-review.md`. If `/pr-review-toolkit:review-pr` is available, you may use it as one input, but it is not sufficient by itself.

Focus on correctness bugs, missing tests, compatibility changes, missing changelog entries, release risk, late or stale review comments, changed agent instructions, and mismatches with AGENTS.md. Classify findings as:
- BLOCKING
- DISCUSS
- FOLLOWUP
- NON_BLOCKING_DECISION
- NOISE

Do not create commits, comments, labels, issues, pushes, merges, approvals, or thread resolutions unless explicitly asked. Return a concise report with evidence and exact files/lines where possible.
```
