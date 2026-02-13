# React Server Components Glossary

### RSC (React Server Component)

A React architecture that allows components to execute exclusively on the server while streaming results to the client. Benefits include:

- Reduced client-side JavaScript
- Direct access to server resources
- Improved initial page load
- Better SEO

## Important: `.client.` / `.server.` File Suffixes Are Unrelated

React on Rails has a separate, older concept where files can have `.client.jsx` or `.server.jsx` suffixes. These control **which webpack bundle** imports the file (client bundle vs. server bundle for SSR) and have nothing to do with React Server Components.

- `Component.client.jsx` → only imported in the client (browser) bundle
- `Component.server.jsx` → only imported in the server (SSR) bundle

A `.server.jsx` file is NOT a React Server Component. A `.client.jsx` file is NOT necessarily a React Client Component. The RSC classification is determined solely by the `'use client'` directive, regardless of file suffix. See the [auto-bundling docs](../../../docs/core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#server-rendering-and-client-rendering-components) for details on file suffixes.

## Types of Components

### Server Components

Components that run exclusively on the server (not included in the client bundle). They can:

- Directly access server-side resources (databases, filesystems)
- Keep dependencies server-side
- Perform async operations
- Cannot contain state or browser-only APIs

For example:

```jsx
import fetch from 'node-fetch';

async function ServerComponent() {
  const data = await (await fetch('https://jsonplaceholder.org/posts/1')).json();
  const databaseData = await getDatabaseData();
  return (
    <div>
      <h1>{data.title}</h1>
      <p>{data.body}</p>
      <p>{databaseData}</p>
    </div>
  );
}
```

### Client Components

Components marked with `'use client'` directive that run on client. They can contain state, effects, and event handlers. These components get hydrated in the browser.

For example:

```jsx
function ClientComponent() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

Note: Server components can import client components, but client components cannot import server components. However, server components can be passed as props to client components.

For example:

```jsx
function ParentServerComponent() {
  return <ClientComponent serverComponent={<ServerComponent />} />;
}
```

## Bundle Related

### React Server Components Bundle (RSC Bundle) (usually `rsc-bundle.js`)

A new server-side bundle introduced by React Server Components. It contains server components and their dependencies only. It doesn't include client components. It should be the same as the `server_bundle.js` bundle. But it uses the `react-on-rails-rsc/WebpackLoader` loader to trim the client components from the bundle.

### Client Bundle

The JavaScript bundle that runs in the browser, containing client components and their dependencies. This bundle is responsible for hydration and client-side interactivity.

## Concepts

### Flight Format (RSC Format)

The wire format used by React Server Components to stream component data from server to client. It's a compact binary format that represents the component tree and its data.

### Hydration

The process where React attaches event handlers and state to server-rendered HTML in the browser. With RSC, hydration happens selectively only for Client Components.

### RSC Payload (Flight Payload)

The serialized output of server components that gets streamed to the client. Contains:

- React render tree of the server component
- References to client components that need hydration
- Data for client components

### Selective Hydration

A feature where client components can hydrate independently and in parallel, allowing for:

- Progressive interactivity
- Prioritized hydration of visible components
- Better performance on slower devices

### Streaming

The ability to progressively send server component renders to the client before all data is ready. Benefits include:

- Faster Time to First Byte (TTFB)
- Progressive rendering of content
- Better user experience during slow data fetches

## Technical

### Client Component Manifest

A JSON file mapping component paths to their corresponding JavaScript chunks. Used by RSC to determine which client-side code to load for hydration.

### RSC URL Path

The endpoint path where RSC requests are handled, defaulting to "rsc_payload/" in the React on Rails Pro configuration.
