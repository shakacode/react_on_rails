# React Server Components Rendering Flow

This document explains the rendering flow of React Server Components (RSC) in React on Rails Pro.

## Types of Bundles

In a React Server Components project, there are three distinct types of bundles, each running in a different environment with different constraints:

### RSC Bundle (rsc-bundle.js)

- Contains only server components and references to client components
- Generated using the RSC Webpack Loader which transforms client components into references
- Used specifically for generating RSC payloads
- Configured with `react-server` condition to enable RSC-specific code paths that tell the runtime that this bundle is used for RSC payload generation.
- **Runtime: Node renderer VM context** -- when the node renderer generates an RSC payload, it executes the uploaded RSC bundle in an isolated VM context. The webpack `target: 'node'` in `rscWebpackConfig.js` is a build-time setting only; it does not grant the runtime VM access to host Node.js globals. Use `supportModules`, `additionalContext`, or bundled imports for any globals your RSC code needs.

### Server Bundle (server-bundle.js)

- Contains both server and client components in their full form
- Used for traditional server-side rendering (SSR)
- Enables HTML generation of any components
- Does not transform client components into references
- **Runtime: Node renderer VM context** -- runs inside `vm.createContext()`, which has no global `require()` and lacks many Node.js/browser globals (see [Bundle Architecture Reference](#bundle-architecture-reference) below)

### Client Bundle

- Split into multiple chunks based on client components
- Each file with `'use client'` directive becomes an entry point
- Code splitting occurs automatically for client components
- Chunks are loaded on-demand during client component hydration
- **Runtime: Browser** -- standard browser APIs available, no Node.js APIs

### Bundle Architecture Reference

Understanding the runtime differences between the three bundles is critical for avoiding hard-to-debug errors. The server bundle and RSC bundle look similar in webpack configuration, and the node renderer executes both through isolated VM contexts:

|                            | Client Bundle                         | Server Bundle (SSR)                                                                                                                                      | RSC Bundle                                                                                                                                                                            |
| -------------------------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Webpack config**         | `clientWebpackConfig.js`              | `serverWebpackConfig.js`                                                                                                                                 | `rscWebpackConfig.js`                                                                                                                                                                 |
| **Runtime**                | Browser                               | Node renderer VM context (`vm.createContext`)                                                                                                            | Node renderer VM context (`vm.createContext`), used for RSC payload generation                                                                                                        |
| **Node builtins**          | Use `resolve.fallback: false` to omit | Use `resolve.fallback: false` (NOT `externals`, unless `supportModules` is enabled)                                                                      | Use `resolve.fallback: false` (NOT `externals`, unless `supportModules` is enabled); do not assume host Node.js globals are visible in the VM                                         |
| **`require()`**            | N/A                                   | **Not available** by default. Webpack `externals` can call CommonJS `require` when `supportModules` is enabled or `additionalContext` is a plain object. | **Not available** by default. Webpack `externals` can call CommonJS `require` when `supportModules` is enabled or `additionalContext` is a plain object.                              |
| **CSS extraction**         | Yes                                   | No (`exportOnlyLocals`)                                                                                                                                  | No                                                                                                                                                                                    |
| **Isolated build env var** | `CLIENT_BUNDLE_ONLY`                  | `SERVER_BUNDLE_ONLY`                                                                                                                                     | `RSC_BUNDLE_ONLY`                                                                                                                                                                     |
| **Missing globals**        | N/A                                   | `MessageChannel`, `fetch`, etc. (see [troubleshooting](../../oss/migrating/rsc-troubleshooting.md#node-renderer-vm-context----missing-globals))          | Same VM global rules as the server bundle. `supportModules` covers common globals, but not `fetch`, `Headers`, `Request`, `Response`, `AbortController`, or `AbortSignal` by default. |

**Key pitfall -- `externals` vs `resolve.fallback` in the server and RSC bundles:**

The server bundle and RSC bundle both run in VM sandboxes that have **no global `require()` function** by default. Webpack's `externals` generates `require('path')` calls in the output, which will crash with `require is not defined` when the renderer executes the bundle as raw script. Instead, use `resolve.fallback: { path: false, fs: false, stream: false }` to tell webpack to omit these modules from the bundle.

`externals` can work when the renderer enables CommonJS execution: use `supportModules`, or set `additionalContext` to any plain object (even `{}`). In that mode, `require()` becomes available inside the bundle and webpack `externals` callbacks resolve correctly. `additionalContext` does not inject a global `require` by itself; it opts into the CommonJS execution mode and injects only the globals you pass. The `require` available inside the bundle in this mode is the renderer host's `require`, so bundle code can load any module installed on the renderer host -- not only modules included in the upload. Even then, `resolve.fallback` remains the safer default. The client bundle also uses `resolve.fallback` to omit Node builtins that don't exist in the browser.

> [!NOTE]
> `rscWebpackConfig.js` still targets `'node'` for build-time module resolution. That webpack target is separate from the isolated VM context that executes the uploaded RSC bundle at runtime.

For `fetch`, `Headers`, `Request`, `Response`, `AbortController`, and `AbortSignal`, see [Node Renderer JavaScript Configuration](../../oss/building-features/node-renderer/js-configuration.md#runtime-globals-for-ssr-and-rsc).

## React Server Component Rendering Flow

When a request is made to a page using React Server Components, the following optimized sequence occurs:

1. Initial Request Processing:
   - The `stream_react_component` helper is called in the view
   - Makes a request to the node renderer
   - Server bundle's rendering function calls `generateRSCPayload` with the component name and props
   - This executes the component rendering in the RSC bundle
   - RSC bundle generates the payload containing server component data and client component references
   - The payload is returned to the server bundle

2. Server-Side Rendering with RSC Payload:
   - The server bundle uses the RSC payload to generate HTML for server components using `RSCServerRoot`
   - `RSCServerRoot` splits the RSC payload stream into two parts:
     - One stream for rendering server components as HTML
     - Another stream for embedding the RSC payload in the response
   - `RSCPayloadContainer` component embeds the RSC payload within the HTML response
   - HTML and embedded RSC payload are streamed together to the client

3. Client Hydration:
   - Browser displays HTML immediately
   - React runtime uses the embedded RSC payload for hydration
   - Client components are hydrated progressively without requiring a separate HTTP request

This approach offers significant advantages:

- Eliminates double rendering of server components
- Reduces HTTP requests by embedding the RSC payload within the initial HTML response
- Provides faster interactivity through streamlined rendering and hydration

```mermaid
sequenceDiagram
    participant Browser
    participant RailsView
    participant NodeRenderer
    participant RSCBundle
    participant ServerBundle

    Note over Browser,ServerBundle: 1. Initial Request
    Browser->>RailsView: Request page
    RailsView->>NodeRenderer: stream_react_component
    NodeRenderer->>ServerBundle: Execute rendering request
    ServerBundle->>RSCBundle: generateRSCPayload(component, props)
    RSCBundle-->>ServerBundle: RSC payload with:<br/>- Server components<br/>- Client component refs
    ServerBundle-->>NodeRenderer: Generate HTML using RSC payload

    Note over Browser,ServerBundle: 2. Single Response
    NodeRenderer-->>Browser: Stream HTML with embedded RSC payload

    Note over Browser: 3. Client Hydration
    Browser->>Browser: Process embedded RSC payload
    loop For each client component
        Browser->>Browser: Fetch component chunk
        Browser->>Browser: Hydrate component
    end
```

## Next Steps

To learn more about how to render React Server Components inside client components, see [React Server Components Inside Client Components](./inside-client-components.md).
