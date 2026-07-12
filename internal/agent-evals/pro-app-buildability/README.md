# Pro app buildability agent eval

This eval asks one coding agent to create and verify a small React on Rails Pro
application without human intervention. It is an evidence surface, not a
product claim. A run only supports a claim when its independently captured
artifacts satisfy the rubric.

## Clean-start prerequisites

- macOS or Linux with `curl`, `git`, `jq`, `node`, `npm`, `perl`, `pnpm`,
  `realpath`, `rg`, `ruby`, `shasum`, GNU `timeout`, and the selected agent CLI
  on `PATH`
- network access to RubyGems, npm, and GitHub
- enough disk space for a new Rails application and its dependencies
- an empty, disposable workspace outside this repository

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
timeout. Both the Codex process and its shell tools start from `env -i` with
private empty `HOME` and `CODEX_HOME` directories inside the temporary run
directory. Tool environment inheritance is `none`, with only `PATH`, private
`HOME` and `TMPDIR`, locale, shell, and `CODEX_EVAL` added back.

`--timeout` is the scaffold-agent call budget. The capability probe has its own
`min(--timeout, 120)` budget. `invocation.json` and `run.json` record both plus
`maximum_agent_call_wall_clock_seconds`, their sum when both agent calls consume
their full budgets. That maximum covers Codex call time only; small runner
preflight, sanitization, evidence derivation, and validation overhead is outside
it.

The configured file credential store is inside that empty disposable
`CODEX_HOME`; no credential is copied, inherited, or mounted into the process.
Private homes prevent default discovery and inheritance, but the workspace-write
sandbox does **not** confine absolute-path reads from the host. The default local
eval therefore keeps model-shell network access off and cannot proceed to
scaffolding. Until a separately reviewed credential broker or stronger
execution boundary exists, the default run records an authentication-blocked
`incomplete` result. This is known evidence, not a supported onboarding claim.

A network-enabled capability/scaffold run is allowed only on a disposable VM or
container that contains no host secrets. The operator must acknowledge that
boundary explicitly:

```bash
internal/agent-evals/pro-app-buildability/bin/run-eval \
  --agent codex --model gpt-5.4 --timeout 2700 \
  --workspace /tmp/ror-pro-agent-eval \
  --output internal/agent-evals/pro-app-buildability/runs/isolated-codex \
  --ack-disposable-secret-free-host
```

That flag records `isolated_host_attestation: true` and enables the supported
`sandbox_workspace_write.network_access=true` setting. It is an operator
attestation, not technical confinement. Before scaffold work, the capability
turn must run the exact commands in `network-probe-prompt.md`; a missing command,
nonzero exit, disabled sandbox network, missing attestation, or evidence-limit
overflow fails closed and prevents scaffolding.

Raw events and stderr live only under a mode-`0700` temporary directory. No
authentication material is made available to the process. `umask 077` applies throughout, and
`EXIT`/`INT`/`TERM` traps delete the directory. Generic categories of stripped
sensitive parent variables are recorded without exposing the operator's exact
variable names; their values are neither read nor passed to the agent.

Evidence parsing is bounded before JSON parsing or file reads. Event bytes and
event count, visited/selected artifact counts, recursion depth, per-file bytes,
and aggregate artifact bytes are recorded in evidence metadata. Any exceeded
budget omits the affected evidence and forces an `incomplete` rubric result.

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
