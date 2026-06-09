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

## Labels

- `P0`: merge-this-week blocker.
- `P1`: target-this-sprint work.
- `P2`: backlog priority.
- `P3`: parked priority.
- `discussion`: RFCs, unclear product direction, or design conversations.
- `needs-customer-feedback`: do not implement until customer evidence or maintainer approval exists.
  Create it with description `Do not implement until customer evidence or maintainer approval exists.` and color `bfd4f2` when label creation is authorized; otherwise report it as a missing label.
- `runtime-fix`: user-facing behavior fix that should actually be implemented.

Label changes are authorized only when the user explicitly asked for labels in the current session or granted issue-triage/write permission for the current task. If unsure, report the label recommendation without changing GitHub.

Do not label AI/code-analysis-only findings as high priority without verified user impact.

## Batch Planning

Before adding issues to a PR batch, classify each target as:

- implementation PR;
- documentation/workaround update;
- no-PR evidence comment;
- product-decision blocker;
- parked/deferred item.

Only implementation PRs and explicitly selected documentation updates should go to worker implementation batches. Parked, close-candidate, and product-decision items belong in audit/comment-only batches or should be excluded.

Use `.agents/skills/evaluate-issue/SKILL.md` when skills are available. Use `.agents/workflows/evaluate-issue.md` as the copy/paste version for assistants without skill support.
