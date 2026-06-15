# Local CI Contract

Before pushing review-comment fixes or CI-sensitive changes, run local checks on the same branch you plan to push:

```bash
bin/ci-local
```

For narrow changes, this alias keeps the intent explicit while using the same changed-files detector:

```bash
bin/ci-local --changed
```

Use the detector directly when you need to inspect the routing decision:

```bash
script/ci-changes-detector origin/main
```

GitHub PR CI is intentionally split into a small required gate and label-driven full CI. Routine failures should be caught locally before pushing; GitHub Actions should confirm the branch, not be the first feedback loop.

When a PR is ready for final validation, request full CI:

```bash
bin/request-full-ci
```

That adds `ready-for-full-ci`. When added with your GitHub token, the label event starts the heavyweight workflows; the label also keeps future commits on that PR in full-CI mode until it is removed.
