# Issue and Fix Evaluation

Use these principles before implementing, batching, or assigning issues. The goal is to spend engineering and CI time on work that matters, not on every plausible gap.

## Core Principle

AI-found gaps are leads, not priorities. Prioritize real customer reports, verified regressions, security/correctness issues, and migration blockers over hypothetical issues found by code analysis.

## Evidence Hierarchy

Prefer issues with direct evidence of user impact:

1. Real customer or user report.
2. Maintainer-observed failure or reproduced obstacle.
3. CI, release candidate, production, or regression-test evidence.
4. AI/code-analysis finding with a plausible failure mode.
5. Speculative improvement without a known affected user.

The lower the evidence level, the more the fix must justify itself through low complexity, clear safety, and obvious long-term value.

## Impact Versus Complexity

A valid issue can still have an over-scoped fix. Evaluate the proposed plan separately from the problem statement.

Prefer:

- fail-fast guardrails over broad behavior changes;
- clearer errors over hidden inference;
- documentation or workaround guidance when current behavior is acceptable;
- small prerequisite fixes before broad migrations;
- no-PR evidence comments when the best outcome is to decline or park work.

Be skeptical of broad changes to identity models, runtime behavior, CI/workflow control, dependency versions, build configuration, Pro/RSC internals, or public APIs unless the user impact is verified and meaningful.

## Disposition Guide

- **Fix now / P0:** release blocker, merge-this-week severity, security/data-loss risk, or active severe regression.
- **Fix now / P1:** verified urgency with a manageable, well-tested implementation path, but not an immediate release blocker.
- **Fix later / P2:** real impact, but not urgent or dependent on sequencing.
- **Park / P3:** plausible but hypothetical, complex, waiting for customer evidence, or better as an RFC.
- **Document/work around:** current behavior is acceptable when users get clear guidance.
- **Close / not planned:** low-value, speculative, duplicate, harmful, or superseded.
- **Product decision:** the issue needs maintainer input before implementation would be safe.

## Process Gap Disposition

For recurring process misses, classify the mechanism before adding or approving
another process issue. Required fields:

- `Mechanism target`: `script`, `schema`, `checklist+replay`, or `park`.
- `Motivating miss`: the PR, review, audit, or incident the mechanism must catch.
- `Replay evidence or park reason`: command, fixture, historical PR/issue, or
  audit artifact used to prove the mechanism catches the miss; for `park`, why
  no mechanism is worth building now.
- `Non-goal`: the broad prose-only rule this should not become.

### Dry Run: #4009 Process Children

Live issue state checked on 2026-06-15:

| Source                   | Item                                                            | Mechanism target   | Motivating miss                                 | Replay evidence or park reason                                                           | Non-goal                        |
| ------------------------ | --------------------------------------------------------------- | ------------------ | ----------------------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------- |
| #3906                    | #3908 lockfile content-diff gate (open)                         | `script`           | Lockfile review missed cross-file drift.        | Replay against #3861/#3769 lockfile diffs and sibling-lock comparison.                   | Another reviewer reminder.      |
| #3906                    | #3910 evidence gate (open)                                      | `checklist+replay` | Review conclusions outran artifacts.            | Replay #3768/#3282 by refuting the conclusion from artifacts and caveats.                | Broad "include evidence" prose. |
| #3906                    | #3912 deterministic orchestration (open)                        | `schema`           | Batch handoffs omitted durable state.           | Worker-result schema plus resume journal; replay omission-prone handoffs such as #3613.  | Narrative status template.      |
| #3906                    | #3913 skill hygiene (open)                                      | `script`           | Skill docs drifted from canonical workflow.     | Sync-marker lint with an induced drift failure and word-count thresholds.                | Manual sync instruction.        |
| #3974                    | #4000 release-train gating (open)                               | `park`             | Release branch model is still unsettled.        | Release branch model needs a maintainer/product decision before more gate prose.         | Premature gate expansion.       |
| #3975                    | #3975 attention contract (open for observation)                 | `checklist+replay` | Attention pings and nit fixes caused churn.     | Next multi-batch closeout must replay decision-point counts and nit/CI-wait behavior.    | Another etiquette paragraph.    |
| #4004                    | No open child; #4004 is closed                                  | `schema`           | Follow-up issue wanted outcome evidence.        | Preserve as an intent-achievement report artifact; do not file another status paragraph. | Loose progress update.          |
| Existing prose-only rule | New-gate stale-base rollout in `AGENTS.md` / `pr-processing.md` | `checklist+replay` | New gates could strand open PRs on stale rules. | Converted to require a named stale-base sweep or rerun option plus replay evidence.      | Vague rollout warning.          |

## Labels

- `P0`: merge-this-week blocker.
- `P1`: target-this-sprint work.
- `P2`: backlog priority.
- `P3`: parked priority.
- `discussion`: RFCs, unclear product direction, or design conversations.
- `needs-customer-feedback`: do not implement until customer evidence or maintainer approval exists.
  See the installed/shared `$evaluate-issue` skill for the canonical creation description, color, and authorization rule.
- `runtime-fix`: user-facing behavior fix that should actually be implemented.

Label changes are authorized only when the current user prompt, worker goal, or task instructions explicitly allow label changes, or the user granted issue-triage/write permission for the current task. If unsure, report the label recommendation without changing GitHub.

Do not label AI/code-analysis-only findings as high priority without verified user impact.

## Batch Planning

For broad issue audits or all-open-issues review, use the installed/shared
`$plan-issue-triage` skill first to generate a review-only prompt. In that
context, GitHub issue comments may be allowed while code, branch, issue, PR,
label, milestone, assignee, title/body, and issue-state changes remain
disallowed unless explicitly approved.

Before adding issues to a PR batch, classify each target as:

- implementation PR;
- `document/work around`;
- no-PR evidence comment;
- product-decision blocker;
- parked/deferred item.

Only implementation PRs and explicitly selected documentation updates should go to worker implementation batches. Parked, close-candidate, and product-decision items belong in audit/comment-only batches or should be excluded.

Use the installed/shared `$evaluate-issue` skill when skills are available. Use
[workflows/evaluate-issue.md](../workflows/evaluate-issue.md) for assistants
that prefer workflow-file entry points over skill invocation syntax.
