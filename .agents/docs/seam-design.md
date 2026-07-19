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

`.agents/agent-workflow.yml` carries non-command values:

- `base_branch`
- `follow_up_prefix`
- `review_gate`
- `approval_exempt`
- `coordination_backend`
- `changelog`
- `benchmark_labels`
- `merge_ledger`
- `ci_parity_environment`
- `hosted_ci_trigger`
- `ci_change_detector`

Repos may add policy keys such as `secret_redaction_patterns` when needed. Use
`n/a` for unavailable policy. Keep values terse and behavior-complete.

Repos that use `untrusted-contributor-intake` add one explicit trusted-base
authority mapping. The seam doctor requires all three values when the mapping
is present, and the skill fails closed when the mapping is absent or invalid:

```yaml
untrusted_contributor_intake:
  trusted_github_host: 'github.com'
  trusted_github_scheme: 'https'
  trusted_github_repo: 'OWNER/REPO'
```

## AGENTS Pointer

Each consumer `AGENTS.md` owns a section named
`## Agent Workflow Configuration`, but the section is only a pointer:

```markdown
## Agent Workflow Configuration

Portable shared skills resolve this repo's commands and policy through:

- **Commands** — run `.agents/bin/<name>` (`setup`, `validate`, `test`, ...); see `.agents/bin/README.md`. A missing script means that capability is n/a here.
- **Policy / config** — `.agents/agent-workflow.yml`.
```

Consumer repos should keep broader human guidance in `AGENTS.md`, but command
resolution and workflow policy come from the binstubs and YAML.

## Seam Initialization

`agent-workflow-seam-doctor --init` creates the smallest complete consumer seam
and immediately validates it through the same public interface. Initialization
preserves valid repo-owned wrappers and existing policy, trust, and unrelated
`AGENTS.md` content. It writes an empty repo-local trust configuration so a new
seam starts fail-closed.

The initializer conservatively detects executable root `bin/validate` and
`bin/test`, or exact JavaScript `validate` and `test` scripts when one recognized
lockfile identifies npm, pnpm, or Yarn. Unknown, partial, and ambiguous command
surfaces get marked fail-closed wrappers and a precise `FAIL` result. Callers can
instead pass both `--validate-command` and `--test-command`; multiline, empty,
and NUL-containing command values are rejected before any write. Simple commands
forward arguments automatically; npm gets its required `--` separator, while
pnpm and Yarn receive arguments directly. Compound shell expressions are kept
verbatim and must include `"$@"` themselves when forwarding is wanted. `env -S`
and `env --split-string` commands are likewise caller-controlled because their
split payload owns argument placement. Missing
policy or trust keys are appended to existing block mappings so comments and
formatting remain intact; initialization fails closed before writing when a
safe append is not possible.

The init marker is the ownership boundary for generated wrappers. Explicit
commands replace both marked wrappers on a later run, while an unmarked valid
wrapper is repo-owned and preserved; explicit replacement of that repo-owned
wrapper fails closed. Put hand-written behavior behind a managed wrapper or
remove the marker deliberately before taking direct ownership.

## Seam Doctor

`agent-workflow-seam-doctor` validates the contract:

- `AGENTS.md` has the pointer section
- `.agents/bin/README.md` exists
- core scripts `validate` and `test` exist, are executable, pass `bash -n`, and
  include the repo-root `cd` preamble
- `.agents/agent-workflow.yml` parses and has all required policy keys with
  resolved values
- an optional `.agents/trusted-github-actors.yml` parses as a mapping and has no
  normalized bot login in both actionable and metadata-only roles; regular
  checks and `--init` preserve preflight compatibility with legacy scalar
  values, while newly generated role values use lists
- repo-local and supplied shared skill/workflow Markdown do not contain
  unresolved executable placeholders such as `<follow-up prefix>`

The doctor intentionally does not execute the wrappers. Before consumer PRs,
also verify that wrapped commands/tasks exist in the target repo. It does reject
the initializer's marked fail-closed wrappers until real commands replace them.

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

- `bin/validate`
- `ruby bin/agent-workflow-seam-doctor-test.rb`
- `ruby bin/push-downstream-test.rb`
- `bin/agent-workflow-seam-doctor --root <consumer-repo> --shared <this-repo>`
- `ruby .agents/bin/agent-workflow-drift-manifest-test.rb --source-root <pinned-agent-workflows>`
- `<pinned-agent-workflows>/bin/check-agent-workflow-drift --manifest
<consumer-repo>/.agents/agent-workflow-drift.yml --source-root
<pinned-agent-workflows> --consumer-root <consumer-repo>`
- Markdown review for edited docs
