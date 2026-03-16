# Comparison with Alternatives

Choosing a React integration strategy for Rails? This guide compares React on Rails (OSS and Pro) with the main alternatives so you can make an informed decision.

## Feature Comparison

| Feature                  |   react-rails    |    Inertia.js    | Hotwire / Turbo  | React on Rails (OSS) | React on Rails Pro  |
| ------------------------ | :--------------: | :--------------: | :--------------: | :------------------: | :-----------------: |
| Server-side rendering    | Limited (ExecJS) |        —         |       N/A        |      ✓ (ExecJS)      |  ✓ (Node renderer)  |
| React Server Components  |        —         |        —         |       N/A        |          —           |          ✓          |
| Streaming SSR            |        —         |        —         |  Turbo Streams   |          —           |          ✓          |
| Code splitting with SSR  |        —         |        —         |       N/A        |          —           |          ✓          |
| Auto-bundling            |        —         |        —         |   Import maps    |          ✓           |          ✓          |
| Rspack / Webpack support |        —         | ✓ (Vite default) |        —         |          ✓           |          ✓          |
| Hot module replacement   |        —         |        ✓         |  Turbo morphing  |          ✓           |          ✓          |
| Type-safe routing        |        —         |    ✓ (Ziggy)     |        —         |          —           | ✓ (TanStack Router) |
| Props from controller    |        —         |        ✓         |       N/A        |          ✓           |          ✓          |
| SSR caching              |        —         |        —         | Fragment caching |          —           |          ✓          |
| Active maintenance       |     Minimal      |        ✓         |        ✓         |          ✓           |          ✓          |

## Overview of Each Option

### react-rails

[react-rails](https://github.com/reactjs/react-rails) was one of the first gems to integrate React with Rails. It provides a `react_component` view helper and basic ExecJS-based server rendering. However, the project has seen minimal maintenance in recent years and lacks support for modern React features like streaming SSR, code splitting, or React Server Components.

**Best for:** Legacy projects already using react-rails that don't need advanced rendering features.

### Inertia.js

[Inertia.js](https://inertiajs.com/) replaces Rails views entirely with a single-page app architecture while keeping server-side routing. Controllers return Inertia responses instead of HTML, and the client-side adapter renders React (or Vue/Svelte) components as full pages.

**Strengths:**

- Simple mental model — controllers drive page navigation, no client-side router needed
- Works with multiple frontend frameworks (React, Vue, Svelte)
- Built-in form helpers and shared data conventions

**Trade-offs:**

- No server-side rendering — all rendering happens in the browser
- Replaces Rails views entirely — you cannot mix ERB and React on the same page
- Requires adopting Inertia's conventions for data passing and page transitions

**Best for:** New apps where you want a SPA-like experience with server-side routing and don't need SSR.

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

| Your situation                      | Recommended approach                                                                      |
| ----------------------------------- | ----------------------------------------------------------------------------------------- |
| CRUD-heavy app, minimal JS needed   | Hotwire / Turbo                                                                           |
| SPA-like experience, no SSR needed  | Inertia.js                                                                                |
| React components within Rails views | React on Rails (OSS)                                                                      |
| React + SSR + SEO requirements      | React on Rails (OSS or Pro)                                                               |
| High-traffic SSR, RSC, streaming    | React on Rails Pro                                                                        |
| Legacy react-rails app              | Migrate to React on Rails ([migration guide](../migrating/migrating-from-react-rails.md)) |

## Can I Combine Approaches?

Yes. React on Rails is designed for progressive adoption:

- Use Hotwire for simple pages and React on Rails for interactive components on the same app
- Migrate from react-rails to React on Rails incrementally — both use a `react_component` helper with similar APIs
- Start with React on Rails OSS and upgrade to Pro when you need advanced features

## Further Reading

- [OSS vs Pro feature comparison](./oss-vs-pro.md)
- [Quick Start guide](./quick-start.md)
- [Migration from react-rails](../migrating/migrating-from-react-rails.md)
