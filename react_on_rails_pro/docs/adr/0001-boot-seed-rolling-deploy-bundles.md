# Seed rolling-deploy bundles at release time, not only at build

**Status:** accepted

When the production image is produced by **promoting the staging image**
(`upstream: hichee-staging` in Control Plane), a build-time pre-seed cannot know
production's live **draining bundle**: it runs in the staging pipeline against a
staging snapshot, and promotion happens later and is sometimes skipped. We
therefore run the **Rails/Rake seed task**
(`rake react_on_rails_pro:pre_seed_renderer_cache`) in a Ruby-capable release,
init, or startup step as the correctness path, and keep the build-time seed as a
fallback floor. A combined Ruby+Node image can run it before Node. A Node-only
renderer needs that step to use the promoted app artifact/config. The step and
renderer must mount the same writable shared volume at
`RENDERER_SERVER_BUNDLE_CACHE_PATH`, or copy/sync the completed cache into the
renderer before it starts; gate renderer start/readiness on completion. Without
a Ruby-capable step that makes the completed cache available to the renderer,
the Rake seed cannot run for it; use multi-source fallback plus 410 recovery or
a combined shape.

## Considered options

- **Build-time seed only (status quo).** Rejected: structurally wrong under the
  promotion model — the image holds staging's previous bundle, and even a
  multi-source build-time seed (staging + production) goes stale across two
  pending promotions.
- **Build a dedicated production image instead of promoting staging.** Rejected:
  fights the promotion model (the point of promotion is shipping the exact
  artifact tested on staging) and still goes stale if a prod image is ever built
  ahead of its release.
- **Boot seed only.** Rejected in favor of belt-and-suspenders: a boot seed that
  can't reach the live endpoint would fall all the way back to the per-request
  410 path. Keeping the build-time multi-source seed bounds that failure to a
  small, rare miss.

## Consequences

- Correctness of the boot seed **depends on deploy ordering (R2)**: its
  Ruby-capable step must complete before renderer readiness and Rails cutover, so
  the environment's live endpoint still advertises the draining hash. If Rails
  cuts over first, the boot seed would fetch the new hash and miss the draining
  one.
- Renderer start/readiness gates on the boot seed **completing, not succeeding**
  — a failed seed degrades to the 410 fallback rather than wedging the deploy.
- The build-time fallback seeds from both staging and production, so the image
  retains each environment's then-live bundle. That keeps staging's own rolling
  deploys warm while still giving a promoted image a recent production bundle if
  the boot seed cannot reach the live endpoint.
