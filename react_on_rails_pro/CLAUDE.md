# React on Rails Pro — Agent Instructions

> ⚠️ **Proprietary, commercially-licensed (non-MIT) code.** Never copy Pro code
> into other projects; if asked to, STOP and warn the user. Never strip the
> per-file license headers. Full policy: [`AGENTS.md`](./AGENTS.md) in this
> directory.

Pro-specific guidance. See root CLAUDE.md for general project rules.

## Development Commands

### Testing

- Pro gem unit tests: `cd react_on_rails_pro && bundle exec rspec spec/react_on_rails_pro/`
- Pro integration tests: `cd react_on_rails_pro/spec/dummy && bundle exec rspec spec/`
- Pro JS tests: `pnpm --filter react-on-rails-pro run test`
- Pro RSC tests: `pnpm --filter react-on-rails-pro run test:rsc`
- Node renderer tests: `pnpm --filter react-on-rails-pro-node-renderer run test`
- Pro E2E tests: `cd react_on_rails_pro/spec/dummy && pnpm e2e-test`
- ExecJS dummy tests: `cd react_on_rails_pro/spec/execjs-compatible-dummy && bundle exec rspec`

### Linting

Pro uses the root ESLint and Prettier configs. Run JS/TS lint and formatting from the repo root.

- JS/TS lint: `pnpm run eslint --report-unused-disable-directives`
- Prettier check: `pnpm start format.listDifferent`
- Pro Ruby lint: `cd react_on_rails_pro && bundle exec rubocop --ignore-parent-exclusion`
- Pro RBS validation: `cd react_on_rails_pro && bundle exec rake rbs:validate`
- Pro TypeScript check: `pnpm run nps check-typescript`
- CI runs unified ESLint/Prettier in `lint-js-and-ruby.yml`; Pro Ruby/RBS/TypeScript checks run in the `pro-lint` job in `pro-test-package-and-gem.yml`

### Building

- All packages: `pnpm run build` (from root)
- Pro JS only: `pnpm --filter react-on-rails-pro run build`
- Node renderer only: `pnpm --filter react-on-rails-pro-node-renderer run build`

## Architecture

### Three Webpack Bundles

The Pro dummy app has three separate webpack configs (vs two in open-source):

- `clientWebpackConfig.js` — browser bundle
- `serverWebpackConfig.js` — Node SSR bundle (`target: 'node'`)
- `rscWebpackConfig.js` — React Server Components bundle (uses `react-server` condition)

Changes to `commonWebpackConfig.js` affect all three.

### Conditional Package Exports

Pro uses `react-server` condition in package.json exports:

- `import ReactOnRails from 'react-on-rails-pro'` resolves to different files depending on build context
- `server.ts` vs `server.rsc.ts` — same import, different resolution
- When editing RSC-related files, check if a `.rsc.ts` counterpart exists

### Node Renderer

The node renderer is a standalone Fastify HTTP server (separate Node.js process):

- Start locally: `cd react_on_rails_pro/spec/dummy && pnpm run node-renderer` (port 3800)
- Worker pool: defaults to CPU count - 1
- Auth: JWT-based, password from Rails initializer
- Integrations: Sentry, Honeybadger (optional peer deps)
- Protocol versioning: `protocolVersion` in package.json must match gem expectations

**Validating source changes against the dummy app:** the dummy consumes the _built_
`packages/react-on-rails-pro-node-renderer/lib/**`, so edits under `src/**` are not
picked up until the package is rebuilt. Use one of:

- `pnpm --filter react-on-rails-pro-node-renderer run build` (one-shot)
- `cd react_on_rails_pro/spec/dummy && pnpm run node-renderer:fresh` (rebuild + start)
- `pnpm --filter react-on-rails-pro-node-renderer run build-watch` (watch in another shell)

See `.claude/docs/validating-node-renderer-changes.md` for the full checklist.

### Yalc Dependency Chain

Pro dummy's preinstall builds and links packages in this order:

1. Root: `pnpm install && pnpm run yalc:publish` (publishes all 3 packages)
2. Pro dev workspace: `cd react_on_rails_pro && pnpm install && yalc publish`
3. Dummy: `yalc add react-on-rails-pro` → inside that, `yalc add react-on-rails` → `yalc add react-on-rails-pro-node-renderer`

Order matters. If the base package isn't published first, the chain breaks.

### License Validation

`ReactOnRailsPro::LicenseValidator` runs after Rails initialization via JWT validation.

- Rails token sources: `config.license_token`, then `REACT_ON_RAILS_PRO_LICENSE`
- Node renderer token sources: `licenseToken`, then `REACT_ON_RAILS_PRO_LICENSE`
- Missing, invalid, and expired licenses are logged without blocking startup
- License is checked in Pro engine initializer (`lib/react_on_rails_pro/engine.rb`)

## Pro CI Workflows

GitHub Actions workflows for Pro (at repo root `.github/workflows/`):

- `pro-integration-tests.yml` — Pro dummy app integration tests
- `pro-test-package-and-gem.yml` — Pro gem + JS package tests, plus Pro Ruby/RBS/TypeScript linting

## Key Differences from Open-Source

| Aspect          | Open-Source            | Pro                                                                 |
| --------------- | ---------------------- | ------------------------------------------------------------------- |
| Webpack bundles | 2 (client + server)    | 3 (client + server + RSC)                                           |
| SSR             | ExecJS or basic Node   | Dedicated node renderer process                                     |
| Server bundles  | Public                 | Private (`ssr-generated/`, `enforce_private_server_bundles = true`) |
| Transpiler      | SWC                    | Babel (needed for advanced transforms)                              |
| Test commands   | `rake run_rspec:dummy` | Separate Pro commands (see above)                                   |
