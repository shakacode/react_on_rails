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
The deployment the pre-seed pulls bundles from — resolved from that
environment's `rolling_deploy_previous_url` (HTTP adapter) at the moment the
seed runs. The source is whatever environment's config is in effect _when and
where the seed executes_.

**Build-time seed**:
Pre-seed baked into the image during `assets:precompile`. Uses the _building_
environment's config and a _snapshot_ of its then-live bundle. Frozen into the
image layer.

**Release-time seed** (a.k.a. **boot seed**):
Pre-seed run by the _target_ environment's renderer container at container boot
via `rake react_on_rails_pro:pre_seed_renderer_cache`, resolving that
environment's _actually-live_ bundle at that moment. Readiness-gated.
_Avoid_: "runtime seed" (ambiguous with the per-request 410 path).

**Multi-source seed**:
A build-time seed whose **pre-seed source** is a _list_ of endpoints (e.g. a
subclassed HTTP adapter reading a comma-separated `ROLLING_DEPLOY_PREVIOUS_URLS`).
Staging seeds from both staging and production so the promoted image is born
prod-ready.

**Promotion model**:
Production is deployed by promoting the _exact staging image_, not by building a
fresh production image. Consequence: the image's **build-time seed** used the
_staging_ pipeline's config and a snapshot taken at staging-build time — never
production's.

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
- Under the **promotion model**, a **build-time seed** _cannot_ satisfy R1: it
  runs in the staging pipeline against a staging snapshot, but production's
  **draining bundle** is only known at the (later, sometimes-skipped) promotion.
- Fix: set staging's **pre-seed source** to **production**, so the promoted
  image is born prod-ready (build-time seed = prod's live bundle). This bounds
  the blast radius but goes stale across _two pending promotions_.
- The residual staleness window (two images built before either is promoted) is
  closed by a **release-time seed** at promotion, which resolves production's
  actually-live **draining bundle**.
- Staging seeding prod bundles means staging's _own_ rolling deploys cold-miss
  (staging drains staging's-previous, which is not seeded). Accepted: staging
  SSR performance during deploys is not a goal.

### Three layers of defense

Correctness is layered; each layer bounds the failure the prior one leaves open.

1. **Multi-source build-time seed** — the image is born prod-ready; failure floor
   if the boot seed can't reach the live endpoint. (Correct for a single pending
   promotion.)
2. **Boot seed (release-time)** — the correctness path: pulls the _actually-live_
   **draining bundle** at container start, closing the two-pending-promotions
   window. Subsumes layer 1's correctness; layer 1 remains only as a fallback.
3. **Deploy ordering (R2)** — renderer live+warm before Rails; readiness gates on
   the boot seed _completing_ (not succeeding — a failed seed degrades to the 410
   fallback rather than wedging the deploy).

**Interdependency:** the **boot seed** returns the correct **draining bundle**
_only because_ the renderer boots before Rails (R2). Before new Rails is live,
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
> **Dev:** "So if staging's **pre-seed source** points at production, the
> promoted image is already prod-ready?"
> **Domain expert:** "For a single pending promotion, yes. Two pending
> promotions still go stale — that's why promotion also runs a **release-time
> seed** against prod's live bundle."
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
