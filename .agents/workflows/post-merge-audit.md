# Post-Merge Audit Prompts

Use these prompts with `.agents/skills/post-merge-audit/SKILL.md` when auditing merged agent batch work, comparing Codex and Claude findings, or turning audit findings into GitHub issues.

## Coordination Rules

These prompts intentionally repeat the worked-issue scope state machine from
`.agents/skills/post-merge-audit/SKILL.md` so copy-paste audits stay
self-contained. Keep state-machine changes mirrored across this workflow,
`SKILL.md`, and `.agents/workflows/pr-processing.md`.

- Use one exact audit id, base, and head for every agent, for example `audit: <YYYY-MM-DD>-post-rc`.
- Format `<AUDIT_ID>` as `<YYYY-MM-DD>-<short-purpose>`, for example `<YYYY-MM-DD>-post-rc` or `<YYYY-MM-DD>-agent-batch-audit`.
- Run Codex and Claude independently first. Do not give either agent the other agent's report until both reports are complete.
- During independent audits, agents may draft issue bodies but must not create issues, comments, labels, fixes, reverts, branches, or PRs.
- Use one coordinator to compare reports, dedupe findings, and propose the issue plan.
- Create GitHub issues only after the user approves the deduped issue plan. For
  release-gate audits, append the approved audit report to the release-gate
  audit ledger first.
- If a required release-gate ledger append fails, do not create issues; report
  the exact command/API error and the ledger issue or permission needed to
  unblock issue creation. The approved audit report remains valid; retry the
  ledger append after the permission, quota, or transient API issue is resolved
  without regenerating the audit unless the base, head, or approved report
  changed.
- If multiple child issues are needed, create one parent issue for the audit
  and one child issue per independently actionable fix/revert/question. For
  release-gate audits, include the release-gate audit ledger comment URL in
  every approved parent or child issue created from the audit. For non-release
  audits with no ledger, record
  `Audit ledger: not applicable (non-release audit)` in approved issue bodies.
- Before creating any issue, search existing open issues for the affected PR number and the hidden fingerprint.
- When batch work is in scope but the batch/run id was not supplied, use the
  resolved `pr-batch` bounded helper to run bounded `agent-coord doctor --json`,
  then bounded `agent-coord status --json` as a broad audit/discovery read.
  Do not use that broad read for worker lane readiness or dependency decisions,
  and do not retry indefinitely. If backend setup or broad discovery access
  fails, record `worked_issue_scope: UNKNOWN (setup)` or
  `worked_issue_scope: UNKNOWN (access)` with the exact command/error and report
  that batch id confirmation is still needed after backend recovery. Only record
  `worked_issue_scope: UNKNOWN (needs batch confirmation)` when backend setup
  and broad discovery access worked but the candidate batch id still needs user
  confirmation.
- For named batch/run audits, run bounded `agent-coord doctor --json`, then
  bounded `agent-coord status --batch-id <batch-id> --json`, and inspect the
  named batch entry as the primary worked-issue scope when available. If
  coordination state cannot be verified, record
  `worked_issue_scope: UNKNOWN (setup)` or
  `worked_issue_scope: UNKNOWN (access)` with the exact command/error. Use
  structured public `codex-claim` comments (GitHub comments containing a
  `codex-claim` HTML comment with key/value fields in the "Public claim
  comment" format from `.agents/workflows/pr-processing.md`) as advisory
  recovery evidence when available before reducing unknown scope to merged PRs.
  If the batch id itself is unknown, scope advisory public-claim discovery to
  issues and open PRs active within the audit time window; use claim `batch:`
  fields to surface candidate ids until the user confirms one.
- For private coordination backend setup and CLI discovery, see
  `docs/coordination-backend.md`.

Suggested hidden fingerprint:

```markdown
<!-- post-merge-audit-finding v1
audit: <AUDIT_ID>
fingerprint: pr-<PR>:<short-issue-slug>
affected_prs: <PR>
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

List any QA lane or intentionally omitted QA lane, with:
- QA lane id/owner, claim status, and last heartbeat status
- QA Evidence block URL or copied contents
- `Tested at` head(s) or audited range
- `QA required`, QA required rationale, and QA lane status / coverage result
- release-blocking status and any findings

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
- Batch id: <BATCH_ID | UNKNOWN | not applicable>
- Base: resolve the most recent release candidate tag/commit unless I provide one explicitly
- Head: current main
- Focus: PRs that appear to be from recent high-concurrency agent/Codex/Claude batch work
- Audit id: <AUDIT_ID>

BATCH_ID = the known batch run id; UNKNOWN = batch work is in scope but the id
was not supplied; not applicable = no coordinated batch is in scope.

First, produce the exact worked-issue scope and merged-PR range:
- when no coordinated batch/run is in scope, skip `agent-coord` and record
  `worked_issue_scope: not applicable`
- when batch work is in scope but the batch id is `UNKNOWN`:
  - using the bounded helper from the resolved `PR_BATCH_SKILL_DIR`
    (`PR_BATCH_SKILL_DIR="${PR_BATCH_SKILL_DIR:-.agents/skills/pr-batch}"`),
    run bounded `agent-coord doctor --json`, then run bounded
    `agent-coord status --json` as a broad audit/discovery read to list
    candidate batch/run ids and lanes; do not use this broad read for worker
    lane readiness or dependency decisions, and do not retry indefinitely
  - if the bounded helper or `agent-coord` binary is missing, or bounded
    `agent-coord doctor --json` fails or times out, record
    `worked_issue_scope: UNKNOWN (setup)`; stop private backend discovery only,
    report the missing helper, missing command, timeout, or error needed to
    recover, and use structured public `codex-claim` comments as an advisory
    fallback
  - if bounded `agent-coord doctor --json` passes but broad discovery status
    fails or times out, record `worked_issue_scope: UNKNOWN (access)`; stop
    private backend discovery only, report the exact broad discovery command,
    timeout, or error, and use structured public `codex-claim` comments as an
    advisory fallback
  - if broad discovery returns no candidate batch/run ids, record
    `worked_issue_scope: UNKNOWN (needs batch confirmation)` and ask me to
    supply or confirm a batch/run id directly; once I supply or confirm one,
    continue with the known-batch-id path below
  - if broad discovery returns candidates but cannot determine which candidate
    is in scope, record
    `worked_issue_scope: UNKNOWN (needs batch confirmation)` and ask me to
    confirm one candidate before treating that candidate's lane list as
    worked-issue scope; once confirmed, continue with the known-batch-id path
    below
  - `UNKNOWN (setup)` and `UNKNOWN (access)` take precedence over
    `UNKNOWN (needs batch confirmation)`; only report candidate ids as
    confirmation targets when backend setup and discovery access both worked
- when a batch id is known:
  - run bounded `agent-coord doctor --json`, then bounded
    `agent-coord status --batch-id <batch-id> --json`, then inspect
    `<BATCH_ID>` in the status output
  - list every worked issue/lane from claims, heartbeats, branches, and
    dependency metadata
  - for each worked issue, include the lane owner, branch, heartbeat/final
    state, linked PR if known, and whether the final state is merged, open,
    blocked, parked, no-PR, done-unmerged, or UNKNOWN
- if `agent-coord` is missing or bounded `agent-coord doctor --json` fails or
  times out, record `worked_issue_scope: UNKNOWN (setup)` with the exact
  command/error. If bounded `agent-coord doctor --json` passes but targeted
  batch status fails or times out, record
  `worked_issue_scope: UNKNOWN (access)` with the exact command/error. In all
  UNKNOWN cases, use structured public `codex-claim` comments as advisory
  coverage when available before continuing with GitHub/git evidence for the
  merged-PR range.
- if bounded `agent-coord doctor --json` and targeted batch status both succeed
  but the named batch entry contains no worked issues or lanes, record
  `worked_issue_scope: empty (no coordination lanes found for <BATCH_ID>)`,
  scan structured public `codex-claim` comments as advisory recovery rows for
  possible no-PR, blocked, parked, or done-unmerged lanes, keep any recovered
  rows marked `UNKNOWN`, report the batch metadata correction needed, and ask
  for confirmation before reducing the audit to the merged-PR range only. If
  the user confirms no lanes were worked, record the empty-batch finding and
  proceed to the merged-PR range. If the user indicates lanes were worked
  despite the empty entry, record
  `worked_issue_scope: UNKNOWN (empty batch, lanes expected)`, collect a manual
  lane list from the user or advisory `codex-claim` comments, and keep
  recovered rows advisory `UNKNOWN` until coordination state is corrected.

Then produce the exact merged-PR range and, only when `worked_issue_scope` is
verified from coordination state, the batch-subset list:
- merged PR number and URL
- merge commit
- branch name
- author
- linked issue
- included or excluded from the batch subset, only when `worked_issue_scope` is
  verified from coordination state
- why it is or is not part of the batch, only when `worked_issue_scope` is
  verified from coordination state

List every PR merged between base and head, not only the PRs that look like
batch work.

If `worked_issue_scope` is `UNKNOWN`, do not invent a worked-issue list from the
merged PR range and do not identify an included/excluded batch subset from PR
links or heuristics. Use structured public `codex-claim` comments as advisory
worked-issue rows when available, keep those rows marked `UNKNOWN`, audit them
alongside the merged PR range, and include a `worked_issue_scope: UNKNOWN`
finding with the command or permission needed to recover the missing issue/lane
list.

Treat `worked_issue_scope: not applicable`, `worked_issue_scope: UNKNOWN (...)`,
and `worked_issue_scope: empty (...)` as merged-PR-range-only or advisory scope
states, not verified batch subsets.

After the scope algorithm identifies the batch or reports an `UNKNOWN` scope,
collect any QA lane and QA Evidence block for that batch. Do not use missing QA
state to shrink the worked-issue scope; report it as a QA coverage finding or
`UNKNOWN` fact instead.

Ask me to confirm the included/excluded worked issues, collected QA lanes and QA
Evidence blocks, advisory `codex-claim` rows, and PR range before deep audit
unless I explicitly say to proceed. When the scope is
`UNKNOWN (needs batch confirmation)`, ask me to choose the candidate batch/run id
before any confirmed worked-issue audit.

After confirmation, audit each known worked issue, QA lane, or advisory
`codex-claim` row for:
- whether the implementation, no-PR comment, QA evidence, blocker, or parked
  disposition satisfied the issue or QA-lane intent and acceptance criteria
- whether the final issue state is correct: merged, closed, still open,
  parked, blocked, no-PR, done-unmerged, or UNKNOWN
- for QA lanes, whether the QA lane status is correct: `satisfied`, `blocked`,
  `waived`, still healthy `in_progress`, `not_applicable` when QA was not
  required, or `unknown`
- whether review comments, handoff expectations, confidence notes, validation
  evidence, QA evidence, decision-point count, and Process Gap Disposition
  fields were handled when required
- classify each worked issue as `in_progress`, `realized`, `partial`,
  `missed`, `regressed`, `stalled`, or `unknown`, using
  `.agents/workflows/continuous-evaluation-loop.md` for the intent-achievement
  definitions; classify QA lanes with the QA-coverage result `satisfied`,
  `blocked`, `waived`, `in_progress`, `not_applicable`, or `unknown`, using the
  Batch QA Lane section in `.agents/workflows/pr-processing.md`
- for healthy `in_progress` worked-issue lanes, evidenced `realized` outcomes,
  evidenced `satisfied` or `waived` QA lanes, and evidenced `not_applicable` QA
  omissions, record no action in the worked-issue/QA table; treat required QA
  lanes still `in_progress` during readiness/release audits as QA coverage
  findings; for `stalled` lanes, recommend resume, reassign, or drop unless the
  user explicitly approves tracking the stalled lane as an issue; for any other
  non-OK worked-issue class (`partial`, `missed`, `regressed`, or `unknown`),
  merged or not, prepare a post-merge audit issue-plan entry or an explicit
  coordinator action naming the missing evidence or decision; for non-OK QA
  coverage outcomes (`blocked`, `unknown`, or release-audit `in_progress`),
  prepare a post-merge audit issue-plan entry or approved coordinator action
  naming the missing evidence, fix, waiver, or decision

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
- missing, stale, insufficiently scoped, head/range-ambiguous, release-blocking,
  or still-`UNKNOWN` QA coverage/scope evidence required by
  `.agents/workflows/pr-processing.md`; do not treat private coordination
  claim/heartbeat `UNKNOWN` as blocking when the documented fallback evidence is
  complete and names a concrete QA owner and branch/worktree
- changes touching CI, packaged/commercial code, build config, code generators,
  performance- or framework-sensitive paths, shared types, or release-sensitive
  docs (per `AGENTS.md`)
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

Return high-risk findings first, then review-gate violations, QA coverage
findings, missing changelog candidates, cross-PR interaction risks, the issue
plan, a worked-issue/QA-lane coverage table, a PR-by-PR table, and exact
commands/data sources. Include any remaining `UNKNOWN` facts and the command or
permission needed to resolve them. Do not make code changes, comments, labels,
issues, reverts, or PRs without approval. The worked-issue/QA-lane coverage
table must include issue number or QA lane id, coordination lane/branch, linked
PR or no-PR/blocker/QA evidence, final state, intent-achievement or QA-coverage
classification, and `UNKNOWN` facts.

Example worked-issue coverage table (`batch-abc` and issue numbers are
placeholders; replace them with the real batch id and issues):
| Issue | Lane/branch | Evidence | Final state | Classification | UNKNOWN facts |
| --- | --- | --- | --- | --- | --- |
| #1234 | batch-abc:issue-1234 / codex/example | PR #2345 merged | merged | realized | none |
| #1235 | batch-abc:issue-1235 / no branch | blocker comment URL | blocked | stalled | owner decision needed |
| #1236 | batch-abc:issue-1236 / codex/partial-example | PR #2346 merged | merged | partial | acceptance criteria C not addressed |
| #1237 | UNKNOWN (advisory) / no coord data | codex-claim comment URL (advisory) | UNKNOWN | unknown | coordination state needed to confirm |
| #1238 | batch-abc:issue-1238 / codex/done-no-merge | no-PR evidence comment URL | done-unmerged | realized | none |
| qa | batch-abc:qa / codex-qa | QA Evidence block URL | done | satisfied | none |
| qa | not required / no branch | handoff comment URL | not_applicable | not_applicable | none |
| qa | batch-abc:qa / codex-qa | QA Evidence block URL | blocked | blocked | fix or waiver needed before release |
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
- different QA coverage findings, QA lane states, or QA Evidence freshness/scope
- different worked-issue inclusion lists, including one agent having
  coordination data while the other records `worked_issue_scope: UNKNOWN`
  - when one report has verified coordination data and another has
    `worked_issue_scope: UNKNOWN`, treat the verified coordination data as the
    candidate worked-issue scope and record the UNKNOWN report as a setup/access
    gap to resolve, not as evidence that no worked-issue scope exists
  - when both reports record `worked_issue_scope: UNKNOWN`, consolidate the
    command/error evidence from both reports and surface a single unresolved
    `worked_issue_scope: UNKNOWN` finding that names the command or permission
    needed before any confirmed worked-issue audit can proceed; continue
    auditing advisory `codex-claim` rows alongside the merged PR range, keeping
    those rows marked `UNKNOWN`
- different intent-achievement classifications for the same worked issue or
  QA-coverage classifications for the same QA lane
- different PR inclusion lists
- different release-candidate base
- different interpretation of validation evidence
- different interpretation of whether AI review evidence was advisory, blocking, or incorrectly counted as approval
- cross-PR interactions only one agent noticed
- issue drafts that duplicate the same underlying fix

Return:
1. consensus high-risk findings
2. reconciled review-gate violations
3. reconciled QA coverage findings
4. disputed findings needing human review
5. PRs both agents consider OK
6. deduped issue plan
7. reconciled worked-issue/QA-lane coverage table with issue number or QA lane
   id, coordination lane/branch, linked PR or no-PR/blocker/QA evidence, final
   state, intent-achievement or QA-coverage classification, and any unresolved
   `UNKNOWN` facts
8. recommended next actions, including a coordinator resume/reassign/drop
   decision for `stalled` lanes instead of defaulting to issue creation

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
- Create one child issue per independently actionable fix PR, revert
  consideration, maintainer question, follow-up task, or approved non-OK
  worked-issue/QA coverage follow-up.
- For release-gate audits, append the audit report to the release-gate audit
  ledger before creating approved follow-up issues; include the resulting ledger
  comment URL in every parent and child issue body.
- If a required release-gate ledger append fails, do not create parent or child
  issues. Report the exact command/API error and the ledger issue, permission,
  or retry needed before issue creation can proceed.
- For non-release audits with no release-gate ledger, include
  `Audit ledger: not applicable (non-release audit)` in every parent and child
  issue body.
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
