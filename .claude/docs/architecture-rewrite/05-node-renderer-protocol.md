# New Architecture: Node Renderer Protocol

## Design Principle

Simplify the communication between the Ruby gem and the Node renderer by:

1. Separating **bundle management** from **render requests**
2. Moving toward a **JSON-based render protocol** (Phase 2)
3. Removing unnecessary URL-embedded state

## Current Protocol Issues

### 1. Bundle management mixed into render requests

Every render request URL encodes the bundle hash: `/bundles/:bundleTimestamp/render/:renderRequestDigest`

When the renderer doesn't have the bundle, it returns HTTP 410, and Ruby retries with the bundle attached as a multipart upload. This means:

- Every render request might trigger a bundle upload
- The first request after a deploy always has an extra round-trip
- Bundle upload competes with render request processing

### 2. Request digest in URL

The `:renderRequestDigest` path segment is only used for prerender caching. It exists because the caching system was originally co-located with the renderer. Now that caching happens on the Ruby side (`ProRendering.render_with_cache`), this digest is redundant in the URL.

### 3. JS code as HTTP body

The render request body is a JS string that the renderer `eval`s in a VM. This means:

- Ruby must generate valid JS code (string building)
- The renderer must parse multipart form data to extract the JS
- Debugging requires inspecting JS strings embedded in HTTP requests

## Phase 1: Clean Up Existing Protocol

Minimal changes that reduce complexity without restructuring the renderer.

### 1a. Separate bundle upload from render

Create a dedicated bundle upload endpoint that runs **proactively** rather than reactively:

```
Current flow:
  POST /bundles/:hash/render/:digest (renderingRequest=JS)
    → 410 "I don't have this bundle"
  POST /bundles/:hash/render/:digest (renderingRequest=JS, bundle=<file>)
    → 200 "Here's your HTML"

Proposed flow:
  POST /bundles/:hash/upload (bundle=<file>)  ← proactive, at deploy/startup
    → 200 "Bundle cached"
  POST /render (renderingRequest=JS, bundleHash=:hash)
    → 200 "Here's your HTML"
```

Benefits:

- Render requests never carry bundle files (smaller, faster)
- Bundle upload happens once at startup, not on first request
- Render endpoint is stateless — it just needs the bundle hash to select the right VM

### 1b. Remove request digest from URL

```
Current:  POST /bundles/:hash/render/:digest
Proposed: POST /render
```

The bundle hash and any digest are sent as form fields or headers, not URL path segments. This simplifies routing and removes the tight coupling between URL structure and caching.

### 1c. Simplify status codes

```
Current:
  200 - Success
  400 - JS execution error
  410 - Bundle needed (retry with bundle)
  412 - Protocol version mismatch
  401 - Auth failure

Proposed:
  200 - Success (body: JSON result)
  400 - Client error (bad request, missing bundle, auth failure)
  500 - Server error (JS execution error, VM crash)

Error body format (all non-200):
  { "error": "human_readable_message", "code": "BUNDLE_NOT_FOUND" | "AUTH_FAILED" | "PROTOCOL_MISMATCH" | "EXECUTION_ERROR" }
```

The 410 status code was an abuse of HTTP semantics (410 means "permanently gone"). Using a JSON error body with a `code` field is clearer and doesn't require special HTTP status handling.

## Phase 2: JSON Render Protocol

The bigger win: stop sending JS code strings and send structured JSON instead.

### Current: Ruby generates JS, Node eval()s it

```
Ruby → "ReactOnRails.serverRenderReactComponent({name: 'Foo', props: {...}, ...})" → Node
Node → vm.runInContext(jsCode) → result
```

### Proposed: Ruby sends JSON, Node renders from it

```
Ruby → { componentName: "Foo", props: {...}, railsContext: {...}, stores: [...] } → Node
Node → ReactOnRails.serverRenderReactComponent(request) → result
```

### New render endpoint

```
POST /render
Content-Type: application/json

{
  "bundleHash": "abc123",
  "componentName": "MyComponent",
  "domNodeId": "MyComponent-react-component-uuid",
  "props": { "data": "value" },
  "railsContext": {
    "railsEnv": "production",
    "href": "https://example.com/page",
    ...
  },
  "stores": [
    {
      "name": "appStore",
      "props": { "items": [...] }
    }
  ],
  "renderMode": "sync",       // "sync" | "html_streaming" | "rsc_payload_streaming"
  "trace": false,
  "throwJsErrors": true,
  "renderingReturnsPromises": false,
  "rscConfig": {               // only present when RSC enabled
    "rscBundleHash": "def456",
    "reactClientManifestFileName": "react-client-manifest.json",
    "reactServerClientManifestFileName": "react-server-client-manifest.json"
  },
  "preHookJs": null            // optional JS to execute before rendering
}
```

### Response format (unchanged)

```json
{
  "html": "<div>...</div>",
  "consoleReplayScript": "<script>...</script>",
  "hasErrors": false,
  "clientProps": null,
  "isShellReady": true
}
```

### Streaming response format (unchanged)

```
Content-Type: application/x-ndjson

{"html":"<div>...","consoleReplayScript":"","hasErrors":false,"isShellReady":true}
{"html":"...</div>","consoleReplayScript":"<script>...</script>","hasErrors":false,"isShellReady":true}
```

### Node renderer changes

The renderer's `handleRenderRequest` would change from:

```typescript
// Current: eval arbitrary JS
const result = await runInVM(bundlePath, jsCodeString);
```

To:

```typescript
// Proposed: call known function with structured data
const result = await runInVM(bundlePath, () => {
  // Set up railsContext
  const railsContext = request.railsContext;

  // Initialize stores
  ReactOnRails.clearHydratedStores();
  for (const store of request.stores) {
    const generator = ReactOnRails.getStoreGenerator(store.name);
    const instance = generator(store.props, railsContext);
    ReactOnRails.setStore(store.name, instance);
  }

  // Execute pre-hook if provided
  if (request.preHookJs) {
    vm.runInThisContext(request.preHookJs);
  }

  // Render component
  const renderFn = selectRenderFunction(request.renderMode, request.rscConfig);
  return ReactOnRails[renderFn]({
    name: request.componentName,
    domNodeId: request.domNodeId,
    props: request.props,
    trace: request.trace,
    railsContext: railsContext,
    throwJsErrors: request.throwJsErrors,
    renderingReturnsPromises: request.renderingReturnsPromises,
  });
});
```

### Benefits of Phase 2

1. **No JS string building on Ruby side**: `RenderRequest#to_json_payload` is trivial.
2. **Debuggable**: JSON requests can be logged, inspected, and replayed easily.
3. **Cacheable**: JSON payloads have natural cache keys (just hash the JSON).
4. **Language-agnostic**: Other renderers (Bun, Deno, edge functions) can implement the same JSON protocol.
5. **Type-safe**: The JSON schema can be validated on both sides.
6. **Eliminates the RSC regex hack**: Instead of regex-replacing `()` at the end of an IIFE, the Node renderer can directly dispatch RSC requests by manipulating the structured request.

## Bundle Management Redesign

### Current: Reactive, per-request

```
Request 1: "Do you have bundle abc123?" → 410 → Upload abc123 → Re-request
Request 2: "Do you have bundle abc123?" → 200 (cached in VM)
```

### Proposed: Proactive, at boot/deploy

```
Boot: POST /bundles/upload (hash=abc123, file=server-bundle.js)
     POST /bundles/upload (hash=def456, file=rsc-bundle.js)  // if RSC
Request 1: POST /render (bundleHash=abc123, ...) → 200
Request 2: POST /render (bundleHash=abc123, ...) → 200
```

The Ruby gem uploads bundles during `config.to_prepare` (which runs at boot and on code reload in development). The render endpoint assumes bundles are available and returns 400 with `code: "BUNDLE_NOT_FOUND"` if not.

For development mode, the gem watches for bundle changes and re-uploads proactively, same as today's `reset_pool_if_server_bundle_was_modified` but triggering an upload instead of resetting.

### Simplified VM management

With proactive bundle upload, the renderer's VM management becomes simpler:

```
Current:
  Request arrives → Check if bundle exists in VM cache → No? Check filesystem → No? Return 410
  Bundle uploaded → Move to filesystem → Create VM context → Cache in memory

Proposed:
  Upload arrives → Create VM context → Cache in memory (no filesystem intermediary)
  Request arrives → Look up VM by bundleHash → Render → Return
```

The filesystem bundle cache can be eliminated for the happy path (in-memory VMs are the source of truth). Filesystem is only used for persistence across renderer restarts.

## Protocol Version

The `protocolVersion` field in the current protocol exists to prevent incompatible gem/renderer communication. This should be retained but moved from form data to an HTTP header:

```
X-ReactOnRails-Protocol: 3.0.0
```

The renderer validates this header on every request and returns 400 with `code: "PROTOCOL_MISMATCH"` if incompatible.

## Authentication

Move from form field to standard HTTP header:

```
Authorization: Bearer <token>
```

This aligns with HTTP conventions and allows standard middleware/proxy-level auth.

## Summary

| Aspect              | Current                       | Phase 1             | Phase 2             |
| ------------------- | ----------------------------- | ------------------- | ------------------- |
| Bundle delivery     | On-demand (410 retry)         | Proactive upload    | Proactive upload    |
| Render request body | JS code string                | JS code string      | JSON payload        |
| URL structure       | /bundles/:hash/render/:digest | /render             | /render             |
| Bundle hash         | URL path                      | Form field          | JSON field          |
| Request digest      | URL path                      | Removed             | N/A                 |
| Error format        | HTTP status codes             | Unified JSON errors | Unified JSON errors |
| Auth                | Form field                    | Header              | Header              |
| Protocol version    | Form field                    | Header              | Header              |
