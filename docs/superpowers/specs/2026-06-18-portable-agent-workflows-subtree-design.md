# Portable Agent Workflows via Subtree — Design

Date: 2026-06-18
Status: approved (Phase 1 implementation)

## Problem

The agent workflow skills in `.agents/skills/` and `.agents/workflows/` (the `pr-batch`
family, PR processing, review handling, post-merge audit, adversarial review, etc.) are
mature and valuable, but they live only in `react_on_rails` and are tangled with
react_on_rails-specific commands, labels, paths, and domain knowledge. We want to reuse
them across other ShakaCode flagship repos (`control-plane-flow`, `shakapacker`,
`shakaperf`, and more) **and keep every repo updated as the workflows evolve** — not a
one-time copy that immediately drifts.

The existing `internal/contributor-info/agent-workflow-adoption.md` documents a manual
"copy then customize in place" flow. That model is fundamentally incompatible with
ongoing sync: any in-place customization creates a merge conflict on every future update.

## Goal

A shared, versioned source of truth for the portable workflow logic that each consumer
repo vendors and can pull updates from conflict-free, with all per-repo differences
isolated to a single, well-defined seam.

## Architecture

```
shakacode/agent-workflows                    ← canonical upstream (new repo, Phase 2)
  skills/…  workflows/…                       repo-AGNOSTIC; the only source of truth

each consumer repo (react_on_rails, control-plane-flow, shakapacker, shakaperf, …)
  .agents/            ← git subtree of upstream; byte-identical; NEVER hand-edited
  .claude/skills → ../.agents/skills           per-repo glue (recreated at adoption)
  AGENTS.md           ← per-repo SEAM: the concrete commands / branch / labels / paths
```

- **Vendoring**: `git subtree add --prefix=.agents <upstream> main --squash`.
- **Updating**: `git subtree pull --prefix=.agents <upstream> main --squash`.
- `--squash` keeps each consumer's history clean (no upstream commit-by-commit noise).
- Conflict-free pulls require one rule: **`.agents/` is never edited in a consumer.** All
  per-repo variation lives in `AGENTS.md`.

The subtree prefix is `.agents/`. The `.claude/skills → ../.agents/skills` symlink and any
`.claude/prompts/*` compatibility pointers are tiny per-repo glue, recreated at adoption,
not vendored.

## The seam: Model A with a named config section

The portable `.agents/` files stop hardcoding repo specifics and instead defer **by name**
to a single section in the consumer's `AGENTS.md`:

```
## Agent Workflow Configuration
- Base branch: …
- Local validation: …          (the command(s) an agent runs before pushing)
- Change detector: …
- CI labels / hosted-CI trigger: …
- Benchmark labels: …
- Follow-up issue prefix: …
- Changelog path & policy: …
- Approval-exempt change categories: …
- Coordination backend (if any): …
```

Why Model A (AGENTS.md only) over a structured `.agents.local.yml`:

- The values are **already duplicated** in both `.agents/` and `AGENTS.md` today, so
  extraction is mostly de-duplication, not information loss.
- `AGENTS.md` is already the stated source of truth and is always in the agent's context.
- The bundled `bin/` scripts already take their inputs as args; nothing needs
  machine-readable config. A second file would only add a place to drift from `AGENTS.md`.

A structured `.agents.local.yml` is deferred until a concrete non-LLM script needs to read
config without prose-parsing. Nothing currently does.

## Separation rule (three transforms)

Every repo-specific reference in `.agents/` resolves to exactly one move:

1. **De-duplicate** — the fact is already in both `.agents/` and `AGENTS.md`. Keep the
   `AGENTS.md` copy; replace the `.agents/` copy with a pointer to the named config
   section. (Most cases; ~zero fidelity risk — the canonical copy stays put.)
2. **Relocate** — react_on_rails domain knowledge that lives only in `.agents/` (Pro
   license rules, RSC/Shakapacker examples). Move it into react_on_rails's `AGENTS.md`; the
   shared file keeps the **general principle** plus a pointer. The repo-specific example
   moves home; the portable principle stays.
3. **Parameterize** — exact tokens (branch, label, command, path). The shared file
   references them via the named config section, which lists them verbatim per repo.

## Shared vs repo-local skills

The subtree is all-or-nothing for the `.agents/` prefix, so genuinely repo-specific skills
must not live in the shared upstream.

- **Shared (portable)**: `pr-batch`, `plan-pr-batch`, `plan-issue-triage`, `triage`,
  `evaluate-issue`, `post-merge-audit`, `adversarial-pr-review`, `autoreview`,
  `address-review`, `verify`, `verify-pr-fix`, `run-ci`, `update-changelog`; workflows
  `pr-processing`, `post-merge-audit`, `adversarial-pr-review`, `address-review`,
  `continuous-evaluation-loop`, `evaluate-issue`.
- **Repo-local (react_on_rails only)**: `stress-test` — a destructive demo-workspace QA
  pass for RSC/SSR/framework leakage. Not shared-library material. In Phase 2 it is
  relocated out of the shared subtree and kept react_on_rails-local; the shared upstream
  excludes it. (Adopters with no equivalent simply never receive it.)

## Keeping it updated

- **`.agents/UPSTREAM`** — marker recording the upstream SHA/tag last synced, so a repo's
  workflow version is visible at a glance. (Phase 2, once the vendoring relationship is
  real.)
- **`bin/agent-workflows-sync`** — wrapper: `git subtree pull --squash`, then the
  validation gate (markdown format + link check + skill `bin/` tests + dry-run), then
  updates the marker.
- **Vendored banner** — `.agents/README.md` states "vendored from shakacode/agent-workflows;
  edit upstream, never here," preventing the #1 failure mode (local edits → pull conflicts).
- _(Optional, later)_ a consumer CI check that fails if `.agents/` diverges from the pinned
  upstream SHA. Robust but heavier; deferred.

## Fidelity preservation

The risk is that genericizing loses precision an agent depends on. Mitigations:

- The canonical values stay in `AGENTS.md`, which is always loaded — de-duplication, not
  deletion.
- Workflow **structure/procedure** is kept verbatim; only literal command/label/branch
  tokens become named-section references.
- The named config section is the single, auditable resolution point.

**Dry-run gate (the proof):** after the refactor, an agent runs a real pr-processing /
pr-batch pass in react_on_rails and must resolve the same commands, labels, and policy as
before. If it cannot, the `AGENTS.md` config section is incomplete and is fixed. This turns
"fidelity" into a pass/fail test rather than a worry.

Residual, bounded losses (accepted): a skill read in isolation without `AGENTS.md` is less
self-contained (mitigated: skills already instruct following `AGENTS.md`, the entry point);
prose that wove a specific example into a general point keeps a generic example, with the
repo-specific one in `AGENTS.md`.

## Phasing

1. **Phase 1 (this repo, one PR — reversible):** make the shared `.agents/` set
   repo-agnostic (the three transforms), add the `## Agent Workflow Configuration` section
   to react_on_rails's `AGENTS.md`, rewrite the adoption guide for the subtree model
   (including the config-section template and shared-vs-local classification), and add
   `bin/agent-workflows-sync`. react_on_rails stays fully working; no subtree wiring yet.
2. **Phase 2 (irreversible — gated on approval):** create `shakacode/agent-workflows`,
   relocate `stress-test` out of the shared set, `git subtree split --prefix=.agents` to
   extract the shared `.agents/` with history into the new repo, re-vendor it back into
   react_on_rails as a subtree, add the `UPSTREAM` marker and vendored banner.
3. **Phase 3 (separate workspaces):** onboard `control-plane-flow`, `shakapacker`,
   `shakaperf` — each a PR that vendors `.agents/` and fills its `AGENTS.md` seam.

## Validation

- `pnpm start format.listDifferent` (Prettier) and `rake autofix` for formatting.
- `bin/check-links` (lychee) for markdown links.
- Skill `bin/` unit tests under `.agents/skills/**/bin/*-test.*` still pass.
- Dry-run fidelity gate (above).
