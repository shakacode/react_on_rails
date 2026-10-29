# Agent Workflow Adoption

React on Rails uses [Shaka](https://github.com/shakacode/shaka)'s versioned
repository contract, which lives in `.agents/shaka/config.yml`.

## Current Boundary

- Install Shaka from a trusted source outside the consumer checkout.
- Initialize or migrate the fixed command wrappers under `.agents/shaka/bin/` with
  `shaka seam init`.
- Validate candidate bytes with `shaka seam check --root . --local`. This mode
  grants neither policy nor merge authority.
- Load workflow policy only from an immutable default-branch commit with
  `shaka seam check --root . --ref <sha>`.
- Keep human-only repository policy in `AGENTS.md` and actor trust in
  `.agents/shaka/trusted-github-actors.yml`.

React on Rails required CI checks out `shakacode/shaka` at an immutable reviewed
commit, runs the candidate validator, and exercises
`script/shaka_seam_check_test.rb` against valid and invalid consumer fixtures.
Do not copy Shaka's schema, key lists, or defaults into this repository.

## Retired Agent Workflows Content

React on Rails no longer uses `shakacode/agent-workflows`. The drift manifest,
its pinned-pack CI check, and the vendored workflow, doc, and helper copies are
gone, and so is the `agent-coord` coordination backend those copies relied on. The one
helper React on Rails still needs is repo-owned:
`.agents/skills/react-on-rails-update-changelog/bin/changelog-merged-prs`.

## What Retires And What Replaces It

| Retired agent-workflows item                                                      | Replacement                                                                                                | Not replaced                                                                                                    |
| --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `pr-processing` workflow                                                          | Shaka delivery (`/shaka`): claim, validation, local review, publication, merge decision                    | Nothing                                                                                                         |
| `address-review` skill and workflow                                               | Shaka review phase: trusted `comments`, `reply`, `resolve`                                                 | Nothing                                                                                                         |
| `adversarial-pr-review` skill and workflow                                        | Shaka local adversarial review (`shaka review run`)                                                        | Nothing                                                                                                         |
| `tdd` workflow, `verify-pr-fix` skill                                             | Shaka implement rule: reproduce first, smallest fix, rerun the same check                                  | Separate evidence-posting flow for manual fix verification                                                      |
| `evaluate-issue` skill and workflow                                               | Shaka value checkpoint plus `internal/contributor-info/issue-evaluation.md`                                | Nothing                                                                                                         |
| `update-changelog` skill                                                          | Repo-local `$react-on-rails-update-changelog`; a follow-up PR extends it from release branches to mainline | Nothing                                                                                                         |
| `pr-batch`, `plan-pr-batch` skills and their helpers                              | Shaka control towers (`$rct`, `$mct`) select work and start one Shaka delivery per task                    | Batch goal prompts, Sol/Terra model routing, batch cancellation protocol, file-touch maps, dispatcher preflight |
| `plan-issue-triage`, `triage` skills                                              | None                                                                                                       | Review-only all-issue audits and generated dependency graphs                                                    |
| `post-merge-audit` skill, `closeout-evidence-replay`                              | Shaka reviews-after-merge for each merged PR                                                               | Cross-PR batch audits and `qa-evidence` marker replay                                                           |
| `continuous-evaluation-loop` workflow                                             | None                                                                                                       | Recurring evaluation loop                                                                                       |
| `pr-security-preflight --strict-trust`                                            | Shaka trusted-actor filtering of public comments, plus the `AGENTS.md` trust rules                         | Pre-launch trust check of assigned issue and PR targets                                                         |
| Drift manifest and pinned-pack CI check                                           | Shaka seam validation in required CI                                                                       | Nothing; the copies are gone                                                                                    |
| `codex-claim` public comment fallback                                             | Shaka `claim`, as advisory evidence                                                                        | Nothing                                                                                                         |
| `agent-coord` backend, `agent-coord-bounded`, release-line lease, published phase | Shaka `claim`; phase from the target branch and tracker mode; one active release lane at a time            | Cross-machine claims, heartbeats, and batch cancellation state                                                  |

## Validation

- `shaka seam check --root . --local`
- `SHAKA_COMMAND=<pinned-shaka>/skills/shaka/scripts/shaka ruby script/shaka_seam_check_test.rb`
- Markdown formatting and link checks for edited documentation
