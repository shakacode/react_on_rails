---
name: react-on-rails-release-train-issue-evaluation
description: Use when evaluating React on Rails GitHub issues for release-train targeting, especially deciding whether new, follow-up, or non-started issues belong on release/17.0.0, another release/X.Y.Z branch, or main.
---

# React on Rails Release Train Issue Evaluation

## Core Rule

Use this with `$evaluate-issue`. That skill answers "is this worth doing?"; this skill answers "does it belong on the active release train or on `main`?"

`release/*` receives only stabilizing fixes. Features, cleanup, docs, process work, non-blocking hardening, and ordinary follow-ups target `main`.

## Backport Shape

When one or more merged `main` PRs qualify for `release/X.Y.Z`, default to one
source PR per release backport PR:

- Process them serially. Merge one backport, fetch the new release tip, then
  branch the next.
- Give each source PR its own `git cherry-pick -x` provenance, conflict record,
  validation, QA evidence, review cycle, and rollback boundary.
- Do not bundle independent source PRs because they share a target, component,
  milestone, or `CHANGELOG.md`. Shared changelog edits require serialization;
  retain each source PR's applicable changelog entry, then reconcile the entries
  and stamp or regenerate the RC changelog after every backport retained in the
  final release set lands.
- Combine only behaviorally inseparable changes that cannot be reviewed,
  tested, or reverted safely alone. Require an explicit maintainer-approved
  rationale naming every source PR before implementation.
- Search open release-targeted PRs before branching. If an aggregate PR already
  violates this shape, recommend separate replacements; close it only with
  explicit write authorization and retain its branch unless deletion is also
  authorized.

## Workflow

1. Refresh repo context: `git fetch --prune origin main`, then `.agents/bin/agent-workflow-seam-doctor`. Fetch the release branch if ancestry matters.
2. Resolve candidates from live GitHub. For strict 48-hour windows, search by date then timestamp-filter locally because GitHub search is date-granular.
3. Exclude started lanes. An issue is started when it has an assignee, linked/open implementation PR, private claim/heartbeat/branch, or implementation comment. Run `agent-coord doctor --json`, then targeted `agent-coord status --repo shakacode/react_on_rails --target <issue> --json`. Dead or expired claims count as started-but-stalled, not non-started.
4. Read release context: active `Release gate:` tracker, `release` + `TRACKING` labels, the `Agent Release Mode` block, `agent-coord` phase when available, source PR base branches, and whether source commits are already on `origin/release/X.Y.Z`.
5. Evaluate each candidate with `$evaluate-issue`: evidence source, impact, complexity, process gap disposition, and priority.
6. Choose the target:
   - `release/X.Y.Z`: verified RC/final stabilizer such as an RC regression, hard-gate failure, install/upgrade blocker, security/data-loss/wrong-output bug, release-branch CI/release tooling blocker, or final-only public API/breaking-change decision.
   - `release/X.Y.Z contingent`: only needed if maintainers decide to cherry-pick a related main-only fix into the train. Name the dependency.
   - `main`: docs, changelog for main-only PRs, CI/tooling hygiene, tests, process automation, non-blocking runtime hardening, features, and performance/cleanup without release-gate proof.
   - `park/close`: P3, speculative, duplicate, no-PR evidence, or not worth doing.
7. For multiple `release/X.Y.Z` selections, record the serial order in the
   output; apply the **Backport Shape** rules above.

Recommend labels/milestones/comments, but do not mutate GitHub unless the user explicitly authorizes writes.

## Output

Use a compact table:

| Issue | Started? | Evidence | Disposition | Target | Rationale | Next action |
| ----- | -------- | -------- | ----------- | ------ | --------- | ----------- |

Call out `UNKNOWN` facts explicitly, especially release tracker mode, source PR base, branch ancestry, and whether the issue is a confirmed RC regression.

## Common Mistakes

- Treating a title that says "before 17.0.0 final" as sufficient. Verify release-gate impact and branch ancestry.
- Sending main-only follow-up defects to `release/17.0.0` when the related fix is not on the release branch. Mark these contingent instead.
- Using labels alone. Labels are hints; issue evidence and the release tracker decide.
- Treating tracker `Mode: development` as "no release train." The branch can still exist; target selection still matters.
