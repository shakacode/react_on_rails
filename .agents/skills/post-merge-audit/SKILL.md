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

Start by resolving the exact audit range and, when auditing a named agent
batch/run, the exact worked-issue scope:

Term: a structured public `codex-claim` comment is a GitHub issue/PR comment
containing a `codex-claim` HTML comment (`<!-- codex-claim v1 ... -->`) with
key/value fields in the "Public claim comment" format from
`.agents/workflows/pr-processing.md`.

When this repository includes the `post-merge-audit-scope` helper, run it first:

```bash
POST_MERGE_AUDIT_SKILL_DIR="${POST_MERGE_AUDIT_SKILL_DIR:-.agents/skills/post-merge-audit}"
"${POST_MERGE_AUDIT_SKILL_DIR}/bin/post-merge-audit-scope" --json
```

The resolver is read-only. It resolves the default release-candidate base, the head SHA, squash-aware merged PRs, prior `post-merge-audit-finding` fingerprints, PRs with open finding markers, and the `to_audit` list. Open finding markers create carry-over PRs that are subtracted from `to_audit`; closed markers remain fingerprint context only. Use the output as the initial merged-PR scope table, then verify assumptions before deep audit.

1. Base: the user-supplied tag/commit, or the most recent release candidate tag when the user says "since the last RC".
2. Head: usually `origin/main` or the current release branch.
3. Merged PR list: every PR merged between base and head.
4. Worked issue list: for private coordination backend setup and CLI discovery,
   see `.agents/docs/coordination-backend.md`. If no
   coordinated batch/run is in scope, record
   `worked_issue_scope: not applicable`. If batch work is in scope but the
   batch/run id is unknown:
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
     `worked_issue_scope: UNKNOWN (needs batch confirmation)` and ask the user
     to supply or confirm a batch/run id directly; once the user supplies or
     confirms one, continue with the known-batch-id path below
   - if broad discovery returns candidates but cannot determine which candidate
     is in scope, record
     `worked_issue_scope: UNKNOWN (needs batch confirmation)` and ask the user
     to confirm one candidate before treating that candidate's lane list as
     worked-issue scope; once confirmed, continue with the known-batch-id path
     below
   - `UNKNOWN (setup)` and `UNKNOWN (access)` take precedence over
     `UNKNOWN (needs batch confirmation)`; only report candidate ids as
     confirmation targets when backend setup and discovery access both worked

   When a batch/run id is known, run bounded `agent-coord doctor --json` and
   bounded `agent-coord status --batch-id <batch-id> --json`, then inspect the
   named batch entry; use claims, heartbeats, and batch metadata as the primary
   worked-issue scope. If `agent-coord` is missing or bounded
   `agent-coord doctor --json` fails or times out, record
   `worked_issue_scope: UNKNOWN (setup)`. If bounded
   `agent-coord doctor --json` passes but targeted batch status fails or times
   out, record `worked_issue_scope: UNKNOWN (access)`. In all UNKNOWN cases,
   include the exact command/error and use structured public `codex-claim`
   comments as an advisory fallback for possible no-PR, blocked, parked, or
   done-unmerged lanes before reducing scope to merged PRs. Keep advisory rows
   marked `UNKNOWN` as needed, and do not infer confirmed completeness from
   merged PRs.
   When the batch/run id itself is unknown, scope that advisory scan to issues
   and open PRs active within the audit time window; use each claim's `batch:`
   field to surface candidate batch ids, not to filter as confirmed scope until
   the user confirms the id.

   If bounded `agent-coord doctor --json` and targeted batch status both succeed
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

5. Batch PR subset: only when `worked_issue_scope` is verified from
   coordination state, map worked issues to PRs through coordination branch
   names, linked PRs, PR bodies, labels, comments, authors, merge timing, and
   git history. Treat `not applicable`, `UNKNOWN (...)`, and `empty (...)` as
   merged-PR-range-only or advisory scope states, not verified batch subsets.
   Keep PR-range inclusion separate from worked-issue coverage so no-PR,
   blocked, parked, and unmerged lanes are still evaluated.

After the scope algorithm identifies the batch or reports an `UNKNOWN` scope,
collect any QA lane and QA Evidence block for that batch. Do not use missing QA
state to shrink the worked-issue scope; report it as a QA coverage finding or
`UNKNOWN` fact instead.

Show included worked issues, included PRs, collected QA lanes and QA Evidence
blocks, excluded near-matches, base/head SHAs, coordination status evidence, and
assumptions. Ask for confirmation before deep audit unless the user explicitly
asks to proceed without confirmation.

## Audit Checks

For each included PR:

- Review completion: find reviews, review comments, issue comments, and review/check runs from Claude, Codex, CodeRabbit, Greptile, Cursor Bugbot, and other configured reviewers.
- Review timing: flag any reviewer check, review, or comment that was still queued/in-progress at merge time or landed after merge.
- Review triage: flag any pre-merge review/comment with `Must Fix`, `MUST-FIX`, `Should Fix`, `DISCUSS`, `Changes Requested`, `blocking`, or similar actionable language when there is no later evidence it was fixed, waived, or explicitly classified.
- Approval semantics: flag any merge that treated an AI reviewer approval, positive issue comment, or "no actionable comments" summary as required maintainer approval or a special approval gate. Also flag any AI finding that was ignored even though it identified a confirmed blocker such as a correctness regression, failing test, security issue, API contract break, data-loss risk, or missing required maintainer approval.
- Adversarial review: flag any requested adversarial review that finished after merge, reviewed an older head SHA, or left untriaged `BLOCKING` or `DISCUSS` findings.
- Changelog: if the diff or PR body indicates a user-visible behavior, API, error message, configuration, performance, security, or breaking change, verify the repo's changelog (see `AGENTS.md` → **Agent Workflow Configuration**) has a matching entry. When entries are missing, recommend running `/update-changelog`.
- Lockfiles: if the PR changed committed lockfiles, verify the PR evidence satisfies the lockfile content-diff requirement from the Handoff Contract in `.agents/skills/pr-batch/SKILL.md`.
- Closing evidence: for any PR whose body or linked issue uses analysis, benchmark, or investigation
  evidence to support a `close` or `document/work around` disposition, verify the conclusion applies the
  full gate from the "Evaluate the fix plan separately" step in `.agents/skills/evaluate-issue/SKILL.md`:
  reproducible artifact or justified missing-artifact caveat, internal consistency, production-environment
  caveats, and refutable-conclusion handling.
- Validation: compare changed areas with the validation evidence in the PR body or comments.
- QA evidence: verify required QA Evidence exists, records `Tested at` with the
  PR/head SHA or audited range it applies to, is current for that head/range,
  covers the changed surfaces, and does not leave release-blocking findings
  untriaged. If private coordination claim/heartbeat state is `UNKNOWN`, verify
  the documented fallback evidence is otherwise complete and names a concrete QA
  owner and branch/worktree before treating QA coverage as satisfied.
- Cross-PR interactions: compare changed files, shared behavior, assumptions, and release-sensitive areas across the batch.
- Decision log: inspect any `Codex Decision Log` or equivalent section and verify the decisions still hold after the merge.

For each worked issue, QA lane, or advisory `codex-claim` recovery row from
coordination state, including no-PR, blocked, parked, done-unmerged, or
still-open lanes:

- Intent coverage: compare the issue or QA-lane intent with the PR diff, no-PR
  evidence comment, QA evidence, branch state, or blocker note.
- Final state: verify whether the issue was merged, closed, parked, blocked,
  left open intentionally, or remains `UNKNOWN`; for QA lanes, verify whether
  the QA coverage status is `satisfied`, `blocked`, `waived`, healthy
  `in_progress`, `not_applicable` when QA was not required, or `unknown`.
- Handoff expectations: check validation evidence, decision-point count,
  confidence notes, QA evidence, review/comment triage, and any Process Gap
  Disposition fields required by `.agents/workflows/pr-processing.md`.
- Classification: reuse the intent-achievement classes from
  `.agents/workflows/continuous-evaluation-loop.md` (`in_progress`,
  `realized`, `partial`, `missed`, `regressed`, `stalled`, or `unknown`) and
  explain any `UNKNOWN` evidence needed to resolve the issue outcome. For QA
  lanes, use the QA-coverage result `satisfied`, `blocked`, `waived`,
  `in_progress`, `not_applicable`, or `unknown` from
  `.agents/workflows/pr-processing.md`.
- Post-merge intake: record healthy `in_progress` worked-issue lanes,
  evidenced `realized` worked-issue outcomes, evidenced `satisfied` or `waived`
  QA lanes, and evidenced `not_applicable` QA omissions in the coverage table as
  no-action items; treat required QA lanes still `in_progress` during readiness
  or release audits as QA coverage findings; route
  `stalled` lanes back to the batch coordinator as resume/reassign/drop
  decisions unless the user explicitly approves tracking the stalled lane as an
  issue; route every other non-OK worked-issue class (`partial`, `missed`,
  `regressed`, or `unknown`), merged or not, and every non-OK QA coverage
  outcome (`blocked`, `unknown`, or release-audit `in_progress`) into the issue
  plan or an explicit coordinator action that names the missing evidence or
  decision.

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
- **Needs changelog update**: user-visible change is missing from the repo's changelog; recommend `/update-changelog`.
- **Needs follow-up issue**: non-blocking work remains valuable and is actionable after release.
- **Needs fix PR**: a real defect, missing test, missing compatibility note, or bad interaction should be fixed before release.
- **Needs revert consideration**: the merge appears risky enough that reverting may be safer than patching.

Classify each worked issue separately so the audit can prove every coordinated
lane was evaluated, even when the issue produced no merged PR:

- `in_progress`: the lane is healthy active/live work with recent heartbeat,
  commits, or review activity and no stalled, regressed, partial, missed, or
  unknown signal; record it as a no-action item.
- `realized`: the issue intent was satisfied and the final state is supported
  by evidence.
- `partial`: the issue intent was incompletely addressed; some acceptance
  criteria landed and others did not.
- `missed`: the issue intent was not addressed; no meaningful implementation
  or evidence comment exists.
- `regressed`: the merge harmed an outcome that was previously satisfied.
- `stalled`: the lane needs a coordinator decision to resume, reassign, or
  drop. Includes `stale` and `dead` lost-heartbeat operational states; see
  `continuous-evaluation-loop.md` for the operational-to-intent mapping.
- `unknown`: the auditor cannot verify the issue outcome from available
  coordination, GitHub, and git evidence.

## Issue Plan

The audit should usually produce an issue plan for non-OK findings, but not create issues until approval.

- **No issue**: for `OK`, duplicate findings, findings fully resolved by the
  audit evidence, evidenced `realized` lanes, healthy `in_progress`
  worked-issue lanes, evidenced `satisfied` or `waived` QA lanes, or evidenced
  QA omissions marked `not_applicable`; include those rows in the
  worked-issue/QA-lane coverage table so the coordinator can see they were
  checked.
- **Changelog only**: for missing changelog entries; prefer one bundled changelog issue or a recommendation to run `/update-changelog`, not one issue per entry.
- **One child issue**: for each independently actionable fix PR, revert consideration, maintainer question, follow-up task, non-OK worked-issue outcome (`partial`, `missed`, `regressed`, or `unknown`), or non-OK QA coverage outcome (`blocked`, `unknown`, or release-audit `in_progress`) that needs follow-up.
- **Parent issue**: create one parent issue only to group two or more related
  _child fix_ issues from the same audit. Do **not** create a standalone
  audit-snapshot tracker (a `Post-<range> audit` / `Post-rc.N catch-up audit`
  issue): per `AGENTS.md` → _Tracking Issues And Handoffs_, the audit report is
  a point-in-time snapshot. For release-gate audits, append that snapshot to the
  standing release audit ledger in place and include the ledger comment URL in
  every approved parent or child issue created from the audit. Locate the ledger
  with the release-mode preflight search: open issues with the `release` and
  `TRACKING` labels, plus `Release gate:` title matches. If no release-gate
  ledger exists for a release audit, surface that absence as a blocker before
  creating follow-up issues. For non-release audits with no release-gate ledger, record
  `Audit ledger: not applicable (non-release audit)` in every approved parent or
  child issue. Genuine non-OK findings still become real child issues; only the
  snapshot/report is what goes to the ledger instead of a new issue.

For process findings, the issue plan must include a Process Gap Disposition
before issue creation:

- `Mechanism target`: `script`, `schema`, `checklist+replay`, or `park`.
- `Motivating miss`: the PR, review, audit, or incident the mechanism must catch.
- `Replay evidence or park reason`: the command, fixture, historical PR/issue,
  or audit artifact used to prove the mechanism catches the miss; for `park`,
  why no mechanism is worth building now.
- `Non-goal`: the broad prose-only rule this finding must not become.

Before creating an approved issue, search existing open issues for the affected PR number and hidden fingerprint:

```markdown
<!-- post-merge-audit-finding v1
audit: <AUDIT_ID>
fingerprint: pr-<PR>:<short-issue-slug>
affected_prs: <PR>
-->
```

Example fingerprint slug: `pr-3724:changelog-server-bundle-load-error`.

Only the coordinator should create issues. Independent Codex and Claude audits should draft issue entries with fingerprints so the coordinator can compare and dedupe them.

## Output

Return high-risk findings first, then:

1. Review-gate violations, including PRs merged before requested reviews finished, before actionable review findings were triaged, or with AI review systems incorrectly counted as approval gates.
2. QA coverage findings, including missing, stale, insufficiently scoped, or
   still-`UNKNOWN` required QA evidence.
3. Missing changelog candidates, with a single recommendation to run `/update-changelog` when any are found.
4. Cross-PR interaction risks.
5. A deduped issue plan with parent/child recommendations and fingerprints.
6. A worked-issue/QA-lane coverage table with issue number or QA lane id,
   coordination lane/branch, linked PR or no-PR/blocker/QA evidence, final
   state, issue intent-achievement or QA-coverage classification, and `UNKNOWN`
   facts (see the example in `.agents/workflows/post-merge-audit.md`).
7. A PR-by-PR table.
8. Exact commands and data sources used, including bounded `agent-coord status`
   output for the named batch or the exact reason coordination state was
   `UNKNOWN`.

Do not create fixes, comments, labels, issues, changelog edits, reverts, or PRs until the user approves the audit report.
