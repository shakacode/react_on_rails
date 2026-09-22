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
// it measured (a) served the shell inside the warm-hit budget and (b) actually streamed the
// hole content, so a broken or cold-serving fixture fails loudly instead of producing
// plausible-looking numbers.
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
  },
);

// The primary A/B pair (plan §6): PPR warm hit (experiment) vs streaming SSR (control),
// different routes on ONE server (#3255 Decision 5 — same delivery path within the pair).
// The pass target is read from the report's TTFB and LCP rows: warm-hit TTFB ≤ 10% of
// streaming-SSR TTFB, LCP no worse. The body carries no comparison logic — the statistics
// stage owns the verdict; the body only makes sure each sampled page finished streaming.
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
