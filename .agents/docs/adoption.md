# Agent Workflow Adoption Guide

Use this guide to make the shared agent workflows available in another
repository without copying another repo's policy into that repo.

The default model is:

- shared skills are installed in the user or agent environment
- each repo owns command wrappers in `.agents/bin/`
- each repo owns non-command policy in `.agents/agent-workflow.yml`
- each repo owns durable PR-batch actor trust in `.agents/trusted-github-actors.yml`
- `AGENTS.md` points agents to those two sources
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

2. **Install or enable the shared skills for the user/agent.** Clone
   [`shakacode/agent-workflows`](https://github.com/shakacode/agent-workflows)
   and use `bin/install-agent-workflows --host codex` or
   `bin/install-agent-workflows --host claude`, or use the agent platform's
   normal user-skill installation mechanism.

3. **Initialize the consumer seam.** From the consumer repo, run:

   ```bash
   agent-workflow-seam-doctor --init --shared "$HOME/src/agent-workflows"
   ```

   The initializer preserves valid repo-owned wrappers and existing policy,
   trust, and `AGENTS.md` content. It detects executable root `bin/validate`
   plus `bin/test`, or exact `validate` and `test` package scripts when exactly
   one of `package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock` identifies the
   runner. It does not guess Ruby/Rake tasks, combine partial validation
   scripts, or choose among ambiguous package managers.

   If detection is unavailable, the command creates clearly marked
   fail-closed wrappers and returns `FAIL` with the next step. Supply both real
   commands to initialize and pass in one invocation:

   ```bash
   agent-workflow-seam-doctor --init \
     --validate-command 'bin/validate' \
     --test-command 'bin/test' \
     --shared "$HOME/src/agent-workflows"
   ```

   `--validate-command` and `--test-command` accept non-empty single-line shell
   commands and must be supplied together. Simple commands forward wrapper
   arguments automatically. `npm run` commands add npm's `--` separator, while
   `pnpm run` and `yarn run` pass arguments directly. Compound shell expressions
   are preserved verbatim, so include `"$@"` when they should receive wrapper
   arguments. Use `--base-branch` when the new policy should not default to
   `main`. `env -S` and `env --split-string` commands are preserved verbatim;
   their split payload must place any desired wrapper forwarding itself.

   Generated wrappers that retain the init marker are tool-owned, and another
   explicit-command run rewrites both of them. Keep custom logic in the target
   commands, or replace a wrapper without the marker and rerun without explicit
   commands to make that wrapper repo-owned. Explicit replacement of a
   repo-owned wrapper fails closed.

4. **Review policy YAML.** The initializer creates
   `.agents/agent-workflow.yml` with required
   non-command policy keys: `base_branch`, `follow_up_prefix`, `review_gate`,
   `approval_exempt`, `coordination_backend`, `changelog`, `benchmark_labels`,
   `merge_ledger`, `ci_parity_environment`, `hosted_ci_trigger`, and
   `ci_change_detector`. Use `n/a` for unavailable policy. Start from
   [`examples/agent-workflow.yml`](https://github.com/shakacode/agent-workflows/blob/main/examples/agent-workflow.yml) when
   bootstrapping a new consumer repo. When an existing mapping needs new
   required keys, initialization appends them without rewriting its comments or
   formatting and fails closed if that merge cannot be represented safely.

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

6. **Review the AGENTS pointer.** `AGENTS.md` stays canonical for human policy,
   and the initializer adds or repairs only this workflow configuration section:

   ```markdown
   ## Agent Workflow Configuration

   Portable shared skills resolve this repo's commands and policy through:

   - **Commands** — run `.agents/bin/<name>` (`setup`, `validate`, `test`, ...); see `.agents/bin/README.md`. A missing script means that capability is n/a here.
   - **Policy / config** — `.agents/agent-workflow.yml`.
   ```

7. **Keep repo-local skills local, but keep workflow references reachable.** Add
   only repo-specific skills, repo-pinned helper `bin/` copies, or local
   validation helpers to the repo. Do not copy shared workflow `SKILL.md` text
   into the repo unless the execution environment cannot load user-installed
   skills. If an agent surface can load installed skill Markdown but cannot
   execute the installed skill's `bin` helpers, keep a local helper copy for
   that skill without adding a duplicate `SKILL.md`.

8. **Validate the contract.** Initialization runs the same seam-doctor check.
   After resolving any fail-closed wrapper guidance, rerun
   `agent-workflow-seam-doctor` with `--shared` pointing at the cloned or
   installed pack root. Then run one dry workflow pass without making changes.

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
agent-workflow-seam-doctor --shared "${AGENT_WORKFLOWS_ROOT:?set path to shakacode/agent-workflows}"
```

For repos that keep the checker in the checkout:

```bash
.agents/bin/agent-workflow-seam-doctor --shared .agents
```

The checker fails when the pointer section is missing, core scripts are missing
or malformed, policy YAML is incomplete, or executable snippets in repo-local or
installed shared skill Markdown still contain unresolved placeholders such as
`<follow-up prefix>`.

## Keeping The Installed Pack Current

Use `agent-workflows-status` to check the installed pack against the recorded
source clone:

```bash
agent-workflows-status --host codex
```

Use `upgrade-agent-workflows` to update the source clone, reinstall, and run the
seam doctor against one or more consumer repos:

```bash
upgrade-agent-workflows \
  --host codex \
  --consumer-root /path/to/consumer/repo
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
- run the seam doctor with `--shared` after every sync or update

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
- `agent-workflow-seam-doctor --shared <path-to-shakacode/agent-workflows>` passes.
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

- `agent-workflow-seam-doctor --shared <path-to-shakacode/agent-workflows>`
- verified wrapped commands exist
- markdown formatting + link check
```
