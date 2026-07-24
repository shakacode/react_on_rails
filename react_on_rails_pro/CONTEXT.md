# React on Rails Pro — Rolling Deploy

How the Node Renderer bundle cache is warmed so that during a rolling deploy —
when old and new app versions run side by side — no SSR request pays the
cold-bundle penalty. Covers the seeding mechanism and how it interacts with the
deploy pipeline (build vs. release, staging-to-production promotion).

## Language

**Rolling deploy**:
The window where old (draining) and new app instances run side by side, both
sending SSR requests to the Node Renderer fleet.

**Draining bundle**:
The bundle hash that draining old Rails instances still request during the
overlap; the new renderer fleet must serve it warm.
_Avoid_: "old bundle" (old relative to what? — the draining bundle is defined by
what is live-and-draining in _this environment_, not by build order).

**Pre-seed**:
Staging previous bundle hashes into the new renderer cache before it serves
traffic, so **draining bundle** requests hit warm cache instead of the **410
fallback**.
_Avoid_: warmup (means the per-request lazy cache fill, the opposite of this).

**Pre-seed source**:
The deployment(s) the pre-seed pulls bundles from — resolved from that
environment's `rolling_deploy_previous_urls` (HTTP adapter) at the moment the
seed runs. The source is whatever environment's config is in effect _when and
where the seed executes_.

**Build-time seed**:
Pre-seed baked into the image during `assets:precompile`. Uses the _building_
environment's config and a _snapshot_ of its then-live bundle. Frozen into the
image layer.

**Release-time seed** (a.k.a. **boot seed**):
Pre-seed run by a Ruby-capable release, init, or startup step via
`bundle exec rake react_on_rails_pro:pre_seed_renderer_cache`, resolving the target
environment's _actually-live_ bundle. A combined Ruby+Node image can run it
before Node; a Node-only renderer needs a Ruby-capable step with the promoted
app artifact/config. That step and the renderer must mount the same writable
shared volume at `RENDERER_SERVER_BUNDLE_CACHE_PATH`, or copy/sync the completed
cache into the renderer before it starts. Renderer start/readiness waits for
completion. Without a Ruby-capable step that makes the completed cache available
to the renderer, use multi-source fallback plus 410 recovery or a combined
shape.
_Avoid_: "runtime seed" (ambiguous with the per-request 410 path).

**Multi-source seed**:
A build-time seed whose **pre-seed source** is a _list_ of endpoints (the
built-in HTTP adapter's `rolling_deploy_previous_urls` accepts more than one).
Staging can carry bundles then advertised by both staging and production, which
improves fallback warmth but cannot determine a later production drain.

**Promotion model**:
Production is deployed by promoting the _exact staging image_, not by building a
fresh production image. Consequence: the image's **build-time seed** used the
_staging_ pipeline's config and snapshots taken at staging-build time. A
multi-source configuration can include production's then-live bundle, but it
still cannot know the production bundle that will be draining at a later
promotion.

**410 fallback**:
The self-healing but slow per-request cold path: cache miss → `410 Gone` → Rails
ships the bundle to the renderer → retry, repeating per request until cached.
The thing pre-seeding exists to avoid.

**Seed correctness (R1)**:
The requirement that the new renderer fleet holds the exact **draining bundle**
for _this_ environment at _this_ release.

**Deploy ordering (R2)**:
The requirement that the new renderer fleet is live and cache-warm _before_ new
Rails takes traffic, and old renderers stay up until old Rails drains. Also
called **renderer-before-Rails**.

## Relationships

- A **rolling deploy** has one **draining bundle** per bundle kind (server, and
  RSC when enabled) that the new renderer fleet must serve warm.
- **Pre-seed** eliminates the **410 fallback** for the **draining bundle**;
  without it, every draining-bundle request pays the cold path.
- **Seed correctness (R1)** and **Deploy ordering (R2)** are independent and
  _both_ required. R2 alone (a delay) cannot rescue a wrong seed; R1 alone
  cannot rescue Rails cutting over before the renderer is warm.
- Under the **promotion model**, a **build-time seed** cannot satisfy R1 for
  every promotion: it runs against snapshots taken in the staging pipeline, but
  production's **draining bundle** is only known at the later promotion.
- Set staging's **pre-seed source** to both **staging and production**, so the
  image carries each environment's then-live bundle. This keeps staging's own
  rolling deploys warm and improves fallback warmth, but still goes stale across
  _two pending promotions_.
- The residual staleness window (two images built before either is promoted) is
  closed by a **release-time seed** at promotion, which resolves production's
  actually-live **draining bundle**.

### Three layers of defense

Correctness is layered; each layer bounds the failure the prior one leaves open.

1. **Multi-source build-time seed** — carries then-advertised bundles as a
   failure floor if the boot seed cannot reach the live endpoint.
2. **Boot seed (release-time)** — the correctness path: pulls the _actually-live_
   **draining bundle** before renderer readiness, closing the
   two-pending-promotions window. Layer 1 remains only as a fallback.
3. **Deploy ordering (R2)** — renderer live+warm before Rails; readiness gates on
   the boot seed _completing_ (not succeeding — a failed seed degrades to the 410
   fallback rather than wedging the deploy).

**Interdependency:** the **boot seed** returns the correct **draining bundle**
only when its release-time step completes before renderer readiness and Rails
cutover (R2). Before new Rails is live,
the environment's live endpoint is still served by the draining old pods, so it
advertises the draining hash. If Rails cut over first, the live endpoint would
advertise the _new_ hash and the boot seed would miss the very bundle it needs.
Layer 2 depends on Layer 3.

## Example dialogue

> **Dev:** "We promote the staging image to prod, and pre-seed is on. Why is
> prod SSR still slow after a rolling deploy?"
> **Domain expert:** "Because the **build-time seed** ran in the staging
> pipeline — the image holds staging's previous bundle, not prod's **draining
> bundle**. The seed was correct for the wrong environment."
> **Dev:** "So does staging's **pre-seed source** including staging and
> production guarantee the promoted image has prod's draining bundle?"
> **Domain expert:** "No. It carries then-advertised bundles and improves the
> fallback, but two pending promotions can still go stale. The **release-time
> seed** against prod's live bundle establishes correctness."
> **Dev:** "And that's enough?"
> **Domain expert:** "That's **R1**. You still need **R2** — the new renderer
> fleet live and warm before Rails cuts over — or you get the 410 storm anyway."

## Flagged ambiguities

- "old bundle" was used to mean both the build-predecessor and the live-draining
  bundle — resolved: the term of record is **draining bundle**, defined by what
  is live in the target environment, not by build order.
- "the delay" (R2) was initially read as a fix for the slow-SSR report — resolved:
  the report is an R1 (wrong-seed) failure; the delay is a necessary but separate
  R2 concern.
