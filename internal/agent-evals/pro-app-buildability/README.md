# Pro app buildability agent eval

This eval asks one coding agent to create and verify a small React on Rails Pro
application without human intervention. It is an evidence surface, not a
product claim. A run only supports a claim when its independently captured
artifacts satisfy the rubric.

## Clean-start prerequisites

- macOS or Linux with `git`, `ruby`, `node`, `npm`, `jq`, and the selected agent
  CLI on `PATH`
- network access to RubyGems, npm, and GitHub
- enough disk space for a new Rails application and its dependencies
- an empty, disposable workspace outside this repository
- a local Codex login in `~/.codex/auth.json` or a path supplied through
  `CODEX_AUTH_FILE`; the runner copies it into a mode-`0600` private temporary
  home and removes that home unconditionally

Install the pinned Draft 2020-12 validator and evidence formatter without
joining the root workspace:

```bash
pnpm --dir internal/agent-evals/pro-app-buildability install \
  --frozen-lockfile --ignore-workspace
```

## Run

From the repository root:

```bash
internal/agent-evals/pro-app-buildability/bin/run-eval \
  --agent codex \
  --model gpt-5.4 \
  --timeout 2700 \
  --workspace /tmp/ror-pro-agent-eval \
  --output internal/agent-evals/pro-app-buildability/runs/local-codex
```

The workspace must not exist or must be empty. The runner initializes a Git
repository, copies the immutable scenario prompt, invokes the agent once, and
captures:

- environment and version metadata;
- the agent's schema-constrained final report;
- independently captured, sanitized command output;
- selected generated manifests/source excerpts with hashes;
- a conservative machine-derived rubric whose citations point to those two
  evidence files; and
- hashes covering every run artifact and every executable, schema, prompt,
  dependency manifest, and lockfile input.

The repository and workspace must be clean, and workspace/output real paths
must be disjoint. Before invoking Codex, the runner requires GNU `timeout` and
checks npm and RubyGems from the same minimal environment used for the run.
Codex is ephemeral, ignores user configuration/rules, disables multi-agent
work, uses the workspace-write sandbox, and receives an explicit model and
timeout. Both the Codex process and its shell tools start from `env -i`; tool
environment inheritance is `none` with only `PATH`, a private empty `HOME`, a
private `TMPDIR`, locale, shell, and `CODEX_EVAL` added back.

Workspace-write network access is enabled explicitly with the supported
`sandbox_workspace_write.network_access=true` Codex configuration. Before any
scaffold work, a capability-only Codex turn must run the exact npm and RubyGems
commands in `network-probe-prompt.md`. The runner derives
`sandbox-network-probe.json` from command events. Missing commands or either
nonzero exit fail closed: the run is recorded as `incomplete` and scaffold work
does not start.

Raw events, stderr, and the copied authentication file live only under a
mode-`0700` temporary directory. `umask 077` applies throughout, and
`EXIT`/`INT`/`TERM` traps delete the directory. Sensitive parent environment
variable names are recorded as stripped; their values are neither read nor
passed to the agent.

## Replay and validate

To replay an existing run, inspect its `invocation.json`, create a fresh empty
workspace, and repeat the command with a new output directory. Runs are
point-in-time observations; package `latest` resolution and network availability
are deliberately captured because they are part of the onboarding experience.

Validate artifact structure and recorded hashes:

```bash
internal/agent-evals/pro-app-buildability/bin/validate-run \
  internal/agent-evals/pro-app-buildability/runs/local-codex
```

Validation uses pinned Ajv 8 in Draft 2020-12 mode for `run.json`,
`agent-report.json`, both independent evidence documents, and the derived
rubric and sandbox-network probe. It also verifies input/output hashes, rejects raw capture files, and
scans for local paths and credential-shaped content. Self-reported success is
never sufficient.

## Interpretation

- **Pass:** every required rubric item has independent evidence, the application
  tests and production build pass, and no human rescue occurred.
- **Fail:** the agent completed its attempt, but one or more required rubric
  items failed.
- **Incomplete:** infrastructure, credentials, network, time, or runner failure
  prevented a meaningful end-to-end attempt.

One passing run supports only the exact agent, versions, platform, and scenario
recorded. Claims about Claude and Codex require separate passing runs. Tutorial
or marketing wording must link to the supporting run artifacts and preserve
environment caveats and observed friction.

## Redaction

Never commit raw secrets or an unreviewed raw transcript. The runner stores only
bounded structured evidence. Its sanitizer removes common token, authorization,
cookie, password, private-key, and local-path values before evidence derivation.
Before committing a run, manually inspect every artifact and search for likely secrets.
If a secret appears, delete the run artifacts, rotate the secret, improve the
sanitizer, and rerun; do not edit evidence into a more favorable result.

The subtree `pnpm-lock.yaml` requires npm Dependabot directory coverage for
`/internal/agent-evals/pro-app-buildability`. Do not treat the harness as
merge-ready until that repository-level coverage is present in the same PR or a
coordinated dependent change.
