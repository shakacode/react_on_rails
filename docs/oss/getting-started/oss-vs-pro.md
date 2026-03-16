# React on Rails: OSS vs Pro Feature Comparison

React on Rails Pro extends the open-source gem with performance optimizations and advanced rendering capabilities. The Pro subscription is **free for evaluation and non-production use**.

## Feature Matrix

| Feature                              |    OSS     |        Pro        | Details                                                                                                                                                                          |
| ------------------------------------ | :--------: | :---------------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| React in Rails views                 |     ✓      |         ✓         | Render React components directly in ERB/Haml views via `react_component` helper                                                                                                  |
| Hot Module Replacement               |     ✓      |         ✓         | Instant feedback during development with [Shakapacker](https://github.com/shakacode/shakapacker) integration                                                                     |
| Server-side rendering                | ✓ (ExecJS) | ✓ (Node renderer) | OSS uses ExecJS (mini_racer); Pro adds a dedicated [Node renderer](../building-features/node-renderer/basics.md) for 10-100x faster SSR                                          |
| Auto-bundling                        |     ✓      |         ✓         | [File-system-based automated bundle generation](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md) — no manual `javascript_pack_tags` needed       |
| Rspack support                       |     ✓      |         ✓         | [~20x faster builds](../api-reference/generator-details.md#rspack-support) using Rspack instead of Webpack                                                                       |
| Redux integration                    |     ✓      |         ✓         | [Redux store registration](../building-features/react-and-redux.md) with server-side rendering support                                                                           |
| I18n                                 |     ✓      |         ✓         | [Internationalization support](../building-features/i18n.md) for multilingual apps                                                                                               |
| React Server Components              |            |         ✓         | Full [RSC support](../../pro/react-server-components/how-react-server-components-work.md) with Rails integration                                                                 |
| Streaming SSR                        |            |         ✓         | [Progressive server rendering](../building-features/streaming-server-rendering.md) using React 18's `renderToPipeableStream` for faster page loads                               |
| Fragment caching                     |            |         ✓         | [Cache rendered components](../building-features/caching.md) with `cached_react_component` — skips prop computation, serialization, and JS evaluation on cache hit               |
| Code splitting / Loadable Components |            |         ✓         | [Route-based code splitting](../building-features/code-splitting.md) with Loadable Components and server-side rendering for optimized bundle sizes                               |
| Node renderer for better SSR         |            |         ✓         | [Dedicated Node.js rendering server](../building-features/node-renderer/basics.md) — eliminates ExecJS overhead, enables proper Node tooling for profiling and memory management |
| TanStack Router SSR                  |            |         ✓         | SSR via [`react-on-rails-pro/tanstack-router`](../building-features/tanstack-router.md) (Pro only); client-side-only TanStack Router works with OSS                              |
| Bundle caching                       |            |         ✓         | [Avoid redundant webpack builds](../building-features/bundle-caching.md) across deployments                                                                                      |

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

- [React on Rails Pro overview](https://www.shakacode.com/react-on-rails-pro/)
- [Pro installation guide](../../pro/installation.md)
- [Book a consultation](https://meetings.hubspot.com/justingordon/30-minute-consultation)
