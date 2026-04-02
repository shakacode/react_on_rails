---
slug: /pro
---

# React on Rails Pro

React on Rails Pro is the advanced rendering and performance tier for React on Rails. Start with the open-source integration, then add Pro when you need higher SSR throughput, React Server Components, streaming SSR, fragment caching, or dedicated Node renderer tooling.

## Start Here

- [Installation](./installation.md) - Fresh install or manual setup
- [Upgrade from OSS to Pro](./upgrading-to-pro.md) - Three-step upgrade path
- [Configuration](../oss/configuration/configuration-pro.md) - Pro-specific runtime settings
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

## Evaluation and Licensing

No license token is required for local development, evaluation, testing, CI/CD, or staging. Production deployments require a paid license.

If your organization is budget-constrained, email [justin@shakacode.com](mailto:justin@shakacode.com). We can provide free or low-cost licenses in qualifying cases. For larger companies, paid licenses support continued React on Rails development.

See [Upgrading to Pro](./upgrading-to-pro.md#try-pro-risk-free) for the current licensing and upgrade details.

## Explore the Dummy App

The fastest way to understand how the Pro feature set fits together is to inspect the example app in this repo:

- [react_on_rails_pro/spec/dummy](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/README.md)

It demonstrates the Node renderer, caching, and SSR-oriented workflows in a real Rails app.

## References

- [Installation](./installation.md)
- [Upgrade from OSS to Pro](./upgrading-to-pro.md)
- [Node Renderer](./node-renderer.md)
- [Streaming SSR](./streaming-ssr.md)
- [Fragment Caching](./fragment-caching.md)
- [React Server Components](./react-server-components/index.md)
- [Pro configuration](../oss/configuration/configuration-pro.md)
- [ShakaCode consulting](mailto:react_on_rails@shakacode.com)
