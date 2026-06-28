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
| `build`     | Build / type-check                           | `pnpm run build` + `pnpm run type-check` + `(cd react_on_rails && bundle exec rake rbs:validate)`                  |
| `docs`      | Docs checks                                  | `script/check-docs-sidebar` + `bin/check-links`                                                                    |
| `ci-detect` | CI change detector                           | `script/ci-changes-detector [base-ref]` (default `origin/main`)                                                    |

Non-command policy lives in [`../agent-workflow.yml`](../agent-workflow.yml).
Workflow-specific checks such as `actionlint` and `yamllint .github/` stay in the
PR-processing workflow for `.github/**` changes rather than the general build entrypoint.
