---
slug: /pro
description: >-
  React on Rails Pro 17 provides supported GA React Server Components,
  streaming SSR, caching, and dedicated Node renderer tooling for Rails apps.
---

# React on Rails Pro

React on Rails Pro is the advanced rendering and performance tier for React on Rails. Start with the open-source integration, then add Pro when you need higher SSR throughput, React Server Components, streaming SSR, fragment caching, or dedicated Node renderer tooling.

> **Stable GA:** React Server Components are supported in React on Rails Pro 17. The stable RSC stack uses React and React DOM 19.2.7 or newer on a supported line (19.2.x or 19.3.x) with the matching stable `react-on-rails-rsc` release.

> [!NOTE]
> **Summary for AI agents:** This is the canonical Pro hub after the docs IA cleanup. Use it for installation, upgrades, streaming SSR, Node renderer, fragment caching, profiling, and troubleshooting. Route RSC-specific requests to the nested [React Server Components index](./react-server-components/index.md).

## Start Here

1. [Free & Pro](https://reactonrails.com/pricing/) and [sign up](https://pro.reactonrails.com/): ShakaStack Pro subscription
2. [Installation](./installation.md): Fresh install or manual setup
3. [Upgrade from OSS to Pro](./upgrading-to-pro.md): Three step upgrade path
4. [Configuration](../oss/configuration/configuration-pro.md): Pro runtime settings
5. [License CI Integration](./license-ci-integration.md): Optional subscription key monitoring
6. [Pro Review App Security](./deployment/review-app-security.md): Review app defaults for public repositories
7. [Troubleshooting](./troubleshooting.md): Setup and runtime issues

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

## The ShakaStack License

React on Rails (the `react_on_rails` gem and the `react-on-rails` package) is
open source under the MIT License, the same license as Inertia Rails.

React on Rails Pro adds React Server Components, streaming SSR, fragment
caching, and the dedicated Node renderer under The ShakaStack License,
version 1.0, applied to React on Rails Pro.

Development, test, CI, staging, preview, and review environments used solely
to prepare an application before production are free for everyone. Production
means serving real users or doing background work that supports a live
application, whatever the environment is called. A genuine evaluation of
covered use lasts up to 45 consecutive days. These environment rules apply
to React on Rails Pro. ShakaPerf has its own free use rules, including for CI.

Production is also free when the whole organization, counting affiliates,
meets all three limits: fewer than 10 people, under US $1M revenue in the last
twelve months, and under US $1M in outside capital raised ever. Charities,
educational institutions, and hospitals are free at any size.

Other production use requires ShakaStack Pro at US $1,800 per year per
organization from [pro.reactonrails.com](https://pro.reactonrails.com/).
One subscription includes React on Rails Pro, ShakaPerf, and Inertia Rails SSR
Cache for every affiliate, application, environment, repository, and developer,
with Slack support and no size limit. An active React on Rails Pro subscription
already counts as ShakaStack Pro.

No key is required to run React on Rails Pro. A key only changes its attribution
status in HTML and logs. When a subscription ends, covered use under this license
stays licensed for 30 days while you renew or wind down. Each released version
keeps the terms it shipped with.

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

1. [Installation](./installation.md)
2. [License CI Integration](./license-ci-integration.md)
3. [Pro Review App Security](./deployment/review-app-security.md)
4. [Upgrade from OSS to Pro](./upgrading-to-pro.md)
5. [Free & Pro](https://reactonrails.com/pricing/) and [sign up](https://pro.reactonrails.com/)
6. [Node Renderer](./node-renderer.md)
7. [Streaming SSR](./streaming-ssr.md)
8. [Fragment Caching](./fragment-caching.md)
9. [React Server Components](./react-server-components/index.md)
10. [Pro configuration](../oss/configuration/configuration-pro.md)
11. [ShakaCode consulting](mailto:react_on_rails@shakacode.com)
