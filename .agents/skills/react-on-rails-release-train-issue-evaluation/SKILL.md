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

- Search open release-targeted PRs before branching. Reuse a valid source-atomic
  PR or an explicitly maintainer-approved aggregate whose sources meet the
  inseparability exception below. If an unapproved aggregate violates this
  shape, recommend separate replacements; close it only with explicit write
  authorization and retain its branch unless deletion is also authorized.
- Process them serially. Merge one backport, fetch the new release tip, then
  update a reused PR onto that tip or branch the next. Rerun validation, QA, and
  review on the updated head before merging.
- Before updating or branching, confirm each selected source patch is still live
  on refreshed `origin/main`. A source reverted or superseded on `main` requires
  renewed maintainer approval before backporting.
- Give each source PR its own `git cherry-pick -x` provenance, conflict record,
  validation, QA evidence, review cycle, and rollback boundary. Every commit
  created by a `main`-to-release backport and landed on the release branch must
  have exactly one direct
  `(cherry picked from commit <source-sha>)` footer; record inherited provenance
  from a source commit in the PR instead of copying another footer. A backport
  with exactly one source commit may preserve that footer in a squash commit.
  For a multi-commit rebase-merged source PR or approved aggregate, stop for a
  maintainer-approved merge plan until the repository can preserve both one
  normalized release commit per source commit and changelog-sweep PR
  attribution; never create a multi-footer commit.
- Do not bundle independent source PRs because they share a target, component,
  milestone, or `CHANGELOG.md`. Shared changelog edits require serialization;
  retain each source PR's applicable changelog entry, then reconcile the entries
  and stamp or regenerate the RC changelog after every backport retained in the
  final release set lands.
- Combine only behaviorally inseparable changes that cannot be reviewed,
  tested, or reverted safely alone. Require an explicit maintainer-approved
  rationale naming every source PR before implementation.

## Workflow

1. Refresh repo context: fetch and prune `origin/main` and the target release
   branch, then run `.agents/bin/agent-workflow-seam-doctor`. Use the refreshed
   release ref for ancestry, prior-backport, and supersession checks.
2. Resolve candidates from live GitHub. For strict 48-hour windows, search by date then timestamp-filter locally because GitHub search is date-granular.
3. Exclude started lanes. For an ordinary issue candidate, an assignee,
   linked/open implementation PR, private claim/heartbeat/branch, or
   implementation comment means the lane is started. A merged `main` source PR
   is completed input, not a started release-backport lane: its linked issue,
   assignee, merged implementation PR, and generic source coordination state do
   not exclude it. Its backport lane is started by a valid source-atomic
   release-targeted implementation PR or branch; an explicitly
   maintainer-approved aggregate whose sources are behaviorally inseparable; a
   backport implementation comment for either valid shape; or private
   coordination state that explicitly identifies that valid release/backport
   lane. An unapproved, shape-violating aggregate does not exclude its source
   candidates; keep them eligible so the **Backport Shape** replacement can be
   recommended.
   Run `agent-coord doctor --json`, then run
   `agent-coord status --repo shakacode/react_on_rails --target <issue-or-pr> --json`
   for each candidate. Dead or expired ordinary-issue claims and explicitly
   identified backport claims count as started-but-stalled, not non-started;
   generic source claims do not prove that a backport started.
4. Read release context: active `Release gate:` tracker, `release` + `TRACKING` labels, the `Agent Release Mode` block, `agent-coord` phase when available, source PR base branches, and whether source commits are already on `origin/release/X.Y.Z`.
5. Evaluate each candidate with `$evaluate-issue`: evidence source, impact, complexity, process gap disposition, and priority.
6. Choose the target:
   - `release/X.Y.Z`: verified RC/final stabilizer such as an RC regression, hard-gate failure, install/upgrade blocker, security/data-loss/wrong-output bug, release-branch CI/release tooling blocker, or final-only public API/breaking-change decision.
   - `release/X.Y.Z contingent`: only needed if maintainers decide to cherry-pick a related main-only fix into the train. Name the dependency.
   - `main`: docs, changelog for main-only PRs, CI/tooling hygiene, tests, process automation, non-blocking runtime hardening, features, and performance/cleanup without release-gate proof.
   - `park/close`: P3, speculative, duplicate, no-PR evidence, or not worth doing.
7. For one or more `release/X.Y.Z` selections, apply the **Backport Shape**
   rules above. For multiple selections, also record the serial order.

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
