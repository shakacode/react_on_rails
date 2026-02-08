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

## Examples and Testing

- **Dummy app**: `react_on_rails/spec/dummy/` - Rails app for testing integration
- **Examples**: Generated via rake tasks for different webpack configurations
- **Rake tasks**: Development tasks in `react_on_rails/rakelib/`; monorepo-level tasks in root `rakelib/`
