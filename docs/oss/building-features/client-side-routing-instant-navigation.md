# Client-Side Routing & Instant Navigation

React on Rails defaults to **component-per-page**: each page is its own `react_component` mount, and clicking a link is a normal Rails request. That is the right default for incremental adoption — but teams building a substantial React section often want **SPA navigation**: instant client-side transitions, a persistent shell layout that never unmounts, and server-driven data per route.

This guide shows the **opt-in starter pattern** for exactly that, built entirely from existing React on Rails Pro APIs:

- [`createTanStackRouterRenderFunction`](./tanstack-router.md) — SSR + hydration for a TanStack Router app
- [`RSCRoute`](../../pro/react-server-components/inside-client-components.md) — streams a React Server Component's payload from a Rails endpoint during client navigation

A complete runnable example lives in the Pro dummy app — see [Working example](#working-example-in-this-repo) below.

## Opt-In, Not a Takeover

The starter is **a React-routed island inside a normal Rails app**, not a framework takeover:

- One Rails catch-all route hands a URL subtree (for example `/dashboard/*`) to the React router. Every other route stays server-rendered Rails (ERB, Hotwire, anything).
- Inertia replaces the view layer per route; Next.js owns the whole app. Here, the rest of your app doesn't change.
- You can mount several independent React-routed sections, or none — adoption stays incremental.

## Requirements

| Capability                           | Needs                                                                                  |
| ------------------------------------ | -------------------------------------------------------------------------------------- |
| Client-only TanStack Router (no SSR) | Open-source React on Rails — it's just a React app                                     |
| SSR of the initial route             | **Pro**: Node Renderer + `config.rendering_returns_promises = true`                    |
| `RSCRoute` server-component routes   | **Pro**: RSC support enabled (`enable_rsc_support`, `rsc_payload_generation_url_path`) |

See [Using TanStack Router](./tanstack-router.md) for the SSR helper details and [React Server Components inside client components](../../pro/react-server-components/inside-client-components.md) for `RSCRoute`.

## Why TanStack Router?

The starter blesses **TanStack Router** because it is the router with a first-class React on Rails Pro SSR helper (`react-on-rails-pro/tanstack-router`), end-to-end TypeScript route types, and built-in data loading.

**React Router remains the documented manual alternative.** [Using React Router](./react-router.md) covers the manual integration pattern, and recommends React Router **v6** over v7 (v7 merged with Remix and uses an architecture that is not a clean fit for React on Rails' manual SSR approach). If your team is already a React Router shop, that guide is the supported path — the starter pattern here (catch-all Rails route, persistent layout, scoped Turbo boundary) carries over; only the SSR dehydration/hydration helper is TanStack-specific.

## The Starter, Piece by Piece

### 1. One Rails route owns the subtree

```ruby
# config/routes.rb
get "dashboard(/*all)" => "dashboard#index", as: :dashboard
```

Every URL under `/dashboard` renders the same view, so deep links server-render the matching route and navigation after that is client-side.

### 2. The view mounts the app and scopes Turbo off

Prepare request-specific route data in Rails first (for example, `@reports = current_user.reports.visible.select(:id, :title)` in the controller), then pass display-safe fields into the React-routed island:

```erb
<%# app/views/dashboard/index.html.erb %>
<div data-turbo="false">
  <%= react_component("DashboardApp",
                      props: {
                        reports: @reports.as_json(only: [:id, :title])
                      },
                      prerender: true,
                      raise_on_prerender_error: true) %>
</div>
```

`raise_on_prerender_error: true` makes SSR failures raise during development and test instead of silently serving a broken page. Decide separately whether that behavior fits your production error-handling policy.

The `data-turbo="false"` boundary keeps Turbo Drive from intercepting link clicks inside the React-routed subtree, so the two routers never compete. Outside this boundary, Turbo keeps working as usual. This guide does not address **deeper Turbo integration** (shared back/forward handling, scroll restoration across the boundary, Turbo Frames around streamed HTML) — that coexistence track is open in [issue #3485](https://github.com/shakacode/react_on_rails/issues/3485).

### 3. A persistent shell layout with nested routes

```jsx
'use client';

import React, { Suspense, useEffect, useState } from 'react';
import {
  Link,
  Outlet,
  RouterProvider,
  createBrowserHistory,
  createMemoryHistory,
  createRootRoute,
  createRoute,
  createRouter,
} from '@tanstack/react-router';
import { createTanStackRouterRenderFunction } from 'react-on-rails-pro/tanstack-router';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

// The shell renders once and stays mounted across navigations.
// Anything stateful here (sidebar state, form drafts, websocket
// connections) survives route changes.
const ReportDataContext = React.createContext({ reports: [] });

const ShellLayout = () => {
  const [count, setCount] = useState(0);
  return (
    <div>
      <nav>
        <Link to="/dashboard">Home</Link>
        <Link to="/dashboard/reports">Reports</Link>
        <button type="button" onClick={() => setCount((c) => c + 1)}>
          Clicks: {count} {/* survives navigation — the shell never unmounts */}
        </button>
      </nav>
      <Outlet />
    </div>
  );
};

const HomePage = () => <h2>Home</h2>;

// An RSCRoute-backed route: the page's content is a React Server
// Component, streamed from a Rails endpoint when the user navigates here.
// componentProps are serialized into the payload request, so the server
// component receives them when the payload is generated (see step 4).
//
// The mounted guard keeps RSCRoute out of the server render: with the
// react_component entry point, RSC payloads cannot be generated during the
// initial SSR (that needs wrapServerComponentRenderer +
// stream_react_component), so deep links server-render the placeholder and
// the client fetches the payload after mount — the same path used on
// client-side navigation.
const ReportsPage = () => {
  const { reports } = React.useContext(ReportDataContext);
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <p>Loading reports...</p>;
  }

  return (
    <Suspense fallback={<p>Loading reports...</p>}>
      <RSCRoute componentName="Reports" componentProps={{ reports }} />
    </Suspense>
  );
};

const rootRoute = createRootRoute({ component: ShellLayout });
const routeTree = rootRoute.addChildren([
  createRoute({ getParentRoute: () => rootRoute, path: '/dashboard', component: HomePage }),
  createRoute({ getParentRoute: () => rootRoute, path: '/dashboard/reports', component: ReportsPage }),
]);

const DashboardApp = createTanStackRouterRenderFunction(
  {
    AppWrapper: ({ children, reports = [] }) => (
      <ReportDataContext.Provider value={{ reports }}>{children}</ReportDataContext.Provider>
    ),
    createRouter: () =>
      createRouter({
        routeTree,
        // The Rails catch-all forwards every /dashboard/* path to this app,
        // so give unmatched URLs a real page instead of a blank Outlet.
        defaultNotFoundComponent: () => <h2>Page not found</h2>,
      }),
  },
  { RouterProvider, createMemoryHistory, createBrowserHistory },
);

export default DashboardApp;
```

With [auto-bundling](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md), placing this file in your components subdirectory registers it automatically — the generated client pack also sets up the default RSC provider that `RSCRoute` needs in the browser.

### 4. The server component

`Reports` is a plain React Server Component (no `'use client'` directive). Its code never ships to the browser; only its rendered payload does:

```jsx
import React from 'react';

const Reports = ({ reports = [] }) => (
  <ul>
    {reports.map((r) => (
      <li key={r.id}>{r.title}</li>
    ))}
  </ul>
);

export default Reports;
```

> [!IMPORTANT]
> The RSC payload is generated by the Pro **Node renderer**, which has no Rails models, database connection, or user session — so a server component must not reach into Rails directly, and an in-component fetch bypasses Rails' authorization and caching.
>
> - Let Rails resolve request-specific data first, then pass only display-safe data as props: through `RSCRoute` `componentProps` (serialized into the payload request, as above) or via [async props](../migrating/rsc-data-fetching.md#async-props-stream-each-slow-prop-independently), where Rails resolves each prop and the component awaits it under `<Suspense>`.
> - **Never use `componentProps` for authorization.** Client navigation re-sends `componentProps` to the RSC payload endpoint; an attacker can send arbitrary values. Re-derive security-sensitive state (current user, permissions, tenant) from the Rails session inside the controller or a Pro async prop, not from client-supplied props.
>
> See [RSC Data Fetching Patterns](../migrating/rsc-data-fetching.md) for the full set of options.

### How navigation behaves

- **Initial page load**: Rails serves SSR HTML for whatever route the URL matches; the client hydrates it. Deep links work because the Rails catch-all route renders the same component for the whole subtree.
- **Client navigation**: TanStack Router swaps only the route outlet. The shell stays mounted, and no Rails page load happens.
- **Navigating to an `RSCRoute` route**: the client fetches the server component's RSC payload over HTTP from the Rails `rsc_payload` endpoint and streams it into the outlet — server-driven data with no separate JSON API layer.
- **Direct visit to the `RSCRoute` route**: the mounted guard means the server renders the placeholder and the client fetches the RSC payload after hydration. Server-rendering the RSC payload during the initial page load requires the `wrapServerComponentRenderer` + `stream_react_component` setup described in [the RSC guide](../../pro/react-server-components/inside-client-components.md), which is a different entry point than the TanStack SSR helper.
- **Repeat visits to an `RSCRoute` route**: this starter does not cache the RSC payload between visits to the same route; each revisit refetches. Payload caching is tracked in [issue #3564](https://github.com/shakacode/react_on_rails/issues/3564).

## How This Compares

**vs. Next.js App Router.** Next gives file-system routing with nested layouts that persist across navigations, streaming, and route prefetching — but it owns the entire app. The starter gives you the same persistent-layout, instant-navigation experience for a section of a Rails app, with React Server Components streamed from your Rails app's `rsc_payload` endpoint (Rails prepares the data — no separate backend to run). There is no file-system routing convention here — routes are explicit code.

**vs. Inertia (inertia-rails).** Inertia's `<Link>` gives SPA navigation with server-driven props, plus prefetch and partial reloads, but it replaces the Rails view layer for every Inertia-rendered route. The starter is scoped: the React router owns one URL subtree, and `RSCRoute` streams server components (not just JSON props) per route. Inertia currently ships link prefetching out of the box; this starter does not (see below).

**Honest gaps (current state).**

- **No prefetch or RSC payload caching yet.** No hover/viewport prefetch API exists yet for warming RSC payloads before navigation — that depends on the RSC payload cache work tracked in [issue #3564](https://github.com/shakacode/react_on_rails/issues/3564).
- **Repeat-visit flash on `RSCRoute` routes.** When the user navigates away from an `RSCRoute`-backed route and returns, TanStack Router unmounts the outlet component, so the placeholder briefly reappears before the payload is refetched. You can avoid that by lifting mount state above the outlet, but the starter keeps the simpler local-state pattern.
- **Turbo coexistence is scoped-off, not integrated.** Deeper Turbo integration is tracked in [issue #3485](https://github.com/shakacode/react_on_rails/issues/3485).

## Working Example in This Repo

The Pro dummy app contains the full runnable starter, exercised by a system test:

- App: `react_on_rails_pro/spec/dummy/client/app/ror-auto-load-components/TanStackStarterApp.jsx`
- Server component: `react_on_rails_pro/spec/dummy/client/app/ror-auto-load-components/StarterServerData.jsx`
- Rails route/controller/view: `react_on_rails_pro/spec/dummy/config/routes.rb` (`tanstack_starter`), `react_on_rails_pro/spec/dummy/app/controllers/tanstack_starter_controller.rb`, `react_on_rails_pro/spec/dummy/app/views/tanstack_starter/index.html.erb`
- System test (SSR, persistent layout, no-reload navigation, RSC streaming): `react_on_rails_pro/spec/dummy/spec/system/tanstack_starter_spec.rb`

The dummy keeps the running example intentionally small: it passes `props: {}`, so it does not need the `AppWrapper`/`ReportDataContext` pattern shown in Step 3. Use that Step 3 pattern when Rails passes request-specific data into the routed island.
