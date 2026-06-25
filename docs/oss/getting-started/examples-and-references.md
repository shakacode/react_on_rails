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

### OSS Flagship Demo (open source)

- Repo: [shakacode/react-on-rails-demo-flagship](https://github.com/shakacode/react-on-rails-demo-flagship)
- Use it when you want the canonical clone-and-run open-source demo: a real
  ActiveRecord-backed CRUD task board with server-side rendering, React 19,
  TypeScript, Redux Toolkit, and Shakapacker + Rspack — no Pro, no RSC.
- Two run modes: `bin/dev` for local development and `docker compose up` for a
  deterministic container boot; `bin/smoke` verifies the server-rendered HTML
  and exits non-zero if SSR fails.

### SSR + HMR Tutorial Demo (open source)

- Repo: [shakacode/react-on-rails-demo-ssr-hmr](https://github.com/shakacode/react-on-rails-demo-ssr-hmr)
- Use it when you want the maintained Rails + React + SSR + HMR walkthrough repo
  that backs the tutorial and Webpack configuration guidance.

### React on Rails Pro + TanStack/RSC Starter (Pro)

- Repo: [shakacode/react-on-rails-starter-tanstack](https://github.com/shakacode/react-on-rails-starter-tanstack)
- Use it when you want the maintained Rails 8 + React on Rails Pro + TanStack
  Router/Query/Table starter with React Server Components, Rspack, Tailwind, and
  shadcn/ui.
- Upstream branch testing: the starter documents how to validate unreleased
  `react_on_rails` and `react_on_rails_rsc` branches in
  [Testing Upstream Branches](https://github.com/shakacode/react-on-rails-starter-tanstack/blob/main/docs/12-upstream-branch-testing.md).
  For the general gem/npm recipes, see
  [Consuming an Unreleased Build](./consuming-an-unreleased-build.md).
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

### Octochangelog RSC Demo

- Repo: [shakacode/react_on_rails-demo-octochangelog-on-rails-pro](https://github.com/shakacode/react_on_rails-demo-octochangelog-on-rails-pro)
- Live demo: [changelog.reactonrails.com](https://changelog.reactonrails.com/)
- Use it when you want a real-app migration to React on Rails Pro showing Rails
  routing, React 19, and streamed React Server Components.

## Control Plane Cost Posture

For public demo and starter staging deployments on Control Plane, keep the app
workload as `type: standard` with `minScale: 1`, set its autoscaling metric to
`disabled`, and enable `capacityAI: true` so Control Plane can right-size idle
capacity while the demo keeps one warm replica. With the autoscaling metric set
to `disabled`, treat replica count as fixed; `maxScale` is not a burst-scaling
lever in this posture. If a demo must absorb traffic bursts, choose a compatible
autoscaling metric deliberately and set a tested `maxScale` ceiling for that
separate scaling posture.
Avoid `CPU Utilization` autoscaling with `minScale: 1` / `maxScale: 1` for
these small staging apps because that combination prevents Capacity AI from
right-sizing the warm workload.

This is not the same as scale-to-zero: steady RAM usage and background work can
still drive cost, and shared Postgres should usually stay manually sized. If a
demo explicitly needs true idle scale-to-zero, create a separate `serverless`
workload before first deploy or plan a delete/recreate migration because Control
Plane will not change an existing `standard` workload to `serverless` in place.
The reusable guidance lives in
[Control Plane Flow: Enable Capacity AI for Demo and Starter Staging Apps](https://github.com/shakacode/control-plane-flow/blob/main/docs/tips.md#enable-capacity-ai-for-demo-and-starter-staging-apps).

## Legacy Repos

Version-specific demos, `test-*` repos, generator snapshots, and older tutorial
repos are useful historical references, but they are not the primary starting
point for new evaluations.

- Legacy full app: [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial) —
  older production-style app with a running site at [www.reactrails.com](https://www.reactrails.com).
  Still useful as a historical reference, but not the recommended starting point for new projects.
- Minimal RSC sample: [shakacode/react-on-rails-rsc-demo](https://github.com/shakacode/react-on-rails-rsc-demo) —
  older minimal React Server Components sample. Use the TanStack Starter above
  for a current React on Rails Pro + RSC starting point.

If you are choosing a public reference repo for docs, talks, or adoption work,
start with the repos above.
