# RSC Client Reference Diagnostics

Use this guide when a public or mostly static RSC page should prove which client-reference chunks it
can load before you introduce route-scoped manifest behavior. The current plugin model emits one
client manifest per build. It does not automatically infer per-page or per-route manifests.

## Emit Diagnostics

The published `react-on-rails-rsc` webpack and rspack plugins do not currently emit a separate
`clientReferenceDiagnosticsFilename` asset. Inspect the emitted client manifest instead, or generate a
small local report from it after the client build completes.

```js
import { readFileSync } from 'node:fs';

const manifest = JSON.parse(readFileSync('public/packs/react-client-manifest.json', 'utf8'));
const assets = new Map();

function addAsset(file, id, type) {
  const entry = assets.get(file) ?? { ids: [], types: [] };

  if (!entry.ids.includes(id)) {
    entry.ids.push(id);
  }

  if (!entry.types.includes(type)) {
    entry.types.push(type);
  }

  assets.set(file, entry);
}

for (const [id, metadata] of Object.entries(manifest)) {
  for (const file of metadata.chunks ?? []) {
    addAsset(file, id, 'js');
  }
  for (const file of metadata.css ?? []) {
    addAsset(file, id, 'css');
  }
}

console.table([...assets.entries()].map(([file, metadata]) => ({ file, ...metadata })));
```

The report should be derived from the manifest entries that the RSC package emits. A shared JS or CSS
file can list multiple client-reference owners. A richer local report can include the client
references recorded in the manifest, the JS chunk files attached to each reference, CSS files, and
byte sizes from the build stats when the bundler exposes them:

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

`bytes` should be `null` when the bundler stats do not expose the asset source. `totalChunkBytes`
should count each emitted JS or CSS asset file once even when multiple client references share that
asset.

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
});
```

This produces an empty client manifest. Use it only for a build target that cannot render client
components. Do not apply `clientReferences: []` to a mixed RSC app; any page that renders a client
component will miss the client-reference metadata it needs at runtime.

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
});
```

The same descriptor shape is supported by `RSCRspackPlugin`. Keep the static page entry separate from
the normal authenticated app entry when the app entry imports large global vendors, analytics, or
dashboard-only clients. The manifest gives a direct audit trail for whether the tiny island pulls only
its own chunk or also pulls an unexpected vendor chunk through an import.

If an island imports a heavy dependency, the manifest or derived report will show that dependency
through the emitted chunk files and byte totals. Remove or defer the import in the island itself; the
manifest only reports what the build emitted and does not rewrite the module graph.

## Boundaries

This diagnostics slice is intentionally narrow:

- It does not create route-scoped or page-scoped manifests.
- It does not discover the exact client references rendered by a specific RSC page.
- It does not emit a separate diagnostics JSON file in the currently published package.
- It does not eliminate vendor chunks automatically.
- It does not solve broader dependency and manifest scoping work.

Use the manifest output to decide whether an explicit static-page build is acceptable today, or
whether the app needs broader manifest-scoping work before treating static RSC pages as
performance-isolated.
