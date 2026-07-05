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
for the design rationale. See
[`shakacode/agent-workflows/docs/installation-and-upgrades.md`](https://github.com/shakacode/agent-workflows/blob/main/docs/installation-and-upgrades.md)
for host install paths, upgrade commands, status states, rollback behavior, and
Codex/Claude notes.

## One-Time Adoption

1. **Inventory the target repo.** Identify base branch, package managers,
   setup/build/lint/format/test/type-check/docs commands, local CI routing,
   hosted-CI trigger, labels, changelog policy, release boundaries, generated
   files, protected-branch requirements, review bots, and which checks are cheap
   locally versus reserved for hosted CI.

2. **Install or enable the shared skills for the user/agent.** Clone
   [`shakacode/agent-workflows`](https://github.com/shakacode/agent-workflows)
   and use its `bin/install-agent-workflows --host codex` or
   `bin/install-agent-workflows --host claude`, or use the agent platform's
   normal user-skill installation mechanism. Install `skills/`, `workflows/`,
   and the shared `bin/` helpers together; shared workflows such as PR batching,
   review triage, and changelog updates call helper scripts relative to their
   installed skill directories.

3. **Add the seam to `AGENTS.md`.** Add an `## Agent Workflow Configuration`
   section using the template below, filled with the target repo's real values.
   This is the only place portable skills resolve repo-specific values.

4. **Keep repo-local skills local, but keep workflow references reachable.** Add
   only repo-specific skills, repo-pinned helper `bin/` copies, or local
   validation helpers to the repo. Do not copy shared workflow `SKILL.md` text
   into the repo unless the execution environment cannot load user-installed
   skills. Do not run an installed-skill-only setup with only `skills/`: install
   `workflows/` too, or keep repo-local workflow copies for skills that still
   reference `.agents/workflows/...`. If an agent surface can load installed
   skill Markdown but cannot execute the installed skill's `bin` helpers, keep
   a local helper copy for that skill without adding a duplicate `SKILL.md`.

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

- **Base branch**: <base branch>.
- **Pre-push local validation**: <local validation command, or "n/a">.
- **CI change detector**: <CI change detector command, or "n/a">.
- **Hosted-CI trigger**: <hosted-CI trigger, or "n/a">.
- **Benchmark labels**: <benchmark labels, or "n/a">.
- **Follow-up issue prefix**: <follow-up prefix, for example `Follow-up:`>.
- **Changelog**: <changelog path and policy, or "n/a">.
- **Lint / format**: <lint / format commands>.
- **Merge ledger**: <merge ledger command, or "n/a">.
- **Docs checks**: <docs checks, or "n/a">.
- **Tests**: <unit / integration / e2e commands>.
- **Build / type checks**: <build / type checks, or "n/a">.
- **Review gate**: <review gate, or "n/a">.
- **Approval-exempt change categories**: <approval-exempt change categories>.
- **Coordination backend**: <coordination backend>.
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

## Keeping The Installed Pack Current

Use `agent-workflows-status` to check the installed pack against the recorded
source clone:

```bash
agent-workflows-status --host codex
```

Stable status tokens are `UP_TO_DATE`, `UPGRADE_AVAILABLE`, `NOT_INSTALLED`, and
`CHECK_FAILED`. Add `--fetch` only when a network check against `origin` is
intended.

Use `upgrade-agent-workflows` to update the source clone, reinstall, and run the
seam doctor against this repo:

```bash
upgrade-agent-workflows \
  --host codex \
  --consumer-root /path/to/react_on_rails
```

The upgrade helper backs up the current install and restores it if reinstall or
consumer seam validation fails. Use `--host claude` for Claude Code installs and
`--no-fetch` when the source clone has already been updated locally.

## Shared Vs Repo-Local Skills

Shared portable skills include PR batching, review handling, post-merge audit,
adversarial review, verification, CI routing, and changelog update workflows.
They should avoid repo-specific commands, labels, paths, and domain examples.

Repo-local skills are for domain-heavy, destructive, or release-policy workflows
that do not make sense everywhere. React on Rails keeps `stress-test`,
`optimize-rsc-performance`, and `react-on-rails-update-changelog` local because
they exercise RSC, SSR, demo-workspace, performance evidence, and release-train
branch-targeting behavior specific to this repo.

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

- `agent-workflows-status --host <codex|claude>` reports `UP_TO_DATE`, or the
  upgrade decision is recorded.
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
