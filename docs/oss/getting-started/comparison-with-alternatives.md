# Comparison with Alternatives

Choosing a React integration strategy for Rails? This guide compares React on Rails (OSS and Pro) with the main alternatives so you can make an informed decision.

## Feature Comparison

| Feature                 |   react-rails    |     Inertia.js      | Hotwire / Turbo  |    Vite Ruby    | React on Rails (OSS) | React on Rails Pro  |
| ----------------------- | :--------------: | :-----------------: | :--------------: | :-------------: | :------------------: | :-----------------: |
| Server-side rendering   | Limited (ExecJS) | ✓ (opt-in, Node.js) |       N/A        |        —        |      ✓ (ExecJS)      |  ✓ (Node renderer)  |
| React Server Components |        —         |          —          |       N/A        |        —        |          —           |          ✓          |
| Streaming SSR           |        —         |          —          |        —         |        —        |          —           |          ✓          |
| Code splitting with SSR |        —         |          —          |       N/A        |        —        |          —           |          ✓          |
| Auto-bundling           |        —         |          —          |        —         |        —        |          ✓           |          ✓          |
| Bundler support         |   Import maps    |  ✓ (Vite default)   |   Import maps    | ✓ (Vite/Rollup) |      ✓ (Rspack)      |     ✓ (Rspack)      |
| Hot module replacement  |        —         |          ✓          |  Turbo morphing  |        ✓        |          ✓           |          ✓          |
| Type-safe routing       |        —         |          —          |        —         |     ✓ (BYO)     |          —           | ✓ (TanStack Router) |
| Props from controller   |        —         |          ✓          |       N/A        |        —        |          ✓           |          ✓          |
| SSR caching             |        —         |          —          | Fragment caching |        —        |          —           |          ✓          |
| React component helper  |        ✓         |          —          |       N/A        |        —        |          ✓           |          ✓          |
| Active maintenance      |     Minimal      |          ✓          |        ✓         |        ✓        |          ✓           |          ✓          |

## Overview of Each Option

### react-rails

[react-rails](https://github.com/reactjs/react-rails) was one of the first gems to integrate React with Rails. It provides a `react_component` view helper and basic ExecJS-based server rendering. The project is now in maintenance mode and maintained by [ShakaCode](https://www.shakacode.com/), with active feature development focused on React on Rails. It lacks support for modern React features like streaming SSR, code splitting, or React Server Components.

Switching from react-rails to React on Rails is straightforward since both use a `react_component` view helper with a compatible API. See the [migration guide](../migrating/migrating-from-react-rails.md) for details.

**Best for:** Legacy projects already using react-rails that don't need advanced rendering features.

### Inertia.js

[Inertia.js](https://inertiajs.com/) replaces Rails views entirely with a single-page app architecture while keeping server-side routing. Controllers return Inertia responses instead of HTML, and the client-side adapter renders React (or Vue/Svelte) components as full pages.

**Strengths:**

- Simple mental model — controllers drive page navigation, no client-side router needed
- Works with multiple frontend frameworks (React, Vue, Svelte)
- Built-in form helpers and shared data conventions

**Trade-offs:**

- SSR is opt-in and requires a separate Node.js server process — not as integrated as React on Rails' built-in SSR
- Replaces Rails views at the per-route level — an action responds as either Inertia or traditional, though incremental adoption is supported
- Requires adopting Inertia's conventions for data passing and page transitions

**Best for:** New apps where you want a SPA-like experience with server-side routing, using a controller-driven architecture across React, Vue, or Svelte.

### Hotwire / Turbo

[Hotwire](https://hotwired.dev/) is Rails' default frontend approach, using Turbo (for page navigation and partial updates) and Stimulus (for lightweight JavaScript behavior). It minimizes JavaScript by sending HTML over the wire.

**Strengths:**

- Zero-JS approach — most interactivity requires no custom JavaScript
- Deep Rails integration — built into Rails 7+ by default
- Turbo Streams enable real-time partial page updates

**Trade-offs:**

- Not React — if your team has React expertise or needs React's component ecosystem, Hotwire is a fundamentally different paradigm
- Complex interactive UIs (drag-and-drop, rich editors, data visualizations) can be harder to build
- No component reuse between web and mobile (React Native)

**Best for:** Apps where most pages are CRUD-oriented and you want to minimize JavaScript complexity.

### Vite Ruby

[Vite Ruby](https://vite-ruby.netlify.app/) integrates the [Vite](https://vite.dev/) build tool with Rails. Vite uses esbuild for fast development builds and Rollup for optimized production bundles. The `vite_rails` gem provides asset tag helpers and a dev server proxy, but it is a **build tool only** — it does not provide React-specific helpers, server-side rendering, or a component rendering layer.

**Strengths:**

- Very fast dev server startup and HMR via Vite's native ESM approach
- Large plugin ecosystem (Vite plugins, Rollup plugins)
- Simple configuration compared to Webpack

**Trade-offs:**

- No `react_component` view helper — you must manually mount React components via DOM selectors or data attributes
- No server-side rendering — SSR requires building your own Node.js rendering pipeline
- No props-from-controller pattern — data must be passed through `data-*` attributes, JSON script tags, or a separate API
- No auto-bundling — each component entry point must be manually registered

**Best for:** Rails apps that only need client-side React rendering and want the simplest possible build tooling without SSR or Rails view integration.

### Vite vs Rspack: Build Tooling Compared

If build performance is your primary concern, both Vite and Rspack offer dramatic improvements over Webpack — but they have different strengths. The following benchmarks come from [rspack-contrib/performance-compare](https://github.com/rspack-contrib/performance-compare), an open-source benchmark suite maintained by the Rspack team that tests both tools on identical React component trees. Treat these numbers as directional rather than independently verified.

#### Build Performance Benchmarks

**Dev server cold startup** (lower is better):

| Project size   |  Rspack  |   Vite   |  Webpack  |
| -------------- | :------: | :------: | :-------: |
| 1k components  |  942 ms  | 3,702 ms | 3,697 ms  |
| 5k components  |  759 ms  | 3,294 ms | 9,324 ms  |
| 10k components | 1,438 ms | 6,505 ms | 21,444 ms |

Rspack's dev server starts **3–5x faster** than Vite because it bundles upfront in Rust, while Vite serves unbundled ESM and transforms on demand — which scales less well as the module graph grows.

**Hot module replacement** (lower is better):

| Project size   | Rspack |  Vite  | Webpack  |
| -------------- | :----: | :----: | :------: |
| 1k components  | 129 ms | 133 ms |  444 ms  |
| 5k components  | 105 ms | 147 ms | 1,831 ms |
| 10k components | 137 ms | 129 ms | 2,783 ms |

HMR is **essentially a tie** — both deliver sub-150ms updates at any project size.

**Production builds** (lower is better):

| Project size   |  Rspack  |   Vite   |  Webpack  |
| -------------- | :------: | :------: | :-------: |
| 1k components  |  539 ms  |  386 ms  | 3,555 ms  |
| 5k components  | 1,724 ms | 1,075 ms | 9,278 ms  |
| 10k components | 3,466 ms | 1,986 ms | 28,138 ms |

Vite (powered by Rolldown) produces production builds **1.4–1.7x faster** than Rspack. Both are **5–10x faster** than Webpack.

**Memory usage in development** (lower is better):

| Project size   | Rspack |   Vite   | Webpack  |
| -------------- | :----: | :------: | :------: |
| 5k components  | 305 MB |  740 MB  | 1,642 MB |
| 10k components | 367 MB | 1,214 MB | 2,064 MB |

Rspack uses **2–3x less memory** than Vite in development.

#### Integration Comparison

Build speed is only part of the picture. Here's how the two approaches compare as Rails integration tools:

| Aspect                     | Vite (via vite_rails)                           | Rspack (via Shakapacker)                             |
| -------------------------- | ----------------------------------------------- | ---------------------------------------------------- |
| **SSR support**            | Vite SSR mode (manual Rails integration)        | Integrated with React on Rails SSR pipeline          |
| **Webpack compatibility**  | None — different plugin/loader format           | Near-complete Webpack API compatibility              |
| **Migration from Webpack** | Full rewrite of build config                    | Minimal changes — same config format                 |
| **Rails view integration** | Asset tag helpers; manual component mounting    | `react_component` helper with props from controllers |
| **Client-side routing**    | Any React router (React Router, TanStack, etc.) | Any React router; TanStack Router SSR in Pro         |
| **Plugin ecosystem**       | Vite/Rollup plugins                             | Webpack/Rspack plugins                               |

**Key takeaway:** As pure bundlers, Vite and Rspack are both excellent — Rspack starts dev faster and uses less memory, while Vite produces production builds faster. HMR is a tie. But Vite is _only_ a bundler. Choosing Vite means giving up React on Rails' `react_component` helper, automatic props passing from controllers, built-in SSR, and auto-bundling. With Rspack, you get competitive build speeds while retaining the full React on Rails integration layer. If you need SSR, the gap widens further: React on Rails provides SSR out of the box, while Vite requires building a custom Node.js rendering pipeline and wiring it into Rails yourself.

### React on Rails (OSS)

[React on Rails](https://github.com/shakacode/react_on_rails) provides full React integration with Rails views. Components render directly in ERB/Haml templates via the `react_component` helper, with props passed from Rails. Server-side rendering uses ExecJS (via mini_racer).

**Strengths:**

- Render React components alongside Rails views — progressive enhancement, not all-or-nothing
- Built-in SSR for SEO and fast initial page loads
- No separate API layer needed — props flow directly from controllers
- Auto-bundling eliminates manual pack management
- Rspack support for faster builds (~20x vs Webpack)
- Hot module replacement for fast development

**Best for:** Rails apps that need React's component model with server-side rendering, without replacing the Rails view layer.

### React on Rails Pro

[React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) extends the OSS gem with production-grade rendering performance and modern React features.

**Key additions over OSS:**

- **React Server Components** — full RSC support with Rails integration
- **Streaming SSR** — progressive rendering with React 18's `renderToPipeableStream`
- **Node renderer** — dedicated Node.js server for 10–100x faster SSR (replaces ExecJS)
- **Fragment caching** — cache rendered components with `cached_react_component`
- **Code splitting with SSR** — route-based splitting via Loadable Components
- **TanStack Router SSR** — type-safe routing with server rendering

Pro is free for evaluation and non-production use. See the [OSS vs Pro feature matrix](./oss-vs-pro.md) for a detailed breakdown.

**Best for:** Production Rails apps with high-traffic pages, SEO requirements, or need for React Server Components.

## Choosing the Right Approach

| Your situation                        | Recommended approach                                                                      |
| ------------------------------------- | ----------------------------------------------------------------------------------------- |
| CRUD-heavy app, minimal JS needed     | Hotwire / Turbo                                                                           |
| SPA-like experience, server routing   | Inertia.js                                                                                |
| Client-side React only, no SSR needed | Vite Ruby (simple) or React on Rails (with Rails view integration)                        |
| React components within Rails views   | React on Rails (OSS)                                                                      |
| React + SSR + SEO requirements        | React on Rails (OSS or Pro)                                                               |
| High-traffic SSR, RSC, streaming      | React on Rails Pro                                                                        |
| Fast builds + full Rails integration  | React on Rails with Rspack                                                                |
| Legacy react-rails app                | Migrate to React on Rails ([migration guide](../migrating/migrating-from-react-rails.md)) |

## Can I Combine Approaches?

Yes. React on Rails is designed for progressive adoption:

- Use Hotwire for simple pages and React on Rails for interactive components on the same app
- Start with React on Rails OSS and upgrade to Pro when you need advanced features

## Further Reading

- [OSS vs Pro feature comparison](./oss-vs-pro.md)
- [Quick Start guide](./quick-start.md)
- [Migration from react-rails](../migrating/migrating-from-react-rails.md)
