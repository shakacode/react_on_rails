# Migrating Your React App to React Server Components

This guide covers the React-side challenges of migrating an existing React application to React Server Components (RSC). It focuses on how to restructure your component tree, handle Context and state management, migrate data fetching patterns, deal with third-party library compatibility, and avoid common pitfalls.

> **Note:** For React on Rails-specific configuration (enabling RSC support, Webpack setup, node renderer, view helpers), see the [React on Rails Pro RSC documentation](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/) and the [performance breakthroughs guide](../pro/major-performance-breakthroughs-upgrade-guide.md).

## Why Migrate?

React Server Components offer significant performance benefits when used correctly:

- **62% reduction** in client-side bundle size ([Frigade case study](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade))
- **63% improvement** in Google Speed Index
- Total blocking time reduced **from 110ms to 1ms**
- Server-only dependencies (date-fns, marked, sanitize-html) never ship to the client

However, these benefits require intentional architecture changes. Simply adding `'use client'` everywhere preserves the status quo. The guides below walk you through the restructuring needed to capture real gains.

## Article Series

This migration guide is organized as a series of focused articles. We recommend reading them in order, but each is self-contained:

### 1. [Component Tree Restructuring Patterns](rsc-component-patterns.md)

How to restructure your component tree for RSC. Covers:

- The top-down migration strategy (start at layouts, push `'use client'` to leaves)
- The "donut pattern" for wrapping server content in client interactivity
- Splitting mixed components into server and client parts
- Passing Server Components as children to Client Components
- Before/after examples of common restructuring patterns

### 2. [Context, Providers, and State Management](rsc-context-and-state.md)

How to handle React Context and global state in an RSC world. Covers:

- Why Context doesn't work in Server Components and what to do about it
- The provider wrapper pattern (creating `'use client'` provider components)
- Composing multiple providers without "provider hell"
- Migrating Redux, Zustand, and Jotai to work alongside RSC
- Using `React.cache()` as a server-side alternative to Context
- Theme, auth, and i18n provider patterns

### 3. [Data Fetching Migration](rsc-data-fetching.md)

How to migrate from client-side data fetching to server component patterns. Covers:

- Replacing `useEffect` + `fetch` with async Server Components
- Migrating from React Query / TanStack Query (prefetch + hydrate pattern)
- Migrating from SWR (fallback data pattern)
- Avoiding server-side waterfalls with parallel fetching
- Streaming data with the `use()` hook and Suspense
- When to keep client-side data fetching

### 4. [Third-Party Library Compatibility](rsc-third-party-libs.md)

How to handle libraries that aren't RSC-compatible. Covers:

- Creating thin `'use client'` wrapper files
- CSS-in-JS migration (styled-components, Emotion alternatives)
- UI library compatibility (MUI, Chakra, Radix, shadcn/ui)
- Form, animation, charting, and date library status
- The barrel file problem and `optimizePackageImports`
- Using `server-only` and `client-only` packages

### 5. [Troubleshooting and Common Pitfalls](rsc-troubleshooting.md)

How to debug and avoid common problems. Covers:

- Serialization boundary issues (what can cross server-to-client)
- Import chain contamination and accidental client components
- Hydration mismatch debugging
- Error boundary limitations with RSC
- Testing strategies (unit, integration, E2E)
- TypeScript considerations
- Performance monitoring and bundle analysis tools
- Common error messages and their solutions

## Quick-Start Migration Strategy

If you want the shortest path to RSC benefits, follow this strategy from [Mux's migration of 50,000 lines](https://www.mux.com/blog/what-are-react-server-components):

1. **Add `'use client'` to your app entry point** -- everything works as before, nothing breaks
2. **Progressively push the directive lower** -- move `'use client'` from parent components to child components
3. **Adopt advanced patterns** -- add Suspense boundaries, streaming, and server-side data fetching

This three-phase approach lets you migrate incrementally without ever breaking your app.

## Component Audit Checklist

Before you start, audit your components using this classification:

| Category | Criteria | Action |
|----------|----------|--------|
| **Server-ready** (green) | No hooks, no browser APIs, no event handlers | Remove `'use client'` -- these are Server Components by default |
| **Refactorable** (yellow) | Mix of data fetching and interactivity | Split into a Server Component (data) + Client Component (interaction) |
| **Client-only** (red) | Uses `useState`, `useEffect`, event handlers, browser APIs | Keep `'use client'` -- these remain Client Components |

## Prerequisites

- React 19+
- React on Rails 15+ and React on Rails Pro 4+ (for React on Rails projects)
- Node.js 20+
- Understanding of the [server vs client component mental model](https://react.dev/reference/rsc/server-components)

## References

- [React Server Components RFC](https://react.dev/reference/rsc/server-components)
- [React `'use client'` directive](https://react.dev/reference/rsc/use-client)
- [React on Rails Pro RSC tutorial](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/tutorial/)
- [React on Rails Pro RSC purpose and benefits](https://www.shakacode.com/react-on-rails-pro/docs/react-server-components/purpose-and-benefits/)
