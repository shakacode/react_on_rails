import { abTest, type BeforeNavigateContext } from 'shaka-shared';

// The PPR fixture route: cached static shell + one Suspense hole that resolves after
// holeDelayMs (1000ms, deliberately past the 500ms PPR settle budget, so the prerender
// deterministically postpones the boundary). `cacheKey` pins one cache entry for the whole
// benchmark run; `dynamicValue` stays fresh per request (default), mirroring production
// warm-hit behavior: cached shell + freshly streamed hole.
//
// PROVISIONAL until #5101 lands the same component in all delivery modes: the streaming-SSR
// control below renders a *different* (structurally similar: streamed ~1s async holes)
// component tree, so this pair currently compares delivery mode + content, not delivery
// mode alone. Both paths are env-overridable so the gate switches to #5101's routes without
// a code change.
const PPR_PATH =
  process.env.SHAKAPERF_PPR_PATH ?? '/ppr_page_for_testing?cacheKey=shakaperf-ppr-gate&holeDelayMs=1000';
const STREAMING_SSR_PATH = process.env.SHAKAPERF_STREAMING_SSR_PATH ?? '/stream_async_components_for_testing';

// Warm-hit proof budget: a warm hit serves the cached shell without any prerender work, so
// first byte lands in single-digit-to-tens of ms on the benchmark host. A cold miss CANNOT
// flush the shell before the PPR settle timer postpones the hole at ~500ms. 400ms therefore
// cleanly separates the two: generous headroom over a warm serve, strictly below the
// cheapest possible cold serve. Event-based proof via ppr.cache.lookup (#5102) is the
// planned upgrade; this behavioral bound is what is observable from the browser today.
const WARM_SHELL_TTFB_BUDGET_MS = 400;

// Cache-warming step (issue #5103 scope): fire one plain GET at the side's URL and drain it
// BEFORE every measured navigation. The first request per run is the cold prerender + cache
// write; every Lighthouse-measured request after it is a warm hit — including the harness's
// perf-warmup sample, which runs this hook too. Warming the control side as well keeps the
// pair symmetric (server JIT/route warm on both sides). Draining the body matters: the
// paired shell+PostponedState cache write lands with prerender completion, and an undrained
// streaming response could be abandoned before that.
const warmRouteBeforeMeasurement = async ({ context, url }: BeforeNavigateContext) => {
  const response = await context.request.get(url);
  if (!response.ok()) {
    throw new Error(`cache-warming request failed with HTTP ${response.status()} for ${url}`);
  }
  await response.text();
};

// Guard: both sides load the SAME PPR route (rsc-fouc precedent — assertions are absolute,
// so the gate fails even when both sides are equally broken). Every sample proves the page
// it measured (a) served the shell inside the warm-hit budget and (b) actually
// server-streamed the hole content — checked in the raw response HTML, where client
// hydration cannot mask a dead resume stream — so a broken or cold-serving fixture fails
// loudly instead of producing plausible-looking numbers.
abTest(
  'ppr warm hit serves cached shell and streams hole content',
  {
    startingPath: PPR_PATH,
    testTypes: ['perf'],
    options: {
      viewports: ['desktop'],
      beforeNavigate: warmRouteBeforeMeasurement,
    },
  },
  async ({ page, annotate, isControl }) => {
    await annotate('waiting for the PPR shell static section');
    await page.waitForSelector('#ppr-static-section', { state: 'visible', timeout: 15_000 });

    await annotate('asserting the measured request was a warm hit');
    const responseStart = await page.evaluate(() => {
      const [nav] = performance.getEntriesByType('navigation') as PerformanceNavigationTiming[];
      return nav ? nav.responseStart : Number.NaN;
    });
    if (!(responseStart < WARM_SHELL_TTFB_BUDGET_MS)) {
      throw new Error(
        `${isControl ? 'control' : 'experiment'} responseStart=${responseStart}ms is not under the ` +
          `${WARM_SHELL_TTFB_BUDGET_MS}ms warm-hit budget — the measured request was likely a cold ` +
          `prerender (missing cache warm-up, or the app is running without SHAKAPERF_PPR_CACHE=true)`,
      );
    }

    await annotate('waiting for the streamed hole content');
    await page.waitForSelector('#ppr-hole-content', { state: 'visible', timeout: 15_000 });

    // The DOM check above proves the page *ended up* with hole content, but client hydration
    // alone produces that too: DelayedPprHole renders synchronously in the browser, so a dead
    // resume stream still grows `#ppr-hole-content` client-side — and such failures dodge the
    // TTFB budget (an erroring hole skips the 500ms settle floor and serves a fast 200 whose
    // cache write is refused; a post-flush resume failure happens on a genuinely warm hit).
    // The harness owns the measured navigation, so the measured response body itself cannot
    // be captured here. Instead, re-exercise the warm-resume path with two sequential plain
    // GETs: the first re-populates the cache when the measured request degraded post-flush
    // and evicted the entry (ppr_handle_post_flush_degradation); the second is therefore a
    // warm hit whose raw HTML must carry the server-streamed hole — hydration cannot mask a
    // raw response.
    //
    // Each probe pins its own unique dynamicValue (same cacheKey, so the same shell entry) and
    // requires THAT value inside the raw hole HTML. Presence of `#ppr-hole-content` alone would
    // also be satisfied by a fully settled prerender cached WITH its hole (a settle-budget
    // regression: static-shell support serves completed HTML from cache without any resume) —
    // fast, hole present, but the dynamic value is stale from the first request. A fresh
    // per-probe value only appears when the server actually rendered this request's props:
    // via the resume phase on a warm hit, or the full stream on a cold miss.
    //
    // Residual gap: a failure striking ONLY the measured request while both probes stay
    // healthy is invisible until the ppr.cache.lookup event wiring (#5102), the documented
    // planned upgrade.
    const side = isControl ? 'control' : 'experiment';
    const probeServerRenderedHole = async (probeName: string) => {
      const probeUrl = new URL(page.url());
      const freshValue = `shakaperf-${probeName}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      probeUrl.searchParams.set('dynamicValue', freshValue);
      const probe = await page.request.get(probeUrl.toString());
      if (!probe.ok()) {
        throw new Error(`server-stream ${probeName} failed with HTTP ${probe.status()} for ${probeUrl}`);
      }
      const probeHtml = await probe.text();
      if (!probeHtml.includes('id="ppr-hole-content"')) {
        throw new Error(
          `${side} raw server HTML (${probeName}) has no #ppr-hole-content — the server render ` +
            'never delivers the hole (hole error: fast 200 with the cache write refused; or the ' +
            'resume phase fails on warm hits via post-flush degradation); any DOM-visible hole ' +
            'content came from client hydration',
        );
      }
      // Scope the freshness check to the RENDERED element: the cache-hit path regenerates the
      // per-request component spec tag (hydration props JSON) even when the rendered hole is
      // stale cached HTML, so a whole-document substring search would match the JSON and prove
      // nothing. Extract the server-rendered #ppr-dynamic-value text instead (no script
      // execution — raw markup only; the props JSON never contains `id="ppr-dynamic-value"`).
      const renderedValues = [...probeHtml.matchAll(/id="ppr-dynamic-value"[^>]*>([^<]*)</g)].map(
        (m) => m[1],
      );
      if (!renderedValues.includes(freshValue)) {
        throw new Error(
          `${side} raw server HTML (${probeName}) rendered #ppr-dynamic-value as ` +
            `${JSON.stringify(renderedValues)} instead of this request's dynamicValue ` +
            `(${freshValue}) — the server returned stale cached hole HTML instead of resuming ` +
            'with fresh props (settle-budget regression: the prerender no longer postpones the ' +
            'hole); a fresh hydration-props JSON blob does not count as server-rendered content',
        );
      }
    };

    // Probe 1 re-warms after a possible measured-request eviction; probe 2 is then
    // deterministically a warm hit exercising the resume path.
    await annotate('asserting the hole content was server-streamed');
    await probeServerRenderedHole('probe-1');
    await annotate('asserting a warm resume renders fresh props');
    await probeServerRenderedHole('probe-2');
  },
);

// The primary A/B pair (plan §6): PPR warm hit (experiment) vs streaming SSR (control),
// different routes on ONE server (#3255 Decision 5 — same delivery path within the pair).
// Enforcement split (README "Enforcement status"): the statistics stage fails the run on
// any statistically significant TTFB/LCP regression — "no worse" is machine-enforced; the
// plan §6 improvement floor (warm-hit TTFB ≤ 10% of streaming-SSR TTFB) is NOT, and is read
// manually from the report's TTFB rows until the #5101 fixture makes the ratio meaningful.
// The body carries no comparison logic; it only makes sure each sampled page finished
// streaming.
abTest(
  'ppr warm hit vs streaming ssr ttfb and lcp',
  {
    startingPath: STREAMING_SSR_PATH,
    experimentPathOverride: PPR_PATH,
    testTypes: ['perf'],
    options: {
      viewports: ['desktop'],
      beforeNavigate: warmRouteBeforeMeasurement,
    },
  },
  async ({ page, annotate }) => {
    // The two sides render different fixtures until #5101, so wait on the one signal both
    // share: the streamed document reaching the load state (the HTML stream has closed, so
    // every streamed hole has been flushed). Note: annotate labels max out at 50 chars.
    await annotate('waiting for the streamed document to load');
    await page.waitForLoadState('load');
  },
);

// The PPR-vs-plain-SSR secondary pair (issue #5103 scope) is deliberately absent: plain
// (non-streaming) SSR cannot render this fixture — DelayedPprHole returns a Promise on the
// server and renderToString cannot await one. #5101 owns resolving that wrinkle (sync
// variant vs dropping plain SSR from the set); add the pair when its routes exist.
