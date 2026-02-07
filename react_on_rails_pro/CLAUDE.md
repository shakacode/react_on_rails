# React on Rails Pro — Agent Instructions

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

Pro has its **own** ESLint and Prettier configs (separate from root): `eslint.config.mjs`, `.prettierrc`, `.prettierignore`.

- Pro ESLint: `cd react_on_rails_pro && pnpm run eslint .`
- Pro Prettier check: `cd react_on_rails_pro && pnpm run prettier --check .`
- CI runs both root and Pro linting separately

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

### Yalc Dependency Chain

Pro dummy's preinstall builds and links packages in this order:

1. Root: `pnpm install && pnpm run yalc:publish` (publishes all 3 packages)
2. Pro dev workspace: `cd react_on_rails_pro && pnpm install && yalc publish`
3. Dummy: `yalc add react-on-rails-pro` → inside that, `yalc add react-on-rails` → `yalc add react-on-rails-pro-node-renderer`

Order matters. If the base package isn't published first, the chain breaks.

### License Validation

`ReactOnRailsPro::LicenseValidator` runs on engine startup via JWT validation.

- License key: `config/react_on_rails_pro_license.key` or `REACT_ON_RAILS_PRO_LICENSE` env var
- Expired licenses cause startup failures in dummy app
- License is checked in Pro engine initializer (`lib/react_on_rails_pro/engine.rb`)

## Pro CI Workflows

GitHub Actions workflows for Pro (at repo root `.github/workflows/`):

- `pro-integration-tests.yml` — Pro dummy app integration tests
- `pro-lint.yml` — Pro-specific linting
- `pro-test-package-and-gem.yml` — Pro gem + JS package tests

## Key Differences from Open-Source

| Aspect             | Open-Source            | Pro                                                                 |
| ------------------ | ---------------------- | ------------------------------------------------------------------- |
| Webpack bundles    | 2 (client + server)    | 3 (client + server + RSC)                                           |
| SSR                | ExecJS or basic Node   | Dedicated node renderer process                                     |
| Server bundles     | Public                 | Private (`ssr-generated/`, `enforce_private_server_bundles = true`) |
| Transpiler         | SWC                    | Babel (needed for advanced transforms)                              |
| Lint/format config | Root configs           | Own ESLint + Prettier configs                                       |
| Test commands      | `rake run_rspec:dummy` | Separate Pro commands (see above)                                   |
