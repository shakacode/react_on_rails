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
- Claude expects a single-line Anthropic API key without control bytes. The
  broker removes one optional trailing newline before Claude `--bare` reads the
  effective bytes through the private `apiKeyHelper` script. The private tmpfs
  remains `noexec`; the reviewed setting invokes that script through `/bin/sh`.

Codex cannot create the namespaces required by its inner bubblewrap
`workspace-write` sandbox under the container's deliberately restricted flags.
For attested Codex only, the runner therefore uses
`--dangerously-bypass-approvals-and-sandbox` and records
`isolated-host-attested`. The outer container remains read-only except for its
UID-owned tmpfs workspace/private areas and evidence staging bind, drops every
capability, limits the container to 4096 processes, and enables
`no-new-privileges`. No extra privilege, capability, or
environment inheritance is added. Non-attested Codex diagnostics retain the
inner `workspace-write` sandbox; never use the attested bypass outside this
reviewed disposable-host boundary.

The wrapper forces agent-containment test mode off. A custom image therefore
cannot enable fake process-root or runner-PID overrides for a production run;
any such image-provided override fails closed.

Each agent call receives `TERM` at its configured timeout and `KILL` after a
fixed 10-second grace. Both possible grace periods are included in the recorded
maximum agent-call wall-clock budget. GNU `timeout` reports a cooperative
timeout as exit 124 and a forced `KILL` as exit 137; the harness maps both to
timeout status 124 before normalization and evidence generation only when
GNU `timeout`'s isolated diagnostic stream proves that `--kill-after` sent the
signal. An agent that independently exits 137 remains a non-timeout failure.

The agent CLI and its tools run under the same container UID. File-backed
authentication therefore cannot be hidden from a malicious agent or tool while
remaining readable by the CLI. Mode `0700` prevents access by other Unix users;
it does not create a privilege boundary within that shared UID. This harness
accepts that limitation only for the repository-owned eval prompt on a
disposable, otherwise secret-free host. It must not be used to run untrusted
prompts or to claim model-credential non-disclosure against a hostile agent.
Network egress is intentionally available for the model API and package
registries; the preflight checks reachability but is not an egress allowlist.
The disposable host must therefore have no ambient network credentials, cloud
instance role, or reachable metadata service (including `169.254.169.254`).

The private directory is removed by the harness traps. Exact credential bytes
are snapshotted in runner memory before the agent starts, then searched as a
binary stream in the workspace after each agent call and in the completed
output after checksums are written. The evidence output path remains absent
while either agent call runs. After each call, the PID-1 runner rejects any
agent-created output path or process left in the container PID namespace; only
then does it construct evidence in runner-private storage, validate the exact
top-level regular-file manifest, and publish it. The unchanged original snapshot remains
authoritative even if the CLI rotates or replaces its writable credential
store; when Codex's current store still exists, its final bytes are scanned as
a second independent needle. For Codex JSON credentials, sensitive
token/key/secret leaf values from both generations are searched independently
as well. A match, nonregular current store, unreadable artifact, or output
symlink fails closed. Workspace scans skip dependency symlinks without following
them, while continuing to inspect every regular file; completed-output scans
reject all symlinks. The committed output continues to record
`auth_material_persisted: false`; it records availability and the attested file
broker, never credential values or paths.

These leak checks detect the exact credential bytes and, for Codex JSON,
selected decoded token/key/secret leaf values. They do not prove that a
transformed, re-encoded, encrypted, hashed, or split representation is absent.
Accordingly, `auth_material_persisted: false` means that the defined checks
found no raw credential or selected sensitive leaf value in the workspace or
published evidence; it is not a cryptographic noninterference claim against a
hostile same-UID agent. The repository-owned prompt and disposable,
otherwise-secret-free host remain mandatory parts of this boundary.

The wrapper holds an atomic destination lock from before container launch
through the final rename. Concurrent wrapper invocations for the same output
therefore fail rather than nesting or overwriting evidence. Unrelated writers
must not mutate the selected output parent while an eval is running.

Process containment is deliberately conservative: any residual process-table
entry other than the PID-1 runner and the active inspector, including a zombie,
rejects the run. Discard the contaminated container rather than publishing
evidence from it.

No React on Rails Pro license token is required for evaluation, development, or CI.
The real eval requires only the operator model credential. Do not provision a Pro license token in this harness.
Never add one to the environment, image, repository, prompt, or command line.

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
uses UID/GID-owned tmpfs filesystems for the workspace, runner-private data, and
temporary files. The runner-private tmpfs stays `noexec`. Private-home Bundler,
RubyGems, and npm configuration directs executable caches and installed bundle
state into `.ror-eval-state` inside the writable workspace tmpfs. The runner
scans that state for credential bytes, removes it before evidence derivation,
and also removes it on every exit without widening the agent environment
allowlist.

The credential source must be outside both the repository and any external Git
metadata bind. Evidence is staged in a mode-`0700` directory inside the requested
destination parent, so publication is a same-filesystem directory rename rather
than a cross-filesystem copy. Failed/rejected runs, interrupted publication, and
any staging directory with unexpected siblings or nested entries are deleted
fail closed. The requested output basename is carried separately into the run
metadata; only one completed `run` staging directory is published under that
requested name after Docker exits successfully.

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
