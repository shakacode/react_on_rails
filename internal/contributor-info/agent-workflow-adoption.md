# Agent Workflow Adoption Guide

Use this guide to make the shared agent workflows available in another
repository without copying React on Rails policy into that repo.

The default model is:

- shared skills are installed in the user or agent environment
- each repo owns its `AGENTS.md` policy and `## Agent Workflow Configuration`
  seam
- a seam checker confirms the installed skill can resolve the repo-specific
  values it needs
- repo-pinned copies are optional and justified case by case

See
[`portable-agent-workflows-seam-design.md`](portable-agent-workflows-seam-design.md)
for the design rationale.

## One-Time Adoption

1. **Inventory the target repo.** Identify base branch, package managers,
   setup/build/lint/format/test/type-check/docs commands, local CI routing,
   hosted-CI trigger, labels, changelog policy, release boundaries, generated
   files, protected-branch requirements, review bots, and which checks are cheap
   locally versus reserved for hosted CI.

2. **Install or enable the shared skills for the user/agent.** Clone
   [`shakacode/agent-workflows`](https://github.com/shakacode/agent-workflows)
   and use its `bin/install-agent-workflows`, or use the agent platform's normal
   user-skill installation mechanism. Install `skills/`, `workflows/`, and the
   shared `bin/` helpers together; shared workflows such as PR batching, review
   triage, and changelog updates call helper scripts relative to their installed
   skill directories.

3. **Add the seam to `AGENTS.md`.** Add an `## Agent Workflow Configuration`
   section using the template below, filled with the target repo's real values.
   This is the only place portable skills resolve repo-specific values.

4. **Keep repo-local skills local.** Add only repo-specific skills, tiny
   compatibility launchers, or local validation helpers to the repo. Do not copy
   shared workflow text into the repo unless the execution environment cannot
   load user-installed skills. If an agent surface can load installed skill
   Markdown but cannot execute the installed skill's `bin/` helpers, keep a
   local helper copy or compatibility launcher for that skill.

5. **Validate the seam.** Run `agent-workflow-seam-doctor` from the shared
   `shakacode/agent-workflows` pack with `--shared` pointing at the cloned or
   installed shared-pack root, or
   `.agents/bin/agent-workflow-seam-doctor` in repos that keep local shared
   copies. Then run one dry workflow pass that resolves the seam values without
   making changes.

6. **Make `AGENTS.md` canonical.** It owns commands, testing, style, git/PR
   safety, release policy, and documentation boundaries. Tool-specific files
   such as `CLAUDE.md` should stay thin and link back to `AGENTS.md`.

## The Seam Template

Copy this into the consumer repo's `AGENTS.md` and replace every value.

```markdown
## Agent Workflow Configuration

Portable shared skills resolve every repo-specific value through this section.

- **Base branch**: <main | master | release branch policy>.
- **Pre-push local validation**: <command an agent runs before pushing, or "n/a">.
- **CI change detector**: <command, or "n/a">.
- **Hosted-CI trigger**: <comment command, label, helper command, or "n/a">.
- **Benchmark labels**: <labels, or "n/a">.
- **Follow-up issue prefix**: <for example, `Follow-up:`>.
- **Changelog**: <path + policy + entry format, or "n/a">.
- **Lint / format**: <lint, autofix, and format-check commands>.
- **Merge ledger**: <machine-checkable merge-readiness command, or "n/a">.
- **Docs checks**: <docs sidebar/link/style commands, or "n/a">.
- **Tests**: <unit / integration / e2e commands>.
- **Build / type checks**: <build, type-check, signature-validation commands, or "n/a">.
- **Review gate**: <preferred independent review check name, or "n/a">.
- **Approval-exempt change categories**: <categories allowed on trusted assignments>.
- **Coordination backend**: <shared backend for multi-batch work, or public claim-comment fallback>.
```

Anything marked `n/a` means the matching shared guidance degrades to "do the
equivalent manually"; the workflow structure still transfers.

## Seam Validation

Run the seam doctor after adding or changing the seam:

```bash
agent-workflow-seam-doctor --shared "${AGENT_WORKFLOWS_ROOT:?set path to shakacode/agent-workflows}"
```

For repos that keep the checker in the checkout:

```bash
.agents/bin/agent-workflow-seam-doctor --shared .agents
```

The checker should pass before agents rely on installed shared skills. It fails
when required seam keys are missing or executable snippets in the repo-local or
installed shared skill Markdown still contain unresolved seam placeholders such
as `<follow-up prefix>`.

## Shared Vs Repo-Local Skills

Shared portable skills include PR batching, review handling, post-merge audit,
adversarial review, verification, CI routing, and changelog update workflows.
They should avoid repo-specific commands, labels, paths, and domain examples.

Repo-local skills are for domain-heavy or destructive workflows that do not make
sense everywhere. React on Rails keeps `stress-test` local because it exercises
RSC/SSR/demo-workspace behavior specific to this repo.

## Optional Repo-Pinned Copies

A repo-pinned copy is useful only when a specific environment cannot load the
user-installed skill pack or when maintainers intentionally want shared workflow
updates reviewed in that repo. If a repo chooses that route:

- keep the pinned copy separate from repo-specific skills where possible
- document the source and version of the pinned copy
- do not customize shared files in place
- keep repo-specific values in `AGENTS.md`, not in the pinned files
- run the seam doctor with `--shared` after every sync or update

Do not make repo pinning the default adoption step.

## What Not To Copy Blindly

- React on Rails package paths such as `react_on_rails/`,
  `packages/react-on-rails/`, and `react_on_rails_pro/`.
- Ruby/Rails/Shakapacker/RSC/Pro rules unless the repo actually uses them.
- Commands that do not exist in the target repo.
- Coordination labels unless the repo creates and defines them.
- High-concurrency execution from public filters without a maintainer-approved
  exact target list.
- Treating AI reviewer approvals or "no actionable comments" summaries as
  required maintainer approval. They are advisory unless they identify a
  confirmed blocker.

## Cross-Repo Coordination

For multi-machine, multi-batch, or cross-repo work, also adopt
[`internal/contributor-info/multi-batch-operations.md`](multi-batch-operations.md).
ShakaCode-internal repos may share the private coordination backend named in
their seam. External adopters can use the structured public claim-comment
fallback until a public backend spec exists.

## Validation Checklist

- `agent-workflow-seam-doctor --shared <path-to-shakacode/agent-workflows>` passes.
- Markdown formatting and link checks pass for edited docs.
- Skill `bin/` unit tests pass when the repo carries local helper scripts.
- A dry run of `$pr-batch` stops with an exact target list and goal prompt
  before spawning workers.
- A dry run of review triage reaches the action menu and resolves base branch,
  validation command, hosted-CI trigger, and follow-up prefix from the seam.

## Suggested Adoption PR Summary

```markdown
## Summary

- add the `## Agent Workflow Configuration` seam to `AGENTS.md`
- document this repo's validation, hosted-CI, changelog, and coordination values
- enable user-installed shared agent skills to resolve this repo's policy
- add or run the seam doctor

## Validation

- `agent-workflow-seam-doctor --shared <path-to-shakacode/agent-workflows>`
- markdown formatting + link check
- dry-run `$pr-batch` and PR-review triage without code changes
```
