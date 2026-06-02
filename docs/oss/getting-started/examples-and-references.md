# Examples and Migration References

Use this page as the canonical index for public React on Rails reference repos.
The goal is to make evaluation, migration, and React on Rails Pro adoption easy
to navigate without scattering hard-coded repository links across the docs.

Some public repos still use older slugs with underscores or legacy wording.
This page is the source of truth for which public repos are current and worth
starting from.

## Starter Repos

Check each entry's note before evaluating — some starters are fully open
source, while others require React on Rails Pro.

### SSR + HMR Tutorial Demo (open source)

- Repo: [shakacode/react-on-rails-demo-ssr-hmr](https://github.com/shakacode/react-on-rails-demo-ssr-hmr)
- Use it when you want the maintained Rails + React + SSR + HMR walkthrough repo
  that backs the tutorial and Webpack configuration guidance.

### React on Rails Pro + RSC Starter (Pro)

- Repo: [shakacode/react-on-rails-rsc-demo](https://github.com/shakacode/react-on-rails-rsc-demo)
  _(slug rename to `react-on-rails-demo-rsc` pending — update this line when the
  rename completes)_
- Use it when you want a minimal public sample for React Server Components with
  React on Rails Pro.
- Note: this repo uses React on Rails Pro. See [OSS vs Pro](./oss-vs-pro.md)
  for evaluation guidance.

### React on Rails + TanStack Starter (Pro)

- Repo: [shakacode/react-on-rails-starter-tanstack](https://github.com/shakacode/react-on-rails-starter-tanstack)
- Use it when you want the maintained Rails 8 + React on Rails Pro + TanStack
  Router/Query/Table starter with React Server Components, Rspack, Tailwind, and
  shadcn/ui.
- Upstream branch testing: the starter documents how to validate unreleased
  `react_on_rails` and `react_on_rails_rsc` branches in
  [Testing Upstream Branches](https://github.com/shakacode/react-on-rails-starter-tanstack/blob/main/docs/12-upstream-branch-testing.md).
- Note: this repo uses React on Rails Pro. See [OSS vs Pro](./oss-vs-pro.md)
  for evaluation guidance.

## In-Repo Reference

### Spec Dummy App

- Repo: [shakacode/react_on_rails — spec/dummy](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails/spec/dummy)
- Use it when you want the simplest in-repo reference for current generator and
  feature behavior.
- Note: this is the in-repo test app used by the RSpec suite, not a standalone
  starter repository.

## Migration References

For detailed proof criteria and migration contribution guidance, see
[Example Migrations](../migrating/example-migrations.md).

- [shakacode/react-on-rails-example-migration](https://github.com/shakacode/react-on-rails-example-migration) —
  focused before/after `react-rails` → React on Rails migration reference.
- [shakacode/react-on-rails-example-open-flights](https://github.com/shakacode/react-on-rails-example-open-flights) —
  larger example app that shows React on Rails replacing `react-rails` in a
  more realistic codebase.

## React on Rails Pro + RSC Demos

> **Note:** The repos below use React on Rails Pro. See [OSS vs Pro](./oss-vs-pro.md)
> for evaluation guidance.

### Hacker News RSC Demo

- Repo: [shakacode/react-on-rails-demo-hacker-news-rsc](https://github.com/shakacode/react-on-rails-demo-hacker-news-rsc)
- Live demo: [hn.reactonrails.com](https://hn.reactonrails.com/)
- Use it when you want a compact public demo of React on Rails Pro with React
  Server Components on a familiar read-heavy UI.

### Marketplace RSC Performance Demo

- Repo: [shakacode/react-on-rails-demo-marketplace-rsc](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc)
- Live demo & evidence: see the [Live Demo and Evidence](../../pro/react-server-components/index.md#live-demo-and-evidence)
  section for Lighthouse reports, bundle-size breakdowns, and the demo itself.
- Use it when you want a public performance-oriented RSC demo showing the shape
  of the user-visible win on a marketplace-style surface.

### Gumroad-Style RSC Benchmark Demo

- Repo: [shakacode/react-on-rails-demo-gumroad-rsc](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
- Use it when you want a benchmark-oriented comparison between an Inertia-style
  surface and a React on Rails Pro + RSC surface on the same product domain.
- Note: this is a ShakaCode-built demo modeled on a Gumroad-style UI, not an
  official Gumroad product or integration.

## Live Demos

- [hn.reactonrails.com](https://hn.reactonrails.com/) — Hacker News reader
  showing React on Rails Pro with React 19 and React Server Components on a
  familiar read-heavy UI.
- [reactrails.com](https://reactrails.com) — production-style React on Rails app
  you can click through in your browser without any local setup. Backed by the
  legacy [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial)
  source.

## Legacy Repos

Version-specific demos, `test-*` repos, generator snapshots, and older tutorial
repos are useful historical references, but they are not the primary starting
point for new evaluations.

- Legacy full app: [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) —
  older production-style app (see Live Demos above for the running site at reactrails.com).
  Still useful as a historical reference, but not the recommended starting point for new projects.

If you are choosing a public reference repo for docs, talks, or adoption work,
start with the repos above.
