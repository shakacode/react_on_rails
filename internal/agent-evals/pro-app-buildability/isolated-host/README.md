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
- Claude expects a single-line Anthropic API key. Claude `--bare` reads it only
  through the private `apiKeyHelper` script.

The private directory is removed by the harness traps. Exact credential bytes
are searched as a binary stream in the workspace after each agent call and in
the completed output after checksums are written. A match, unreadable artifact,
or output symlink fails closed. The committed output continues to record
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
temporary files, and installed gems.

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
