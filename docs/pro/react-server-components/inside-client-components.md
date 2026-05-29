# Embedding Server Components in Client Components

React doesn't normally allow a client component to directly render a server component. React on Rails Pro provides a way around this using the `RSCRoute` component, which lets you embed server components inside client component trees. This guide covers when to use it, how it works, the complete setup, and the patterns for routing, error handling, and performance.

## When to use this feature

Use this feature when a `'use client'` component needs to render server components at some point in its tree. The most common case is **client-side routing with server-rendered routes** — for example, a React Router app where some routes are server components that render server-prepared data.

**You probably don't need this feature if:**

- Your server component is the top-level component rendered by Rails. Use `registerServerComponent` directly. See [Create a React Server Component](./create-without-ssr.md).
- The server component's props change frequently. Every unique combination of `componentName` and props triggers an HTTP request for a fresh RSC payload, so this is not a good fit for components whose props change on every keystroke, interval, or animation frame.

## How it works

When React on Rails Pro encounters `<RSCRoute componentName="Dashboard" componentProps={{ user }} />` inside a client component, it does **not** look up a client-side implementation of `Dashboard`. Instead, it references the server component by name and relies on the framework to deliver its RSC payload:

1. **During server-side rendering**, the server renders `Dashboard` alongside the client component tree and embeds its RSC payload directly in the HTML response. When the browser hydrates, `RSCRoute` reads the embedded payload — no extra HTTP request.
2. **During client-side navigation**, when `RSCRoute` appears in the tree for the first time (e.g., the user navigates to a new route), the client fetches the RSC payload from the server over HTTP and renders it.
3. **When props change**, a new HTTP request is made for each unique combination of `componentName` and props. Identical combinations are cached (see [Performance and caching behavior](#performance-and-caching-behavior)).

For this to work, the client component tree must be wrapped with `wrapServerComponentRenderer`, which provides the context `RSCRoute` relies on internally. You never need to create an `RSCProvider` yourself — wrapping with `wrapServerComponentRenderer` (or using `registerServerComponent` directly) sets it up automatically.

## Walkthrough: A router with server component routes

This walkthrough builds a client-side router where some routes are server components that render server-prepared data. Let's build an app with two routes: a `Dashboard` and a `Profile`, each rendered as a server component.

### 1. Create the server components

Server components are regular React components **without** a `'use client'` directive. They run on the server and render from data passed as props — in React on Rails, Rails prepares that data (see [step 5](#5-render-from-the-rails-view)).

```jsx
// components/Dashboard.jsx (no 'use client' — this is a server component)
const Dashboard = ({ user }) => {
  return <div>Welcome back, {user.name}</div>;
};
export default Dashboard;
```

```jsx
// components/Profile.jsx
const Profile = ({ user }) => {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.bio}</p>
    </div>
  );
};
export default Profile;
```

> **React on Rails note:** These server components receive `user` as a prop rather than calling `await fetchUser(userId)`. The Node renderer that produces the RSC payload has no Rails models or database connection, and an in-component fetch would bypass Rails' authorization and caching. Rails loads the user in the controller and passes it down the tree (Rails view → `AppRouter` → `RSCRoute` `componentProps`). If you want data to resolve asynchronously while the rest of the page streams, don't fetch inside the component — use [async props](../../oss/migrating/rsc-data-fetching.md#async-props-stream-each-slow-prop-independently), where Rails emits each prop as it's ready and the component awaits it under `<Suspense>`. See [RSC Data Fetching Patterns](../../oss/migrating/rsc-data-fetching.md).
>
> **Security:** `componentProps` are serialized into the RSC payload and, on each client-side navigation, sent from the browser to the RSC payload endpoint verbatim — so they are client-visible and can be tampered with. Pass only display-safe fields (the [step-5 view](#5-render-from-the-rails-view) uses `only: [:id, :name, :bio]`) and never use `componentProps` as a trust anchor. Passing `user.id` for display or linking is fine; the hazard is using it for **authorization** — the RSC payload endpoint must identify the current user from the Rails session, not from props, and re-derive anything security-sensitive server-side.

### 2. Create the client component that uses `RSCRoute`

This component references server components **by name** via `RSCRoute` — it does not import them. It doesn't need a `'use client'` directive itself because it's imported by the wrapper files (Step 3), which declare the client boundary.

```tsx
// components/AppRouter.tsx
import { Routes, Route, Link } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function AppRouter({ user }) {
  return (
    <>
      <nav>
        <Link to="/dashboard">Dashboard</Link>
        <Link to="/profile">Profile</Link>
      </nav>
      <Routes>
        <Route path="/dashboard" element={<RSCRoute componentName="Dashboard" componentProps={{ user }} />} />
        <Route path="/profile" element={<RSCRoute componentName="Profile" componentProps={{ user }} />} />
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

Use `stream_react_component` to render the wrapped component. Rails loads the user and passes it as a prop, so the server components don't fetch it themselves:

```erb
<%= stream_react_component("AppRouter",
      props: { user: current_user.as_json(only: [:id, :name, :bio]) }) %>
```

> [!IMPORTANT]
> You **must** use `stream_react_component`, not `react_component`, whenever the component tree uses `RSCRoute`. The server variant of `wrapServerComponentRenderer` will throw a descriptive error if you use `react_component`.

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

Auto-bundling does **not** handle **wrapping**. You must still author `AppRouter.client.tsx` and `AppRouter.server.tsx` yourself with `wrapServerComponentRenderer` as shown in [Step 3 of the walkthrough](#3-wrap-the-client-component-for-both-bundles). The generator uses whatever you export from those files as the "AppRouter" component in each bundle.

> [!IMPORTANT]
> The `.server.tsx` / `.client.tsx` variants here are legitimate because both wrappers are **client components** (both start with `'use client'`) that happen to use different imports for client-side vs server-side rendering. **Do not** apply the `.client` / `.server` suffixes to the actual server components referenced by `RSCRoute` (`Dashboard.jsx`, `Profile.jsx`). Server components have no client-side variant — their code never runs in the browser. See [the RSC variant rules](../../oss/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#when-to-use-client--server-variants-with-rsc) for details.

## Performance and caching behavior

Understanding how RSC payloads are fetched and cached is critical to using this feature effectively.

### Server-side rendering (initial page load)

When the page is server-rendered, the RSC payloads for all `RSCRoute` components on that page are generated during SSR and embedded directly in the HTML response. When the browser hydrates, `RSCRoute` reads the embedded payload — **no extra network round-trip**.

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

export default function ProfilePage({ user }) {
  return (
    <ErrorBoundary FallbackComponent={RetryFallback}>
      <RSCRoute componentName="Profile" componentProps={{ user }} />
    </ErrorBoundary>
  );
}
```

> [!NOTE]
> `useRSC` is available anywhere inside a tree set up by `wrapServerComponentRenderer` or `registerServerComponent` (including the auto-bundled versions). You never need to create an `RSCProvider` manually — the context is always set up for you.

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

Wrap `RSCRoute` in `Suspense` to show a loading indicator while the RSC payload is being fetched. This is relevant for client-side navigation — during SSR, the payload is already embedded in the HTML.

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
| `RSCRoute`                             | `react-on-rails-pro/RSCRoute`                                                                | Default     | Renders a server component inside a client component. Props: `componentName: string`, `componentProps: object`.                                                                                                                 |
| `wrapServerComponentRenderer` (client) | `react-on-rails-pro/wrapServerComponentRenderer/client`                                      | Default     | Wraps a `'use client'` component for client-side hydration. Provides the context `RSCRoute` needs internally. The wrapped result must be registered with `ReactOnRails.register` unless you use auto-bundling.                  |
| `wrapServerComponentRenderer` (server) | `react-on-rails-pro/wrapServerComponentRenderer/server`                                      | Default     | Same as above, for server-side rendering. The wrapped function receives `railsContext` as its second argument.                                                                                                                  |
| `registerServerComponent` (client)     | `react-on-rails-pro/registerServerComponent/client`                                          | Default     | Registers server component placeholders in the client bundle. Takes names as strings: `registerServerComponent('A', 'B')`. The client fetches the RSC payload from the server or uses the payload already embedded in the HTML. |
| `registerServerComponent` (server)     | `react-on-rails-pro/registerServerComponent/server`                                          | Default     | Registers server components in the server bundle. Takes an object: `registerServerComponent({ A, B })`.                                                                                                                         |
| `useRSC`                               | `import { useRSC } from 'react-on-rails-pro/RSCProvider'`                                    | **Named**   | Hook providing `refetchComponent(name, props)` for manual refetch and error recovery. Available anywhere inside a tree set up by `wrapServerComponentRenderer` or `registerServerComponent`.                                    |
| `isServerComponentFetchError`          | `import { isServerComponentFetchError } from 'react-on-rails-pro/ServerComponentFetchError'` | **Named**   | Type guard to check if an error came from a failed server component fetch. The error has `serverComponentName` and `serverComponentProps` fields.                                                                               |

## Troubleshooting

**Error: "Component 'X' is registered as a server component but is being rendered with the react_component helper"**

This error occurs when using `react_component` with `prerender: true` (or the default prerender setting). The server-side `wrapServerComponentRenderer` requires streaming capabilities that only `stream_react_component` provides. Either switch to `stream_react_component`, or if you don't need SSR, use `react_component` with `prerender: false` — RSCRoute will fetch the RSC payload over HTTP on the client side.

**Empty content where the server component should appear**

Check the browser's network tab — is the request to your RSC payload endpoint (derived from `rsc_payload_generation_url_path` config, default `/rsc_payload/:componentName`) succeeding? If not:

- Make sure the server component is registered in your server bundle with `registerServerComponent({ ComponentName })`.
- Make sure `rsc_payload_route` is mounted in `config/routes.rb`.
- Make sure the component name in `<RSCRoute componentName="…" />` matches the registration exactly.

**`useRSC` returns `undefined` or throws**

The component calling `useRSC` is not inside a tree set up by `wrapServerComponentRenderer` or `registerServerComponent`. Make sure you registered the `.client.tsx` / `.server.tsx` variants (not the raw client component), or that auto-bundling is picking them up correctly.

**The bundler complains about importing a server component from a client component**

You should never import a server component directly from a client component. Reference it by name with `<RSCRoute componentName="…" />` instead.
