# Agent Workflow Adoption Guide

Use this guide to make the shared agent workflows available in another
repository without copying another repo's policy into that repo.

The default model is:

- shared skills are installed in the user or agent environment
- each repo owns command wrappers in `.agents/bin/`
- each repo owns the Shaka typed contract in `.agents/agent-workflow.yml`
- each repo owns durable PR-batch actor trust in `.agents/trusted-github-actors.yml`
- `AGENTS.md` keeps human-only policy and the Shaka pointer section
- repo-pinned copies are optional and justified case by case

See [seam-design.md](seam-design.md) for the design rationale. See
[installation-and-upgrades.md](installation-and-upgrades.md) for host install
paths, upgrade commands, status states, rollback behavior, and Codex/Claude
notes.

## One-Time Adoption

1. **Inventory the target repo.** Identify base branch, package managers,
   setup/build/lint/format/test/type-check/docs commands, local CI routing,
   hosted-CI trigger, labels, changelog policy, release boundaries, generated
   files, protected-branch requirements, review bots, and which checks are cheap
   locally versus reserved for hosted CI.

2. **Install Shaka for the user/agent.** Clone
   [`shakacode/shaka`](https://github.com/shakacode/shaka) outside every
   consumer checkout and run that clone's `bin/install` into the host skill
   directory. Cursor uses `$HOME/.cursor/skills`; Codex uses
   `$HOME/.agents/skills`; Claude Code uses `$HOME/.claude/skills`. See
   [Shaka getting started](https://github.com/shakacode/shaka/blob/main/docs/getting-started.md).
   Shared `agent-workflows` skills (`$pr-batch`, `$address-review`, and similar)
   remain a separate host install when this repository still uses that pack.

3. **Initialize the consumer seam.** From the consumer repo, run the installed
   Shaka helper. Do not use `agent-workflow-seam-doctor --init` to create the
   contract: on a missing YAML that helper still writes unversioned V1 keys,
   and `shaka seam check` rejects them.

   ```bash
   "$HOME/.cursor/skills/shaka/scripts/shaka" seam init \
     --root . \
     --setup-command "bin/setup" \
     --validate-command "bin/ci-local" \
     --test-command "bin/test" \
     --review-policy meaningful_changes \
     --review-check claude-review
   ```

   Use the `scripts/shaka` path printed by `bin/install` for the host you
   installed. Pass this repository's real wrapper targets. The command creates
   `.agents/agent-workflow.yml` and the Scripts-to-Rule-Them-All wrappers when
   they are absent. It refuses to overwrite repo-owned wrappers or YAML.
   Default merge preference is Ask. Add `--merge-preference auto` only when
   that is the repository's established authority. Use `--base-branch` when
   work should not default to the GitHub default branch.

   Existing consumers that already have wrappers, as this repository does,
   write the typed YAML by hand to the same shape `seam init` would emit, then
   validate with `shaka seam check --root .`.

4. **Review policy YAML.** This repository's `.agents/agent-workflow.yml` is the
   Shaka typed contract (`version`, `base_branch`, `review`, `merge`, `branches`).
   Human-only React on Rails policy stays in `AGENTS.md`. Do not add V1 keys such
   as `follow_up_prefix` or `hosted_ci_trigger` to the Shaka YAML; `shaka seam check`
   rejects unknown keys.

5. **Review repo-local trust YAML.** The generated
   `.agents/trusted-github-actors.yml` contains empty, fail-closed lists. Add
   only repo-specific maintainers, teams, or automation that this repository
   has deliberately approved. The preflight resolution order is `--trust-config`, repo-local
   `.agents/trusted-github-actors.yml`, `$AGENT_WORKFLOWS_TRUST_CONFIG`,
   `~/.agents/trusted-github-actors.yml`, then the packaged fail-closed fallback.
   That fallback trusts `github-actions[bot]` only as metadata; its comment text
   is never actionable. Put repo-specific maintainers and actionable automation
   in the consumer repo's local trust file unless maintainers verify and choose
   a narrower team slug.

6. **Review the AGENTS pointer.** `AGENTS.md` stays canonical for human policy.
   Its pointer must resolve the trusted default branch, run installed
   `shaka seam check --ref REF`, execute the paths that command reports, and
   keep human-only boundaries in `AGENTS.md`. The legacy doctor pointer is not
   the Shaka contract.

7. **Keep repo-local skills local, but keep workflow references reachable.** Add
   only repo-specific skills, repo-pinned helper `bin/` copies, or local
   validation helpers to the repo. Do not copy shared workflow `SKILL.md` text
   into the repo unless the execution environment cannot load user-installed
   skills. If an agent surface can load installed skill Markdown but cannot
   execute the installed skill's `bin` helpers, keep a local helper copy for
   that skill without adding a duplicate `SKILL.md`.

8. **Validate the contract.** Run installed
   `shaka seam check --root . --local`, then run one dry workflow pass without
   making changes. Candidate validation grants neither policy nor merge
   authority; agents load trusted policy with `--ref <immutable-default-sha>`.
   Do not run `agent-workflow-seam-doctor` against the typed seam. That helper
   remains transitional legacy content for `agent-workflows` fixtures only.

9. **Make `AGENTS.md` canonical.** Tool-specific files such as `CLAUDE.md`
   should stay thin and link back to `AGENTS.md`.

## Command Wrappers

Simple wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
exec bundle exec rspec "$@"
```

Composed wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
"$root/.agents/bin/build"
"$root/.agents/bin/test"
```

Before opening a consumer PR, verify every wrapped command/task exists in that
repo. `bash -n` catches syntax errors, not missing package scripts or Rake tasks.

## Seam Validation

```bash
shaka seam check --root . --local
```

The same Shaka parser must validate trusted policy from an immutable default
branch commit before an agent relies on it:

```bash
shaka seam check --root . --ref <default-branch-sha>
```

The local mode rejects unknown or duplicate keys, invalid nested values, and
unsafe, missing, or non-executable command paths without granting authority.

## Keeping The Installed Pack Current

Use `agent-workflows-status` to check the installed pack against the recorded
source clone:

```bash
agent-workflows-status --host codex
```

Use `upgrade-agent-workflows` to update the source clone and reinstall the
transitional pack, then validate this consumer with trusted Shaka:

```bash
upgrade-agent-workflows --host codex
shaka seam check --root /path/to/consumer/repo --ref <immutable-default-sha>
```

## Shared Vs Repo-Local Skills

Shared portable skills include PR batching, review handling, post-merge audit,
adversarial review, verification, CI routing, and changelog update workflows.
They should avoid repo-specific commands, labels, paths, and domain examples.

Repo-local skills are for domain-heavy or destructive workflows that do not make
sense everywhere. React on Rails keeps its stress testing, RSC performance, and
release-train changelog skills local because they depend on this repository's
runtime surfaces and release policy.

## Optional Repo-Pinned Copies

A repo-pinned copy is useful only when a specific environment cannot load the
user-installed skill pack or when maintainers intentionally want shared workflow
updates reviewed in that repo. If a repo chooses that route:

- keep the pinned copy separate from repo-specific skills where possible
- document the source and version of the pinned copy
- do not customize shared files in place
- keep repo-specific command/policy values in `.agents/bin/` and
  `.agents/agent-workflow.yml`
- keep transitional `agent-workflows` copies covered by their drift manifest

### Detecting Drift In Pinned Copies

React on Rails keeps its reviewed mapping in
`.agents/agent-workflow-drift.yml`. The consumer-owned
`.agents/bin/agent-workflow-drift-manifest-test.rb` defines the complete governed
inventory and reviewed exclusions; the source-pack checker validates the mapped
bytes, modes, and overlay hashes against the pinned revision.

A consumer that reviews and pins shared files can use
`bin/check-agent-workflow-drift` from this source pack to detect later changes
on either side. The checker is read-only and makes no network calls. Pass all
three locations explicitly:

```bash
/path/to/agent-workflows/bin/check-agent-workflow-drift \
  --manifest /path/to/consumer/.agents/agent-workflow-drift.yml \
  --source-root /path/to/pinned/agent-workflows \
  --consumer-root /path/to/consumer
```

The source root must be the top level of a Git checkout whose `HEAD` is the
manifest's full 40-hex `source_revision`. Each mapped source file must also be
Git-clean against that exact revision, including staged and unstaged changes.
The checker compares the pinned blob and mode with the stage-zero index entry,
then hashes the actual worktree bytes using the pinned revision's attributes on
Git 2.41 or newer. Safe built-in checkout transformations such as
`core.autocrlf` are accepted on those Git versions. Older Git releases use a
portable byte-strict fallback with all filters disabled; a checkout
transformation that changes the worktree bytes is therefore reported as source
drift until the checker runs with Git 2.41 or newer.
Repository- or user-configured external clean/process filters are disabled and
never executed; a worktree that only matches after such a filter therefore
fails closed as source drift. Replacement objects are also disabled, and
external diff or text conversion drivers are not invoked. System and global
attribute files are ignored, a nonempty repository `info/attributes` override
fails closed, and configured filesystem monitors are disabled. Lazy object
fetching and Git transport protocols are disabled for every probe; a partial
checkout with a missing pinned attributes object fails closed instead of
contacting its promisor remote. This cleanliness check does not rewrite the
consumer contract: `identical` still compares current filesystem bytes, and
overlay SHA-256 values still hash the current source and consumer bytes directly.

Manifest version 1 has two mapping modes:

- `identical` requires byte-identical source and consumer files, and requires
  both filesystem modes to match the pinned source's Git mode.
- `overlay` records a reviewed local difference. It requires a nonempty reason
  and the SHA-256 of both files, plus the reviewed `consumer_mode`; a later
  content or mode change on either side is unexpected drift. Reasons may span
  multiple lines; the checker escapes control, format, and Unicode separator
  characters when rendering them so each result remains visually safe on one
  diagnostic line.

Version 1 validates only the mappings declared in `files`. A clean result does
not prove that the manifest covers every vendored source or consumer file. Each
consumer adopting the checker must pair it with an automated, consumer-owned
completeness test that compares the repository's intended vendored inventory
with the manifest mappings. Inventory policy stays consumer-local; version 1
does not define generic scope or exclusion rules.

Mode checks deliberately normalize regular files to Git's portable `100644`
(not executable) or `100755` (executable) modes instead of comparing exact
POSIX permissions. The pinned source tree mode is authoritative for the source.
The consumer need not be a Git checkout: the checker derives its normalized
mode from whether the filesystem owner-execute bit is set. Symlinks, submodules, and
other file kinds are unsupported and fail closed rather than being followed as
equivalent regular files.

```yaml
version: 1
source_revision: '0123456789abcdef0123456789abcdef01234567'
files:
  - source: skills/example/SKILL.md
    consumer: .agents/skills/example/SKILL.md
    mode: identical
  - source: workflows/example.md
    consumer: .agents/workflows/example.md
    mode: overlay
    reason: 'Consumer keeps repository-specific policy in this reviewed overlay.'
    consumer_mode: '100644'
    source_sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    consumer_sha256: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
```

Replace the example revision and hashes with values from the reviewed source
and consumer files. Paths use forward slashes and must be relative,
non-traversing, and unique on both sides. The checker reports deterministic
`CLEAN IDENTICAL`, `EXPECTED OVERLAYS`, and `UNEXPECTED DRIFT` buckets. It exits
nonzero for unexpected changes, missing or escaping files, a stale source
revision, mode or file-kind drift, invalid hashes, duplicate mappings, or
malformed schema.

## Validation Checklist

- `agent-workflows-status --host <codex|claude>` reports `UP_TO_DATE`, or the
  upgrade decision is recorded.
- `shaka seam check --root . --local` passes.
- Every generated wrapper's underlying command exists in the target repo.
- `pr-security-preflight --repo OWNER/REPO --trust-config .agents/trusted-github-actors.yml --strict-trust <exact-targets>`
  reports `SECURITY_PREFLIGHT_OK` for maintainer-approved exact targets.
- Markdown formatting and link checks pass for edited docs.
- A dry run of `$pr-batch` stops with an exact target list and goal prompt
  before spawning workers.

## Suggested Adoption PR Summary

```markdown
## Summary

- add standard `.agents/bin/*` wrappers for portable shared agent skills
- add non-command policy in `.agents/agent-workflow.yml`
- point `AGENTS.md` at the command and policy contract

## Validation

- `shaka seam check --root . --local`
- verified wrapped commands exist
- markdown formatting + link check
```
