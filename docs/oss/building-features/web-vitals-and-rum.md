# Web Vitals and Real User Monitoring (RUM)

React on Rails instruments **server-side** render performance — the repo's
`benchmarks/` suite feeds a Bencher-based regression dashboard, and
[Performance Benchmarks](../core-concepts/performance-benchmarks.md) covers
ExecJS vs Node Renderer throughput. What that does not tell you is how your app
performs **for real users in real browsers**: Largest Contentful Paint (LCP),
Cumulative Layout Shift (CLS), Interaction to Next Paint (INP), Time to First
Byte (TTFB), and First Contentful Paint (FCP). This page closes that loop with a
**first-party** Real User Monitoring setup: the browser collects Web Vitals with
the [`web-vitals`](https://github.com/GoogleChrome/web-vitals) library and
beacons them to **your own Rails endpoint** — no third-party analytics vendor,
no Vercel, no extra SaaS bill, and the data never leaves your app
(privacy/GDPR friendly).

For comparison: Next.js ships
[`useReportWebVitals`](https://nextjs.org/docs/app/api-reference/functions/use-report-web-vitals),
a thin hook over the same `web-vitals` library, and pairs it with Vercel Speed
Insights for turnkey field RUM — a path that effectively assumes you deploy on
Vercel and send your traffic data there. On Rails, the equivalent is just
another controller action: POST the vitals to your app and aggregate them with
ActiveRecord or your existing APM.

> **Scope note:** This page covers wiring the framework-agnostic `web-vitals`
> metrics. Framework-level hydration-timing instrumentation (`performance.mark`
> entries emitted from the React on Rails client runtime — "time to hydrate",
> "first interaction after hydration") is a planned follow-up, tracked in
> [issue #3877](https://github.com/shakacode/react_on_rails/issues/3877). It has
> not shipped yet; nothing on this page depends on it.

## How the pieces fit

1. **Client**: a small script in your client bundle subscribes to the five Core
   Web Vitals via `web-vitals`, queues them, and flushes the queue with
   `navigator.sendBeacon` when the page is hidden or unloaded.
2. **Sampling**: only a configurable fraction of page views report (default
   below: 10%), so high-traffic apps don't write a row per page view.
3. **Server**: a Rails route + controller accepts the JSON beacon, validates it
   with strong parameters, and stores it (or forwards it to your APM).
4. **Aggregation**: you query percentiles (p75 is the Core Web Vitals
   threshold standard) from your own database.

## Client: collecting and beaconing vitals

Add the [`web-vitals`](https://github.com/GoogleChrome/web-vitals) package:

```bash
npm install web-vitals
# or: yarn add web-vitals
# or: pnpm add web-vitals
```

Then add the following to a Shakapacker entry — either a dedicated pack or your
existing client bundle entry. It is intentionally plain JavaScript with no React
on Rails API dependency, so it works in any client bundle:

```js
// app/javascript/packs/web-vitals-reporter.js
// (or import it from your existing client bundle entry)
import { onCLS, onFCP, onINP, onLCP, onTTFB } from 'web-vitals';

const VITALS_ENDPOINT = '/web_vitals';

// Report only a fraction of page views. Decide once per page load so a sampled
// page view reports its full set of metrics (you can also read the rate from a
// <meta> tag to configure it from Rails without rebuilding the bundle).
const SAMPLE_RATE = 0.1; // 10%
const isSampled = Math.random() < SAMPLE_RATE;

const queue = new Set();

function addToQueue(metric) {
  queue.add(metric);
}

function flushQueue() {
  if (!isSampled || queue.size === 0) {
    return;
  }

  const body = JSON.stringify({
    // Send the pathname only — query strings can contain tokens or PII.
    page: window.location.pathname,
    metrics: [...queue].map(({ name, value, id, rating, delta, navigationType }) => ({
      name,
      value,
      id,
      rating,
      delta,
      navigation_type: navigationType,
    })),
  });
  queue.clear();

  // sendBeacon queues delivery even while the page unloads. Wrap the payload in
  // a Blob so the request carries a JSON content type and Rails parses the
  // params (a bare string would be sent as text/plain).
  const blob = new Blob([body], { type: 'application/json' });
  if (!(navigator.sendBeacon && navigator.sendBeacon(VITALS_ENDPOINT, blob))) {
    // Fallback for browsers without sendBeacon: keepalive lets the request
    // outlive the page.
    fetch(VITALS_ENDPOINT, {
      method: 'POST',
      body,
      headers: { 'Content-Type': 'application/json' },
      keepalive: true,
    });
  }
}

onCLS(addToQueue);
onFCP(addToQueue);
onINP(addToQueue);
onLCP(addToQueue);
onTTFB(addToQueue);

// CLS, LCP, and INP only settle when the page is hidden or unloaded, so flush
// on visibility change rather than on a timer.
addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'hidden') {
    flushQueue();
  }
});
// pagehide covers older Safari, which does not reliably fire visibilitychange
// on unload.
addEventListener('pagehide', flushQueue);
```

Why this shape:

- **Queue + flush on `visibilitychange`/`pagehide`** — CLS, LCP, and INP are
  not final until the user leaves the page, so per-metric immediate POSTs would
  both undercount and multiply requests. Batching into one beacon per page view
  is the pattern the `web-vitals` documentation recommends.
- **`navigator.sendBeacon`** — a normal `fetch`/XHR issued during unload is
  routinely cancelled by the browser; `sendBeacon` hands the payload to the
  browser to deliver asynchronously even after the page is gone. The
  `keepalive: true` fetch is the fallback for the rare browser without it.
- **Payload fields** mirror the `web-vitals`
  [`Metric` type](https://github.com/GoogleChrome/web-vitals#metric): `name`
  (`'CLS' | 'FCP' | 'INP' | 'LCP' | 'TTFB'`), `value`, `id` (unique per metric
  per page load — use it to deduplicate), `rating`
  (`'good' | 'needs-improvement' | 'poor'`), `delta` (change since the last
  report of this metric), and `navigationType` (e.g. `'navigate'`,
  `'reload'`, `'back-forward'`, `'prerender'`).

## Server: a first-party ingestion endpoint

Add a route:

```ruby
# config/routes.rb
post "/web_vitals", to: "web_vitals#create"
```

And a controller:

```ruby
# app/controllers/web_vitals_controller.rb
class WebVitalsController < ApplicationController
  # sendBeacon cannot set custom request headers, so the beacon arrives without
  # the X-CSRF-Token header Rails expects. Skipping forgery protection on this
  # one write-only, anonymous endpoint is the standard trade-off -- see the
  # CSRF section below before copying this.
  skip_forgery_protection

  VALID_NAMES = %w[CLS FCP INP LCP TTFB].freeze
  VALID_RATINGS = %w[good needs-improvement poor].freeze

  def create
    vitals_params[:metrics].to_a.each do |metric|
      next unless VALID_NAMES.include?(metric[:name])
      next unless VALID_RATINGS.include?(metric[:rating])

      WebVitalMetric.create!(
        name: metric[:name],
        value: Float(metric[:value]),
        delta: Float(metric[:delta]),
        metric_id: metric[:id].to_s,
        rating: metric[:rating],
        navigation_type: metric[:navigation_type].to_s,
        page: vitals_params[:page].to_s.byteslice(0, 255)
      )
    end

    head :no_content
  rescue ArgumentError, TypeError
    # Float() raises on non-numeric values -- reject malformed beacons.
    head :unprocessable_entity
  end

  private

  def vitals_params
    params.permit(:page, metrics: %i[name value id rating delta navigation_type])
  end
end
```

The strong-params schema matches the client payload (and the `web-vitals`
`Metric` type): `name`, `value`, `id`, `rating`, `delta`, `navigation_type`,
plus the page path. Everything else in the request is dropped.

### CSRF and abuse considerations

`skip_forgery_protection` is what makes the `sendBeacon` path work, and it is a
real trade-off:

- **Why it is usually acceptable here**: the endpoint is write-only, stores
  anonymous numeric metrics, returns no data, and performs no action on behalf
  of a user — there is nothing for a classic CSRF attack to gain.
- **What you give up**: anyone can POST junk metrics. Mitigate with the strict
  schema validation above (unknown names/ratings are dropped, non-numeric
  values are rejected) and rate limiting (e.g. a
  [Rack::Attack](https://github.com/rack/rack-attack) throttle on
  `POST /web_vitals` per IP). Treat the data as untrusted telemetry, not as an
  audit log.
- **Alternative that keeps CSRF protection**: skip `sendBeacon` entirely and
  always use `fetch(..., { keepalive: true })` with the `X-CSRF-Token` header
  read from the `csrf-token` meta tag (emitted by `csrf_meta_tags`). `keepalive` requests survive unload in
  modern browsers, though delivery is somewhat less reliable than `sendBeacon`
  (keepalive requests share a small per-origin in-flight budget). Pick this if
  your security posture rules out any unprotected endpoint.

### Sampling

The `SAMPLE_RATE` constant in the client snippet controls what fraction of page
views report. 10% is a sensible default for most apps: Core Web Vitals are
percentile statistics, so you need volume, not completeness. Guidance:

- **Low-traffic apps** (under ~10k page views/day): sample 100% (`1`) — you
  need every data point to compute a stable p75.
- **High-traffic apps**: 1–10% is typically plenty. At 1M page views/day, a 1%
  sample still yields 10k measurements.
- Decide **once per page view** (as the snippet does), never per metric —
  otherwise a page view contributes CLS but not LCP and your per-page
  correlations break.
- To tune the rate without rebuilding the bundle, emit it from Rails (e.g.
  `<meta name="web-vitals-sample-rate" content="<%= ENV.fetch('WEB_VITALS_SAMPLE_RATE', '0.1') %>">`)
  and read it in the snippet instead of hardcoding the constant.

## Storage and aggregation

This is guidance, not a product — storage and visualization are your app's
choice. Two common paths:

### Option 1: ActiveRecord table

```ruby
# Generate with `bin/rails generate migration CreateWebVitalMetrics` so the
# migration version matches your app's Rails version.
class CreateWebVitalMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :web_vital_metrics do |t|
      t.string :name, null: false
      t.float :value, null: false
      t.float :delta
      t.string :metric_id
      t.string :rating
      t.string :navigation_type
      t.string :page
      t.datetime :created_at, null: false
    end

    add_index :web_vital_metrics, %i[name created_at]
    add_index :web_vital_metrics, %i[page name]
  end
end
```

Core Web Vitals thresholds are defined at the **75th percentile**, so query p75
rather than averages (averages hide the slow tail that ratings are based on):

```sql
-- p75 LCP per page over the last 7 days (PostgreSQL)
SELECT page,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY value) AS p75_lcp_ms,
       count(*) AS samples
FROM web_vital_metrics
WHERE name = 'LCP'
  AND created_at > now() - interval '7 days'
GROUP BY page
ORDER BY p75_lcp_ms DESC;
```

Prune old rows on a schedule (a nightly
`WebVitalMetric.where("created_at < ?", 90.days.ago).delete_all` job) or roll
daily percentiles up into a summary table if volume grows.

### Option 2: forward to your existing APM

If you already run an APM or metrics stack (New Relic, Datadog, Sentry,
Prometheus/StatsD, Scout, Skylight…), skip the table and forward from the
controller instead — e.g. emit a custom event or a distribution/histogram
metric tagged with `name`, `rating`, and `page`. You keep the same first-party
beacon and endpoint; only the sink changes. This is usually the right call when
the APM already owns your dashboards and alerting.

## Privacy

This setup is deliberately privacy-friendly, but keep it that way:

- **No PII in beacons.** The payload is metric names and numbers plus a page
  path. Do not add user IDs, emails, session tokens, or full URLs — the snippet
  sends `location.pathname` precisely because query strings can carry tokens or
  personal data. If a path itself embeds an identifier (e.g. `/users/123`),
  normalize it before storing (`/users/:id`).
- **First-party only.** Data goes from the user's browser to your own origin
  and stays in your database. There is no third-party analytics script, no
  cross-site cookie, and no data-processing agreement with an analytics vendor
  to manage — which substantially simplifies the GDPR story compared with
  shipping field data to an external RUM service.
- **No fingerprinting.** Resist the temptation to add user-agent strings,
  precise geolocation, or device fingerprints "for segmentation." Coarse
  dimensions (`navigation_type`, `rating`, page path) answer almost every
  performance question.

## How this complements server-side benchmarks

The `benchmarks/` suite and [Performance
Benchmarks](../core-concepts/performance-benchmarks.md) answer "did this change
make server rendering slower?" under controlled load. Field Web Vitals answer
"what do real users experience?" across real devices, networks, and cache
states — including everything the server-side numbers cannot see: asset
delivery, font loading (see [Font Optimization](./fonts.md), which targets LCP
and CLS directly), hydration cost, and third-party scripts. Use both: Bencher
to catch server-render regressions in CI, and your vitals table to verify that
optimizations actually move p75 LCP/CLS/INP for users.

## Related

- [Performance Benchmarks](../core-concepts/performance-benchmarks.md) — the
  server-side measurement story this complements
- [Font Optimization](./fonts.md) — a direct LCP/CLS lever, verifiable with
  this setup
- [Caching](./caching.md) — server-side render caching, a common TTFB lever
- [web.dev: Web Vitals](https://web.dev/articles/vitals) — metric definitions
  and thresholds
- [GoogleChrome/web-vitals](https://github.com/GoogleChrome/web-vitals) — the
  collection library
- [Issue #3877](https://github.com/shakacode/react_on_rails/issues/3877) —
  tracking for the planned framework-level hydration-timing instrumentation
