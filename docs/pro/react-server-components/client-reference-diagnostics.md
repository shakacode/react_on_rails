# RSC Client Reference Diagnostics

Use this guide when a public or mostly static RSC page should prove which client-reference chunks it
can load before you introduce route-scoped manifest behavior. The current plugin model emits one
client manifest per build. It does not automatically infer per-page or per-route manifests.

## Emit Diagnostics

Enable the optional diagnostics asset on the client build:

```js
new RSCWebpackPlugin({
  isServer: false,
  clientReferenceDiagnosticsFilename: 'rsc-client-reference-diagnostics.json',
});
```

Rspack uses the same option:

```js
new RSCRspackPlugin({
  isServer: false,
  clientReferenceDiagnosticsFilename: 'rsc-client-reference-diagnostics.json',
});
```

The emitted JSON reports the client references recorded in the manifest, the JS chunk files attached
to each reference, and byte sizes for emitted assets when the bundler exposes them:

```json
{
  "version": 1,
  "manifestFilename": "react-client-manifest.json",
  "isServer": false,
  "clientReferenceCount": 1,
  "totalChunkBytes": 1234,
  "clientReferences": [
    {
      "file": "file:///absolute/path/to/TinyIsland.js",
      "id": "./TinyIsland.js",
      "name": "*",
      "chunks": [
        {
          "id": "client-TinyIsland-js",
          "file": "client-TinyIsland-js.chunk.js",
          "bytes": 1234
        }
      ],
      "totalBytes": 1234
    }
  ]
}
```

`bytes` is `null` only when the bundler does not expose the asset source during manifest emission.
`totalChunkBytes` counts each emitted JS or CSS asset file once even when multiple client references
share that asset.

On client and server builds, CSS entries are reported from the emitted CSS assets for the generated
chunk group for the listed client reference. If one island imports another client reference, the
imported child reference does not inherit a separate CSS asset that belongs only to the importing
island.

This diagnostics view is chunk-asset scoped, not selector scoped. If the bundler emits an owner
island's CSS asset with selectors from a statically imported child in the same physical CSS file, the
owner reference still reports that combined asset.

## Static Page Patterns

For a server-only static RSC entry, use an explicit empty client reference list for that build:

```js
new RSCWebpackPlugin({
  isServer: false,
  clientReferences: [],
  clientReferenceDiagnosticsFilename: 'rsc-client-reference-diagnostics.json',
});
```

This produces an empty client manifest and an empty diagnostics file. Use it only for a build target
that cannot render client components. Do not apply `clientReferences: []` to a mixed RSC app; any page
that renders a client component will miss the client-reference metadata it needs at runtime.

For a static page with one or two small islands, isolate the static build and declare only the island
files that the public page may render:

```js
new RSCWebpackPlugin({
  isServer: false,
  clientReferences: [
    {
      directory: './app/public-rsc',
      recursive: false,
      include: /TinyIsland\.(js|jsx|ts|tsx)$/,
    },
  ],
  clientReferenceDiagnosticsFilename: 'rsc-client-reference-diagnostics.json',
});
```

The same descriptor shape is supported by `RSCRspackPlugin`. Keep the static page entry separate from
the normal authenticated app entry when the app entry imports large global vendors, analytics, or
dashboard-only clients. The diagnostics file gives a direct audit trail for whether the tiny island
pulls only its own chunk or also pulls an unexpected vendor chunk through an import.

If an island imports a heavy dependency, the diagnostics file will show that dependency through the
emitted chunk files and byte totals. Remove or defer the import in the island itself; the diagnostics
option only reports what the build emitted and does not rewrite the module graph.

## Boundaries

This diagnostics slice is intentionally narrow:

- It does not create route-scoped or page-scoped manifests.
- It does not discover the exact client references rendered by a specific RSC page.
- It does not eliminate vendor chunks automatically.
- It does not solve broader dependency and manifest scoping work.

Use the diagnostics output to decide whether an explicit static-page build is acceptable today, or
whether the app needs broader manifest-scoping work before treating static RSC pages as
performance-isolated.
