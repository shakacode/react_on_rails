# Embedding Server Components in Client Components

React doesn't normally allow a client component to directly render a server component. React on Rails Pro provides a way around this using the `RSCRoute` component, which lets you embed server components inside client component trees. This guide covers when to use it, how it works, the complete setup, and the patterns for routing, error handling, and performance.

## When to use this feature

Use this feature when a `'use client'` component needs to render server components at some point in its tree. The most common case is **client-side routing with server-rendered routes** — for example, a React Router app where some routes are server components that fetch data on the server.

**You probably don't need this feature if:**

- Your server component is the top-level component rendered by Rails. Use `registerServerComponent` directly. See [Create a React Server Component](./create-without-ssr.md).
- The server component's props change frequently. Every unique combination of `componentName` and props triggers an HTTP request for a fresh RSC payload, so this is not a good fit for components whose props change on every keystroke, interval, or animation frame.

## How it works

When React on Rails Pro encounters `<RSCRoute componentName="Dashboard" componentProps={{ userId: 42 }} />` inside a client component, it does **not** look up a client-side implementation of `Dashboard`. Instead, it references the server component by name and relies on the framework to deliver its RSC payload. By default, `RSCRoute` uses `ssr={true}`, so it participates in server-side rendering for the initial request:

1. **During server-side rendering**, the server renders `Dashboard` alongside the client component tree and embeds its RSC payload directly in the HTML response. When the browser hydrates, `RSCRoute` reads the embedded payload — no extra HTTP request.
2. **During client-side navigation**, when `RSCRoute` appears in the tree for the first time (e.g., the user navigates to a new route), the client fetches the RSC payload from the server over HTTP and renders it.
3. **When props change**, a new HTTP request is made for each unique combination of `componentName` and props. Identical combinations are cached (see [Performance and caching behavior](#performance-and-caching-behavior)).

For this to work, the client component tree needs the React on Rails Pro RSC provider context. For server-rendered `RSCRoute` payloads, `wrapServerComponentRenderer` sets up that context. For auto-bundled roots that only defer `RSCRoute` payloads with `ssr={false}`, React on Rails Pro registers a default client provider in the generated client pack when RSC support is enabled. You never need to create an `RSCProvider` yourself.

### Deferring initial server rendering with `ssr={false}`

For lower-priority server component routes, pass `ssr={false}` to skip that route during the initial server render:

```tsx
<RSCRoute componentName="Recommendations" componentProps={{ userId }} ssr={false} />
```

Use this for below-the-fold, collapsed, or secondary content that does not need to be fully rendered in the initial HTML. During streaming SSR, the route intentionally bails out before generating or embedding that route's RSC payload. If the route is inside a scoped `Suspense` boundary, React emits that boundary's fallback HTML and retries the route on the client. In auto-bundled client-rendered roots, the initial Rails response contains only the root mount point and the browser fetches the RSC payload after the root renders. In auto-bundled streaming roots where every `RSCRoute` payload is deferred with `ssr={false}`, the server can stream scoped `Suspense` fallbacks without a manual RSC renderer wrapper. In all cases, the route uses the same `RSCProvider` path as any other `RSCRoute`: provider cache lookup, payload fetch or embedded-payload reuse when available, `PromiseWrapper`, `ServerComponentFetchError`, and the existing retry patterns all still apply.

The tradeoff is that the deferred content appears later. The browser must resolve the RSC payload during hydration or client rendering, so users will see the nearest `Suspense` fallback until the server component appears. Place `Suspense` close to the deferred route so the loading UI is scoped to that route instead of replacing a large part of the page.

```tsx
import { Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function Sidebar({ userId }) {
  return (
    <Suspense fallback={<div>Loading recommendations…</div>}>
      <RSCRoute componentName="Recommendations" componentProps={{ userId }} ssr={false} />
    </Suspense>
  );
}
```

## Walkthrough: A router with server component routes

This walkthrough builds a client-side router where some routes are server components that fetch data on the server. Let's build an app with two routes: a `Dashboard` and a `Profile`, each rendered as a server component.

### 1. Create the server components

Server components are regular React components **without** a `'use client'` directive. They can be `async` and access server-only resources.

```jsx
// components/Dashboard.jsx (no 'use client' — this is a server component)
const Dashboard = async ({ userId }) => {
  const user = await fetchUser(userId);
  return <div>Welcome back, {user.name}</div>;
};
export default Dashboard;
```

```jsx
// components/Profile.jsx
const Profile = async ({ userId }) => {
  const user = await fetchUser(userId);
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </div>
  );
};
export default Profile;
```

### 2. Create the client component that uses `RSCRoute`

This component references server components **by name** via `RSCRoute` — it does not import them. It doesn't need a `'use client'` directive itself because it's imported by the wrapper files (Step 3), which declare the client boundary.

```tsx
// components/AppRouter.tsx
import { Routes, Route, Link } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function AppRouter({ userId }) {
  return (
    <>
      <nav>
        <Link to="/dashboard">Dashboard</Link>
        <Link to="/profile">Profile</Link>
      </nav>
      <Routes>
        <Route
          path="/dashboard"
          element={<RSCRoute componentName="Dashboard" componentProps={{ userId }} />}
        />
        <Route path="/profile" element={<RSCRoute componentName="Profile" componentProps={{ userId }} />} />
      </Routes>
    </>
  );
}
```

Notice that `AppRouter.tsx` imports `RSCRoute` but does **not** import `Dashboard` or `Profile`. The server components' code stays on the server — only their names travel to the client.

### 3. Wrap the client component for both bundles

`RSCRoute` needs context that is set up by `wrapServerComponentRenderer`. You need two wrapper files — one for client-side hydration and one for server-side rendering — **both with `'use client'`**.

```tsx
// components/AppRouter.client.tsx
'use client';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';
import { BrowserRouter } from 'react-router-dom';
import AppRouter from './AppRouter';

export default wrapServerComponentRenderer((props) => (
  <BrowserRouter>
    <AppRouter {...props} />
  </BrowserRouter>
));
```

```tsx
// components/AppRouter.server.tsx
'use client';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/server';
import { StaticRouter } from 'react-router-dom/server';
import type { RailsContext } from 'react-on-rails-pro';
import AppRouter from './AppRouter';

function ServerAppRouter(props: object, railsContext: RailsContext) {
  const path = railsContext.pathname;
  return () => (
    <StaticRouter location={path}>
      <AppRouter {...props} />
    </StaticRouter>
  );
}

export default wrapServerComponentRenderer(ServerAppRouter);
```

The server wrapper uses `StaticRouter` with the current URL derived from `railsContext` because the router needs to know which route to render during SSR. The client wrapper uses `BrowserRouter` for normal client-side navigation.

### 4. Register the components

If you're **not** using `auto_load_bundle`, you need to register the components manually. The wrapped `AppRouter` is registered with `ReactOnRails.register` in both the client and server bundles. The server components referenced by `RSCRoute` are registered with `registerServerComponent` in the client and server bundles — plus they must be imported in the RSC bundle (the RSC webpack config handles this automatically via the RSC loader; see [Create a React Server Component](./create-without-ssr.md) for the RSC bundle setup).

> [!NOTE]
> Server components only need client-bundle registration if they will also be rendered directly from Rails views via `stream_react_component`. If a server component is **only** used via `RSCRoute` inside a client component (as `Dashboard` and `Profile` are in this walkthrough), you can skip its client-bundle registration. The walkthrough registers them as a safe default.

On the client side, follow the [manual bundle splitting pattern](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#manual-bundle-splitting-pre-auto-bundling-pattern) — one pack file per component so each view only loads the code it needs:

```tsx
// packs/client/AppRouter.tsx
import ReactOnRails from 'react-on-rails-pro';
import AppRouter from '../../components/AppRouter.client';

ReactOnRails.register({ AppRouter });
```

```tsx
// packs/client/Dashboard.tsx
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

registerServerComponent('Dashboard');
```

```tsx
// packs/client/Profile.tsx
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

registerServerComponent('Profile');
```

On the server side, one aggregated entry file registers everything:

```tsx
// packs/server-bundle.tsx
import ReactOnRails from 'react-on-rails-pro';
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/server';
import AppRouter from '../components/AppRouter.server';
import Dashboard from '../components/Dashboard';
import Profile from '../components/Profile';

ReactOnRails.register({ AppRouter });
registerServerComponent({ Dashboard, Profile });
```

Notice the two different shapes of `registerServerComponent`:

- The **server bundle** takes an object (`{ Dashboard, Profile }`) because the actual component code needs to be bundled into the server.
- The **client bundle** takes names as strings (`'Dashboard'`, `'Profile'`) because the client only needs a placeholder — the server component code stays on the server.

For the full reference on the two signatures and how auto-bundling handles them, see [Auto-Bundling with React Server Components](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#auto-bundling-with-react-server-components).

If you **are** using `auto_load_bundle`, you can skip the registration files entirely. See [Auto-bundling with server components](#auto-bundling-with-server-components) below.

### 5. Render from the Rails view

Use `stream_react_component` to render the wrapped component:

```erb
<%= stream_react_component("AppRouter", props: { userId: current_user.id }) %>
```

> [!IMPORTANT]
> Use `stream_react_component`, not `react_component`, whenever the initial response should server-render `RSCRoute` content or stream `Suspense` fallback HTML for `ssr={false}` routes. If you intentionally want a client-rendered root, use `react_component(..., prerender: false)` with auto-bundling and `ssr={false}` routes. The unsupported case is `react_component(..., prerender: true)` for server-rendered RSC usage; the server variant of `wrapServerComponentRenderer` will throw a descriptive error there.

That's the complete setup. The rest of this guide covers how to simplify registration with auto-bundling, understand performance and caching, handle errors, and apply common patterns.

## Auto-bundling with server components

If you enable `auto_load_bundle: true`, React on Rails generates the registration code for you based on the `'use client'` directive and file naming. For the complete story on how auto-bundling classifies components, how it produces client packs and server bundle files, and the rules for using `.client.tsx` / `.server.tsx` variants with RSC, see the canonical reference: [Auto-Bundling with React Server Components](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#auto-bundling-with-react-server-components).

This section covers only what's specific to the `RSCRoute` + `wrapServerComponentRenderer` pattern from this walkthrough.

### File layout for this walkthrough

The auto-bundle directory holds the files you want auto-bundling to **register as entry points** — the components you actually render from Rails views via `react_component` or `stream_react_component`, plus the server components rendered by `RSCRoute` (they also need to be registered so the framework can fetch their RSC payloads by name). In this walkthrough, the entry points are the wrapped variants `AppRouter.client.tsx` and `AppRouter.server.tsx` (not the raw `AppRouter.tsx`), because they are what you want registered under the name `"AppRouter"` in each bundle, plus the server components `Dashboard.jsx` and `Profile.jsx`, which are referenced by name from `RSCRoute`. The raw `AppRouter.tsx` is just implementation code imported by those wrappers, so it lives outside the auto-bundle directory regardless of its filename:

```text
client/app/
├── components/
│   └── AppRouter.tsx                         # implementation only — imported by the wrappers, not an entry point
└── ror-auto-load-components/
    ├── AppRouter.client.tsx                  # 'use client' — entry point, wraps with wrapServerComponentRenderer/client
    ├── AppRouter.server.tsx                  # 'use client' — entry point, wraps with wrapServerComponentRenderer/server
    ├── Dashboard.jsx                         # server component entry point (no 'use client')
    └── Profile.jsx                           # server component entry point (no 'use client')
```

The wrappers import the raw `AppRouter` from `../../components/AppRouter`. Since that file isn't in the scanned directory, auto-bundling never sees it as its own entry point — it's pulled in transitively as part of the wrapped variants' bundles.

### What auto-bundling does and doesn't handle

Auto-bundling takes care of the **registration** layer: it generates the per-component client packs (using `ReactOnRails.register` for the wrapped `AppRouter` and `registerServerComponent` for `Dashboard` / `Profile`) and adds everything to the aggregated server bundle file. You don't need to write `packs/client-bundle.tsx` or modify `packs/server-bundle.tsx` for these components.

For streaming SSR that server-renders any `RSCRoute` payload, auto-bundling does **not** replace the explicit wrappers. You must still author `AppRouter.client.tsx` and `AppRouter.server.tsx` yourself with `wrapServerComponentRenderer` as shown in [Step 3 of the walkthrough](#3-wrap-the-client-component-for-both-bundles). The generator uses whatever you export from those files as the "AppRouter" component in each bundle.

For roots that only use deferred `RSCRoute ssr={false}` payloads, auto-bundling can set up the client RSC provider automatically when RSC support is enabled. Generated client component packs import `react-on-rails-pro/registerDefaultRSCProvider/client` before registering the root. This supports `RSCRoute ssr={false}` in the browser without manually wrapping the root. Fully manual client entrypoints that bypass generated packs can import the same registration module before calling `ReactOnRails.register`.

> [!IMPORTANT]
> The `.server.tsx` / `.client.tsx` variants here are legitimate because both wrappers are **client components** (both start with `'use client'`) that happen to use different imports for client-side vs server-side rendering. **Do not** apply the `.client` / `.server` suffixes to the actual server components referenced by `RSCRoute` (`Dashboard.jsx`, `Profile.jsx`). Server components have no client-side variant — their code never runs in the browser. See [the RSC variant rules](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#when-to-use-client--server-variants-with-rsc) for details.

## Performance and caching behavior

Understanding how RSC payloads are fetched and cached is critical to using this feature effectively.

### Server-side rendering (initial page load)

When the page is server-rendered, the RSC payloads for `RSCRoute` components are generated during SSR and embedded directly in the HTML response by default. When the browser hydrates, `RSCRoute` reads the embedded payload — **no extra network round-trip**.

If a route uses `ssr={false}`, that route is skipped during the initial server render and does not generate an embedded payload for that request. A scoped `Suspense` boundary can still render fallback HTML in the streamed response. On the client retry, the route resolves through the existing provider path and may reuse an equivalent cached payload from the same provider when one already exists; otherwise, it fetches the payload over HTTP.

### Client-side navigation

When a user navigates client-side and a new `RSCRoute` enters the tree, the client makes an HTTP request to fetch the RSC payload from the server. The request URL is derived from the `rsc_payload_generation_url_path` configuration plus the component name and props.

### Caching

RSC payloads are cached in memory by a key of `componentName` + `JSON.stringify(componentProps)`. This means:

- **Identical props** → cached, no new request.
- **Different props** → new request.
- Object identity doesn't matter — the cache compares the serialized JSON.

### Why the "rarely changing props" rule exists

Because every unique prop combination triggers a new HTTP request, `RSCRoute` is a poor fit for components whose props change on every re-render. The router use case works well because route changes are discrete events — the props for each route are stable across navigations.

**Bad example — don't do this:**

```tsx
'use client';
import { useState } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      {/* BAD: every click triggers a new HTTP request */}
      <RSCRoute componentName="ServerCounter" componentProps={{ count }} />
    </div>
  );
}
```

## Error handling

When a server component fetch fails (e.g., network hiccup, server crash, transient error), `RSCRoute` throws a `ServerComponentFetchError` that you can catch with a React error boundary. You can then use the `useRSC` hook to manually refetch the component without a full page reload.

```tsx
'use client';
import { ErrorBoundary } from 'react-error-boundary';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import { useRSC } from 'react-on-rails-pro/RSCProvider';
import { isServerComponentFetchError } from 'react-on-rails-pro/ServerComponentFetchError';

function RetryFallback({ error, resetErrorBoundary }) {
  const { refetchComponent } = useRSC();

  if (isServerComponentFetchError(error)) {
    const { serverComponentName, serverComponentProps } = error;
    return (
      <div>
        <p>Failed to load {serverComponentName}.</p>
        <button
          onClick={() => {
            refetchComponent(serverComponentName, serverComponentProps)
              .catch((err) => console.error('Retry failed:', err))
              .finally(() => resetErrorBoundary());
          }}
        >
          Retry
        </button>
      </div>
    );
  }

  // Not a server component fetch error — let a higher boundary handle it
  throw error;
}

export default function ProfilePage({ userId }) {
  return (
    <ErrorBoundary FallbackComponent={RetryFallback}>
      <RSCRoute componentName="Profile" componentProps={{ userId }} />
    </ErrorBoundary>
  );
}
```

> [!NOTE]
> `useRSC` is available anywhere inside a tree set up by `wrapServerComponentRenderer`, `registerServerComponent`, or the auto-bundled default client provider for deferred-only roots. You never need to create an `RSCProvider` manually — the context is always set up for you.

## Common patterns

### Nested routes

You can nest client and server components to arbitrary depth:

```tsx
'use client';
import { Routes, Route } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import ClientSettings from './ClientSettings';

export default function AppRouter() {
  return (
    <Routes>
      <Route path="/admin" element={<RSCRoute componentName="AdminLayout" />}>
        <Route path="users" element={<RSCRoute componentName="UserList" />} />
        <Route path="settings" element={<ClientSettings />} />
      </Route>
    </Routes>
  );
}
```

### Using `Outlet` in server components

React Router's `Outlet` is a client component (it uses context). To use it inside a server component, re-export it as a client component:

```tsx
// components/Outlet.tsx
'use client';
export { Outlet as default } from 'react-router-dom';
```

Then use it in your server component:

```jsx
// components/AdminLayout.jsx (server component)
import Outlet from './Outlet';

export default function AdminLayout() {
  return (
    <div>
      <h1>Admin</h1>
      <Outlet />
    </div>
  );
}
```

### `Suspense` for loading states

Wrap `RSCRoute` in `Suspense` to show a loading indicator while the RSC payload is being fetched during client-side navigation:

```tsx
'use client';
import { Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function Page({ user }) {
  return (
    <Suspense fallback={<div>Loading…</div>}>
      <RSCRoute componentName="SlowServerComponent" componentProps={{ user }} />
    </Suspense>
  );
}
```

This same scoped `Suspense` pattern is important for `ssr={false}` routes during the initial streaming response. With default `ssr={true}`, the payload is already embedded during SSR. With `ssr={false}`, React on Rails Pro skips the route's server payload work, streams the nearest `Suspense` fallback, and retries the route on the client.

### Conditional rendering

When a server component becomes visible for the first time on the client, it triggers an HTTP request to fetch the RSC payload. Wrap it in `Suspense` to handle the loading state:

```tsx
'use client';
import { useState, Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function DetailsPanel({ id }) {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div>
      <button onClick={() => setIsOpen(!isOpen)}>{isOpen ? 'Hide' : 'Show'} details</button>
      {isOpen && (
        <Suspense fallback={<div>Loading details…</div>}>
          <RSCRoute componentName="Details" componentProps={{ id }} />
        </Suspense>
      )}
    </div>
  );
}
```

## API reference

Unless noted otherwise, each API below is a default export — use default-import syntax.

| API                                    | Import                                                                                       | Export type | Purpose                                                                                                                                                                                                                         |
| -------------------------------------- | -------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RSCRoute`                             | `react-on-rails-pro/RSCRoute`                                                                | Default     | Renders a server component inside a client component. Props: `componentName: string`, `componentProps: object`, `ssr?: boolean` (defaults to `true`; use `false` to defer initial server rendering for this route).             |
| `wrapServerComponentRenderer` (client) | `react-on-rails-pro/wrapServerComponentRenderer/client`                                      | Default     | Wraps a `'use client'` component for client-side hydration. Provides the context `RSCRoute` needs internally. The wrapped result must be registered with `ReactOnRails.register` unless you use auto-bundling.                  |
| `wrapServerComponentRenderer` (server) | `react-on-rails-pro/wrapServerComponentRenderer/server`                                      | Default     | Same as above, for server-side rendering. The wrapped function receives `railsContext` as its second argument.                                                                                                                  |
| `registerServerComponent` (client)     | `react-on-rails-pro/registerServerComponent/client`                                          | Default     | Registers server component placeholders in the client bundle. Takes names as strings: `registerServerComponent('A', 'B')`. The client fetches the RSC payload from the server or uses the payload already embedded in the HTML. |
| `registerServerComponent` (server)     | `react-on-rails-pro/registerServerComponent/server`                                          | Default     | Registers server components in the server bundle. Takes an object: `registerServerComponent({ A, B })`.                                                                                                                         |
| `useRSC`                               | `import { useRSC } from 'react-on-rails-pro/RSCProvider'`                                    | **Named**   | Hook providing `refetchComponent(name, props)` for manual refetch and error recovery. Available anywhere inside a tree set up by `wrapServerComponentRenderer`, `registerServerComponent`, or the default client provider.      |
| `isServerComponentFetchError`          | `import { isServerComponentFetchError } from 'react-on-rails-pro/ServerComponentFetchError'` | **Named**   | Type guard to check if an error came from a failed server component fetch. The error has `serverComponentName` and `serverComponentProps` fields.                                                                               |

## Troubleshooting

**Error: "Component 'X' is registered as a server component but is being rendered with the react_component helper"**

This error occurs when using `react_component` with `prerender: true` (or the default prerender setting). The server-side `wrapServerComponentRenderer` requires streaming capabilities that only `stream_react_component` provides. Either switch to `stream_react_component`, or if you don't need SSR for the RSC route, use `react_component` with `prerender: false`, auto-bundling, and `ssr={false}` — `RSCRoute` will fetch the RSC payload over HTTP on the client side.

**Empty content where the server component should appear**

If the route uses `ssr={false}` without a nearby `Suspense` boundary, the supported streaming wrapper's root `Suspense fallback={null}` may produce an empty area until the route resolves on the client. Add a scoped `Suspense` boundary around the route if you want loading UI in the streamed HTML while the deferred payload is pending.

Check the browser's network tab — is the request to your RSC payload endpoint (derived from `rsc_payload_generation_url_path` config, default `/rsc_payload/:componentName`) succeeding? If not:

- Make sure the server component is registered in your server bundle with `registerServerComponent({ ComponentName })`.
- Make sure `rsc_payload_route` is mounted in `config/routes.rb`.
- Make sure the component name in `<RSCRoute componentName="…" />` matches the registration exactly.

**`useRSC` returns `undefined` or throws**

The component calling `useRSC` is not inside a tree set up by `wrapServerComponentRenderer`, `registerServerComponent`, or the default provider registration for an auto-bundled root that only defers `RSCRoute` payloads with `ssr={false}`. Make sure you registered the `.client.tsx` / `.server.tsx` variants for streaming SSR that server-renders RSC payloads, or that auto-bundling is generating the client pack for your deferred-only root. If you use a fully manual client entrypoint, import `react-on-rails-pro/registerDefaultRSCProvider/client` before registering the root.

**The bundler complains about importing a server component from a client component**

You should never import a server component directly from a client component. Reference it by name with `<RSCRoute componentName="…" />` instead.
