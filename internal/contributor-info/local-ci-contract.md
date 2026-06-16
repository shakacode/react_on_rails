# Local CI Contract

Before pushing review-comment fixes or CI-sensitive changes, run local checks on
the same branch you plan to push:

```bash
bin/ci-local
```

`bin/ci-local` defaults to optimized local CI. It auto-detects the current PR's
base branch via `gh pr view` when available, then falls back to `origin/main` or
`main`. Agents and contributors should not pass a normal `<base-ref>` argument;
the script owns base discovery so local and hosted routing stay aligned.

For narrow changes, this accepted alias makes the default intent explicit:

```bash
bin/ci-local --changed
```

For broad local coverage where practical:

```bash
bin/ci-local --all
```

Use the detector directly only when you need to inspect routing:

```bash
script/ci-changes-detector origin/main
```

GitHub PR CI is intentionally split into a small required gate, optimized hosted
CI, and force-full hosted CI. Routine failures should be caught locally before
pushing; GitHub Actions should confirm the branch, not be the first feedback
loop.

When a PR is ready for hosted validation, request optimized hosted CI:

```bash
bin/request-hosted-ci
```

That adds `ready-for-hosted-ci`. When added with your GitHub token, the label
event can start hosted workflows; the label also keeps future commits on that PR
in optimized hosted-CI mode until it is removed.

For an auditable PR-visible request, comment `+ci-run-hosted` after the final
push for the current batch. The comment command dispatches hosted workflows for
the current head SHA before adding `ready-for-hosted-ci`, because a label added
by a workflow's `GITHUB_TOKEN` does not start new `pull_request` workflow runs by
itself.

Use `+ci-force-full` only when a maintainer intentionally wants to bypass
optimized hosted selection and run every hosted suite.
