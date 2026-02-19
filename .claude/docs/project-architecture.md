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

## `.client` and `.server` File Suffixes vs. RSC Directive (Important Distinction)

React on Rails has two **independent** classification systems that both use "client" / "server" terminology. Confusing them is a common mistake.

### Bundle Placement: `.client.` / `.server.` file suffixes

A React on Rails auto-bundling feature that controls which **webpack bundle** imports a file. This exists independently of React Server Components and is used with or without RSC:

- `Component.client.jsx` → client bundle only (browser)
- `Component.server.jsx` → server bundle (and RSC bundle when RSC enabled). Must have a paired `.client.` file.
- `Component.jsx` (no suffix) → both bundles

This is purely about source file routing. A `.server.jsx` file is NOT a React Server Component.

### RSC Classification: `'use client'` directive

The `'use client'` directive is part of the React Server Components architecture. It marks a component as a React Client Component (one that can use hooks, state, event handlers, and browser APIs). Components without this directive are treated as React Server Components.

When auto-bundling is enabled with RSC support (Pro feature), React on Rails uses this directive to control multiple things:

- **Registration**: Components with `'use client'` are registered via `ReactOnRails.register()`. Components without it are registered via `registerServerComponent()`.
- **RSC bundling**: The RSC webpack loader uses this directive to decide whether a component is included in the RSC bundle or replaced with a client reference in that bundle.

The `client_entrypoint?` method in `packs_generator.rb` is what detects this directive during auto-bundling.

### How They Interact

These are orthogonal concerns. The file suffix controls which bundle, and the directive controls RSC registration:

| File             | `'use client'`? | Goes into                    | Registered as    |
| ---------------- | --------------- | ---------------------------- | ---------------- |
| `Foo.jsx`        | Yes             | Both bundles                 | Client component |
| `Foo.jsx`        | No              | Both bundles                 | Server component |
| `Foo.client.jsx` | Yes             | Client bundle                | Client component |
| `Foo.client.jsx` | No              | Client bundle                | Server component |
| `Foo.server.jsx` | Yes             | Server bundle (+ RSC bundle) | Client component |
| `Foo.server.jsx` | No              | Server bundle (+ RSC bundle) | Server component |

In practice, paired `.client.`/`.server.` files should always have matching `'use client'` status because the client and server must agree on a component's RSC role for hydration to work.

### Key code paths in `packs_generator.rb`

- `common_component_to_path` — finds files without `.client.`/`.server.` suffix
- `client_component_to_path` — finds `.client.` files
- `server_component_to_path` — finds `.server.` files (requires a paired `.client.`)
- `client_entrypoint?` — checks for `'use client'` directive (RSC classification)
- `pack_file_contents` — generates different registration code based on `client_entrypoint?`

## Examples and Testing

- **Dummy app**: `react_on_rails/spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Development tasks in `react_on_rails/rakelib/`; monorepo-level tasks in root `rakelib/`
