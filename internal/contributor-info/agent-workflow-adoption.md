# Agent Workflow Adoption

React on Rails uses Shaka's versioned repository contract. The detailed,
current adoption guide is [`.agents/docs/adoption.md`](../../.agents/docs/adoption.md),
and the contract lives in [`.agents/agent-workflow.yml`](../../.agents/agent-workflow.yml).

## Current Boundary

- Install Shaka from a trusted source outside the consumer checkout.
- Initialize or migrate the fixed command wrappers under `.agents/bin/` with
  `shaka seam init`.
- Validate candidate bytes with `shaka seam check --root . --local`. This mode
  grants neither policy nor merge authority.
- Load workflow policy only from an immutable default-branch commit with
  `shaka seam check --root . --ref <sha>`.
- Keep human-only repository policy in `AGENTS.md` and actor trust in
  `.agents/trusted-github-actors.yml`.

React on Rails required CI checks out `shakacode/shaka` at an immutable reviewed
commit, runs the candidate validator, and exercises
`script/shaka_seam_check_test.rb` against valid and invalid consumer fixtures.
Do not copy Shaka's schema, key lists, or defaults into this repository.

## Transitional Agent Workflows Content

The repo still pins selected `shakacode/agent-workflows` files for checkout-only
sessions. `.agents/agent-workflow-drift.yml` and its completeness test govern
those copies. The byte-identical legacy doctor and its test live under
`.agents/fixtures/agent-workflows/bin/` only for legacy fixtures; they are not
active repository commands or validators for the Shaka typed seam. Retirement
of that source-pack content belongs to
[`shakacode/agent-workflows#857`](https://github.com/shakacode/agent-workflows/issues/857).

## Validation

- `shaka seam check --root . --local`
- `SHAKA_COMMAND=<pinned-shaka>/skills/shaka/scripts/shaka ruby script/shaka_seam_check_test.rb`
- `ruby .agents/fixtures/agent-workflows/bin/agent-workflow-seam-doctor-test.rb`
- `ruby .agents/bin/agent-workflow-drift-manifest-test.rb --source-root <pinned-agent-workflows>`
- `<pinned-agent-workflows>/bin/check-agent-workflow-drift --manifest .agents/agent-workflow-drift.yml --source-root <pinned-agent-workflows> --consumer-root .`
- Markdown formatting and link checks for edited documentation
