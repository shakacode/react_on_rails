# Project Architecture

## Monorepo Structure

This is a monorepo containing both the open-source package and the Pro package:

- **Open Source**: Root directory contains the main React on Rails gem and package
- **Pro Package**: `react_on_rails_pro/` contains the Pro features (separate linting/formatting config). See `react_on_rails_pro/CLAUDE.md` for Pro-specific development guidance.
- **Ruby gem**: Located in `react_on_rails/lib/`, provides Rails integration and server-side rendering
- **NPM package**: Located in `packages/react-on-rails/src/`, provides client-side React integration

**IMPORTANT**: The `react_on_rails_pro/` directory has its own Prettier/ESLint configuration. When CI runs, it lints both directories separately. The pre-commit hooks will catch issues in both directories.

## Core Components

### Ruby Side (`react_on_rails/lib/react_on_rails/`)

- **`helper.rb`**: Rails view helpers for rendering React components
- **`server_rendering_pool.rb`**: Manages Node.js processes for server-side rendering
- **`configuration.rb`**: Global configuration management
- **`engine.rb`**: Rails engine integration
- **Generators**: Located in `react_on_rails/lib/generators/react_on_rails/`

### JavaScript/TypeScript Side (`packages/react-on-rails/src/`)

- **`ReactOnRails.client.ts`**: Client-only entry point
- **`ReactOnRails.full.ts`**: Full entry point (client + server-side rendering support)
- **`serverRenderReactComponent.ts`**: Server-side rendering logic
- **`ComponentRegistry.ts`**: Manages React component registration
- **`StoreRegistry.ts`**: Manages Redux store registration

## Build System

- **Ruby**: Standard gemspec-based build
- **JavaScript**: TypeScript compilation to `packages/react-on-rails/lib/`
- **Testing**: Jest for JS, RSpec for Ruby
- **Linting**: ESLint for JS/TS, RuboCop for Ruby

## pnpm Workspace Overrides (React Version Pinning)

The root `package.json` uses `pnpm.overrides` with `>` selectors to force React 19
on specific dummy apps while allowing others to stay on React 18:

```json
"react_on_rails>react": "$react",
"react_on_rails_pro_dummy>react": "$react"
```

**How it works**: The selector `pkgName>dep` targets the dependency `dep` only when it
belongs to the workspace member whose `name` field matches `pkgName`. The `$react` token
resolves to the root `devDependencies.react` version (`^19.0.3`).

**Which packages are targeted**:
| Override selector | Workspace member | Directory |
|---|---|---|
| `react_on_rails` | `react_on_rails` | `react_on_rails/spec/dummy` |
| `react_on_rails_pro_dummy` | `react_on_rails_pro_dummy` | `react_on_rails_pro/spec/dummy` |

**Intentionally excluded**: `react_on_rails_pro/spec/execjs-compatible-dummy` (name=`app`)
keeps its declared React 18 to provide React 18 test coverage.

**Fragility note**: These selectors are coupled to the `name` field in each dummy app's
`package.json`. If a package name changes, the override silently stops applying. CI guards
(`script/check-react-major-version.mjs`) will catch version mismatches.

## Examples and Testing

- **Dummy app**: `react_on_rails/spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Development tasks in `react_on_rails/rakelib/`; monorepo-level tasks in root `rakelib/`
