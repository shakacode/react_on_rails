# Master Branch Health Monitoring

**CRITICAL: Master staying broken affects the entire team. Don't let it persist.**

## Immediate Actions After Your PR Merges

Within 30 minutes of your PR merging to master:

1. **Check CI status:**

   ```bash
   # View the merged PR's CI status
   gh pr view <your-pr-number> --json statusCheckRollup

   # Or check recent master runs
   gh run list --branch master --limit 5
   ```

2. **If you see failures:**
   - Investigate IMMEDIATELY
   - Don't assume "someone else will fix it"
   - You are responsible for ensuring your PR doesn't break master

## Polling CI Status While Waiting

**When actively monitoring CI, poll every 30 seconds (not 180 seconds):**

```bash
# Poll every 30 seconds while CI is running
while true; do
  gh pr view --json statusCheckRollup --jq '.statusCheckRollup | group_by(.conclusion) | map({conclusion: .[0].conclusion, count: length})'
  sleep 30
done
```

Or use the automated tool which polls at 30-second intervals:

```bash
bin/ci-rerun-failures  # Automatically waits for in-progress CI, polling every 30s
```

**Why 30 seconds?**

- CI jobs typically complete in 3-15 minutes
- 30-second polling gives responsive feedback without excessive API calls
- 180 seconds (3 minutes) is too slow—you waste time waiting unnecessarily
- GitHub API rate limits are 5000 requests/hour, so 30-second polls are fine

## When You Discover Master is Broken

1. **Determine if it's from your PR:**

   ```bash
   gh run list --branch master --limit 10
   ```

2. **Take immediate action:**
   - If your PR broke it: Submit a fix PR within the hour, OR revert and resubmit
   - If unsure: Investigate and communicate with team
   - Never leave master broken overnight

## Silent Failures are Most Dangerous

Some failures don't show up in standard CI:

- yalc publish failures
- Build artifact path issues
- Package installation problems

**Always manually test critical workflows:**

- If you changed package structure → test `yarn run yalc.publish`
- If you changed build configs → test `yarn build && ls -la lib/`
- If you changed generators → test `rake run_rspec:example_basic`

## Understanding Workflow Reruns

**Important limitation:**

- Re-running a workflow does NOT change its `conclusion` in the GitHub API
- GitHub marks a run as "failed" even if a manual rerun succeeds
- Our CI safety checks (as of [PR #2062](https://github.com/shakacode/react_on_rails/pull/2062)) now handle this correctly
- But be aware: old commits with failed reruns may still block docs-only commits

**What this means:**

- If master workflows fail, reruns alone won't fix the circular dependency
- You need a new commit that passes to establish a clean baseline
- See [PR #2065](https://github.com/shakacode/react_on_rails/pull/2065) for an example of breaking the cycle
