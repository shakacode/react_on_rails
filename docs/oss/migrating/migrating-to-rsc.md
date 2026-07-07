# Migrating Your React App to React Server Components

This guide covers the React-side challenges of migrating an existing React on Rails application to React Server Components (RSC). It focuses on how to restructure your component tree, handle Context and state management, migrate data fetching patterns, deal with third-party library compatibility, and avoid common pitfalls.

> [!NOTE]
> **Summary for AI agents:** Use this page when the user has an existing React on Rails app and wants to adopt RSC. This covers the React-side migration (component restructuring, state, data fetching). For the initial RSC setup, see the [RSC tutorial](../../pro/react-server-components/tutorial.md). RSC requires Pro with the Node renderer.

> **React on Rails Pro required:** RSC support requires [React on Rails Pro](../../pro/react-on-rails-pro.md) 4+ with the node renderer. The Pro gem provides the streaming view helpers (`stream_react_component`, `stream_react_component_with_async_props`, `rsc_payload_react_component`, and `rsc_payload_react_component_with_async_props`), the RSC webpack plugin and loader, and the `registerServerComponent` API. For setup, see the [RSC tutorial](../../pro/react-server-components/tutorial.md). For upgrade steps, see the [performance breakthroughs guide](../../pro/major-performance-breakthroughs-upgrade-guide.md).

## Why Migrate?

React Server Components offer significant performance benefits when used correctly:

- Significant reductions in client-side bundle size reported across RSC adoption case studies
- Improvements in Google Speed Index and Total Blocking Time
- Server-only dependencies (date-fns, marked, sanitize-html) never ship to the client

Real-world results from teams that have adopted server-first rendering (RSC in production, plus DoorDash's pre-RSC SSR baseline):

- **Frigade** — 62% reduction in client-side bundle size ([source](../../pro/react-server-components/success-stories.md#frigade--62-smaller-client-bundle))
- **BlogHunch** — 30% server cost reduction ([source](../../pro/react-server-components/success-stories.md#bloghunch--30-lower-server-costs-in-one-month))
- **Mux** — incremental migration of ~50,000 lines to RSC ([source](../../pro/react-server-components/success-stories.md#mux--migrating-50000-lines-of-react-to-rsc))
- **DoorDash** — 65% LCP improvement (Next.js SSR baseline, pre-RSC) ([source](../../pro/react-server-components/success-stories.md#doordash--core-web-vitals-transformation-ssr-baseline-pre-rsc))

Full case studies with context and caveats: [Migration Success Stories](../../pro/react-server-components/success-stories.md).

However, these benefits require intentional architecture changes. Simply adding `'use client'` everywhere preserves the status quo -- `'use client'` is a [boundary marker, not a component annotation](rsc-component-patterns.md#use-client-marks-a-boundary-not-a-component-type). The guides below walk you through the restructuring needed to capture real gains.

## Article Series

This migration guide is organized as a series of focused articles. We recommend reading them in order, but each is self-contained:

### 1. [Preparing Your App](rsc-preparing-app.md)

How to set up the RSC infrastructure before migrating any components. Covers:

- Installing dependencies and configuring Rails for RSC
- Creating the RSC webpack bundle and adding the RSC plugin to existing bundles
- Adding `'use client'` to all existing component entry points (so nothing changes yet)
- Switching to streaming view helpers and controllers
- After this step, the app works identically -- you're just ready for migration

### 2. [Component Tree Restructuring Patterns](rsc-component-patterns.md)

How to restructure your component tree for RSC. Covers:

- The top-down migration strategy (start at layouts, push `'use client'` to leaves)
- The "donut pattern" for wrapping server content in client interactivity
- Splitting mixed components into server and client parts
- Passing Server Components as children to Client Components
- Before/after examples of common restructuring patterns

### 3. [Context, Providers, and State Management](rsc-context-and-state.md)

How to handle React Context and global state in an RSC world. Covers:

- Why Context doesn't work in Server Components and what to do about it
- The provider wrapper pattern (creating `'use client'` provider components)
- Composing multiple providers without "provider hell"
- Migrating Redux to work alongside RSC
- Using `React.cache()` as a server-side alternative to Context
- Theme, auth, and i18n provider patterns

### 4. [Data Fetching Migration](rsc-data-fetching.md)

How to migrate from client-side data fetching to server component patterns. Covers:

- Replacing `useEffect` + `fetch` with async Server Components
- Migrating from React Query / TanStack Query (prefetch + hydrate pattern)
- Migrating from SWR (fallback data pattern)
- Avoiding server-side waterfalls with parallel fetching
- Streaming data with the `use()` hook and Suspense
- When to keep client-side data fetching

### 5. [HTTP Response Ownership](rsc-http-response-patterns.md)

How to keep HTTP response semantics in Rails while rendering the UI with RSC. Covers:

- Preflight patterns for controller/service decisions before streaming
- Route-level `404` and not-found UI patterns
- Redirect ownership and why it should stay in Rails
- Cache header strategy for public and personalized RSC responses
- Passing response policy into the RSC tree as serializable props

### 6. [Third-Party Library Compatibility](rsc-third-party-libs.md)

How to handle libraries that aren't RSC-compatible. Covers:

- Creating thin `'use client'` wrapper files
- CSS-in-JS migration (styled-components, Emotion alternatives)
- UI library compatibility (MUI, Chakra, Radix, shadcn/ui)
- Form, animation, charting, and date library status
- The barrel file problem and direct imports
- Using `server-only` and `client-only` packages

### 7. [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md)

How to debug and avoid common problems. Covers:

- Serialization boundary issues (what can cross server-to-client)
- Import chain contamination and accidental client components
- Hydration mismatch debugging
- Error boundary limitations with RSC
- Testing strategies (unit, integration, E2E)
- TypeScript considerations
- Performance monitoring and bundle analysis tools
- Common error messages and their solutions

### 8. [Flight Payload Optimization](rsc-flight-payload.md)

How to optimize RSC Flight payload size for better performance. Covers:

- What's in the Flight payload and why it can be surprisingly large
- Why "all display-only = server" is an oversimplification
- The counterintuitive pattern: when presentational Client Components outperform Server Components
- How to measure and analyze your Flight payload
- Compression effectiveness and the LCP tradeoff
- React on Rails double JSON.stringify overhead

### 9. [RSC Performance Validation](rsc-performance-validation.md)

How to prove that an RSC conversion improved the page users actually see. Covers:

- Local control/experiment setup on the same machine
- Warm cached SSR baselines for pages that already use React on Rails Pro caching
- Visual regression checks paired with Lighthouse and resource metrics
- Package-stack discipline for published, canary, RC, and diagnostic builds
- Required PR metrics and the public-page case study

### 10. [Mostly Static RSC Shell With a Tiny Sidecar](rsc-static-shell-sidecar.md)

How to render public/static-ish pages as mostly static RSC HTML while preserving a few browser
behaviors without loading the full global application pack. Covers:

- Rails layout opt-out for selected global JavaScript packs
- Inert JSON props/context handoff to a sidecar
- Intent hydration with keyboard, accessibility, and no-JS fallback checks
- CSS parity and behavior audit checklists
- Bundler and `clientReferences` caveats

## How RSC Maps to React on Rails

Before diving into the React patterns, understand how RSC maps to React on Rails' architecture.

**Multiple component roots.** Unlike single-page apps with one `App.jsx` root, React on Rails renders independent component trees from ERB views. Each `react_component`, `stream_react_component`, or `stream_react_component_with_async_props` call is a separate root. You migrate **per-component**, not per-app.

**Three API changes per component.** Each component you migrate touches three layers:

| Layer           | Before                               | After                                                                                                                                                                                               |
| --------------- | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ERB view helper | `react_component("Product", ...)`    | `stream_react_component("Product", ...)` or `stream_react_component_with_async_props("Product", ...)` when Rails emits async props                                                                  |
| JS registration | `ReactOnRails.register({ Product })` | `registerServerComponent` (signature varies per bundle — see [details](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#the-two-registerservercomponent-signatures)) |
| Controller      | Standard Rails controller            | Add `include ReactOnRailsPro::Stream`                                                                                                                                                               |

**Three webpack bundles.** RSC requires separate client, server, and RSC bundles. The `registerServerComponent` API behaves differently in each:

- **RSC bundle** -- registers the actual Server Component for RSC payload generation
- **Server bundle** -- wraps the component for streaming SSR
- **Client bundle** -- registers a placeholder that fetches the RSC payload from the server

> **Setup instructions:** For webpack configuration, bundle structure, route setup, and step-by-step instructions, see the [React on Rails Pro RSC tutorial](../../pro/react-server-components/tutorial.md). This guide focuses on the **React-side patterns** you'll need after setup is complete.

## Quick-Start Migration Strategy

Tailored for React on Rails' multi-root architecture:

1. **[Prepare your app](rsc-preparing-app.md)** -- set up the RSC infrastructure, add `'use client'` to all component entry points, and switch to streaming rendering. The app works identically -- nothing changes yet.
2. **Pick a component and push the boundary down** -- move `'use client'` from the root component to its interactive children, letting parent components become Server Components.
3. **Adopt advanced patterns** -- add Suspense boundaries, [`stream_react_component`](rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) for streaming SSR, `stream_react_component_with_async_props` for progressively emitted Rails data, and server-side data fetching.
4. **[Keep route policy in Rails](rsc-http-response-patterns.md)** -- for each route, decide redirects, status codes, and cache headers before streaming commits the response.
5. **Repeat for each registered component** -- migrate components one at a time, in any order.

This approach lets you migrate incrementally, one component at a time, without ever breaking your app.

## Component Audit Checklist

Before you start, audit your components using this classification:

| Category                  | Criteria                                                   | Action                                                                |
| ------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------- |
| **Server-ready** (green)  | No hooks, no browser APIs, no event handlers               | Remove `'use client'` -- these are Server Components by default       |
| **Refactorable** (yellow) | Mix of data fetching and interactivity                     | Split into a Server Component (data) + Client Component (interaction) |
| **Client-only** (red)     | Uses `useState`, `useEffect`, event handlers, browser APIs | Keep `'use client'` -- these remain Client Components                 |

## Migration Readiness Checklist

Before starting any component migration, verify these items. Skipping them is the most common source of wasted debugging time:

### Infrastructure

- [ ] **React 19.2 installed** -- both `react` and `react-dom` on 19.2.x with patch `>= 19.2.7`, with matching versions (`yarn why react` shows no duplicates)
- [ ] **Node renderer configured** -- RSC requires `NodeRenderer`, not ExecJS. If `config.server_renderer` is not set to `"NodeRenderer"`, migrate first
- [ ] **`react-on-rails-rsc` 19.2.x with patch `>= 19.2.1`** -- during the React on Rails Pro 17 RC soak, use `19.2.1-rc.0`; check with `yarn why react-on-rails-rsc`
- [ ] **Three webpack bundles building** -- client, server, and RSC bundles all compile without errors
- [ ] **RSC manifests generated** -- `react-client-manifest.json` and `react-server-client-manifest.json` exist in your webpack output directory
- [ ] **RSC payload route mounted** -- `rsc_payload_route` in `config/routes.rb`
- [ ] **Procfile.dev updated** -- separate watcher process for the RSC bundle (`HMR=true RSC_BUNDLE_ONLY=true bin/shakapacker --watch`)

### Common Pre-Migration Mistakes

These mistakes account for the majority of setup failures:

| Mistake                                                         | Symptom                                                           | Fix                                                                                                                                               |
| --------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Missing `rsc_payload_route` in routes                           | 404 on RSC payload requests                                       | Add `rsc_payload_route` to `config/routes.rb`                                                                                                     |
| Only 2 webpack bundles (forgot RSC)                             | Components remain Client Components after removing `'use client'` | Create `rscWebpackConfig.js` and add to build pipeline ([Step 4](rsc-preparing-app.md#step-4-set-up-the-rsc-webpack-bundle))                      |
| `'use client'` on bundle entry files instead of component files | Can't migrate components individually                             | Move `'use client'` to each component source file ([Step 5](rsc-preparing-app.md#step-5-add-use-client-to-all-registered-component-entry-points)) |
| Missing `'use client'` on `.server.jsx` files                   | Auto-bundled components break after enabling RSC                  | `.server.jsx` is a bundle convention, not an RSC designation -- add `'use client'` to both `.client.jsx` and `.server.jsx`                        |
| React version duplicates in `node_modules`                      | Cryptic hook errors, "Invalid hook call"                          | Deduplicate with `yarn why react` and webpack aliases                                                                                             |
| Not switching to `stream_react_component`                       | No streaming benefits, components render synchronously            | Replace `react_component` with `stream_react_component` in views                                                                                  |
| Missing `include ReactOnRailsPro::Stream` in controller         | `stream_view_containing_react_components` undefined               | Add the concern to controllers that render React components                                                                                       |

## Prerequisites

- React 19+
- [React on Rails Pro](../../pro/react-on-rails-pro.md) 4+ with React on Rails 15+
- Node renderer configured (RSC requires server-side JavaScript execution)
- RSC webpack bundle configured (see [RSC tutorial](../../pro/react-server-components/tutorial.md))
- Node.js 20+
- Understanding of the [server vs client component mental model](https://react.dev/reference/rsc/server-components)

## Related Guides

- [Upgrading an Existing Pro App to RSC](../../pro/react-server-components/upgrading-existing-pro-app.md) — generator-based runbook for adding RSC to an existing Pro app, including legacy webpack compatibility and verification checklist
- [React 19 Native Metadata](../building-features/react-19-native-metadata.md) — replace react-helmet and `react_component_hash` with React 19's built-in `<title>`, `<meta>`, and `<link>` hoisting. Native metadata works with streaming and RSC out of the box.
- [HTTP Response Ownership](rsc-http-response-patterns.md) — keep `404`, redirects, and cache policy in Rails while rendering route UI with RSC.
- [RSC Performance Validation](rsc-performance-validation.md) — build the visual plus performance evidence package before claiming an RSC win.
- [Mostly Static RSC Shell With a Tiny Sidecar](rsc-static-shell-sidecar.md) — keep public RSC shells static while moving small browser behaviors into an explicit sidecar.

## References

- [React Server Components RFC](https://react.dev/reference/rsc/server-components)
- [React `'use client'` directive](https://react.dev/reference/rsc/use-client)
- [React on Rails Pro RSC tutorial](../../pro/react-server-components/tutorial.md)
- [React on Rails Pro RSC purpose and benefits](../../pro/react-server-components/purpose-and-benefits.md)
- [RSC migration success stories](../../pro/react-server-components/success-stories.md)
