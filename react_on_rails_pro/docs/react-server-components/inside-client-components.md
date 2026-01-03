# Using React Server Components Inside Client Components

React on Rails now supports rendering React Server Components (RSC) directly inside React Client Components. This guide explains how to use this feature effectively in your applications.

## Overview

React Server Components provide several benefits.However, React traditionally doesn't allow server components to be directly rendered inside client components. This feature bypasses that limitation.

> [!IMPORTANT]
> This feature should be used judiciously. It's best suited for server components whose props change very rarely, such as router routes. **Do not** use this with components whose props change frequently as it triggers HTTP requests to the server on each re-render.

## Basic Usage

### Before

Previously, server components could only be embedded inside client components if passed as a prop from a parent server component:

```tsx
// Parent Server Component
export default function Parent() {
  return (
    <ClientComponent>
      <ServerComponent />
    </ClientComponent>
  );
}
```

### After

Now, you can render server components directly inside client components using the `RSCRoute` component:

```tsx
'use client';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function ClientComponent() {
  return (
    <div>
      <RSCRoute componentName="ServerComponent" componentProps={{ user }} />
    </div>
  );
}
```

## Setup Steps

### 1. Register your server components

Register your server components in your Server and RSC bundles:

```tsx
// packs/server_bundle.tsx
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/server';
import MyServerComponent from './components/MyServerComponent';
import AnotherServerComponent from './components/AnotherServerComponent';

registerServerComponent({
  MyServerComponent,
  AnotherServerComponent,
});
```

> [!NOTE]
> Server components only need to be registered in the client bundle if they will be rendered directly in Rails views using the `stream_react_component` helper. If you're only using server components inside client components via `RSCRoute`, you can skip client bundle registration entirely. In this case, it's enough to register the server component in the server and RSC bundles.

### 2. Create your client component

Create a client component that uses `RSCRoute` to render server components:

```tsx
// components/MyClientComponent.tsx
'use client';
import { useState } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function MyClientComponent({ user }) {
  return (
    <div>
      <h1>Hello from Client Component</h1>
      <RSCRoute componentName="MyServerComponent" componentProps={{ user }} />
    </div>
  );
}
```

### 3. Wrap your client component

Create client and server versions of your component wrapped with `wrapServerComponentRenderer`:

#### Client version:

```tsx
// components/MyClientComponent.client.tsx
'use client';
import ReactOnRails from 'react-on-rails-pro';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';
import MyClientComponent from './MyClientComponent';

const WrappedComponent = wrapServerComponentRenderer(MyClientComponent);

ReactOnRails.register({
  MyClientComponent: WrappedComponent,
});
```

#### Server version:

```tsx
// components/MyClientComponent.server.tsx
import ReactOnRails from 'react-on-rails-pro';
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/server';
import MyClientComponent from './MyClientComponent';

const WrappedComponent = wrapServerComponentRenderer(MyClientComponent);

ReactOnRails.register({
  MyClientComponent: WrappedComponent,
});
```

### 4. Use in Rails view

```erb
<%= stream_react_component('MyClientComponent', props: { user: current_user.as_json }, prerender: true) %>
```

> [!NOTE]
> You must use `stream_react_component` rather than `react_component` for server components or client components that use server components.

## Use Cases and Examples

### ❌ Bad Example - Frequently Changing Props

```tsx
'use client';
import { useState } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function ClientComponent() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <label>Count: {count}</label>
      {/* BAD EXAMPLE: Server Component props change with each button click */}
      <RSCRoute componentName="ServerComponent" componentProps={{ count }} />
    </div>
  );
}
```

> [!WARNING]
> This implementation will make a server request on every state change, significantly impacting performance.

### ✅ Good Example - Router Integration

```tsx
'use client';
import { Routes, Route, Link } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import AnotherClientComponent from './AnotherClientComponent';

export default function AppRouter({ user }) {
  return (
    <>
      <nav>
        <Link to="/">Home</Link>
        <Link to="/about">About</Link>
        <Link to="/client-component">Client Component</Link>
      </nav>
      <Routes>
        {/* Mix client and server components in your router */}
        <Route path="/client-component" element={<AnotherClientComponent />} />
        {/* GOOD EXAMPLE: Server Component props rarely change */}
        <Route path="/about" element={<RSCRoute componentName="About" componentProps={{ user }} />} />
        <Route path="/" element={<RSCRoute componentName="Home" componentProps={{ user }} />} />
      </Routes>
    </>
  );
}
```

## Advanced Usage

### Nested Routes with Server Components

The framework supports nesting client and server components to arbitrary depth:

```tsx
'use client';
import { Routes, Route } from 'react-router-dom';
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import ServerRouteLayout from './ServerRouteLayout';
import ClientRouteLayout from './ClientRouteLayout';

export default function AppRouter() {
  return (
    <Routes>
      <Route path="/main-server-route" element={<ServerRouteLayout />}>
        <Route path="/server-subroute" element={<RSCRoute componentName="MyServerComponent" />} />
        <Route path="/client-subroute" element={<ClientSubcomponent />} />
      </Route>
      <Route path="/main-client-route" element={<ClientRouteLayout />}>
        <Route path="/client-subroute" element={<ClientSubcomponent />} />
        <Route path="/server-subroute" element={<RSCRoute componentName="MyServerComponent" />} />
      </Route>
    </Routes>
  );
}
```

### Using `Outlet` in Server Components

To use React Router's `Outlet` in server components, create a client version:

```tsx
// ./components/Outlet.tsx
'use client';
export { Outlet as default } from 'react-router-dom';
```

Then use it in your server components:

```tsx
// ./components/ServerRouteLayout.tsx
import Outlet from './Outlet';

export default function ServerRouteLayout() {
  return (
    <div>
      <h1>Server Route Layout</h1>
      <Outlet />
    </div>
  );
}
```

## Auto-Loading Bundles

If you're using the `auto_load_bundle: true` option in your React on Rails configuration, you don't need to manually register components using `ReactOnRails.register`. However, you still need to:

1. Create both client and server wrappers for your components
2. Properly import the environment-specific implementations of `wrapServerComponentRenderer`

## Component Lifecycle

When using server components inside client components:

1. **During Initial SSR**:

   - The server component is rendered on the server
   - Its payload is embedded directly in the HTML response
   - No additional HTTP requests are needed for hydration

2. **During Client Navigation**:

   - When a user navigates to a new route client-side
   - The client makes an HTTP request to fetch the server component payload
   - The route is rendered with the fetched server component

3. **During State Changes**:
   - If a server component's props change, a new HTTP request is made
   - The component is re-rendered with the new props
   - This is why you should avoid frequently changing props

## Performance Considerations

- Page responsiveness is improved because RSC payloads are embedded in the HTML and no additional HTTP requests are needed for hydration
- Client navigation to new routes with server components requires an HTTP request
- Avoid changing server component props frequently
- Consider using suspense boundaries for loading states during navigation

## Common Patterns

### Using a Loading State

```tsx
'use client';
import { Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function ClientComponent({ user }) {
  return (
    <div>
      <Suspense fallback={<div>Loading server component...</div>}>
        <RSCRoute componentName="ServerComponent" componentProps={{ user }} />
      </Suspense>
    </div>
  );
}
```

### Conditional Rendering

```tsx
'use client';
import { useState } from 'react';
import { Suspense } from 'react';
import RSCRoute from 'react-on-rails-pro/RSCRoute';

export default function ClientComponent({ user }) {
  const [showServerComponent, setShowServerComponent] = useState(false);

  return (
    <div>
      <button onClick={() => setShowServerComponent(!showServerComponent)}>
        {showServerComponent ? 'Hide' : 'Show'} Server Component
      </button>

      {showServerComponent && (
        <Suspense fallback={<div>Loading...</div>}>
          <RSCRoute componentName="ServerComponent" componentProps={{ user }} />
        </Suspense>
      )}
    </div>
  );
}
```

> [!NOTE]
> When conditionally rendering server components, an HTTP request will be made when the component becomes visible.

## Best Practices

1. **Use for rarely changing components**: Server components are ideal for routes, layouts, and content that doesn't change frequently.

2. **Always wrap in Suspense**: Server components may load asynchronously, especially after client navigation.

3. **Pass stable props**: Avoid passing state variables that change frequently as props to server components.

4. **Use for data-heavy components**: Components that need to fetch data from databases or APIs are good candidates for server components.

By following these guidelines, you can effectively leverage React Server Components while maintaining optimal performance.
