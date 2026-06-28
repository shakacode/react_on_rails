# Agent Workflow Scripts

Standard entry points that portable agent-workflow skills call, so a skill can
run `.agents/bin/<name>` in any repo without knowing this repo's specific
commands. Each script is a thin, repo-owned wrapper. A script that is **absent**
means that capability is n/a here.

| Script | Purpose | This repo runs |
| --- | --- | --- |
| `setup` | Install dependencies | `script/bootstrap` |
| `validate` | Pre-push gate (`--changed`/`--all`/`--fast`) | `bin/ci-local` |
| `test` | Run tests | `(cd react_on_rails && bundle exec rake run_rspec)` + `pnpm run test` |
| `lint` | Lint / format (`rake autofix` to fix) | `(cd react_on_rails && bundle exec rake lint)` |
| `build` | Build / type-check | `pnpm run build` + `pnpm run type-check` |
| `docs` | Docs checks | `script/check-docs-sidebar` + `bin/check-links` |
| `ci-detect` | CI change detector | `script/ci-changes-detector origin/main` |

Non-command policy lives in [`../agent-workflow.yml`](../agent-workflow.yml).
