# RSC FOUC ShakaPerf Gate

This ShakaPerf gate protects the React Server Components `'use client'` CSS
FOUC fix. It runs against the React on Rails Pro dummy app route
`/rsc_posts_page_over_http`, which renders `UseClientCssProbe` behind a client
boundary with CSS imported from a module.

The gate intentionally runs ShakaPerf against one release-candidate server for
both control and experiment URLs. The first-visible assertion is absolute, so it
fails even when both sides are the same broken build. The visual report still
captures the probe and gives release artifacts for review.

## Checks

- `rsc first paint use-client css emits stylesheet before hydration`: blocks app
  JavaScript and verifies the server-rendered stylesheet link exists before
  capturing the probe.
- `rsc real first-visible probe is styled`: uses `waitUntil: "commit"` and RAF
  polling to assert the first visible probe frame already has the expected CSS.

## Local Run

Start the Pro dummy app with test assets and the node renderer, then run:

```bash
pnpm exec shaka-perf compare \
  --categories visreg \
  --config test/shakaperf/rsc-fouc/abtests.config.ts \
  --filter test/shakaperf/rsc-fouc/ab-tests/rsc-fouc-release-gate.abtest.ts \
  --controlURL http://127.0.0.1:3030 \
  --experimentURL http://127.0.0.1:3030 \
  --full-report-zip
```

Reports are written to `compare-results/`.
