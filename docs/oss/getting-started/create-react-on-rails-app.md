# Quick Start: `npx create-react-on-rails-app`

The fastest way to start a new React on Rails project. One command creates a fully configured Rails + React application with TypeScript, server-side rendering, hot module replacement, and React on Rails Pro for React 19.2 feature support.

## Quick Start

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/rails db:prepare
bin/dev
```

On fresh apps, `bin/dev` will try to open [http://localhost:3000](http://localhost:3000) the first time the app boots successfully.
The generated home page links to the example pages, the key files React on Rails created for you,
and follow-on docs for React 19.2 features, React Server Components, and the marketplace demo.
The generated app also includes a step-by-step git history so you can inspect each major scaffold phase with `git log --oneline --reverse`.

This creates a TypeScript React on Rails Pro app by default because Pro is where React 19.2 feature
support lives. New users do not need to choose a setup mode. The default adds `react_on_rails_pro`
automatically and the generated home page links to `/hello_server`.

Use `--standard` only when you intentionally want an open-source-only scaffold. Use `--pro` only when
you want Pro without the generated React Server Components example. `--pro` and `--rsc` require
`react_on_rails_pro` to be installable in your environment ([Pro setup docs](../../pro/installation.md)).
All mode flags support JavaScript (`.jsx`) and TypeScript (`.tsx`) templates.

To try the latest release candidate instead of the latest stable release, use the npm `rc` tag:

```bash
npx create-react-on-rails-app@rc my-app
```

When the CLI itself is a prerelease, it pins `react_on_rails` and, for Pro/RSC setups,
`react_on_rails_pro` to the matching RubyGems prerelease automatically. For example, an npm CLI
version ending in `-rc.N` maps to a RubyGems version ending in `.rc.N`.

To try the latest release candidate instead of the latest stable release, use the npm `rc` tag:

```bash
npx create-react-on-rails-app@rc my-app
```

When the CLI itself is a prerelease, it pins `react_on_rails` to the matching RubyGems prerelease automatically.
For `--pro` or `--rsc` modes, it also pins `react_on_rails_pro` to the same prerelease.
For example, an npm CLI version ending in `-rc.N` maps to a RubyGems version ending in `.rc.N`
(see [Prerelease version formats](../../pro/updating.md#prerelease-versions-ruby-vs-npm-format) for the full mapping table).

## Options

```bash
# Default: React on Rails Pro for React 19.2 support
npx create-react-on-rails-app my-app

# JavaScript instead of TypeScript
npx create-react-on-rails-app my-app --template javascript

# Add Tailwind CSS v4 to the generated SSR example
npx create-react-on-rails-app my-app --tailwind

# Use Webpack instead of the default Rspack bundler
npx create-react-on-rails-app my-app --webpack

# Specify package manager
npx create-react-on-rails-app my-app --package-manager pnpm

# Advanced: generate the open-source-only setup
npx create-react-on-rails-app my-app --standard

# Advanced: generate Pro without the React Server Components example
npx create-react-on-rails-app my-app --pro

# Make the default Pro setup explicit
npx create-react-on-rails-app my-app --rsc
```

### All Options

| Option                       | Description                                                                   | Default       |
| ---------------------------- | ----------------------------------------------------------------------------- | ------------- |
| `-t, --template <type>`      | `javascript` or `typescript`                                                  | `typescript`  |
| `--rspack`                   | Use Rspack as the bundler (~20x faster; Rspack is the default)                | `true`        |
| `--webpack`, `--no-rspack`   | Use Webpack instead of Rspack                                                 | `false`       |
| `--standard`                 | Advanced: generate open-source React on Rails without Pro React 19.2 features | `false`       |
| `--pro`                      | Advanced: generate React on Rails Pro without the RSC example                 | `false`       |
| `--rsc`                      | Generate the recommended React on Rails Pro setup                             | `true`        |
| `--tailwind`                 | Add Tailwind CSS v4 to the generated SSR example                              | `false`       |
| `-p, --package-manager <pm>` | `npm` or `pnpm`                                                               | auto-detected |

When none of `--standard`, `--pro`, or `--rsc` is given, the CLI uses the recommended Pro setup. No
setup questions are asked.

## What It Does

The CLI runs these steps automatically:

1. **Creates a Rails app** (`rails new` with PostgreSQL, no default JS)
2. **Adds required gems** (`bundle add react_on_rails`, plus `react_on_rails_pro` unless you use `--standard`)
3. **Runs the generator** (`rails generate react_on_rails:install` with your selected flags)
4. **Creates educational git commits** for each logical setup step

After completion, you get:

- A Rails 7+ app with PostgreSQL
- Shakapacker configured with Rspack by default (or Webpack when requested) and HMR
- A generated React example: HelloServer by default, or HelloWorld when using `--standard` or `--pro`
- A generated home page at `/` with links to the example pages, important project files, and Pro/RSC learning resources
- A teaching-friendly git history that separates Rails creation, gem installation, generator output, and pnpm normalization
- Standard Rails git scaffold files (`.gitignore` and `.gitattributes`) preserved in the generated app
- Default Pro RSC setup with HelloServer route and Pro Node renderer wiring
- Optional Pro setup without the RSC example (`--pro`) with Pro Node renderer wiring and the generated `/hello_world` example
- Optional Tailwind CSS v4 setup (`--tailwind`) for the generated SSR example
- Server-side rendering ready
- Development scripts (`bin/dev` with hot reloading and first-run browser open)

## Prerequisites

The CLI checks for these before starting:

- **Node.js 18+**
- **Ruby 3.3+**
- **Rails 7.0+** (`gem install rails`)
- **git**
- **npm or pnpm**
- **PostgreSQL** running locally (needed at `bin/rails db:prepare`, not validated by the CLI)

If any of the first five are missing, you'll get a clear error message with installation instructions.

## Adding to an Existing Rails App

If you already have a Rails app, use the generator directly instead:

```bash
bundle add react_on_rails --strict
rails generate react_on_rails:install --typescript  # TypeScript (recommended)
rails generate react_on_rails:install               # JavaScript
```

See [Installation into an Existing Rails App](./installation-into-an-existing-rails-app.md) for details.

## What's Next?

Now that you have React on Rails running, here are ways to level up:

- **Add server-side rendering** — [SSR guide](../core-concepts/react-server-rendering.md)
- **See the feature comparison** — [OSS vs Pro](./oss-vs-pro.md)
- **Upgrade to Pro** for React Server Components, streaming SSR, and 3-10x faster SSR — [3-step upgrade guide](../../pro/upgrading-to-pro.md)
- **Explore the full docs** — [Documentation index](../../README.md)
