# Issue Evaluation Workflow

Use this workflow before fixing, batching, or assigning a GitHub issue when value is uncertain, especially when the issue was found by AI/code analysis rather than by real users.

The authoritative rubric lives in `.agents/skills/evaluate-issue/SKILL.md`. Read and follow that file first; this workflow exists for agents that prefer workflow-file entry points over skill invocation syntax.

## Sequence

1. Exact issues or PRs:
   - Follow `.agents/skills/evaluate-issue/SKILL.md` directly.
   - Report `UNKNOWN` for any fact that cannot be verified.
2. Filters, labels, milestones, pasted lists, or other unverified batch scopes:
   - Run `.agents/skills/plan-pr-batch/SKILL.md` first to resolve exact candidates.
   - After exact candidates are known, follow `.agents/skills/evaluate-issue/SKILL.md` for targets that are speculative, AI/code-analysis-only, over-scoped, or unclear in value, priority, or fix scope.
3. Batch handoff:
   - Exclude `park / P3`, `close`, and `product decision` items from implementation batches unless the batch is explicitly audit/comment-only.
   - Convert low-value assigned issues into no-PR evidence comments rather than speculative PRs.
   - Carry the disposition into `$pr-batch` as the target outcome: implementation PR, no-PR evidence comment, `document/work around`, or product-decision blocker.

For investigation or benchmark issues, recommendations to `close`, `park`, or
`document/work around` require closing evidence. Cite a reproducible artifact
(script, data file, benchmark command plus environment) or state the
missing-artifact caveat, verify that headline numbers match the document's own
tables, and carry production-environment caveats when the evidence was collected
on a different platform. If a second agent can reasonably refute the conclusion
from the artifacts alone, recommend a correction, follow-up, or explicit caveat
instead of closing as settled.
