# Installation And Upgrades

Use this guide to install `shakacode/agent-workflows` once per agent host and
keep that installed pack current without copying shared workflow files into
every repository.

## Installation Model

The shared pack belongs in the user or agent home. Each consumer repository
keeps its own policy in `AGENTS.md` under `## Agent Workflow Configuration`.
The shared skills read that seam at runtime, so the same installed pack can work
across repositories with different branches, CI commands, labels, changelog
rules, and review gates.

Repository-pinned copies are still allowed when a platform cannot load installed
skills, but they are the exception. The default path is:

1. Clone this repository.
2. Install it into the host that will run the skills.
3. Validate each consumer repo seam.
4. Dry-run one workflow before launching a real batch.

## Host Targets

`bin/install-agent-workflows` supports the same installed layout for Codex and
Claude:

| Host     | Default target                                                        |
| -------- | --------------------------------------------------------------------- |
| `codex`  | `${CODEX_HOME:-$HOME/.codex}`                                         |
| `claude` | `${CLAUDE_HOME:-$HOME/.claude}`                                       |
| `auto`   | An existing Codex or Claude home, only when exactly one is detectable |

Use `--target DIR` for custom homes such as `~/.agents`. The host name controls
the default target and metadata; it does not change the shared workflow text.

## Install

Clone the source pack:

```bash
git clone https://github.com/shakacode/agent-workflows "$HOME/src/agent-workflows"
cd "$HOME/src/agent-workflows"
```

Install for Codex:

```bash
bin/install-agent-workflows --host codex
```

Install for Claude Code:

```bash
bin/install-agent-workflows --host claude
```

Install into an explicit shared agent home:

```bash
bin/install-agent-workflows --host codex --target "$HOME/.agents"
```

For local development on this pack, symlink mode keeps the installed skills
pointing at the clone:

```bash
bin/install-agent-workflows --host codex --mode symlink
```

The installer writes:

- `<target>/skills/*`
- `<target>/workflows/*`
- `<target>/bin/agent-workflow-seam-doctor`
- `<target>/bin/agent-workflows-status`
- `<target>/bin/install-agent-workflows`
- `<target>/bin/upgrade-agent-workflows`
- `<target>/.agent-workflows-install.json`

Copy mode replaces only this pack's skill and workflow names; it preserves
unrelated files already present in the target agent home.

The metadata file records host, mode, source clone, pack version, source
revision, branch, remote, and install time. The status and upgrade helpers use
that metadata so they can run from either the source clone or the installed
host.

## Status Checks

Check the installed pack against the source clone recorded at install time:

```bash
agent-workflows-status --host codex
```

Check a specific install and source:

```bash
agent-workflows-status \
  --target "$HOME/.codex" \
  --source "$HOME/src/agent-workflows"
```

Stable status tokens:

| Token               | Exit | Meaning                                                      |
| ------------------- | ---: | ------------------------------------------------------------ |
| `UP_TO_DATE`        |    0 | Installed revision matches the available source revision.    |
| `UPGRADE_AVAILABLE` |    1 | Source has a different revision than the installed metadata. |
| `NOT_INSTALLED`     |    2 | Target has no `.agent-workflows-install.json`.               |
| `CHECK_FAILED`      |    3 | The check could not safely determine status.                 |

Use `--json` for machine-readable output. Use `--fetch` only when you want a
network check against `origin`; without `--fetch`, status compares against the
current local source clone.

## Upgrade

Upgrade the source clone, reinstall the pack, and validate a consumer repo seam:

```bash
upgrade-agent-workflows \
  --host codex \
  --consumer-root /path/to/consumer/repo
```

For an already-updated local source clone, skip the network step:

```bash
upgrade-agent-workflows \
  --host codex \
  --source "$HOME/src/agent-workflows" \
  --consumer-root /path/to/consumer/repo \
  --no-fetch
```

Preview without mutating the install:

```bash
upgrade-agent-workflows --host codex --dry-run
```

Upgrade behavior:

1. Resolve target and source from arguments or install metadata.
2. Fetch and fast-forward the source clone unless `--no-fetch` is set.
3. Back up the target install.
4. Reinstall with the recorded or requested mode.
5. Run `agent-workflow-seam-doctor --root <consumer> --shared <source>` for
   every `--consumer-root`.
6. Restore the previous install if reinstall or seam validation fails.

The command prints `UPGRADE_COMPLETE` on success and `ROLLBACK_COMPLETE` when it
restores the prior install after a failed upgrade.

## Verification After Upgrade

For the shared pack itself:

```bash
cd "$HOME/src/agent-workflows"
bin/validate
```

For each active consumer repo:

```bash
cd /path/to/consumer/repo
agent-workflow-seam-doctor --shared "$HOME/src/agent-workflows"
```

Then dry-run one installed workflow, such as `$plan-pr-batch` or
`$address-review`, until it resolves base branch, validation, hosted CI,
review-gate, changelog, and follow-up values from the repo seam without making
code changes.

## Codex And Claude

The skill Markdown is host-neutral. Codex and Claude both use the same
`skills/`, `workflows/`, and `bin/` layout after installation. Files under
`skills/*/agents/openai.yaml` are optional Codex UI metadata and are ignored by
Claude.

Some workflow steps name host-specific tools, such as `codex review`, Claude
Code slash commands, or `/simplify`. Treat those as available-tool branches:
use them only when the current host actually provides them, and record the
fallback when it does not. The repo seam still controls repository policy.

## Active Batches

Do not stop healthy in-flight batches just because the shared pack changed.
Long-running agents usually keep the skill text they already loaded. Use the new
pack for new batches and canary runs. Restart only lanes that are blocked by
stale workflow instructions or that explicitly need the new process.

## Network And Privacy

`agent-workflows-status` does not contact the network unless `--fetch` is
provided. `upgrade-agent-workflows` fetches and fast-forwards the source clone by
default. Use `--no-fetch` when the source clone has already been updated or when
the session must avoid network access.

## Troubleshooting

- `NOT_INSTALLED`: run `bin/install-agent-workflows --host <host>` or pass the
  correct `--target`.
- `CHECK_FAILED missing source root`: reinstall from a valid clone, or pass
  `--source /path/to/agent-workflows`.
- `UPGRADE_AVAILABLE`: run `upgrade-agent-workflows` or manually update the
  source clone and reinstall.
- `Auto host detection found both Codex and Claude homes`: rerun with
  `--host codex` or `--host claude`.
- `Refusing to replace non-symlink path`: symlink mode will not overwrite a real
  file or directory. Use copy mode or remove the conflicting path deliberately.
- `invalid byte sequence in US-ASCII` or other `Encoding::` errors from a Ruby
  helper: an older install is running under a non-UTF-8 locale (`LANG=C` /
  `LC_ALL=C`, common in CI and headless agents). The pack Ruby tools now read
  text as UTF-8 regardless of locale; run `upgrade-agent-workflows --host <host>`
  to pick up the fix.
