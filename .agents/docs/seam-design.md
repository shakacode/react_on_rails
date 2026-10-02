# Portable Agent Workflows Via Binstubs And Policy YAML

Date: 2026-06-18
Status: approved direction, updated 2026-06-27

## Problem

The shared `pr-batch` family and related agent workflows should run across
ShakaCode repos without copying repo-specific commands, labels, branches,
release policy, paths, or domain examples into the shared pack. Consumer repos
need a small, structured contract that is easy for humans to review and easy for
helper scripts to validate.

## Goal

Make the shared skills portable by installing them once in the user or agent
environment, then make each consumer repo expose a small, validated contract:

- commands are executable repo-owned binstubs under `.agents/bin/`
- non-command policy is structured YAML in `.agents/agent-workflow.yml`
- `AGENTS.md` points humans and agents at those two sources

## Language

Use [source-pack-glossary.md](https://github.com/shakacode/agent-workflows/blob/main/docs/source-pack-glossary.md) as the canonical glossary
for terms such as Source Pack, Consumer Repo, Agent Workflow Configuration Seam,
Host Installer Path, Native Plugin Path, Workflow Lessons Library, Readiness
Vocabulary, Review Finding, and State-Machine Fixture. Keep this document
focused on the seam architecture; update the glossary when new workflow-pack
terms need stable meaning across issues, PRs, and implementation prompts.

## Architecture

```text
shakacode/agent-workflows
  skills/... and workflows/...        portable process, installed per user/agent
  bin/...                             install, status, upgrade, validation, sync helpers

consumer repo
  .agents/bin/README.md               command table for this repo
  .agents/bin/setup                   optional dependency setup
  .agents/bin/validate                required pre-push gate
  .agents/bin/test                    required test entry point
  .agents/bin/lint                    optional lint/format entry point
  .agents/bin/build                   optional build/type-check entry point
  .agents/bin/docs                    optional docs check entry point
  .agents/bin/ci-detect               optional CI routing entry point
  .agents/agent-workflow.yml          non-command policy
  .agents/agent-workflow-drift.yml    reviewed pin for vendored shared files
  .agents/skills/...                  repo-specific skills or pinned helper copies
  AGENTS.md                           pointer section; no workflow policy
  CLAUDE.md                           optional thin import of @AGENTS.md
```

The default distribution path remains this repository plus the user's normal
skill installation mechanism. Repository-pinned copies remain an escape hatch
for execution environments that cannot use user-installed shared skills. React
on Rails pins only the shared files needed by checkout-only workflows and keeps
shared `SKILL.md` files out of the local picker.

## Command Contract

Portable skills call `.agents/bin/<name>` rather than embedding a target repo's
real commands. Each wrapper is a thin Bash script:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
exec bundle exec rspec "$@"
```

Composed scripts compute the root once and call siblings by absolute path:

```bash
#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
"$root/.agents/bin/build"
"$root/.agents/bin/test"
```

`validate` is the authoritative comprehensive pre-push gate. `test`, `lint`,
`build`, `docs`, and `ci-detect` are convenience subsets. An absent optional
script means that capability is n/a in that repo.

## Policy Contract

This consumer uses the Shaka typed seam in `.agents/agent-workflow.yml`
(`version`, `base_branch`, `review`, `merge`, `branches`). Remaining
React on Rails policy (hosted CI, changelog, merge ledger, follow-up prefix,
coordination backend, redaction, and trust) lives in `AGENTS.md`.

Installed Shaka is the only validator for this typed contract. Required CI pins
the reviewed Shaka Git revision and runs `seam check --local`; runtime workflow
authority comes only from `seam check --ref <immutable-default-sha>`.
The repo-pinned legacy doctor lives under
`.agents/fixtures/agent-workflows/bin/`, byte-identical to its source, only for
transitional fixture and drift coverage.

Public-comment trust is a separate contract in
`.agents/trusted-github-actors.yml`, not a seam key. Shaka's comment reader loads
that file from the trusted default-branch commit and fails closed on malformed
settings or overlapping actionable and metadata-only bot roles. Required CI
also exercises the pinned Shaka trust parser against the candidate file.

## AGENTS Pointer

Each consumer `AGENTS.md` owns a section named
`## Agent Workflow Configuration`, but the section is only a pointer:

```markdown
## Agent Workflow Configuration

Resolve the trusted default branch to an immutable commit. Load and validate
`.agents/agent-workflow.yml` with the trusted installed `shaka seam check --ref REF`
command. Run the fixed executable paths reported by that command from the candidate
checkout; do not reconstruct their behavior from prose. `AGENTS.md` retains human-only boundaries.
```

Consumer repos should keep broader human guidance in `AGENTS.md`. Command
resolution uses `.agents/bin/`; Shaka typed policy uses `.agents/agent-workflow.yml`.

## Seam Initialization

New and migrated consumers use `shaka seam init`. The legacy doctor is fixture
data and must never be run with `--init` against this repository.

## Seam Validation

`shaka seam check --local` validates the candidate contract:

- `.agents/agent-workflow.yml` has the complete versioned Shaka schema
- unknown and duplicate keys fail
- nested review and merge values are valid
- fixed command paths stay inside the repository, exist, and are executable
- the result is labeled `local/candidate` and grants no policy or merge authority

React on Rails required CI runs that parser and
`script/shaka_seam_check_test.rb`. The legacy doctor and its test remain
byte-identical under `.agents/fixtures/agent-workflows/bin/` so drift validation
can cover legacy fixtures without exposing the doctor as an active command.

## Repository-Pinned Copies

Some repos may need a pinned copy of shared workflow files because their
execution environment cannot depend on user-installed skills or because shared
workflow updates must be reviewed inside that repo. Treat that as an explicit
deployment choice. The default architecture remains installed shared skills plus
a validated repo-owned seam.

React on Rails validates this deployment choice in two layers: its consumer-owned
manifest test proves that every file in the governed prefixes is mapped or has a
reviewed exclusion, and the pinned source-pack checker proves mapped content and
Git modes still match the reviewed revision.

## Validation

Run source-pack checks from the pinned checkout, then run the consumer manifest
test from React on Rails.

- `shaka seam check --root <consumer-repo> --local`
- `SHAKA_COMMAND=<pinned-shaka>/skills/shaka/scripts/shaka ruby script/shaka_seam_check_test.rb`
- `bin/validate`
- `ruby .agents/fixtures/agent-workflows/bin/agent-workflow-seam-doctor-test.rb`
- `ruby bin/push-downstream-test.rb`
- `ruby .agents/bin/agent-workflow-drift-manifest-test.rb --source-root <pinned-agent-workflows>`
- `<pinned-agent-workflows>/bin/check-agent-workflow-drift --manifest
<consumer-repo>/.agents/agent-workflow-drift.yml --source-root
<pinned-agent-workflows> --consumer-root <consumer-repo>`
- Markdown review for edited docs
