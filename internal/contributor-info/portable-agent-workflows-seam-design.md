# Portable Agent Workflow Seam Design

Date: 2026-06-18

Status: migrated to Shaka's versioned seam on 2026-09-20

## Current Architecture

```text
trusted Shaka installation
  workflow and typed seam parser

consumer repository
  AGENTS.md                         human-only constraints and Shaka pointer
  .agents/agent-workflow.yml        versioned Shaka policy
  .agents/bin/{setup,validate,test} fixed executable command interface
  .agents/trusted-github-actors.yml repository-specific actor trust
```

Shaka owns the schema and defaults for `.agents/agent-workflow.yml`. Candidate
validation uses `shaka seam check --local` and cannot grant authority. Runtime
workflow policy comes from `shaka seam check --ref <immutable-default-sha>`.
This distinction prevents a pull request from changing the policy used to judge
itself.

Shared skills continue to call the repository-owned `.agents/bin/` wrappers,
so repositories expose stable commands without copying repository-specific
behavior into portable skills. `AGENTS.md` remains canonical for human-only
testing, publishing, privacy, and release constraints.

## Legacy Transition

Selected `shakacode/agent-workflows` files remain pinned for workflows that have
not yet moved to Shaka. They are transitional implementation content, not a
second seam authority. React on Rails keeps the legacy doctor and test
byte-identical under `.agents/fixtures/agent-workflows/bin/` solely for their
fixture suite and drift coverage. The remaining source-pack retirement owner is
[`shakacode/agent-workflows#857`](https://github.com/shakacode/agent-workflows/issues/857).

The current adoption procedure is
[`agent-workflow-adoption.md`](agent-workflow-adoption.md). Do not add a new
schema overlay or teach the legacy doctor to accept Shaka keys.

## Validation

- pinned Shaka candidate validation and consumer regression fixtures
- fixed command paths that exist, stay inside the repository, and are executable
- consumer-owned completeness plus pinned-source drift checks for transitional files
- Markdown formatting and link checks
