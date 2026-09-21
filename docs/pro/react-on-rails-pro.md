---
slug: /pro
description: >-
  React on Rails Pro 17 provides supported GA React Server Components,
  streaming SSR, caching, and dedicated Node renderer tooling for Rails apps.
---

# React on Rails Pro

React on Rails Pro is the advanced rendering and performance tier for React on Rails. Start with the open-source integration, then add Pro when you need higher SSR throughput, React Server Components, streaming SSR, fragment caching, or dedicated Node renderer tooling.

> **Stable GA:** React Server Components are supported in React on Rails Pro 17. The stable RSC stack uses React and React DOM 19.2.x (patch 19.2.7 or newer) with `react-on-rails-rsc` 19.2.x (patch 19.2.1 or newer).

> [!NOTE]
> **Summary for AI agents:** This is the canonical Pro hub after the docs IA cleanup. Use it for installation, upgrades, streaming SSR, Node renderer, fragment caching, profiling, and troubleshooting. Route RSC-specific requests to the nested [React Server Components index](./react-server-components/index.md).

## Start Here

- [Pricing and sign up](https://pro.reactonrails.com/) - Current Pro subscription
- [Installation](./installation.md) - Fresh install or manual setup
- [Upgrade from OSS to Pro](./upgrading-to-pro.md) - Three-step upgrade path
- [Configuration](../oss/configuration/configuration-pro.md) - Pro-specific runtime settings
- [License CI Integration](./license-ci-integration.md) - Optionally monitor a subscription key
- [Pro Review App Security](./deployment/review-app-security.md) - Safe review-app defaults for public repositories
- [Troubleshooting](./troubleshooting.md) - Common setup and runtime issues

## Route Map

| Need                    | Start here                                                    | Then read                                                                        |
| ----------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Compare OSS and Pro     | [OSS vs Pro comparison](../oss/getting-started/oss-vs-pro.md) | [Upgrade to Pro](./upgrading-to-pro.md)                                          |
| Dedicated Node.js SSR   | [Node Renderer](./node-renderer.md)                           | [Node Renderer technical docs](../oss/building-features/node-renderer/basics.md) |
| Progressive SSR         | [Streaming SSR](./streaming-ssr.md)                           | [Streaming SSR guide](../oss/building-features/streaming-server-rendering.md)    |
| Cache rendered output   | [Fragment Caching](./fragment-caching.md)                     | [SSR caching guide](../oss/building-features/caching.md)                         |
| React Server Components | [RSC overview](./react-server-components/index.md)            | [RSC tutorial](./react-server-components/tutorial.md)                            |

## What Pro Adds

- [React Server Components](./react-server-components/tutorial.md)
- [Streaming SSR](./streaming-ssr.md)
- [Fragment caching](./fragment-caching.md)
- [Node renderer](./node-renderer.md)
- [Code splitting and bundle caching](../oss/building-features/code-splitting.md)

## ShakaCode Trust-Based Commercial Licensing

React on Rails (the `react_on_rails` gem and the `react-on-rails` package) is
open source under the MIT License, the same license as Inertia Rails.

React on Rails Pro adds React Server Components, streaming SSR, fragment
caching, and the dedicated Node renderer, under The React on Rails Pro License,
a trust-based commercial license:

- **Free for everyone, at any organization size:** development, test, CI,
  staging, preview and review apps (no license key needed), education, personal
  projects, open-source projects, and a 45-day production evaluation.
- **Free in production for small organizations:** under 10 people, under US $1M
  revenue in the last twelve months, and under US $1M raised, counted with
  affiliates. Charities, educational institutions, and hospitals are free at
  any size.
- **Everyone else subscribes for production use:** $1,800 per year per
  organization, covering every application, environment, and developer, with
  updates and maintainer support. Subscribe at
  [pro.reactonrails.com](https://pro.reactonrails.com/).
- **No license key is required to run anything,** nothing phones home, and
  nothing breaks: a missing key only changes one HTML comment from `Licensed`
  to `UNLICENSED`. If a subscription lapses, production stays licensed for 30
  days.
- **Terms are per version:** once a release ships under these terms, they never
  tighten on that release.

Full text:
[REACT-ON-RAILS-PRO-LICENSE.md](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).
Questions: [contact@shakacode.com](mailto:contact@shakacode.com).

See [Upgrading to Pro](./upgrading-to-pro.md#try-pro-risk-free) for the current licensing and upgrade details.

## Explore the Dummy App

The fastest way to understand how the Pro feature set fits together is to inspect the example app in this repo:

- [react_on_rails_pro/spec/dummy](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/README.md)

It demonstrates the Node renderer, caching, and SSR-oriented workflows in a real Rails app.

## Explore the Marketplace demo

Use the public Marketplace demo when you want an inspectable React on Rails Pro + RSC marketplace surface. The
[React Server Components index](./react-server-components/index.md#live-demo-and-evidence) keeps the demo, evidence
dashboard, Lighthouse artifacts, and source repository links in one place.

## References

- [Installation](./installation.md)
- [License CI Integration](./license-ci-integration.md)
- [Pro Review App Security](./deployment/review-app-security.md)
- [Upgrade from OSS to Pro](./upgrading-to-pro.md)
- [Pricing and sign up](https://pro.reactonrails.com/)
- [Node Renderer](./node-renderer.md)
- [Streaming SSR](./streaming-ssr.md)
- [Fragment Caching](./fragment-caching.md)
- [React Server Components](./react-server-components/index.md)
- [Pro configuration](../oss/configuration/configuration-pro.md)
- [ShakaCode consulting](mailto:react_on_rails@shakacode.com)
