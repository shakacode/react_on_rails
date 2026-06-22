# Portable Agent Workflows via User-Installed Skills And Repo Seam

Date: 2026-06-18
Status: approved direction, updated 2026-06-21

## Problem

The `pr-batch` family and related agent workflows are useful outside React on
Rails, but the current copies mix reusable process with repo-specific commands,
labels, release policy, paths, and domain examples. We want ShakaCode agents to
carry these workflows across repos without copying a stale `.agents/` tree into
every repository or making each repo responsible for shared workflow updates.

## Goal

Make shared skills portable by installing them in the user or agent environment,
then make each repo expose a small, validated `AGENTS.md` seam that supplies the
repo-specific values the portable skills need.

## Architecture

```text
shakacode/agent-workflows
  skills/... and workflows/...        portable process, installed per user/agent
  bin/...                             install, status, upgrade, and validation helpers

consumer repo
  AGENTS.md                           canonical policy plus Agent Workflow Configuration seam
  .agents/bin/agent-workflow-seam-doctor
                                      optional local checker for the seam contract
  .agents/skills/...                  repo-local overrides, compatibility copies, or domain skills
  .agents/workflows/...               repo-local workflow files only when the repo needs them
```

The default distribution path is
[`shakacode/agent-workflows`](https://github.com/shakacode/agent-workflows) plus
the user's normal skill installation mechanism. For example, an agent may
install the shared `pr-batch`, `verify`, `address-review`, and changelog skills
once into Codex or Claude and use them in any repo. The skill then reads the
target repo's `AGENTS.md` seam to resolve concrete commands and policy.

Repository-pinned copies remain an optional escape hatch for environments that
need exact workflow text in the checkout, such as cloud agents that cannot use a
user skill install. They are not the default design and should be justified by a
specific reproducibility or execution-environment need.

## The Seam

Each adopting repo owns a section named `## Agent Workflow Configuration` in
`AGENTS.md`. Shared skills may refer to these values by name:

- base branch
- local validation command
- CI change detector
- hosted-CI trigger and labels
- benchmark labels
- follow-up issue prefix
- changelog path, policy, and entry format
- lint, format, build, type, docs, and test commands
- merge ledger
- review gate
- approval-exempt change categories
- coordination backend

The seam is deliberately human-readable because `AGENTS.md` is already the
repo's canonical agent policy. Add a structured config file only when a
non-LLM script needs to consume the values mechanically.

## Seam Doctor

`agent-workflow-seam-doctor` checks the boundary between portable skills and the
repo:

- verifies that `AGENTS.md` has the required seam keys
- fails on unresolved template values in the seam
- scans repo-local and explicitly supplied installed shared skill/workflow
  Markdown for executable snippets that still contain unresolved seam
  placeholders such as `<follow-up prefix>`

It does not reject ordinary command parameters such as `<PR>` or `<sha>`. Those
are task inputs, not repo-seam values.

## Why Not Subtree First

`git subtree` solves "every repo has a pinned copy of the shared files," but
that is not the primary problem. The primary problem is whether a portable skill
can safely resolve repo-specific behavior. A subtree also makes the `.agents/`
prefix all-or-nothing, which is awkward when a repo has real local skills such
as React on Rails' `stress-test`.

Use a repository-pinned copy only when the execution environment cannot depend
on user-installed shared skills or when the repo intentionally wants to review
shared workflow updates like source code. Otherwise, install the shared skill
pack once for the user/agent and validate each repo's seam.

## Shared Vs Repo-Local

Shared skills should contain portable procedure and safety rules:

- issue and PR batching
- PR processing
- review comment triage
- verification
- changelog updates
- post-merge and adversarial audits
- CI routing helpers

Shared skill installation must include each skill's `bin/` helpers with its
`SKILL.md`, and workflow text should call helpers relative to the installed
skill directory or through a repo-local compatibility launcher. A repo that can
load installed skill Markdown but cannot execute installed helper scripts should
pin the helper scripts locally.

Repo-local content should contain concrete policy and domain knowledge:

- `AGENTS.md`
- repo-specific destructive or domain-heavy skills
- local scripts such as seam validators or helper launchers
- compatibility copies only when a tool cannot load installed skills

## Phasing

1. React on Rails seam PR: add the repo seam, genericize shared workflow text to
   resolve values through that seam, add `agent-workflow-seam-doctor`, and update
   the adoption guide around user-installed shared skills.
2. Shared pack: publish `shakacode/agent-workflows`, install it in the agent
   surfaces ShakaCode uses, and run its `bin/validate` before shared updates.
   Use `agent-workflows-status` and `upgrade-agent-workflows` for ongoing
   installed pack maintenance.
3. Consumer repos: install or enable the shared skills for the user/agent, add
   the repo seam, run the seam doctor, and dry-run one workflow.
4. Optional pinning: revisit repository-pinned copies only for repos or agents
   that cannot rely on the user-installed skill pack.

## Validation

- `ruby .agents/bin/agent-workflow-seam-doctor-test.rb`
- `.agents/bin/agent-workflow-seam-doctor`
- `agent-workflow-seam-doctor --shared <path-to-shakacode/agent-workflows>`
- Markdown format and link checks for edited documentation
- a dry run of one shared workflow against the repo seam
