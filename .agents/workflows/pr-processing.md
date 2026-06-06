# PR Processing Workflow

Use this workflow when an agent is assigned an issue, an existing PR, a PR review-fix pass, or a multi-PR landing plan. The goal is to reduce review turns, CI churn, and follow-up issue noise by doing more local work before asking GitHub to spend reviewer or runner time.

## Default Operating Model

1. Resolve the work item:
   - Issue: fetch the issue body, comments, linked PRs, and acceptance criteria.
   - PR: fetch the PR body, changed files, review decision, checks, labels, unresolved review threads, and recent comments. Treat an assigned PR like an assigned issue whose implementation has already started; the same value, scope, testing, and readiness rules still apply.
   - Multi-PR landing plan: build a dependency map first; exclude WIP/draft PRs unless the user explicitly includes them.
2. Validate that the work is worth doing:
   - Confirm the issue or PR describes a real project benefit, not just speculative polish or churn.
   - Push back on poorly defined, low-value, or harmful requests before creating a PR.
   - For assigned issues, an acceptable outcome may be an issue comment explaining why no PR should be created.
3. Isolate the work:
   - Use the current checkout for one focused task.
   - For multiple independent PRs or lanes, use one worktree per PR branch so agents do not overlap edits.
4. Make a local batch:
   - Fix all clear blockers in one local pass.
   - Batch review fixes into one follow-up push when practical.
   - Do not push "hopeful" fixes just to let CI discover basic failures.
5. Self-review before every push or PR-ready signal.
6. Run local validation based on changed areas.
7. Update the PR body, issue, or one concise PR comment with exact verification evidence and remaining gaps.
8. Only then request review, full CI, or merge readiness.

## Initial GitHub Commands

Replace angle-bracket placeholders such as `<PR>` and `<PR_NUMBER>` with real values before running these commands.

For a PR, gather current state before touching code:

```bash
gh pr view <PR> --json number,title,body,state,isDraft,headRefName,baseRefName,mergeStateStatus,reviewDecision,statusCheckRollup,labels,url
gh pr diff <PR> --name-only
gh pr checks <PR>
```

Fetch unresolved review threads when review comments matter:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
OWNER=${REPO%/*}
NAME=${REPO#*/}
PR_NUMBER=<PR_NUMBER>
gh api graphql --paginate -f owner="${OWNER}" -f name="${NAME}" -F pr="${PR_NUMBER}" -f query='query($owner:String!, $name:String!, $pr:Int!, $endCursor:String) { repository(owner:$owner, name:$name) { pullRequest(number:$pr) { reviewThreads(first:100, after:$endCursor) { nodes { id isResolved comments(first:100) { nodes { id databaseId body author { login } url path line } } } pageInfo { hasNextPage endCursor } } } } }'
```

For an issue, gather enough context to avoid duplicate work:

```bash
gh issue view <ISSUE> --json number,title,body,state,labels,comments,url
gh issue list --search "<key terms from issue>" --state open
gh pr list --search "<key terms from issue>" --state open
```

## Self-Review Gate

Before pushing, opening a PR, marking a PR ready, or asking for another review pass, review the local diff as if you were the first code reviewer:

- Scope: does the diff solve the requested issue without unrelated churn?
- Correctness: what could be nil, stale, duplicated, order-dependent, or race-prone?
- Adjacent patterns: does the code match nearby Ruby, TypeScript, generator, Pro, and docs conventions?
- Tests: is there a regression test for changed behavior, not just incidental coverage?
- Security: are shell commands, file paths, generated code, secrets, markdown links, and external input handled safely?
- Performance: did the change add avoidable work to render, build, CI, SSR, RSC, or benchmark paths?
- Review surface: are names, comments, PR body text, and changelog entries clear enough to avoid predictable review comments?

If self-review finds a real issue, fix it locally before pushing. Do not post self-review findings as new GitHub comments unless the user explicitly asks for a summary.

## Reproduction And TDD Gate

Before fixing a bug or behavior regression, verify the incorrect behavior where possible.

- Prefer a failing test that reproduces the issue and passes after the fix.
- Use test-driven development for bug fixes and behavior changes when practical: reproduce, see the failure, apply the fix, and rerun the test.
- If a direct regression test is not practical, document why and use the closest useful local verification.
- If the change affects developer workflow, locally exercise that workflow rather than relying only on unit tests.
- For app-facing behavior, do minimal manual testing through the relevant non-Pro and Pro test apps when appropriate.
- Try to run the same relevant local tests that CI would run for the changed area before pushing.

## Local Validation Gate

Run the change detector first:

```bash
script/ci-changes-detector origin/main
```

Then run the recommended local CI or a tighter set that covers the same changed area:

```bash
bin/ci-local
```

Use targeted checks when a full local run is too expensive, but explain the substitution:

- Ruby gem code: `bundle exec rubocop`, `bundle exec rake run_rspec:gem`, and `bundle exec rake rbs:validate` when signatures changed.
- Dummy app or integration behavior: `bundle exec rake run_rspec:dummy` or the specific dummy spec.
- JS/TS package code: `pnpm run lint`, `pnpm run test`, `pnpm run type-check`, and `pnpm start format.listDifferent`.
- Generator changes: `rake run_rspec:shakapacker_examples_basic`, then broader generator specs when risk is high.
- Pro changes: run the Pro-specific lint/tests that cover the edited files.
- Workflow changes: `actionlint` for edited workflows and the relevant command validation.
- Developer workflow changes: exercise the affected command or setup path locally, including generated-app or dummy-app smoke checks when relevant.
- App-facing changes: run minimal manual checks in the relevant non-Pro and Pro test apps, and document what was or was not exercised.
- Docs-only changes: markdown formatting/link checks when applicable; do not run RuboCop on YAML or markdown.

Use the 15-minute rule from `AGENTS.md`: if another short local check would likely catch the failure before CI, run it locally.

## Full CI Backpressure

Use the `+ci-*` PR comment commands from the CI command workflow for full-CI decisions. These commands provide the audit trail for running, stopping, checking, or waiving full CI.

- During active implementation or review-fix churn, do not request full CI.
- If a PR is still being iterated and already has `full-ci`, ask whether to comment `+ci-stop-full` before pushing more batches.
- Use `+ci-status` before deciding whether full CI is already enabled or waived for the current SHA.
- Use `+ci-run-full` only after local validation, self-review, review-thread triage, and the final push for the current batch.
- Use `+ci-skip-full [reason]` only with explicit maintainer approval and only for low-risk/current-SHA cases where the reason is auditable.
- Use `+ci-help` when the command syntax or current behavior is unclear.
- Put one `+ci-*` command per PR comment; the workflow handles only the first command in a comment.
- Do not add or remove `full-ci` directly when a `+ci-*` command would create a clearer audit trail.

## Review Comment Handling

For Claude Code, use `/address-review`. For Codex or other assistants, use `.agents/workflows/address-review.md`. The default stance is:

- `MUST-FIX`: fix in the PR.
- `DISCUSS`: ask the user or make a narrow, evidence-backed decision.
- `OPTIONAL`: address inline only when the user opts in.
- `SKIPPED`: reply with rationale only when useful; do not create work from noise.

Do not let follow-up issues become a substitute for finishing the PR. Follow-up tracking is allowed only for real, non-blocking work that remains valuable outside the PR context.

## Follow-Up Tracking Policy

Follow-up issues are expensive. Default to no new issue.

Create follow-up tracking only when all of these are true:

- The work is actionable without rereading the full PR.
- The work is valuable outside the immediate review thread.
- The work is not a duplicate of an existing issue or accepted roadmap item.
- The work is not a blocker for the current PR.
- The user explicitly chooses issue tracking after seeing the deferred bundle.

When tracking is warranted:

- Prefer linking an existing issue.
- Otherwise create at most one bundled follow-up issue per PR by default.
- More than one follow-up issue requires explicit user approval.
- Title new follow-up issues with `Follow-up:`.
- Build issue bodies with `--body-file` and reject literal `\n` escapes before posting.

## Merge Readiness Gate

Before saying a PR is ready to merge:

```bash
gh pr view <PR> --json mergeStateStatus,reviewDecision,statusCheckRollup,isDraft,labels
gh pr checks <PR>
```

Also verify:

- PR is not draft unless the user is only asking for readiness work.
- `mergeStateStatus` is clean or the remaining instability is understood and non-required.
- No current `CHANGES_REQUESTED`.
- No unresolved current review thread changes correctness, tests, security, or required scope.
- Required checks are green, or the user has explicitly accepted an auditable waiver for full CI.
- The PR body or latest agent comment includes exact local validation commands and results.

If approved and green but not merging immediately, use the repository's standard `ready-to-merge` label when available.

## Multi-PR Landing Plan

For a manual multi-PR landing plan:

1. Exclude WIP/draft PRs unless the user opts them in.
2. Build a dependency order from PR bodies, stacked branches, changed files, and review comments.
3. Split work into independent lanes only when each lane has a separate worktree.
4. For each candidate PR, verify it is the right thing to work on now: approved or worth fixing, non-duplicative, scoped, and clear enough to complete.
5. For blocked PRs, fix only the blocking cause, rerun targeted local checks, and batch one push.
6. Do not create follow-up issues for ordinary review nits. Use one deferred bundle per PR only after explicit user approval.
7. Use full CI sparingly: final readiness gate, high-risk changes, or maintainer request.
