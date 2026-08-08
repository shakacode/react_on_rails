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
must be disjoint. Before invoking the selected agent, the runner requires GNU `timeout` and
checks npm and RubyGems from the same minimal environment used for the run.
Codex runs ephemeral with strict ignored user configuration and rules. Claude
runs `--bare` without session persistence, slash commands, plugins, Chrome,
MCP servers, or the Agent tool. Both receive an explicit model and timeout and
start from `env -i` with private homes inside the temporary run directory. Tool
environment inheritance is `none`, with only `PATH`, private `HOME` and
`TMPDIR`, locale, shell, and `CODEX_EVAL` added back.

`--timeout` is the scaffold-agent call budget. The capability probe has its own
`min(--timeout, 120)` budget. `invocation.json` and `run.json` record both plus
`maximum_agent_call_wall_clock_seconds`, their sum when both agent calls consume
their full budgets. That maximum covers agent call time only; small runner
preflight, sanitization, evidence derivation, and validation overhead is outside
it.

The configured file credential store and private agent homes are inside the
mode-`0700` disposable directory. Without `--model-credential-file`, no
credential is copied or inherited into the process. Home-discovered Bundler,
RubyGems, and npm configuration sends writable package state to the removable
`.ror-eval-state` directory inside the workspace; that state is scanned and
deleted before evidence derivation and on every exit. The seven-variable agent
environment allowlist remains unchanged.

Non-attested Codex diagnostics retain the inner `workspace-write` sandbox and
record `workspace-write`. Docker prevents that inner bubblewrap sandbox from
creating its namespaces under the isolated-host flags, so an attested Codex run
uses `--dangerously-bypass-approvals-and-sandbox` and records
`isolated-host-attested`. That bypass is allowed only behind
`--ack-disposable-secret-free-host`, where the reviewed outer container supplies
the read-only repository, writable workspace tmpfs, dropped capabilities, and
`no-new-privileges` boundary. Attested Claude records the same outer boundary;
unattested Claude diagnostics record `claude-permission-gated`. Never use the
attested Codex bypass directly on a developer workstation.

A network-enabled capability/scaffold run is allowed only through the reviewed
isolated-host wrapper on a disposable host that contains no unrelated secrets.
The wrapper supplies `--ack-disposable-secret-free-host`; that flag records
`isolated_host_attestation: true` and permits model-shell network access within
the outer container boundary. It is an operator attestation, not technical
confinement by the agent CLI. Before scaffold work, the capability turn must run
the exact commands in `network-probe-prompt.md`; a missing command, nonzero exit,
disabled network, missing attestation, or evidence-limit overflow fails closed
and prevents scaffolding.

Credentialed runs additionally require `--model-credential-file` and refuse
that option without the isolated-host attestation. Codex accepts a complete
`auth.json` object; Claude accepts one nonempty API-key line without control
bytes. The operator input must be a non-symlink file with no group/world access.
The broker copies it only into the disposable private directory, never widens
environment inheritance, and records `auth_material_available: true` with
`auth_source: operator-attested-file-broker`. Use the reviewed container wrapper
instead of running this directly on a workstation:

The selected CLI and its tools share one container UID, so a file credential
readable by the CLI is not hidden from a malicious agent running as that UID.
This is an accepted limitation only for the repository-owned prompt on a
disposable host with no unrelated secrets. The broker reduces persistence risk;
it is not a credential-isolation boundary against a hostile model.

```bash
docker build --tag react-on-rails-pro-app-eval:local \
  --file internal/agent-evals/pro-app-buildability/isolated-host/Dockerfile \
  internal/agent-evals/pro-app-buildability

internal/agent-evals/pro-app-buildability/isolated-host/run-in-container \
  --agent claude --model sonnet --timeout 2700 \
  --model-credential-file /secure/operator/claude-api-key \
  --output /absolute/path/to/eval-output/local-claude
```

See [`isolated-host/README.md`](isolated-host/README.md) for the threat model,
mounts, credential formats, and license boundary. Image build and harness tests
never run an eval and require no model credential or Pro license.

Raw events and stderr live only under a mode-`0700` temporary directory. When
the broker is enabled, authentication is available only through the selected
agent's private file-backed mechanism; otherwise it is unavailable. `umask 077`
applies throughout, and `EXIT`/`INT`/`TERM` traps delete the directory. Generic
categories of stripped sensitive parent variables are recorded without
exposing the operator's exact variable names; their values are neither read nor
passed to the agent. Exact credential bytes are rejected if they appear in the
workspace or completed output, including when embedded inside a larger file.
Claude's optional trailing newline is removed before scanning so the effective
key is checked. Sensitive string leaves from Codex JSON authentication are
checked separately from the complete JSON document. If Codex rotates its
private credential store, both the immutable original snapshot and the final
current store are scanned so neither generation can reach workspace or output
artifacts.

If timeout terminates Claude with a Bash call still pending, normalization
records that call as failed with exit `124` and continues to the incomplete,
checksummed run evidence. The same unmatched call remains fatal for every
non-timeout exit. Only an unterminated final JSON fragment may be discarded on
timeout; malformed complete events remain fatal even when the exit is `124`.

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
