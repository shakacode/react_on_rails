# Agent Workflow Adoption

React on Rails uses [Shaka](https://github.com/shakacode/shaka)'s versioned
repository contract, which lives in
[`.agents/agent-workflow.yml`](../../.agents/agent-workflow.yml).

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

## Retired Agent Workflows Content

React on Rails no longer syncs files from `shakacode/agent-workflows`. The
drift manifest and its pinned-pack CI check are gone. Vendored pack copies still
in `.agents/` are no longer verified against upstream; follow-up PRs remove
them together with their remaining callers.

Until then, treat `.agents/docs/*.md` and `.agents/workflows/*.md` as historical.
Their instructions to run `.agents/bin/agent-workflow-drift-manifest-test.rb`,
`check-agent-workflow-drift`, or `.agents/agent-workflow-drift.yml` describe the
retired drift check and no longer apply.

## Validation

- `shaka seam check --root . --local`
- `SHAKA_COMMAND=<pinned-shaka>/skills/shaka/scripts/shaka ruby script/shaka_seam_check_test.rb`
- Markdown formatting and link checks for edited documentation
