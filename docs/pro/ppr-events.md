# PPR Instrumentation Events

> **Experimental**: `ppr_react_component` (Partial Prerendering) is an experimental Pro feature. Event names and payloads may change between minor versions.

Every PPR render path emits [`ActiveSupport::Notifications`](https://guides.rubyonrails.org/active_support_instrumentation.html) events so operators can monitor cache effectiveness, cache health, and degradations without touching the render pipeline. This page is the complete catalog: eight events, their triggers, payloads, and the guarantees they ship with.

Names follow the Rails convention `ppr.<area>.<what>.react_on_rails_pro` — the library name goes last so subscribers can match every PPR event with one pattern:

```ruby
# config/initializers/ppr_metrics.rb — count every PPR event in StatsD
ActiveSupport::Notifications.subscribe(/\Appr\..*\.react_on_rails_pro\z/) do |name, _start, _finish, _id, payload|
  StatsD.increment(name.sub(".react_on_rails_pro", ""), tags: ["component:#{payload[:component_name]}"])
end
```

All constants live on `ReactOnRailsPro::Ppr` (e.g. `ReactOnRailsPro::Ppr::CACHE_LOOKUP_NOTIFICATION`), so subscribe via the constants rather than string literals where you can.

## The catalog

| Event                            | Fires when                                                                                                                | Payload                                                                                                                 |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `ppr.cache.lookup`               | Once per `ppr_react_component` invocation, at the validated cache read                                                    | `component_name`, `outcome` (`:hit` \| `:miss`)                                                                         |
| `ppr.static_shell`               | A render completed with no Suspense holes (`postponed_state` nil) and no render error                                     | `component_name`                                                                                                        |
| `ppr.cache.write`                | A shell + PostponedState envelope was persisted                                                                           | `component_name`, `cache_key` (raw — see below)                                                                         |
| `ppr.cache.write_refused`        | A cache write was skipped or failed                                                                                       | `component_name`, `reason` (`"render_error"` \| `"expired"` \| `"store_error"`)                                         |
| `ppr.cache.read_error`           | The cache store raised during a read (treated as a miss)                                                                  | `component_name`, `error` (class name only)                                                                             |
| `ppr.cache.evict_invalid`        | A cached entry failed envelope validation and was deleted                                                                 | `component_name`, `reason` (`"malformed"` \| `"unknown_schema"` \| `"react_version_mismatch"` \| `"checksum_mismatch"`) |
| `ppr.resume.degraded_pre_flush`  | The cache-hit path raised **before** the shell was committed; entry evicted, full SSR fallback served in the same request | `component_name`, `error` (class name only)                                                                             |
| `ppr.resume.degraded_post_flush` | The resume phase raised **after** the shell was flushed; entry evicted, stream terminated (page heals on reload)          | `component_name`, `error` (class name only)                                                                             |

Full event names carry the `.react_on_rails_pro` suffix, e.g. `ppr.cache.lookup.react_on_rails_pro`.

## `ppr.cache.lookup` — cache effectiveness

The hit/miss counter. Exactly **one** lookup event fires per `ppr_react_component` invocation, decided by the validated cache read before any render work:

- `outcome: :hit` — a validated cached envelope was found; the cached shell serves with no prerender request.
- `outcome: :miss` — no usable entry: first visit, expired, evicted as invalid, or a cache read error. The full prerender runs.

One event with the outcome in the payload follows Rails' own cache convention (`cache_read.active_support` and its `:hit` payload key). The hit rate is one subscription:

```ruby
lookups = Hash.new(0)
ActiveSupport::Notifications.subscribe(ReactOnRailsPro::Ppr::CACHE_LOOKUP_NOTIFICATION) do |*args|
  lookups[args.last[:outcome]] += 1
end
# hit rate = lookups[:hit].to_f / (lookups[:hit] + lookups[:miss])
```

Semantics worth knowing before you alert on it:

- **The event records the lookup, not the delivery.** If a hit's serve path fails before the shell reaches the response, the lookup is not retracted — the request additionally emits `ppr.resume.degraded_pre_flush` and falls back to a full render. A _degraded hit_ is therefore the pair `lookup{outcome: :hit}` + `degraded_pre_flush` in the same request; the fallback render emits **no second lookup**, so `hits + misses` always equals the number of helper invocations.
- **Diagnostic misses stay diagnosable.** An invalid entry or a read error counts as `outcome: :miss` _and_ fires its own `evict_invalid` / `read_error` event — the lookup keeps denominators honest while the sibling event carries the reason.
- **Per invocation, not per page.** A page rendering three `ppr_react_component` calls emits three lookups. `hits / lookups` is a component-render hit rate; interpret page-level questions accordingly.
- **`ppr.static_shell` is a different axis.** It reports "this render had no holes" and says nothing about cache state; the two compose (a fully-static warm serve emits `lookup{hit}` + `static_shell`).

## Guarantees

**Events never break the page (the non-fatal contract).** Every emission on a render path is wrapped so a raising subscriber cannot take down the render — the shell still serves and cache writes still land. Boundary: the wrapper rescues `StandardError`; a subscriber raising a bare `Exception` subclass (`SystemExit` and friends) propagates by design. Note that this is a Pro-side guarantee: plain `ActiveSupport::Notifications` **re-raises subscriber errors to the instrumenting caller**, so keep your own subscribers cheap and rescued anyway — they run inline on the request thread.

**Payloads are redacted (no request data).** Error payloads carry only the error **class name**, never `error.message`, which can embed user input (PRs #4966/#4976). Lookup payloads carry only `component_name` and `outcome` — deliberately no cache key, because PPR cache keys are user-supplied (`cache_key: ["dashboard", current_user.id]` is typical) and can carry identifiers.

**The one raw-value exception**: `ppr.cache.write` includes the raw computed `cache_key`, kept for cache debugging (finding the entry in Redis). If your subscriber forwards payloads to an external system, drop or hash that field.

**Ordering within one invocation** (events on the same request thread, in emission order — `evict_invalid` / `read_error` fire _inside_ the cache read, so they precede the `lookup` event that reports the read's outcome):

| Scenario                    | Sequence                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------ |
| Cold miss (normal page)     | `lookup{miss}` → `cache.write`                                                       |
| Warm hit (normal page)      | `lookup{hit}`                                                                        |
| Fully static, cold → warm   | `lookup{miss}` → `cache.write` → `static_shell`, then `lookup{hit}` → `static_shell` |
| Invalid entry               | `cache.evict_invalid` → `lookup{miss}` → `cache.write`                               |
| Read error                  | `cache.read_error` → `lookup{miss}` → `cache.write`                                  |
| Render error                | `lookup{miss}` → `cache.write_refused{render_error}`                                 |
| Degraded hit (pre-flush)    | `lookup{hit}` → `resume.degraded_pre_flush` → `cache.write`                          |
| Resume failure (post-flush) | `lookup{hit or miss}` → … → `resume.degraded_post_flush`                             |

**Attribution is process-global.** Subscriptions see every thread in the process; there is no per-request scoping. When counting per request (as the [cache warm-up](./ppr-cache-warm-up.md) tool does), run in a process that is not concurrently serving PPR traffic.

## Reference consumer

`ReactOnRailsPro::Ppr::CacheWarmer` subscribes to five of these events to classify each warm-up request as `warmed` / `already_warm` / `no_ppr` / `failed` — see [PPR Cache Warm-Up](./ppr-cache-warm-up.md). In particular, "2xx response with zero PPR events" is how it detects a warm path that renders no `ppr_react_component` at all.
