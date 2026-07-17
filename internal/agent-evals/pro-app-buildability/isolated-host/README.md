# Isolated host for credentialed evals

This image is the reviewed boundary for a credentialed Pro app buildability
eval. Do not run a credentialed eval directly on a developer workstation. The
container must be disposable and the host must contain no unrelated secrets.
The explicit `--ack-disposable-secret-free-host` passed by the wrapper is an
operator attestation; it is not a claim that the agent CLI provides a complete
host filesystem sandbox.

The wrapper passes the selected agent an `env -i` environment. Agent shell
inheritance stays `none`, and the allowlist remains exactly `PATH`, private
`HOME` and `TMPDIR`, locale, `SHELL`, and `CODEX_EVAL`. The model credential is
never placed in an environment variable or command-line argument. The wrapper
streams the operator file on standard input directly into the
harness's mode-`0700` private directory before the agent starts. No credential
file is mounted into the container. The private copy is used as the agent's
native file-backed credential source:

- Codex expects a complete `auth.json` JSON object.
- Claude expects a single-line Anthropic API key. The broker removes one
  optional trailing newline before Claude `--bare` reads the effective bytes
  through the private `apiKeyHelper` script. The private tmpfs remains
  `noexec`; the reviewed setting invokes that script through `/bin/sh`.

The agent CLI and its tools run under the same container UID. File-backed
authentication therefore cannot be hidden from a malicious agent or tool while
remaining readable by the CLI. Mode `0700` prevents access by other Unix users;
it does not create a privilege boundary within that shared UID. This harness
accepts that limitation only for the repository-owned eval prompt on a
disposable, otherwise secret-free host. It must not be used to run untrusted
prompts or to claim model-credential non-disclosure against a hostile agent.

The private directory is removed by the harness traps. Exact credential bytes
are snapshotted in runner memory before the agent starts, then searched as a
binary stream in the workspace after each agent call and in the completed
output after checksums are written. The unchanged snapshot remains authoritative
even if the CLI rotates or replaces its writable credential store. For Codex
JSON credentials, sensitive token/key/secret leaf values are searched
independently as well. A match, unreadable artifact, or output symlink fails
closed. The committed output continues to record
`auth_material_persisted: false`; it records availability and the attested file
broker, never credential values or paths.

The React on Rails Pro license is not handled by this broker. Provision it only
through the product's supported licensing flow on the disposable isolated host;
never add it to the environment, image, repository, prompt, or command line.
Do not run the real eval until both the operator model credential and required
Pro license are available on that host.

## Build

From the repository root:

```bash
docker build \
  --tag react-on-rails-pro-app-eval:local \
  --file internal/agent-evals/pro-app-buildability/isolated-host/Dockerfile \
  internal/agent-evals/pro-app-buildability
```

The build takes no credentials. Agent CLI and pnpm versions are pinned as
Docker build arguments so a version update remains reviewable.

## Run

Create a new output path whose parent already exists. The wrapper refuses a
dirty repository, an existing output, symlink inputs, permissive credential
files, and missing credential files. It mounts the repository and linked
worktree Git metadata read-only, streams the credential on standard input, and
uses UID/GID-owned tmpfs filesystems for the workspace, runner-private data,
temporary files, and installed gems. The runner-private tmpfs stays `noexec`;
an automatically removed npm cache lives beside the workspace on its executable
tmpfs so `npx` can run downloaded package shims without widening the agent
environment allowlist.

The credential source must be outside both the repository and any external Git
metadata bind. Evidence is first written to a private host staging directory.
Failed/rejected runs and any staging directory with unexpected siblings are
deleted; only one completed `run` directory is published to the requested
output path after Docker exits successfully.

```bash
internal/agent-evals/pro-app-buildability/isolated-host/run-in-container \
  --agent codex \
  --model gpt-5.4 \
  --timeout 2700 \
  --model-credential-file /secure/operator/codex-auth.json \
  --output /absolute/path/to/eval-output/local-codex
```

For Claude, use `--agent claude`, a Claude model name, and a mode-`0600`
single-line API key file. Never paste either credential into the terminal. The
wrapper reads the file directly and does not run a real eval during image
build or harness tests.
