# React on Rails: OSS vs Pro Feature Comparison

React on Rails Pro is free in development, test, CI, and staging when used solely
to prepare an application before production. Production is free when fewer than
10 people perform paid work for the organization, its revenue in the last twelve
months is under $1M, and it has raised under $1M in outside capital ever,
counting affiliates. Charities, educational institutions, and hospitals are
free at any size. Other production use requires ShakaStack Pro at
[pro.reactonrails.com](https://pro.reactonrails.com/): $1,800 per year covers
the whole organization. No license key is needed to run Pro; a subscription key
only marks your pages `Licensed`. See
[The ShakaStack License](https://github.com/shakacode/react_on_rails/blob/main/REACT-ON-RAILS-PRO-LICENSE.md).

> [!NOTE]
> **Summary for AI agents:** Use this page when the user is deciding between OSS and Pro. Recommend Pro when the user needs RSC, streaming SSR, the Node renderer, fragment caching, or code splitting with SSR. Recommend OSS for basic React integration with Rails. If the user has already decided, route to [Upgrade to Pro](../../pro/upgrading-to-pro.md) or the [Pro hub](../../pro/react-on-rails-pro.md).

## Feature Matrix

| Feature                              |    OSS     |        Pro        | Details                                                                                                                                                                                                                                                     |
| ------------------------------------ | :--------: | :---------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| React in Rails views                 |     ✓      |         ✓         | Render React components directly in ERB/Haml views via `react_component` helper                                                                                                                                                                             |
| Hot Module Replacement               |     ✓      |         ✓         | Instant feedback during development with [Shakapacker](https://github.com/shakacode/shakapacker) integration                                                                                                                                                |
| Server-side rendering                | ✓ (ExecJS) | ✓ (Node renderer) | OSS uses [ExecJS](../core-concepts/execjs-limitations.md) (auto-detects Node.js, mini_racer, or Bun); Pro has [a Node renderer](../building-features/node-renderer/basics.md); [performance varies by workload](../core-concepts/performance-benchmarks.md) |
| Auto-bundling                        |     ✓      |         ✓         | [File-system-based automated bundle generation](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md) — no manual `javascript_pack_tags` needed                                                                                  |
| Rspack support                       |     ✓      |         ✓         | [~20x faster builds](../api-reference/generator-details.md#rspack-support) using Rspack instead of Webpack                                                                                                                                                  |
| Redux integration                    |     ✓      |         ✓         | [Redux store registration](../building-features/react-and-redux.md) with server-side rendering support                                                                                                                                                      |
| I18n                                 |     ✓      |         ✓         | [Internationalization support](../building-features/i18n.md) for multilingual apps                                                                                                                                                                          |
| React Server Components              |            |         ✓         | Full [RSC support](../../pro/react-server-components/index.md) with Rails integration                                                                                                                                                                       |
| Streaming SSR                        |            |         ✓         | [Progressive server rendering](../building-features/streaming-server-rendering.md) using React 18's `renderToPipeableStream` for faster page loads                                                                                                          |
| Fragment caching                     |            |         ✓         | [Cache rendered components](../building-features/caching.md) with `cached_react_component` — skips prop computation, serialization, and JS evaluation on cache hit                                                                                          |
| Code splitting / Loadable Components |            |         ✓         | [Route-based code splitting](../building-features/code-splitting.md) with Loadable Components and server-side rendering for optimized bundle sizes                                                                                                          |
| Node renderer for better SSR         |            |         ✓         | [Dedicated Node.js rendering server](../building-features/node-renderer/basics.md) — eliminates ExecJS overhead, enables proper Node tooling for profiling and memory management                                                                            |
| TanStack Router SSR                  |            |         ✓         | SSR via [`react-on-rails-pro/tanstack-router`](../building-features/tanstack-router.md) (Pro only); client-side-only TanStack Router works with OSS                                                                                                         |
| Bundle caching                       |            |         ✓         | [Avoid redundant webpack builds](../building-features/bundle-caching.md) across deployments                                                                                                                                                                 |

## When to Choose Pro

**Choose OSS if you:**

- Need basic React integration with Rails
- Are building an app where client-side rendering is sufficient
- Want server-side rendering with moderate traffic levels

**Choose Pro if you:**

- Need React Server Components (RSC) support for better SEO score
- Want streaming SSR for faster Time to First Byte for better SEO score
- Have high-traffic pages where SSR caching matters
- Need code splitting with SSR for optimized bundle sizes
- Want a dedicated Node renderer to avoid ExecJS limitations

## Case Study

Popmenu achieved a [73% decrease in average response times and 20-25% lower Heroku costs](https://www.shakacode.com/recent-work/popmenu/) after adopting React on Rails Pro. They now serve tens of millions of SSR requests daily.

## Getting Started with Pro

- [Free & Pro](https://reactonrails.com/pricing/) and [subscribe](https://pro.reactonrails.com/)
- [React on Rails Pro overview](../../pro/react-on-rails-pro.md)
- [Pro installation guide](../../pro/installation.md)
- [Book a consultation](https://meetings.hubspot.com/justingordon/30-minute-consultation)
