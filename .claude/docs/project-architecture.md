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

The root `package.json` uses `pnpm.overrides` to enforce a single React version
across the workspace while carving out an exception for React 18 testing:

```json
"react": "$react",
"react-dom": "$react-dom",
"app>react": "^18.3.1",
"app>react-dom": "^18.3.1"
```

**How it works**:

- `"react": "$react"` — Global override forcing all React to `^19.0.3`
  (the root `devDependencies.react` version). Ensures single-copy resolution.
- `"app>react": "^18.3.1"` — Exception for the `app` package (the execjs-compatible
  dummy at `react_on_rails_pro/spec/execjs-compatible-dummy`), pinning it to React 18.
  The `>` selector targets a specific package by its `name` field.

**Why global + exception**: A global override is needed because pnpm workspace members
with peer deps (like `packages/react-on-rails`) would otherwise get their own
`node_modules/react` copy, causing dual-resolution failures in webpack builds.

**Fragility note**: The `app>` exception selector is coupled to the `name` field in
`react_on_rails_pro/spec/execjs-compatible-dummy/package.json`. If that name changes,
the exception silently stops working. CI guards (`script/check-react-major-version.mjs`)
will catch version mismatches.

## Examples and Testing

- **Dummy app**: `react_on_rails/spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Development tasks in `react_on_rails/rakelib/`; monorepo-level tasks in root `rakelib/`
