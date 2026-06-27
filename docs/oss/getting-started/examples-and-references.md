# Examples and References

Use this page as the canonical index for public React on Rails reference repos. If you are starting a
new app, do not start by comparing example repos. Start with the CLI:

```bash
npx create-react-on-rails-app my-app
```

New apps use React on Rails Pro by default because Pro is where React 19.2 feature support lives. The
repos below are references for learning, validation, demos, migrations, and talks.

## Start Here

| Goal                                  | Use                                                                                                       |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Create a new app                      | `npx create-react-on-rails-app my-app`                                                                    |
| Study the current Pro app shape       | [shakacode/react-on-rails-starter-tanstack](https://github.com/shakacode/react-on-rails-starter-tanstack) |
| Show the React 19.2-era product story | [Marketplace RSC Performance Demo](#marketplace-rsc-performance-demo)                                     |
| Study a complete Rails CRUD baseline  | [Flagship Task Board Demo](#flagship-task-board-demo)                                                     |
| Study migration from `react-rails`    | [react-rails Migration References](#react-rails-migration-references)                                     |

## Current Pro References

These are the references to use for new product, adoption, and template discussions.

### React on Rails Pro TanStack Starter

- Repo: [shakacode/react-on-rails-starter-tanstack](https://github.com/shakacode/react-on-rails-starter-tanstack)
- Use it when you want the maintained Rails 8 + React on Rails Pro starter that shows the current app
  architecture: React Server Components, TanStack Router/Query/Table, Rspack, Tailwind, and shadcn/ui.
- Upstream branch testing: the starter documents how to validate unreleased `react_on_rails` and
  `react_on_rails_rsc` branches in
  [Testing Upstream Branches](https://github.com/shakacode/react-on-rails-starter-tanstack/blob/main/docs/12-upstream-branch-testing.md).
  For the starter CLI prerelease path, see the `@rc` notes in
  [Quick Start: `npx create-react-on-rails-app`](./create-react-on-rails-app.md).

### Marketplace RSC Performance Demo

- Repo: [shakacode/react-on-rails-demo-marketplace-rsc](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc)
- Live demo and evidence: see the repo README for Lighthouse reports, bundle-size breakdowns, and the
  demo itself.
- Use it when you want a public performance-oriented demo showing the user-visible win on a
  marketplace-style surface.

### Hacker News RSC Demo

- Repo: [shakacode/react-on-rails-demo-hacker-news-rsc](https://github.com/shakacode/react-on-rails-demo-hacker-news-rsc)
- Live demo: [hn.reactonrails.com](https://hn.reactonrails.com/)
- Use it when you want a compact public demo of React on Rails Pro on a familiar read-heavy UI.

### Gumroad-Style RSC Benchmark Demo

- Repo: [shakacode/react-on-rails-demo-gumroad-rsc](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
- Use it when you want a benchmark-oriented comparison between an Inertia-style surface and a React on
  Rails Pro surface on the same product domain.
- Note: this is a ShakaCode-built demo modeled on a Gumroad-style UI, not an official Gumroad product
  or integration.

### Octochangelog RSC Demo

- Repo:
  [shakacode/react_on_rails-demo-octochangelog-on-rails-pro](https://github.com/shakacode/react_on_rails-demo-octochangelog-on-rails-pro)
- Live demo: [changelog.reactonrails.com](https://changelog.reactonrails.com/)
- Use it when you want a real-app migration to React on Rails Pro showing Rails routing, React 19, and
  streamed React Server Components.

## Other Public References

Use these when you need a public baseline app, tutorial companion, or migration reference.

### Flagship Task Board Demo

- Repo: [shakacode/react-on-rails-demo-flagship](https://github.com/shakacode/react-on-rails-demo-flagship)
- Use it when you want a clone-and-run Rails CRUD reference app: ActiveRecord-backed task board,
  server-side rendering, React, TypeScript, Redux Toolkit, and Shakapacker + Rspack.
- This repo is a product-style baseline for the Pro demos. Check the repo README for its current stack
  before describing it publicly.
- Two run modes: `bin/dev` for local development and `docker compose up` for a deterministic container
  boot; `bin/smoke` verifies the server-rendered HTML and exits non-zero if SSR fails.

### SSR + HMR Tutorial Demo

- Repo: [shakacode/react-on-rails-demo-ssr-hmr](https://github.com/shakacode/react-on-rails-demo-ssr-hmr)
- Use it when you want the maintained Rails + React + SSR + HMR walkthrough repo that backs the
  tutorial and Webpack configuration guidance.

## react-rails Migration References

For migration guidance, see [Migrating from react-rails](../migrating/migrating-from-react-rails.md).

- [shakacode/react-on-rails-example-migration](https://github.com/shakacode/react-on-rails-example-migration)
  — focused before/after `react-rails` to React on Rails migration reference.
- [shakacode/react-on-rails-example-open-flights](https://github.com/shakacode/react-on-rails-example-open-flights)
  — larger example app that shows React on Rails replacing `react-rails` in a more realistic codebase.
