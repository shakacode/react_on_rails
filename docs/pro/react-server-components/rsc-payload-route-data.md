# RSC Payloads as Route Data

React on Rails Pro exposes a browser helper for client routers that want to load a Server Component tree as route data instead of rendering an `<RSCRoute>` directly.

Use this when a loader in TanStack Router or another client router should fetch the Pro RSC payload endpoint and hand a `Promise<React.ReactNode>` to a route component.

This helper is browser-only. In TanStack Router SSR apps, mark the route as client-only with `ssr: false` so the loader does not run during server `router.load()`. Use your router's equivalent client-only setting in non-TanStack apps. For SSR/preloaded payloads, use `<RSCRoute>` and the standard React on Rails Pro streaming path.

```tsx
import { createRscPayloadNode } from 'react-on-rails-pro/rscPayloadNode';

export const route = createFileRoute('/rsc-showcase')({
  ssr: false,
  loader: () => ({
    serverPanel: createRscPayloadNode({
      componentName: 'RscShowcaseServerPanel',
      payloadPath: '/rsc_payload',
      props: { requestedBy: 'TanStack Router loader' },
    }),
  }),
  component: RscShowcaseRoute,
});
```

Then read the promise with React `use()` inside a `Suspense` boundary:

```tsx
import React, { Suspense, use } from 'react';

function RscShowcaseRoute() {
  const { serverPanel } = route.useLoaderData();

  return (
    <Suspense fallback={<div>Loading server panel...</div>}>
      <ServerPanel nodePromise={serverPanel} />
    </Suspense>
  );
}

function ServerPanel({ nodePromise }: { nodePromise: Promise<React.ReactNode> }) {
  return use(nodePromise);
}
```

## API

```ts
createRscPayloadNode(options): Promise<React.ReactNode>
```

| Option          | Required | Description                                                                                                                                                      |
| --------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `componentName` | Yes      | Registered Server Component name served by the Pro RSC payload route. Because it is appended to the request path, it must not include `/`, `\`, `?`, or `#`.     |
| `payloadPath`   | Yes      | Rails path configured with `rsc_payload_route`, for example `/rsc_payload`. The helper appends `/<componentName>?props=<json>` using the same Pro payload route. |
| `props`         | No       | Props serialized into the `props` query parameter. Defaults to `{}`.                                                                                             |
| `headers`       | No       | Additional request headers. Keep these application-specific, for example tracing headers or a conventional `X-Requested-With` header.                            |
| `credentials`   | No       | Fetch credentials mode. Defaults to `same-origin` so Rails session cookies accompany same-origin payload requests. Use `include` only when your app requires it. |
| `signal`        | No       | Optional `AbortSignal` from a router loader or navigation cancellation path.                                                                                     |

The helper returns a normal promise that resolves to a React node. It hides the Pro length-prefixed payload parser and React Flight stream construction; application code should not import `react-on-rails-rsc/client.browser` or parse the payload wire format.

## CSP Behavior

`createRscPayloadNode` consumes the RSC response as fetched data and passes raw Flight bytes to React. It does not depend on React on Rails Pro's streamed inline bootstrap scripts, and it does not replay renderer console metadata as inline scripts. This makes the route-data path suitable for strict Content Security Policy setups.

For full HTML streaming with embedded payloads, use `stream_react_component`, `<RSCRoute>`, and the standard RSC SSR flow instead.

## SSR Preloading Status

SSR preloading for `createRscPayloadNode` route data is intentionally deferred. The helper is browser-only today: it fetches the RSC payload from the client loader and returns the promise for `use()`/`Suspense`.

If the initial HTML response must include the Server Component payload without an extra browser fetch, render the route with `<RSCRoute>` through the normal React on Rails Pro streaming SSR path. A future API can add an explicit server preload bridge without requiring application code to depend on the Pro payload wire format.
