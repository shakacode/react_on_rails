# React Server Components in React on Rails Pro

> **Pro Feature** — React Server Components require [React on Rails Pro](https://pro.reactonrails.com/) 4+ with the node renderer.
> Free or very low cost for startups and small companies. [Get a license →](https://pro.reactonrails.com)

## What Are React Server Components?

React Server Components (RSC) allow you to write components that execute on the server and stream their rendered output to the client. Unlike traditional server-side rendering, which renders the entire page to a string before sending it, RSC streams individual component trees progressively and keeps server-only dependencies out of the client bundle entirely.

With React on Rails Pro, RSC integrates directly into your Rails application:

- Server components run in the Node renderer alongside your Rails backend
- The RSC webpack loader and plugin handle bundling automatically
- Rails view helpers (`stream_react_component`, `rsc_payload_react_component`) manage the streaming lifecycle
- Auto-bundling detects `'use client'` directives and generates the correct registrations

## Why RSC Matters

### Smaller Client Bundles

Server components and their dependencies never ship to the browser. Libraries like `date-fns`, `marked`, or `sanitize-html` stay entirely server-side, reducing bundle sizes significantly. Frigade reported a [62% reduction in client-side bundle size](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade) after adopting RSC.

### Faster Time to First Byte

Combined with streaming SSR, RSC sends the initial HTML shell immediately while data-dependent components resolve and stream in progressively. Users see content sooner, and search engines can index the full page.

### Selective Hydration

React's selective hydration allows client components to become interactive independently as their code loads, rather than waiting for the entire page's JavaScript to execute. Components that users interact with get priority hydration.

### Direct Data Access

Server components can access databases, file systems, and internal APIs directly without exposing endpoints to the client. This simplifies data fetching and eliminates the need for client-side data fetching libraries in many cases.

## Current Support Status

React on Rails Pro 4+ provides full RSC support with:

- RSC webpack loader (`react-on-rails-rsc/WebpackLoader`) for server/client component separation
- RSC webpack plugin (`react-on-rails-rsc/WebpackPlugin`) for client manifest generation
- Streaming view helpers for progressive rendering
- Auto-bundling integration that detects `'use client'` directives
- Server-side rendering of RSC pages with hydration

### Requirements

- React on Rails Pro v4.0.0 or higher
- React 19.0.x (19.1.x and later are not yet supported)
- React on Rails v16.0.0 or higher
- Node renderer — installed separately via `react-on-rails-pro-node-renderer` npm package (see [Pro Installation](../installation.md#install-react-on-rails-pro-node-renderer))
- Shakapacker or Rspack for bundling

## Getting Started

### New to RSC?

Start with the tutorial series, which builds from basics to advanced features:

1. [Create an RSC page without SSR](./create-without-ssr.md) — learn the fundamentals
2. [Add streaming and interactivity](./add-streaming-and-interactivity.md) — Suspense and client components
3. [Add server-side rendering](./server-side-rendering.md) — full SSR for RSC pages
4. [Selective hydration](./selective-hydration-in-streamed-components.md) — how React prioritizes component hydration

See the full [RSC tutorial](./tutorial.md) for the complete learning path.

### Upgrading an Existing Pro App?

See [Upgrading an Existing Pro App to RSC](./upgrading-existing-pro-app.md) for the generator-based runbook: prerequisites, `rails g react_on_rails:rsc` usage, legacy webpack compatibility, and a verification checklist.

### Migrating Your React Components?

The [migration guide](../../oss/migrating/migrating-to-rsc.md) covers how to incrementally adopt RSC in an existing React on Rails application, including:

- [Preparing your app](../../oss/migrating/rsc-preparing-app.md) — infrastructure setup before changing components
- [Component patterns](../../oss/migrating/rsc-component-patterns.md) — restructuring your component tree
- [Context and state management](../../oss/migrating/rsc-context-and-state.md) — handling React Context across the server/client boundary
- [Data fetching](../../oss/migrating/rsc-data-fetching.md) — migrating from client-side to server-side data access
- [Third-party libraries](../../oss/migrating/rsc-third-party-libs.md) — dealing with library compatibility
- [Troubleshooting](../../oss/migrating/rsc-troubleshooting.md) — common issues and solutions

## Deep Dives

- [How RSC Works](./how-react-server-components-work.md) — bundling process, RSC payload format, and client references
- [RSC Rendering Flow](./rendering-flow.md) — detailed rendering lifecycle, bundle types, and architecture
- [Flight Protocol Syntax](./flight-protocol-syntax.md) — the wire format for streaming RSC data
- [RSC Inside Client Components](./inside-client-components.md) — composing server and client components
- [Purpose and Benefits](./purpose-and-benefits.md) — waterfall loading patterns, bundle size, and selective hydration

## Related Documentation

- [Streaming Server Rendering](../../oss/building-features/streaming-server-rendering.md) — streaming SSR setup and best practices
- [OSS vs Pro Feature Comparison](../../oss/getting-started/oss-vs-pro.md) — what's included in each tier
- [Pro Installation](../installation.md) — setting up React on Rails Pro
- [RSC Glossary](./glossary.md) — terminology reference
