# Local CI Contract for AI and Maintainers

Before pushing review-comment fixes, run:

```bash
bin/ci-local
```

For narrow changes, the changed-files path is explicit:

```bash
bin/ci-local --changed
```

For a faster smoke pass while iterating:

```bash
bin/ci-local --fast
```

For final local validation before requesting full GitHub CI:

```bash
bin/ci-local --all
```

The goal is to catch routine failures locally on fast hardware instead of using GitHub Actions as the first feedback loop. Request full GitHub CI with:

```bash
bin/request-full-ci
```
