# RSC FOUC — Human Verification Procedure (Rspack v2 / 17.0)

Purpose: confirm or deny, on a real app or the Pro dummy app, the code-derived FOUC
conditions in [rsc-css-fouc-findings.md](./rsc-css-fouc-findings.md). Every step is
observation-only; no framework code changes are required. Expected time: ~1–2 hours.

> [!IMPORTANT]
> **Executed 2026-07-09 — verdict: FAIL on the supported production config.** Steps 1–3
> were run on the dummy app (Rspack 2.0.5, rsc 19.2.1-rc.0, production mode): the
> streamed reveal carried only a non-blocking preload and an ungated `$RC(`, and the
> probe rendered visibly unstyled for ~3.9 s with CSS delayed 4 s. See the addendum in
> [rsc-css-fouc-findings.md](./rsc-css-fouc-findings.md). The original theory below
> understated the failure: a healthy `css` array does **not** gate the streamed reveal —
> post-shell hints emit preloads only, and every stream-level gating layer is
> production-dead. The procedure remains valid for re-verifying after a fix and for
> classifying other apps' builds.

The refined theory this procedure tests: **the server-streamed reveal is CSS-gated only
when a `data-precedence="rsc-css"` stylesheet link lands before the boundary's reveal
script in the byte stream. In default production builds none of the layers that emit
such links can fire (numeric chunk ids kill inference/deferral; id-based CSS filenames
kill preload promotion), so streamed FOUC occurs whenever chunk-CSS latency exceeds the
parse window — regardless of manifest `css`-array health. Dev/test builds are gated but
have a rare timing variant when Flight data lags the 100 ms deferral window.**

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

Then inspect the client manifest. It lives in the Shakapacker output directory — in the
dummy app that is `public/webpack/<RAILS_ENV>/` (so `public/webpack/production/` for a
production build); in a typical generated app it is `public/packs/`. Point `jq` at the
directory for the env you just built, not a glob — a glob can silently pick up a stale
manifest from another env:

```bash
jq '.filePathToModuleMetadata | to_entries[]
    | select(.key | test("FoucProbe|<YourClientComponent>"))
    | {key, chunks: .value.chunks, css: .value.css}' \
  public/webpack/production/react-client-manifest.json
```

Record two booleans:

- **B1 (L1 input present):** does the entry have a non-empty `css` array with resolvable
  hrefs? Missing/empty ⇒ L1 (preinit hints) is dead for this build. Note: on Rspack,
  `19.2.1-rc.0`+ with a concrete `publicPath` is necessary but **not sufficient** —
  native CSS handling (module type `css` instead of `css/mini-extract`) or split-chunks
  configs that move CSS outside the reference's chunk group can still leave `css`
  missing (finding F2). Record the extraction mechanism and splitChunks posture along
  with the boolean.
- **B2 (named ids):** are the even-indexed elements of `chunks` quoted strings like
  `"client1"`? Numbers ⇒ L3/L4 are dead for this build (finding F1(a)). Also note the
  **CSS filename shape** in the `css` hrefs: `css/<number>-<hash>.css` ⇒ L2 is dead too
  (finding F1(b)); `css/clientN-<hash>.css` ⇒ L2 can match.

Also check the sidecar, `loadable-stats.json`. It is emitted into the same Shakapacker
output directory as the manifest; at runtime the renderer reads the copy staged **next
to the server bundle** in the node renderer's bundle directory (staged by
`assets_to_copy`/`PrepareNodeRenderBundles`; in the dummy see
`config/initializers/react_on_rails_pro.rb`). Check the staged copy if the renderer is
running, the build-output copy otherwise:

```bash
jq '.assetsByChunkName | with_entries(select(.key | test("^client[0-9]+$")))' \
  public/webpack/production/loadable-stats.json
```

Empty/missing, or `clientN` entries without `.css` assets ⇒ L3/L4 dead regardless of B2.

Expected per the findings: production ⇒ B2 = numeric + id-based CSS filenames on both
bundlers (only L1 live); Rspack + 19.2.0-line or `publicPath: 'auto'` ⇒ B1 = missing.
Observed 2026-07-09 (dummy, Rspack 2.0.5, rsc 19.2.1-rc.0, production): B1 present,
B2 numeric, CSS id-named — see the findings-register addendum.

## Step 2 — Read the raw stream (no browser yet)

With Rails + node renderer running against the Step 1 build:

```bash
curl -sN http://localhost:3000/rsc_fouc_probe > /tmp/stream.html
grep -c 'data-precedence="rsc-css"' /tmp/stream.html
grep -o '\$R[CR]' /tmp/stream.html | sort | uniq -c
```

Interpretation table:

| Observation                                                                                    | Meaning                                                                                                                                                                                                                                                               |
| ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<link … data-precedence="rsc-css">` appears **before** the boundary's reveal script           | Streamed reveal is gated (browser blocks the following inline script on the pending sheet). Observed only in dev/test builds; do not expect `$RR(` for hint-replayed styles — the 2026-07-09 production capture showed hints yield preloads, not React-gated reveals. |
| `<link rel="preload" as="style">` for the boundary CSS, no `rsc-css` link, plain `$RC(` reveal | **Ungated reveal — the confirmed production defect.** FOUC occurs whenever CSS latency exceeds the parse window (verified visibly, Step 3).                                                                                                                           |
| Links present, reveal is plain `$RC(`                                                          | A fallback layer produced the links — L2 or L3, not React. Attribute before concluding (see below); check the links precede the reveal in byte order.                                                                                                                 |
| **No** `rsc-css` links anywhere, reveal is plain `$RC(`                                        | All layers dead ⇒ FOUC predicted deterministically on a cold cache. Go to Step 3 to see it.                                                                                                                                                                           |
| `<link rel="preload" as="style" …clientN….css>` never promoted to `rel="stylesheet"`           | L2 regression **only if** the href actually matches `/css/clientN-*.css` (dev/test naming). Production id-named hrefs are expected to stay unpromoted — that is F1(b), not a regression.                                                                              |

Attributing a `data-precedence` link to L2 vs L3 (they coexist with `$RC(`):

- **L3-injected** links have the exact minimal shape
  `<link rel="stylesheet" href="…" data-precedence="rsc-css">` (no `crossorigin`, no
  other attributes) and no earlier `rel="preload"` tag for the same href in the stream.
  In a production build, L3 links are impossible (F1(a)) — any link you see there is L1
  or L2.
- **L2-promoted** links retain the original preload tag's other attributes (e.g.
  `crossorigin`, query strings) with `rel` rewritten; the href matches the
  `css/clientN-*.css` shape.
- Definitive discriminator when in doubt: temporarily move `loadable-stats.json` out of
  the renderer bundle directory and re-request — links that disappear were L3.

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
2. Add a network-request block or use "Slow 3G", or better: right-click the boundary's
   CSS request (`css/clientN-*.css` in dev/test, `css/<id>-*.css` in production) →
   "Block request URL", load, observe, then unblock. Expected behavior while the sheet
   is blocked depends on which layer Step 2 showed active:
   - **L1 active (`$RR` reveals):** the probe stays hidden/suspended — React's
     `completeBoundaryWithStyles` holds the reveal until the sheet loads.
   - **L2/L3 links + `$RC` reveals (dev/test only):** the probe should also stay
     hidden, but by a different mechanism — the parser delays execution of the `$RC(`
     script behind the pending stylesheet that precedes it. The Suspense-contract
     guarantee is weaker here (it depends on link-before-script byte order in the
     stream, which is what Step 2's byte-order check verifies), so treat a flash under
     this mode as an ordering failure of the fallback layers, not of React.
   - **FOUC confirmed (either mode):** the probe's DOM appears **unstyled** (default
     colors/fonts) while the CSS is blocked. `getComputedStyle` sentinel: the dummy
     probe sets a CSS custom property (`--rsc-fouc-probe-sentinel: loaded`) only via the
     stylesheet, so `sentinel !== 'loaded'` while visible = flash.
3. Playwright equivalent (what `rsc_fouc.spec.ts` automates): route-intercept the target
   CSS, delay its fulfillment ~2 s, assert the probe is never
   visible-with-default-styles during the window. To run the existing spec against a
   **production** build, build with `NODE_ENV=production` and start the same server —
   this is the exact gap in CI coverage (the gate only runs `NODE_ENV=test`).

## Step 4 — The rare dev/test-mode race (only if Steps 1–3 came out healthy)

This targets finding F3 (100 ms deferral window). Only meaningful when **all three**
hold: B1 is false, B2 is named (dev/test build), **and** the Step 1 sidecar check showed
a non-empty `loadable-stats.json` with `.css` assets under `clientN` keys — L4 never
arms when the chunk→CSS map is empty, so a missing/empty/CSS-less sidecar makes this
test meaningless (any flash then is the all-layers-dead case, not a timing race).

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

| Build                                                                                                                | B1 (`css` arrays)  | Predicted                                                                                   | Observed                                                                                                                         |
| -------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| webpack, production                                                                                                  | expected present   | ~~no FOUC~~ ungated reveal                                                                  | Step 1 2026-07-09: identical posture (numeric id, id-named CSS) — same defect expected                                           |
| Rspack 2.x + rsc pkg ≥ 19.2.1-rc.0, concrete publicPath, production                                                  | expected present   | ~~no FOUC~~ ungated reveal                                                                  | **FAIL 2026-07-09** (Rspack 2.0.5): Steps 1–3 — preload-only stream, ungated $RC, ~3.9 s visible unstyled probe with CSS delayed |
| Rspack 2.x + rsc pkg 19.2.0-line, production                                                                         | absent             | **deterministic cold-cache FOUC**                                                           |                                                                                                                                  |
| Rspack 2.x, `publicPath: 'auto'`, production                                                                         | absent             | **deterministic cold-cache FOUC**                                                           |                                                                                                                                  |
| either bundler, dev/test, slow server component, Step 4 prerequisites met (B1=false, named ids, CSS-bearing sidecar) | n/a (L3/L4 active) | rare timing FOUC (F3); without the Step 4 prerequisites classify as all-layers-dead instead |                                                                                                                                  |

If the two "deterministic" rows reproduce, the one-time sighting is explained without
any further race-hunting: first cold visit flashes, browser cache hides every
subsequent attempt. If they don't reproduce, capture `/tmp/stream.html` from the
failing run and re-check Step 2's byte-order table before assuming a race.
