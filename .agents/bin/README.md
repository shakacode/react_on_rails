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

Shaka typed policy lives in [`../agent-workflow.yml`](../agent-workflow.yml).
Installed Shaka is the seam validator; required CI checks out an immutable
Shaka Git revision and runs `seam check --local` plus the consumer regression
fixtures in `script/shaka_seam_check_test.rb`. The byte-identical legacy doctor
and test live under `.agents/fixtures/agent-workflows/bin/`, outside this active
command directory, solely for transitional source-pack drift coverage.
Human-only React on Rails policy stays in `AGENTS.md`.

Local Shaka must support `review.local_review_count`, introduced in
[`da95d68`](https://github.com/shakacode/shaka/commit/da95d68fd8215ae9f789a03a8c9588fb6ccf15c9),
and run with Ruby 3.4 or newer. If an older installation rejects that key, follow
[Shaka's upgrade procedure](https://github.com/shakacode/shaka/blob/main/docs/migration.md)
before starting a new task, then run `shaka seam check --root . --local`.
The older `--ci-review-job` capability probe alone does not establish support for
this setting; keep the failed check visible until the installation is updated.

Workflow-specific checks such as `actionlint` and `yamllint .github/` stay in the
PR-processing workflow for `.github/**` changes rather than the general build entrypoint.
