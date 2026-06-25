# Quick Start: `npx create-react-on-rails-app`

The fastest way to start a new React on Rails project. One command creates a fully configured Rails + React application with TypeScript, server-side rendering, hot module replacement, and, optionally, React Server Components (RSC).

## Quick Start

```bash
npx create-react-on-rails-app my-app
cd my-app
bin/rails db:prepare
bin/dev
```

On fresh apps, `bin/dev` will try to open [http://localhost:3000](http://localhost:3000) the first time the app boots successfully.
The generated home page links to the example pages, the key files React on Rails created for you,
and follow-on docs for OSS vs Pro, React Server Components, and the marketplace demo.
The generated app also includes a step-by-step git history so you can inspect each major scaffold phase with `git log --oneline --reverse`.

When no `--pro` or `--rsc` flag is given, the CLI prompts you to choose a setup mode:

1. **Standard** — open-source React on Rails with SSR
2. **Pro** — adds Node.js server rendering (requires `react_on_rails_pro`)
3. **RSC** — React Server Components (requires `react_on_rails_pro`) _(recommended, default)_

The default choice is RSC. Press Enter to accept it, or type `1` or `2` to pick a different mode.
In non-interactive environments (CI, pipes), standard mode is used automatically.
When the mode prompt is shown, the CLI also asks whether to add Tailwind CSS v4 to the generated SSR example.

To skip the prompt, pass `--standard`, `--pro`, or `--rsc` explicitly.
All mode flags support JavaScript (`.jsx`) and TypeScript (`.tsx`) templates.
`--pro` and `--rsc` require `react_on_rails_pro` to be installable in your environment
([Pro setup docs](../../pro/installation.md)).

## Options

```bash
# Prompts for mode (Standard / Pro / RSC), defaults to RSC
npx create-react-on-rails-app my-app

# Skip prompt — use RSC directly
npx create-react-on-rails-app my-app --rsc

# Skip prompt — use Pro directly
npx create-react-on-rails-app my-app --pro

# Skip prompt — use Standard (open-source) directly
npx create-react-on-rails-app my-app --standard

# JavaScript instead of TypeScript
npx create-react-on-rails-app my-app --template javascript

# Add Tailwind CSS v4 to the generated SSR example
npx create-react-on-rails-app my-app --tailwind

# Use Webpack instead of the default Rspack bundler
npx create-react-on-rails-app my-app --webpack

# Specify package manager
npx create-react-on-rails-app my-app --package-manager pnpm

# Combine RSC with Webpack
npx create-react-on-rails-app my-app --rsc --webpack
```

### All Options

| Option                       | Description                                                    | Default                  |
| ---------------------------- | -------------------------------------------------------------- | ------------------------ |
| `-t, --template <type>`      | `javascript` or `typescript`                                   | `typescript`             |
| `--rspack`                   | Use Rspack as the bundler (~20x faster)                        | `true`                   |
| `--webpack`, `--no-rspack`   | Use Webpack instead of Rspack                                  | `false`                  |
| `--standard`                 | Use open-source React on Rails (skip prompt)                   | `false`                  |
| `--pro`                      | Enable React on Rails Pro (requires `react_on_rails_pro`)      | `false`                  |
| `--rsc`                      | Enable React Server Components (requires `react_on_rails_pro`) | `false`                  |
| `--tailwind`                 | Add Tailwind CSS v4 to the generated SSR example               | prompt with mode/`false` |
| `-p, --package-manager <pm>` | `npm` or `pnpm`                                                | auto-detected            |

When none of `--standard`, `--pro`, or `--rsc` is given, the CLI prompts interactively in TTY environments (default: RSC). In non-TTY environments (CI, pipes, redirected output), standard mode is used automatically.
When `--tailwind` is omitted, Tailwind is prompted only alongside the mode prompt and disabled otherwise.

## What It Does

The CLI runs these steps automatically:

1. **Creates a Rails app** (`rails new` with PostgreSQL, no default JS)
2. **Adds required gems** (`bundle add react_on_rails`, plus `react_on_rails_pro` for `--pro` / `--rsc`)
3. **Runs the generator** (`rails generate react_on_rails:install` with your selected flags)
4. **Creates educational git commits** for each logical setup step

After completion, you get:

- A Rails 7+ app with PostgreSQL
- Shakapacker configured with Rspack by default (or Webpack when requested) and HMR
- A working HelloWorld React component (TypeScript by default)
- A generated home page at `/` with links to the example pages, important project files, and Pro/RSC learning resources
- A teaching-friendly git history that separates Rails creation, gem installation, generator output, and pnpm normalization
- Standard Rails git scaffold files (`.gitignore` and `.gitattributes`) preserved in the generated app
- Optional Pro setup (`--pro`) with Pro Node renderer wiring and the generated `/hello_world` example
- Optional RSC setup (`--rsc`) with HelloServer route and Pro Node renderer wiring
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
