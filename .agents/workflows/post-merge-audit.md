# Post-Merge Audit Prompts

Use these prompts with `.agents/skills/post-merge-audit/SKILL.md` when auditing merged agent batch work, comparing Codex and Claude findings, or turning audit findings into GitHub issues.

## Coordination Rules

- Use one exact audit id, base, and head for every agent, for example `audit: <YYYY-MM-DD>-post-rc`.
- Format `<AUDIT_ID>` as `<YYYY-MM-DD>-<short-purpose>`, for example `<YYYY-MM-DD>-post-rc` or `<YYYY-MM-DD>-agent-batch-audit`.
- Run Codex and Claude independently first. Do not give either agent the other agent's report until both reports are complete.
- During independent audits, agents may draft issue bodies but must not create issues, comments, labels, fixes, reverts, branches, or PRs.
- Use one coordinator to compare reports, dedupe findings, and propose the issue plan.
- Create GitHub issues only after the user approves the deduped issue plan and
  the approved audit report has been appended to the release-gate audit ledger.
- If multiple child issues are needed, create one parent issue for the audit and one child issue per
  independently actionable fix/revert/question. Link the release-gate audit ledger comment from every
  approved parent or child issue created from the audit.
- Before creating any issue, search existing open issues for the affected PR number and the hidden fingerprint.
- For named batch/run audits, run `agent-coord doctor`, then `agent-coord status`, and inspect the named
  batch entry as the primary worked-issue scope when available. If coordination state cannot be verified,
  record `worked_issue_scope: UNKNOWN` with the exact command/error instead of silently reducing the audit
  to merged PRs.
- For private coordination backend setup and CLI discovery, see
  `internal/contributor-info/agent-coordination-backend.md`.

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
Run an independent post-merge audit of merged PRs (and, when a batch id is known, its worked-issue scope)
since the last release candidate.

Use git, GitHub, and agent-coord ground truth. Do not rely on prior chat memory.

Scope:
- Repository: <OWNER>/<REPO>
- Batch id: <BATCH_ID, or UNKNOWN if not applicable>
  (if UNKNOWN or not applicable, skip the agent-coord lookup below)
- Base: resolve the most recent release candidate tag/commit unless I provide one explicitly
- Head: current main
- Focus: PRs that appear to be from recent high-concurrency agent/Codex/Claude batch work
- Audit id: <AUDIT_ID>

First, produce the exact worked-issue scope and merged-PR range:
- run `agent-coord doctor`, then `agent-coord status` when a batch id is known,
  then inspect `<BATCH_ID>` in the status output
- list every worked issue/lane from claims, heartbeats, branches, and dependency
  metadata
- for each worked issue, include the lane owner, branch, heartbeat/final state,
  linked PR if known, and whether the final state is merged, open, blocked,
  parked, no-PR, done-unmerged, or UNKNOWN
- if agent-coord is missing, unavailable, or either command fails, record
  `worked_issue_scope: UNKNOWN` with the exact command/error and continue with
  GitHub/git evidence for the merged-PR range only

Then produce the exact merged-PR range and batch-subset list:
- merged PR number and URL
- merge commit
- branch name
- author
- linked issue
- included or excluded from the batch subset
- why you think it is or is not part of the batch

List every PR merged between base and head, not only the PRs that look like
batch work. Ask me to confirm the included/excluded worked issues and PRs before
deep audit.

If `worked_issue_scope` is `UNKNOWN`, do not invent a worked-issue list from the
merged PR range. After confirmation, audit the merged PR range only and include
a `worked_issue_scope: UNKNOWN` finding with the command or permission needed to
recover the missing issue/lane list.

After confirmation, audit each known worked issue for:
- whether the implementation, no-PR comment, blocker, or parked disposition
  satisfied the issue intent and acceptance criteria
- whether the final issue state is correct: merged, closed, still open,
  parked, blocked, no-PR, done-unmerged, or UNKNOWN
- whether review comments, handoff expectations, confidence notes, validation
  evidence, decision-point count, and Process Gap Disposition fields were
  handled when required
- classify each worked issue as `in_progress`, `realized`, `partial`,
  `missed`, `regressed`, `stalled`, or `unknown`, using
  `.agents/workflows/continuous-evaluation-loop.md` for the intent-achievement
  definitions
- for healthy `in_progress` lanes and evidenced `realized` outcomes, record no
  action in the worked-issue table; for `stalled` lanes, recommend resume,
  reassign, or drop unless the user explicitly approves tracking the stalled
  lane as an issue; for any other non-OK worked-issue class (`partial`,
  `missed`, `regressed`, or `unknown`), merged or not, prepare a post-merge
  audit issue-plan entry or an explicit coordinator action naming the missing
  evidence or decision

Also audit each included merged PR for:
- risky behavior change
- missing or weak validation
- missing lockfile content-diff evidence when committed lockfiles changed, using
  the Handoff Contract in `.agents/skills/pr-batch/SKILL.md`
- weak closing evidence in any PR whose body or linked issue uses analysis,
  benchmark, or investigation evidence to support a `close` or
  `document/work around` disposition: apply the full gate from the "Evaluate the
  fix plan separately" step in `.agents/skills/evaluate-issue/SKILL.md`,
  including reproducible artifact or justified missing-artifact caveat, internal
  consistency, production-environment caveats, and refutable-conclusion handling
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
- for process findings only: `Mechanism target` (`script`, `schema`,
  `checklist+replay`, or `park`), `Motivating miss`, `Replay evidence or park
  reason`, and `Non-goal`

Return high-risk findings first, then review-gate violations, missing changelog
candidates, cross-PR interaction risks, the issue plan, a worked-issue coverage
table, a PR-by-PR table, and exact commands/data sources. Include any remaining
`UNKNOWN` facts and the command or permission needed to resolve them. Do not make
code changes, comments, labels, issues, reverts, or PRs without approval.
The worked-issue coverage table must include issue number, coordination
lane/branch, linked PR or no-PR/blocker evidence, final state,
intent-achievement classification, and `UNKNOWN` facts.
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
- for process findings only, the proposed Process Gap Disposition fields:
  `Mechanism target` (`script`, `schema`, `checklist+replay`, or `park`),
  `Motivating miss`, `Replay evidence or park reason`, and `Non-goal`

Pay special attention to disagreements:
- one agent flags risk and the other misses it
- different worked-issue inclusion lists, including one agent having
  coordination data while the other records `worked_issue_scope: UNKNOWN`
- different intent-achievement classifications for the same worked issue
- different PR inclusion lists
- different release-candidate base
- different interpretation of validation evidence
- different interpretation of whether AI review evidence was advisory, blocking, or incorrectly counted as approval
- cross-PR interactions only one agent noticed
- issue drafts that duplicate the same underlying fix

Return:
1. consensus high-risk findings
2. disputed findings needing human review
3. reconciled worked-issue coverage table with consensus classification and any
   unresolved `UNKNOWN` facts
4. PRs both agents consider OK
5. deduped issue plan
6. recommended next actions

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
- Append the audit report to the release-gate audit ledger before creating approved follow-up issues; include the
  resulting ledger comment URL in every parent and child issue body.
- For missing changelog findings, prefer one bundled changelog issue or recommend `/update-changelog`; do not create one issue per missing entry unless explicitly approved.
- For process findings, preserve the approved Process Gap Disposition fields:
  `Mechanism target`, `Motivating miss`, `Replay evidence or park reason`, and
  `Non-goal`.
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
