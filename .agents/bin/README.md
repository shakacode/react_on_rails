# Agent Workflow Scripts

Standard entry points that portable agent-workflow skills call, so a skill can
run `.agents/bin/<name>` in any repo without knowing this repo's specific
commands. Each script is a thin, repo-owned wrapper. The scripts listed below
are required for this repo's portable contract; capabilities without a listed
script are n/a here.

| Script      | Purpose                                      | This repo runs                                                                                                     |
| ----------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `setup`     | Install dependencies                         | `bin/setup`                                                                                                        |
| `validate`  | Pre-push gate (`--changed`/`--all`/`--fast`) | `bin/ci-local`                                                                                                     |
| `test`      | Run tests                                    | `(cd react_on_rails && bundle exec rake run_rspec:all_but_examples)` (includes JS tests via rake dependency)       |
| `lint`      | Lint / format (`rake autofix` to fix)        | `(cd react_on_rails && bundle exec rake lint)` + Pro RuboCop + `pnpm run lint` + `pnpm start format.listDifferent` |
| `build`     | Build / type-check                           | `pnpm run build` + `pnpm run type-check` + OSS and Pro RBS validation when present                                 |
| `docs`      | Docs checks                                  | `script/check-docs-sidebar` + `bin/check-links`                                                                    |
| `ci-detect` | CI change detector                           | `script/ci-changes-detector [base-ref]` (default `origin/main`)                                                    |

`validate` intentionally delegates base discovery to `bin/ci-local`; do not pass
a normal `<base-ref>` argument. See
[`internal/contributor-info/local-ci-contract.md`](../../internal/contributor-info/local-ci-contract.md)
for the local CI contract.

Additional helper:

- `shared-skill-dir <skill-name>` resolves a skill directory from an explicit
  repo-local skill override or repo-pinned helper `bin/` copy first, then
  `$AGENT_WORKFLOWS_ROOT`, installed Codex or Claude skills, or finally
  `$HOME/src/agent-workflows`. Use it when a workflow needs a helper script from
  a shared skill without keeping duplicate local `SKILL.md` copies.
- `agent-workflow-drift-manifest-test.rb --source-root <pinned-agent-workflows>`
  verifies that `.agents/agent-workflow-drift.yml` covers every required file
  and governed source prefix, with only the reviewed source-only exclusions.
  Required CI runs it before the pinned source pack's content/mode drift checker.

Non-command policy lives in [`../agent-workflow.yml`](../agent-workflow.yml).
Workflow-specific checks such as `actionlint` and `yamllint .github/` stay in the
PR-processing workflow for `.github/**` changes rather than the general build entrypoint.
