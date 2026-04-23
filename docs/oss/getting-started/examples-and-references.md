# Examples and Migration References

Use this page as the canonical index for public React on Rails reference repos.
The goal is to make evaluation, migration, and React on Rails Pro adoption easy
to navigate without scattering hard-coded repository links across the docs.

Some public repos still use older slugs with underscores or legacy wording.
This page is the source of truth for which public repos are current and worth
starting from.

## Starter Repos

### SSR + HMR Tutorial Demo

- Repo: [shakacode/react-on-rails-demo-ssr-hmr](https://github.com/shakacode/react-on-rails-demo-ssr-hmr)
- Use it when you want the maintained Rails + React + SSR + HMR walkthrough repo
  that backs the tutorial and Webpack configuration guidance.

### React on Rails Pro + RSC Starter

- Repo: [shakacode/react-on-rails-rsc-demo](https://github.com/shakacode/react-on-rails-rsc-demo)
- Use it when you want a minimal public sample for React Server Components with
  React on Rails Pro.
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

### Migrate from `react-rails`

- Repo: [shakacode/react-on-rails-example-migration](https://github.com/shakacode/react-on-rails-example-migration)
- Use it when you want a focused before/after migration reference instead of
  reconstructing the upgrade from older blog posts.

### Open Flights Migration Example

- Repo: [shakacode/react-on-rails-example-open-flights](https://github.com/shakacode/react-on-rails-example-open-flights)
- Use it when you want a larger example app that shows React on Rails replacing
  `react-rails` in a more realistic codebase.

## React on Rails Pro + RSC Demos

> **Note:** The repos below use React on Rails Pro. See [OSS vs Pro](./oss-vs-pro.md)
> for evaluation guidance.

### Hacker News RSC Demo

- Repo: [shakacode/react-on-rails-demo-hacker-news-rsc](https://github.com/shakacode/react-on-rails-demo-hacker-news-rsc)
- Use it when you want a compact public demo of React on Rails Pro with React
  Server Components on a familiar read-heavy UI.

### Marketplace RSC Performance Demo

- Repo: [shakacode/react-on-rails-demo-marketplace-rsc](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc)
- Use it when you want a public performance-oriented RSC demo showing the shape
  of the user-visible win on a marketplace-style surface.

### Gumroad-Style RSC Benchmark Demo

- Repo: [shakacode/react-on-rails-demo-gumroad-rsc](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
- Use it when you want a benchmark-oriented comparison between an Inertia-style
  surface and a React on Rails Pro + RSC surface on the same product domain.
- Note: this is a ShakaCode-built demo modeled on a Gumroad-style UI, not an
  official Gumroad product or integration.

## Legacy Repos

Version-specific demos, `test-*` repos, generator snapshots, and older tutorial
repos are useful historical references, but they are not the primary starting
point for new evaluations.

- Legacy full app: [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) — older production-style app with a [live demo at reactrails.com](https://reactrails.com). Still useful as a historical reference, but not the recommended starting point for new projects.

If you are choosing a public reference repo for docs, talks, or adoption work,
start with the repos above.
