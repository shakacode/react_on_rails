# PPR Cache Warm-Up

> **Experimental**: `ppr_react_component` (Partial Prerendering) and this warm-up mechanism are experimental Pro features. APIs may change between minor versions.

PPR serves a cached static shell instantly and streams only the dynamic Suspense holes on each request. That model has one structural cost: **someone has to pay for the first render of every shell**. This page explains when that cost hits, and how to pay it with a deploy hook instead of with your first visitor.

## The Cold-Start Problem

The first request per PPR cache key runs the full prerender — in the Pro dummy app benchmark that was **~5.9 s cold vs ~0.16 s warm TTFB (≈36×)**. Once per key, that is acceptable. The catch is _when_ keys go cold:

- The PPR cache key includes the **bundle digests**, so **every deploy structurally invalidates every PPR entry**. After each deploy, the first visitor to each PPR route pays the multi-second prerender again.
- PPR v1 has no single-flight control: until the first prerender's cache write lands, **concurrent visitors to the same key each run their own prerender** (last write wins). A busy route right after a deploy multiplies the cost.

Warm-up closes that window: a post-deploy hook requests your PPR routes once, so the cache is already populated when real traffic arrives.

## How Warm-Up Works

The warmer issues **real in-process requests** through your full middleware and controller stack (the same `ActionDispatch::Integration::Session` machinery behind `app.get` in a Rails console). `ppr_react_component` runs with real controller context, your real `cache_key` procs, and real props, and persists exactly the shell + `PostponedState` envelope a live visitor's request would. Cache entries are never written directly, so there is no second code path that can drift from production behavior.

Because the requests are in-process:

- **No web server is required** — warm-up can run in a release phase before the new version serves any traffic.
- **The right keys are warmed by construction** — the process boots the new release's code, so it computes the new bundle digests. With real HTTP through a load balancer you cannot control which code version answers during a rollout.
- **One run warms every instance** — provided `Rails.cache` is a shared store (Redis, Memcached). With a per-instance store (`:memory_store`, `:file_store`), a release-phase process warms only its own private cache and the mechanism does nothing useful; PPR itself needs a shared store for the same reason.

Paths are requested **serially**: the Node renderer is typically cold right after a deploy, and serial warm-up avoids stampeding it.

## Configuration

List the paths to warm in your React on Rails Pro initializer:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.ppr_warm_up_paths = ["/", "/pricing", "/products/best-sellers"]
end
```

For a dynamic list, assign a callable — it runs at warm time, so it may query the database:

```ruby
config.ppr_warm_up_paths = -> { Product.popular.limit(20).map { |p| "/products/#{p.slug}" } }
```

## The Rake Task

```bash
bundle exec rake react_on_rails_pro:ppr:warm
```

The task requests each configured path, isolates failures (one failing route never aborts the rest), and finishes with a summary:

```text
[ReactOnRailsPro] PPR warm-up finished in 14.2s (2 warmed, 1 already-warm/no-ppr, 1 failed)
  warmed: / (1 entry written)
  warmed: /pricing (1 entry written)
  already_warm: /products/best-sellers
  failed: /broken-page (HTTP 500)
```

Options via environment variables:

| Variable               | Effect                                                                                                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `PPR_WARM_PATHS=/a,/b` | Override the configured list for this run.                                                                                                       |
| `PPR_WARM_HOST=...`    | Host header for the requests. Set your canonical host if cached shells contain absolute URLs — the shell HTML is cached verbatim, host included. |
| `PPR_WARM_HTTPS=false` | Issue plain-HTTP requests (default is HTTPS so `force_ssl` apps don't answer with a redirect).                                                   |
| `PPR_WARM_STRICT=true` | Exit non-zero when any path fails.                                                                                                               |

The variables are `PPR_WARM_`-prefixed on purpose: bare `HOST`/`HTTPS` are commonly pre-set by shells, CGI servers, and Docker images, and a leaked value would silently change warm-up behavior.

**Exit-code policy:** by default the task exits 0 even when paths fail, because warm-up is best-effort — the worst case is what you have without it (the first visitor pays the prerender), and a failed warm-up should not roll back an otherwise good release. Use `PPR_WARM_STRICT=true` where you want the deploy pipeline to surface failures loudly. The one exception: an entirely empty path list (nothing configured and no `PPR_WARM_PATHS`) is a misconfiguration, not a failed warm-up, and exits non-zero with guidance regardless of `PPR_WARM_STRICT`.

## The Ruby API

The task is a thin wrapper over a callable service, for use from background jobs or custom deploy tooling:

```ruby
summary = ReactOnRailsPro::Ppr::CacheWarmer.call(
  paths: ["/", "/pricing"],                       # optional; defaults to config.ppr_warm_up_paths
  host: "www.example.com",                         # optional; see PPR_WARM_HOST above
  https: true,                                     # optional; default true
  headers: { "Cookie" => warm_up_session_cookie }  # optional; e.g. for member-only pages
)

summary.warmed.map(&:path)        # => ["/", "/pricing"]
summary.already_warm              # cache hit — or the page renders no PPR component at all
summary.failed.map(&:detail)      # => ["HTTP 500", ...]
summary.success?                  # => false if anything failed
Rails.logger.warn(summary.to_log) unless summary.success?
```

Outcomes are attributed by observing the `ppr.cache.write` / `ppr.cache.write_refused` instrumentation events during each request. One caveat until PPR hit/miss counters land: a 2xx response with no cache write is reported as _already warm_, which also covers a page that renders no `ppr_react_component` at all — a typo'd path that still routes somewhere real shows up in this bucket, not in `failed`. Attribution observes process-global events, so run warm-up in a process that is not concurrently serving PPR traffic (a release phase, rake task, or job worker — the usual setups — all qualify); in a process that is also serving requests, another request's events could be attributed to the path being warmed.

## Where to Hook It Into Your Deploy

Warm-up must run **after the new bundle digest is live** — the digest is part of the cache key, so entries written against the old digest are useless to the new code. **Never run warm-up as a build step**: at build time the new digests may not be final and the production cache store is often unreachable; build-step prerendering is a separate (SSG) track.

**Heroku release phase** — the release phase runs the new slug (new digests) before new dynos serve traffic, which is exactly right:

```procfile
release: bundle exec rake db:migrate react_on_rails_pro:ppr:warm
```

**Kubernetes** — run a post-rollout `Job` from the same image as the new pods:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ppr-warm-up
spec:
  template:
    spec:
      containers:
        - name: warm
          image: myapp:NEW_TAG # same image as the rollout
          command: ['bundle', 'exec', 'rake', 'react_on_rails_pro:ppr:warm']
      restartPolicy: Never
```

**Boot-time background job** — when you have no release phase, enqueue from an initializer so warming starts as the new version boots (requests served before warming finishes fall back to first-request prerender). A spurious enqueue from a console or rake boot is harmless — paths that are already cached classify as _already warm_ and run no prerender — so a plain production check is a reasonable guard. (Don't gate on `defined?(Rails::Server)`: it is only defined when booted via `bin/rails server`, not when Puma is started directly.)

```ruby
# config/initializers/ppr_warm_up.rb
Rails.application.config.after_initialize do
  PprWarmUpJob.perform_later if Rails.env.production?
end

class PprWarmUpJob < ApplicationJob
  def perform(paths: nil)
    summary = ReactOnRailsPro::Ppr::CacheWarmer.call(paths: paths)
    Rails.logger.warn(summary.to_log) unless summary.success?
  end
end
```

During a rolling deploy, old instances keep reading their old-digest entries while warm-up populates the new-digest keys — both coexist in the shared store, so warming early never breaks the instances still running old code.

## Interaction with `expires_in` and `revalidate_tag`

**`cache_options: { expires_in: ... }`** — warm-up writes through the same helper call, so the entry gets whatever TTL the view declares. If the TTL is shorter than your deploy cadence, entries expire between deploys and the next visitor pays the prerender again; for short TTLs on hot routes, schedule re-warming (cron or a recurring job) rather than only warming at deploy time. Re-running warm-up is cheap for keys that are still cached — they are classified _already warm_ and no prerender runs.

**`ReactOnRailsPro.revalidate_tag`** — revalidating a tag evicts the paired shell record immediately, and the next visitor pays the prerender. If that page matters, the code that revalidates can re-warm in the same breath:

```ruby
def publish_product_update(product)
  ReactOnRailsPro.revalidate_tag("product:#{product.id}")
  PprWarmUpJob.perform_later(paths: ["/products/#{product.slug}"])
end
```

## Troubleshooting

- **Every path reports `failed (redirected to ...)`** — your app redirects the warmer's requests, typically `force_ssl` (keep the default `https: true`), a locale redirect, or authentication. For member-only pages pass a session cookie via the Ruby API's `headers:` option; a redirecting path warms nothing, so list the final path instead.
- **Warm-up reports `warmed` but visitors still miss** — check that `Rails.cache` is a shared store reachable from both the warm-up process and your web instances, and that warm-up ran the same release (same bundle digests) your instances serve.
- **Paths report `already_warm` unexpectedly** — remember this bucket also covers pages that render no `ppr_react_component` (see above).
