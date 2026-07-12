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
- any React on Rails Pro credentials or license that the public install path
  actually requires; do not put credential values in the prompt or artifacts
- an empty, disposable workspace outside this repository

Record the exact repository revision and tool versions for every run. The
runner records the presence of known credential variables as booleans but never
their values.

## Run

From the repository root:

```bash
internal/agent-evals/pro-app-buildability/bin/run-eval \
  --agent codex \
  --workspace /tmp/ror-pro-agent-eval \
  --output internal/agent-evals/pro-app-buildability/runs/local-codex
```

The workspace must not exist or must be empty. The runner initializes a Git
repository, copies the immutable scenario prompt, invokes the agent once, and
captures:

- environment and version metadata;
- the agent's schema-constrained final report after deterministic redaction;
- a filesystem inventory and repository status after the attempt;
- independently executed verification command output; and
- hashes tying the artifacts together.

The default Codex invocation is ephemeral, ignores user configuration, uses the
workspace-write sandbox, and does not bypass approvals. Override the model with
`CODEX_EVAL_MODEL`; record that choice in the run metadata. The runner never
loads API tokens. It redacts credential-shaped text and local paths before
extracting the structured report, then deletes the broad event stream and
stderr rather than treating them as safe evidence.

## Replay and validate

To replay an existing run, inspect its `invocation.txt`, create a fresh empty
workspace, and repeat the command with a new output directory. Runs are
point-in-time observations; package `latest` resolution and network availability
are deliberately captured because they are part of the onboarding experience.

Validate artifact structure and recorded hashes:

```bash
internal/agent-evals/pro-app-buildability/bin/validate-run \
  internal/agent-evals/pro-app-buildability/runs/local-codex
```

Then grade each rubric item in `rubric.md` from the workspace and captured
verification evidence. Self-reported success is never sufficient.

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

Never commit raw secrets or an unreviewed raw transcript. `run-eval` stores only
the structured final report. Its sanitizer removes common token, authorization,
cookie, password, private-key, local-path, and credential-environment
assignments. Before committing a run, manually inspect every artifact and search
for likely secrets.
If a secret appears, delete the run artifacts, rotate the secret, improve the
sanitizer, and rerun; do not edit evidence into a more favorable result.
