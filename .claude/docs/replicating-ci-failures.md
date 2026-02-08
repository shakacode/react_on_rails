# Replicating CI Failures Locally

**CRITICAL: NEVER wait for CI to verify fixes. Always replicate failures locally first.**

## When Analyzing CI Failures

1. **First, reproduce the failure locally** using the tools below
2. **If you cannot reproduce locally**, clearly state why:
   - "Working in Conductor isolated workspace - cannot run full Rails app"
   - "Requires Docker/Redis/PostgreSQL not available in current environment"
   - "Integration tests need full webpack build pipeline not set up locally"
3. **Mark all proposed fixes as UNTESTED** until they can be verified:
   - DON'T: "This fixes the integration test failures"
   - DO: "This SHOULD fix the integration test failures (UNTESTED - requires local Rails app with webpack)"
4. **Provide reproduction steps** even if you can't execute them:
   - Include exact commands to run
   - Document environment requirements
   - Explain what success looks like

## Switch Between CI Configurations

The project tests against two configurations:

- **Latest**: Ruby 3.4, Node 22, Shakapacker 9.5.0, React 19 (runs on all PRs)
- **Minimum**: Ruby 3.2, Node 20, Shakapacker 8.2.0, React 18 (runs only on master)

```bash
# Check your current configuration
bin/ci-switch-config status

# Switch to minimum dependencies (for debugging minimum CI failures)
bin/ci-switch-config minimum

# Switch back to latest dependencies
bin/ci-switch-config latest
```

**See `SWITCHING_CI_CONFIGS.md` for detailed usage and troubleshooting.**

**See `react_on_rails/spec/dummy/TESTING_LOCALLY.md` for local testing tips and known issues.**

## Re-run Failed CI Jobs

```bash
# Automatically detects and re-runs only the failed CI jobs
bin/ci-rerun-failures

# Search recent commits for failures (when current commit is clean/in-progress)
bin/ci-rerun-failures --previous

# Or for a specific PR number
bin/ci-rerun-failures 1964
```

This script:

- Fetches actual CI failures from GitHub using `gh` CLI
- Runs only what failed - no wasted time on passing tests
- Waits for in-progress CI - offers to poll until completion
- Searches previous commits - finds failures before your latest push
- Shows you exactly what will run before executing
- Maps CI jobs to local commands automatically

## Run Only Failed Examples

When RSpec tests fail, run just those specific examples:

```bash
# Copy failure output from GitHub Actions, then:
pbpaste | bin/ci-run-failed-specs        # macOS
# xclip -o | bin/ci-run-failed-specs     # Linux (requires: apt install xclip)
# wl-paste | bin/ci-run-failed-specs     # Wayland (requires: apt install wl-clipboard)

# Or pass spec paths directly:
bin/ci-run-failed-specs './spec/system/integration_spec.rb[1:1:1:1]'

# Or from a file:
bin/ci-run-failed-specs < failures.txt
```

This script:

- Runs only failing examples - not the entire test suite
- Parses RSpec output - extracts spec paths automatically
- Deduplicates - removes duplicate specs
- Auto-detects directory - runs from react_on_rails/spec/dummy when needed
