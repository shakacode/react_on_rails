# Starter provenance

The two applications were generated on 2026-09-03 and then reduced to the same stateful React page. Generator output is committed rather than downloaded during benchmark execution.

## React on Rails + Rspack

```bash
rails _8.1.3_ new starters/rspack --skip-bundle --skip-git --skip-test --skip-system-test --skip-active-record --skip-action-mailer --skip-action-mailbox --skip-active-job --skip-active-storage --skip-javascript --skip-hotwire --skip-jbuilder --skip-kamal --skip-docker --skip-ci
cd starters/rspack
bin/rails generate react_on_rails:install --typescript --rspack --ignore-warnings --no-agent-files --force
```

Post-generation alignment:

- pinned Rails 8.1.3, React on Rails 17.0.1, React 19.0.4, and react-dom 19.0.4;
- pinned `rack-proxy < 1.0` because Shakapacker 10.3.0's development proxy uses the pre-1.0 dynamic-backend API;
- replaced the example component with the matched marker/input page and made it the root route;
- removed generated credentials, repository-level CI metadata, and nested lint configuration from the embedded fixture.

## Inertia Rails + Vite

```bash
rails _8.1.3_ new starters/vite --skip-bundle --skip-git --skip-test --skip-system-test --skip-active-record --skip-action-mailer --skip-action-mailbox --skip-active-job --skip-active-storage --skip-javascript --skip-hotwire --skip-jbuilder --skip-kamal --skip-docker --skip-ci
cd starters/vite
bin/rails generate inertia:install --framework=react --typescript --package-manager=pnpm --no-interactive --no-tailwind --vite --example-page
```

Post-generation alignment:

- pinned Rails 8.1.3, Inertia Rails 3.22.0, React 19.0.4, and react-dom 19.0.4;
- aligned the generated Node TypeScript project with its generated `vite.config.mts` filename;
- replaced the example page with the matched marker/input page and made it the root route;
- removed generated credentials and nested lint configuration from the embedded fixture.

Both applications retain the normal generated `bin/dev` and bundler configuration. Their lockfiles, not semver ranges in generated package manifests, define the versions measured by a recorded run.
