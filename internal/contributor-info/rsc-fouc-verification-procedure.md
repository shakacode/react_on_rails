# RSC FOUC — Human Verification Procedure (Rspack v2 / 17.0)

Purpose: confirm or deny, on a real app or the Pro dummy app, the code-derived FOUC
conditions in [rsc-css-fouc-findings.md](./rsc-css-fouc-findings.md). Every step is
observation-only; no framework code changes are required. Expected time: ~1–2 hours.

The one-sentence theory to confirm: **FOUC occurs exactly when a client component's CSS
`css` array is missing from `react-client-manifest.json` (layer L1 dead) AND the build
is production-mode (numeric chunk ids kill layers L3/L4) — plus a rare timing variant in
dev/test builds when a boundary's Flight data arrives after the 100 ms deferral window.**

## Step 0 — Fix the test surface

Use a page with a `'use client'` component that imports a CSS/SCSS Module and is
rendered inside an async Server Component (so its CSS ships as a `clientN` chunk, not in
the layout pack). The dummy app already has one: `/rsc_fouc_probe`
(`RscFoucProbe.jsx` → `FoucProbe/RscFoucProbeClient.jsx`). On a real app, pick any RSC
route whose styled client component lives below a Suspense boundary.

Record for the run: bundler (`webpack`/`rspack`), `react-on-rails-rsc` version
(`cat node_modules/react-on-rails-rsc/package.json | grep version`), and
`output.publicPath` (from `bin/shakapacker` output or config).

## Step 1 — Classify the build (this decides everything else)

Build all three bundles the way the deployment does, e.g.:

```bash
RAILS_ENV=production NODE_ENV=production bin/shakapacker           # production posture
# vs
RAILS_ENV=test NODE_ENV=test bin/shakapacker                        # CI posture
```

Then inspect the client manifest (in `public/<output>/`):

```bash
jq '.filePathToModuleMetadata | to_entries[]
    | select(.key | test("FoucProbe|<YourClientComponent>"))
    | {key, chunks: .value.chunks, css: .value.css}' \
  public/*/react-client-manifest.json
```

Record two booleans:

- **B1 (L1 input present):** does the entry have a non-empty `css` array with resolvable
  hrefs? Missing/empty ⇒ L1 (preinit hints) is dead for this build.
- **B2 (named ids):** are the even-indexed elements of `chunks` quoted strings like
  `"client1"`? Numbers ⇒ L3/L4 are dead for this build (finding F1).

Also check the sidecar:

```bash
jq '.assetsByChunkName | with_entries(select(.key | test("^client[0-9]+$")))' \
  <renderer bundle dir>/loadable-stats.json
```

Empty/missing, or `clientN` entries without `.css` assets ⇒ L3/L4 dead regardless of B2.

Expected per the findings: production ⇒ B2 = numeric on both bundlers;
Rspack + 19.2.0-line or `publicPath: 'auto'` ⇒ B1 = missing.

## Step 2 — Read the raw stream (no browser yet)

With Rails + node renderer running against the Step 1 build:

```bash
curl -sN http://localhost:3000/rsc_fouc_probe > /tmp/stream.html
grep -c 'data-precedence="rsc-css"' /tmp/stream.html
grep -o '\$R[CR]' /tmp/stream.html | sort | uniq -c
```

Interpretation table:

| Observation                                                                                                    | Meaning                                                                                                        |
| -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `<link … data-precedence="rsc-css">` appears **before** the boundary's reveal script, and the reveal is `$RR(` | L1 healthy: React emitted the sheet and gates the reveal itself. FOUC not expected.                            |
| Links present, reveal is plain `$RC(`                                                                          | L1 dead, L3 injected the links; check they precede the reveal in byte order. Protection is Pro's, not React's. |
| **No** `rsc-css` links anywhere, reveal is plain `$RC(`                                                        | All layers dead ⇒ FOUC predicted deterministically on a cold cache. Go to Step 3 to see it.                    |
| `<link rel="preload" as="style" …clientN….css>` never promoted to `rel="stylesheet"`                           | L2 regression (or non-default asset paths breaking the `/css/clientN-*.css` filter).                           |

Byte-order check for a specific boundary:

```bash
grep -bo 'data-precedence="rsc-css"\|\$RC(\|\$RR(' /tmp/stream.html | head -20
```

Every stylesheet link's offset must be smaller than its boundary's reveal offset.

## Step 3 — Reproduce (or rule out) the visible flash

The flash is only visible when the CSS response is slower than the reveal, so control
the CSS latency instead of hoping:

1. Open the page in Chrome DevTools → Network → **Disable cache** (mandatory — a disk
   cache hit hides the bug forever after the first visit, which is why one-time
   sightings happen).
2. Add a network-request block or use "Slow 3G", or better: right-click the
   `clientN-*.css` request → "Block request URL", load, observe, then unblock. With the
   sheet blocked:
   - **Correct behavior:** the probe component stays hidden/suspended (React holds the
     reveal) or the whole boundary stays on its fallback.
   - **FOUC confirmed:** the probe's DOM appears **unstyled** (default colors/fonts)
     while the CSS is blocked. `getComputedStyle` sentinel: the dummy probe sets a CSS
     custom property (`--rsc-fouc-probe-sentinel: loaded`) only via the stylesheet, so
     `sentinel !== 'loaded'` while visible = flash.
3. Playwright equivalent (what `rsc_fouc.spec.ts` automates): route-intercept the target
   CSS, delay its fulfillment ~2 s, assert the probe is never
   visible-with-default-styles during the window. To run the existing spec against a
   **production** build, build with `NODE_ENV=production` and start the same server —
   this is the exact gap in CI coverage (the gate only runs `NODE_ENV=test`).

## Step 4 — The rare dev/test-mode race (only if Steps 1–3 came out healthy)

This targets finding F3 (100 ms deferral window). Only meaningful when B1 is false and
B2 is named (i.e., L3/L4 are the active protection — dev/test builds).

1. Make the Server Component slow: add `sleep 0.5` (or a slow query) to the async props
   for the RSC page so the first client-reference Flight row arrives well after 100 ms.
2. Reload the page ~50 times with cache disabled and CSS latency ~200 ms (DevTools
   throttling). Watch the probe (or record with the Playwright paint-recorder from the
   spec).
3. **Expected if F3 is real:** occasional (not every run) frames where the boundary
   reveals before its stylesheet applies. Frequency will be low — this matches the
   "reproduced exactly once" report.
4. Negative control: same run with the sleep removed should show zero flashes.

## Step 5 — Record the verdict

For the release decision, the matrix that matters:

| Build                                                 | B1 (`css` arrays)  | Predicted                         | Observed |
| ----------------------------------------------------- | ------------------ | --------------------------------- | -------- |
| webpack, production                                   | expected present   | no FOUC (React gates)             |          |
| rspack ≥ 19.2.1-rc.0, concrete publicPath, production | expected present   | no FOUC                           |          |
| rspack 19.2.0-line, production                        | absent             | **deterministic cold-cache FOUC** |          |
| rspack, `publicPath: 'auto'`, production              | absent             | **deterministic cold-cache FOUC** |          |
| either bundler, dev/test, slow server component       | n/a (L3/L4 active) | rare timing FOUC (F3)             |          |

If the two "deterministic" rows reproduce, the one-time sighting is explained without
any further race-hunting: first cold visit flashes, browser cache hides every
subsequent attempt. If they don't reproduce, capture `/tmp/stream.html` from the
failing run and re-check Step 2's byte-order table before assuming a race.
