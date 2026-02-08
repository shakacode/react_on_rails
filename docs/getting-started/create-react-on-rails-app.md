# create-react-on-rails-app

The fastest way to start a new React on Rails project. One command creates a fully configured Rails + React application with TypeScript, server-side rendering, and hot module replacement.

## Quick Start

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/dev
```

Visit [http://localhost:3000/hello_world](http://localhost:3000/hello_world) to see your React component.

This creates a TypeScript app by default. For JavaScript, use `--template javascript`.

## Options

```bash
# JavaScript instead of TypeScript
npx create-react-on-rails-app my-app --template javascript

# Use Rspack for ~20x faster builds
npx create-react-on-rails-app my-app --rspack

# Specify package manager
npx create-react-on-rails-app my-app --package-manager pnpm

# Combine options
npx create-react-on-rails-app my-app --rspack --package-manager pnpm
```

### All Options

| Option                       | Description                                 | Default       |
| ---------------------------- | ------------------------------------------- | ------------- |
| `-t, --template <type>`      | `javascript` or `typescript`                | `typescript`  |
| `--rspack`                   | Use Rspack instead of Webpack (~20x faster) | `false`       |
| `-p, --package-manager <pm>` | `npm` or `pnpm`                             | auto-detected |
| `--skip-install`             | Skip dependency installation                | `false`       |

## What It Does

The CLI runs these steps automatically:

1. **Creates a Rails app** (`rails new` with PostgreSQL, no default JS)
2. **Adds React on Rails** (`bundle add react_on_rails`)
3. **Runs the generator** (`rails generate react_on_rails:install`)

After completion, you get:

- A Rails 8 app with PostgreSQL
- Shakapacker configured with Webpack (or Rspack) and HMR
- A working HelloWorld React component (TypeScript by default)
- Server-side rendering ready
- Development scripts (`bin/dev` with hot reloading)

## Prerequisites

The CLI checks for these before starting:

- **Node.js 18+**
- **Ruby 3.0+**
- **Rails** (`gem install rails`)
- **npm or pnpm**

If any are missing, you'll get a clear error message with installation instructions.

## Adding to an Existing Rails App

If you already have a Rails app, use the generator directly instead:

```bash
bundle add react_on_rails --strict
rails generate react_on_rails:install --typescript  # TypeScript (recommended)
rails generate react_on_rails:install               # JavaScript
```

See [Installation into an Existing Rails App](./installation-into-an-existing-rails-app.md) for details.
