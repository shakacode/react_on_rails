# Migrating Your React App to React Server Components

This guide covers the React-side challenges of migrating an existing React on Rails application to React Server Components (RSC). It focuses on how to restructure your component tree, handle Context and state management, migrate data fetching patterns, deal with third-party library compatibility, and avoid common pitfalls.

> **React on Rails Pro required:** RSC support requires [React on Rails Pro](https://pro.reactonrails.com/) 4+ with the node renderer. The Pro gem provides the streaming view helpers (`stream_react_component`, `rsc_payload_react_component`), the RSC webpack plugin and loader, and the `registerServerComponent` API. For setup, see the [RSC tutorial](../../pro/react-server-components/tutorial.md). For upgrade steps, see the [performance breakthroughs guide](../../pro/major-performance-breakthroughs-upgrade-guide.md).

## Why Migrate?

React Server Components offer significant performance benefits when used correctly:

- Significant reductions in client-side bundle size reported across RSC adoption case studies
- Improvements in Google Speed Index and Total Blocking Time
- Server-only dependencies (date-fns, marked, sanitize-html) never ship to the client

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

### 5. [Third-Party Library Compatibility](rsc-third-party-libs.md)

How to handle libraries that aren't RSC-compatible. Covers:

- Creating thin `'use client'` wrapper files
- CSS-in-JS migration (styled-components, Emotion alternatives)
- UI library compatibility (MUI, Chakra, Radix, shadcn/ui)
- Form, animation, charting, and date library status
- The barrel file problem and direct imports
- Using `server-only` and `client-only` packages

### 6. [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md)

How to debug and avoid common problems. Covers:

- Serialization boundary issues (what can cross server-to-client)
- Import chain contamination and accidental client components
- Hydration mismatch debugging
- Error boundary limitations with RSC
- Testing strategies (unit, integration, E2E)
- TypeScript considerations
- Performance monitoring and bundle analysis tools
- Common error messages and their solutions

## How RSC Maps to React on Rails

Before diving into the React patterns, understand how RSC maps to React on Rails' architecture.

**Multiple component roots.** Unlike single-page apps with one `App.jsx` root, React on Rails renders independent component trees from ERB views. Each `react_component` or `stream_react_component` call is a separate root. You migrate **per-component**, not per-app.

**Three API changes per component.** Each component you migrate touches three layers:

| Layer           | Before                               | After                                                         |
| --------------- | ------------------------------------ | ------------------------------------------------------------- |
| ERB view helper | `react_component("Product", ...)`    | `stream_react_component("Product", ...)`                      |
| JS registration | `ReactOnRails.register({ Product })` | `registerServerComponent({ Product })` (in all three bundles) |
| Controller      | Standard Rails controller            | Add `include ReactOnRailsPro::Stream`                         |

**Three webpack bundles.** RSC requires separate client, server, and RSC bundles. The `registerServerComponent` API behaves differently in each:

- **RSC bundle** -- registers the actual Server Component for RSC payload generation
- **Server bundle** -- wraps the component for streaming SSR
- **Client bundle** -- registers a placeholder that fetches the RSC payload from the server

> **Setup instructions:** For webpack configuration, bundle structure, route setup, and step-by-step instructions, see the [React on Rails Pro RSC tutorial](../../pro/react-server-components/tutorial.md). This guide focuses on the **React-side patterns** you'll need after setup is complete.

## Quick-Start Migration Strategy

Tailored for React on Rails' multi-root architecture:

1. **[Prepare your app](rsc-preparing-app.md)** -- set up the RSC infrastructure, add `'use client'` to all component entry points, and switch to streaming rendering. The app works identically -- nothing changes yet.
2. **Pick a component and push the boundary down** -- move `'use client'` from the root component to its interactive children, letting parent components become Server Components.
3. **Adopt advanced patterns** -- add Suspense boundaries, [async props](rsc-data-fetching.md#data-fetching-in-react-on-rails-pro) for streaming data from Rails, and server-side data fetching.
4. **Repeat for each registered component** -- migrate components one at a time, in any order.

This approach lets you migrate incrementally, one component at a time, without ever breaking your app.

## Component Audit Checklist

Before you start, audit your components using this classification:

| Category                  | Criteria                                                   | Action                                                                |
| ------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------- |
| **Server-ready** (green)  | No hooks, no browser APIs, no event handlers               | Remove `'use client'` -- these are Server Components by default       |
| **Refactorable** (yellow) | Mix of data fetching and interactivity                     | Split into a Server Component (data) + Client Component (interaction) |
| **Client-only** (red)     | Uses `useState`, `useEffect`, event handlers, browser APIs | Keep `'use client'` -- these remain Client Components                 |

## Prerequisites

- React 19+
- [React on Rails Pro](https://pro.reactonrails.com/) 4+ with React on Rails 15+
- Node renderer configured (RSC requires server-side JavaScript execution)
- RSC webpack bundle configured (see [RSC tutorial](../../pro/react-server-components/tutorial.md))
- Node.js 20+
- Understanding of the [server vs client component mental model](https://react.dev/reference/rsc/server-components)

## Related Guides

- [React 19 Native Metadata](../building-features/react-19-native-metadata.md) — replace react-helmet and `react_component_hash` with React 19's built-in `<title>`, `<meta>`, and `<link>` hoisting. Native metadata works with streaming and RSC out of the box.

## References

- [React Server Components RFC](https://react.dev/reference/rsc/server-components)
- [React `'use client'` directive](https://react.dev/reference/rsc/use-client)
- [React on Rails Pro RSC tutorial](../../pro/react-server-components/tutorial.md)
- [React on Rails Pro RSC purpose and benefits](../../pro/react-server-components/purpose-and-benefits.md)
