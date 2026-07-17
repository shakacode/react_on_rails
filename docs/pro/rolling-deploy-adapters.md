# Rolling-Deploy Adapters

React on Rails Pro pre-seeds the Node Renderer cache so that during a **rolling deploy** — when the old and new versions of your app briefly run side by side — the renderer never has to cold-start a bundle in the middle of a request.

The **built-in HTTP adapter** does this with **no extra infrastructure**: the still-running deployment serves its own bundles over an authenticated endpoint, and the next deploy pulls them. This is the recommended setup for almost everyone.

> **TL;DR** — Set three config values, use the auto-mounted controller, and in-flight requests for draining bundle versions stop paying the `410 Gone` → re-upload → retry tax. No S3, IAM, or extra gem. **[Jump to setup](#set-up-the-http-adapter).**

## The problem

During a rolling deploy:

- Old Rails instances (bundle hash `abc`) are still draining traffic.
- New Rails instances (bundle hash `def`) serve new traffic.
- New renderer instances receive requests for **both** hashes.

Pre-seeding the current hash (`def`) eliminates the 410→retry only for the new bundle. Requests referencing `abc` still hit a cold cache on new renderers, producing 410 retries per request until the renderer has cached that bundle via upload.

<p>
  <img src="images/rolling-deploy-problem.svg" alt="During a rolling deploy, draining old Rails (hash abc) and new Rails (hash def) both send SSR requests to a new renderer pool seeded only with the current hash def. The def requests hit the cache, but the abc requests miss and trigger 410 Gone, re-upload, and retry once per request." width="840" />
</p>

The cold path is bounded and self-healing, but it is not free. On a cache miss the renderer can't serve the request on its own: it returns `410 Gone`, Rails ships the bundle over to the renderer, and only then does the request render. That extra renderer ↔ Rails round-trip — a network hop plus the bundle transfer — adds latency to **every** request that touches a cold bundle, and it repeats per request until that bundle is cached, so a deploy shows up as a latency and error-rate spike. The whole point of a rolling-deploy adapter is to **avoid these cache misses entirely** so no request ever pays that cost during a deploy.

## The solution

A **rolling-deploy adapter** makes new renderer instances start warm for **every** in-flight bundle hash — not just the current one — so draining `abc` requests hit the cache instead of triggering a 410.

<p>
  <img src="images/rolling-deploy-solution.svg" alt="With a rolling_deploy_adapter the new renderer pool is pre-seeded with both the draining hash abc and the current hash def before it serves traffic, so both old draining Rails and new Rails requests hit the cache — no 410, no retry." width="840" />
</p>

The built-in HTTP adapter is the simplest way to get there, and it's covered next. If your build can't reach the previous deployment, or you'd rather keep bundles in your own store, you can [write a custom adapter](./rolling-deploy-custom-adapters.md) instead.

## Set up the HTTP adapter

> Introduced as a scaffold in PR [#3379](https://github.com/shakacode/react_on_rails/pull/3379) — part 1 of a multi-PR series. A hard HTTPS gate, streaming download, and additional hardening land in follow-ups; see [Security](#security) below.

The currently-deployed Rails server already has every bundle and companion asset on disk. The HTTP adapter has the **next** deploy's build pull those files directly from the **previous** deploy over an authenticated HTTP endpoint — `upload` is a deliberate no-op because the running server _is_ the store:

<p>
  <img src="images/http-adapter-flow.svg" alt="The next deploy's build CI runs the HTTP adapter, which calls the still-running previous deployment's authenticated GET /manifest and GET /bundles/:hash endpoints, receives a gzipped tarball of the bundle plus companion assets read from disk, and extracts and stages each bundle into the new renderer cache." width="840" />
</p>

### 1. Configure the adapter

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.rolling_deploy_adapter      = ReactOnRailsPro::RollingDeployAdapters::Http
  config.rolling_deploy_token        = ENV.fetch("ROLLING_DEPLOY_TOKEN")    # shared secret, ≥ 32 bytes
  config.rolling_deploy_previous_urls = ENV["ROLLING_DEPLOY_PREVIOUS_URLS"] # comma-delimited or an Array
end
```

- **`rolling_deploy_token`** — the shared bearer token ("password"). Generate one with `SecureRandom.hex(32)` and set the **same** value on both the running server (which authenticates incoming pulls) and the build CI (which sends it). The config validator rejects tokens shorter than 32 bytes.
- **`rolling_deploy_previous_urls`** — one or more previous-deployment URLs reachable **from the build CI**. It accepts an Array, a comma-delimited String, or one String. Use a bare origin such as `https://old.example.com` to inherit `rolling_deploy_mount_path`, or include an explicit path such as `https://old.example.com/internal/rolling-deploy` to preserve that path. Order is retained and duplicates are removed. Leave it unset (or empty) to disable discovery on that build. The singular `rolling_deploy_previous_url` remains supported for compatibility, but configuring both singular and plural values is an error.
- **`rolling_deploy_mount_path`** — the Rails path where the Pro engine auto-mounts the bundle-serving endpoint when the built-in HTTP adapter is configured. Defaults to `/react_on_rails_pro/rolling_deploy`. Set it to a custom path when your previous deployment is reachable elsewhere, or set it to `nil`/blank to opt out of auto-mounting and draw the routes yourself.

Previous URLs must use HTTP or HTTPS and include a host. Credentials, query strings, and fragments are rejected. A bare origin also requires a nonblank `rolling_deploy_mount_path`; use an explicit path when the local engine mount is disabled.

### 2. Server endpoint auto-mount

When `config.rolling_deploy_adapter = ReactOnRailsPro::RollingDeployAdapters::Http`, React on Rails Pro automatically routes the bundle-serving controller at `config.rolling_deploy_mount_path`:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.rolling_deploy_adapter = ReactOnRailsPro::RollingDeployAdapters::Http
  config.rolling_deploy_token = ENV.fetch("ROLLING_DEPLOY_TOKEN")
  # No config/routes.rb entry is required for the default mount path.
end
```

That exposes two authenticated endpoints under the mount path (default `/react_on_rails_pro/rolling_deploy`):

| Endpoint             | Returns                                                                                                                                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /manifest`      | JSON with `hashes`, `rsc_enabled`, `generated_at`, `protocol_version: 2`, and `artifact_identity: { scheme: "rorp-v2-sha256", version: 2 }` for the current deploy. Older protocol-v1 manifests remain readable. |
| `GET /bundles/:hash` | `application/gzip` tarball containing `bundle.js` plus that artifact ID's exact companion assets.                                                                                                                |

The auto-mounted routes are prepended ahead of application routes, so terminal catch-all routes do not shadow the endpoint. They also use an internal route-helper prefix, so apps that still have an older manual mount at the default path keep booting while you remove the redundant manual route.

### Manual route override

Most apps should use the auto-mount. Draw routes manually only when you need app-controlled routing behavior, such as a secondary endpoint or a wrapper around the built-in controller.

To take over routing completely, opt out of the engine route and draw your own:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.rolling_deploy_adapter = ReactOnRailsPro::RollingDeployAdapters::Http
  config.rolling_deploy_mount_path = nil
end
```

Set `config.rolling_deploy_mount_path = ""` instead when your configuration source represents opt-outs as blank strings.

```ruby
# config/routes.rb
ReactOnRailsPro::RollingDeploy::BundlesController.draw_routes(
  self,
  path: "/internal/rolling-deploy"
)
```

To keep the auto-mount and add one or more secondary manual mounts, pass a distinct `as_prefix:` for each manual mount so Rails' named-route registry does not collide:

```ruby
# config/routes.rb
ReactOnRailsPro::RollingDeploy::BundlesController.draw_routes(
  self,
  path: "/internal/rolling-deploy",
  as_prefix: "internal_rolling_deploy"
)
```

### Security

- **Bearer-token auth** on every request (`Authorization: Bearer <token>`), constant-time compare, with a uniform `401` for missing/malformed/wrong tokens so callers can't distinguish failure modes.
- The `:hash` parameter is matched against an **allowlist** of the current deployment's real bundle hashes — anything else returns `404` before touching the filesystem.
- Responses carry `Cache-Control: no-store`, `Pragma: no-cache`, and `X-Content-Type-Options: nosniff`.
- Tarball extraction is **path-traversal-proofed**, accepts regular files only, and enforces a 200 MB uncompressed cap (zip-bomb guard).
- Discovery and download use monotonic overall deadlines as well as capped per-request connection/read timeouts, so a slow sequence of origins cannot reset the operation's wall-clock budget.

> [!WARNING]
> **Use HTTPS in production.** The token is a bearer credential. Over plain HTTP to a non-loopback host the adapter logs a warning that the token is being sent over an unencrypted connection; a hard HTTPS gate is planned for a follow-up release. Until then, ensure every `rolling_deploy_previous_urls` entry uses `https://` in production environments.

### Companion assets are handled automatically

Each bundle hash ships with the companion assets built alongside it — `loadable-stats.json`, plus `react-client-manifest.json` and `react-server-client-manifest.json` when RSC is enabled. They map chunk and component IDs to the exact asset URLs that hash's build produced, so serving a draining hash with the **wrong** build's manifests would break client-side hydration. The HTTP adapter packs each hash's companions into the same tarball, so this stays correct with no work on your part. (Custom adapters must return them explicitly — see [Companion assets](./rolling-deploy-custom-adapters.md#companion-assets).)

Current Pro artifact IDs begin with `rorp-v2-` and identify the role, bundle bytes, companion destination names, and companion bytes together. Changing only a manifest or `loadable-stats.json` therefore produces a new ID and invalidates fragment and renderer caches consistently. With multiple previous origins, duplicate legacy/protocol-v1 hashes are omitted because their payload provenance is ambiguous. Duplicate v2 IDs are safe to try in configured order because every downloaded payload is recomputed and rejected unless it matches the requested ID.

## Deploy the renderer before Rails

> [!IMPORTANT]
> During a rolling deploy, the new Node Renderer must be live and cache-warm **before** the new Rails server starts serving traffic. If Rails goes first, the adapter's warm-cache guarantee doesn't hold for that window — you get exactly the 410 storm it's meant to prevent.

Pre-seeding warms the **renderer's** cache. Rails renders nothing itself; it sends SSR requests to the renderer. So a warm cache only helps if the new renderer is already up and serving when the new Rails (bundle `def`) starts sending it traffic:

- New Rails (`def`) can only be served warm by a renderer that has `def` cached — and that's the **new** renderer instances.
- Draining old Rails (`abc`) is served warm by either fleet, because the new renderer was pre-seeded with `abc` too.

If the new Rails goes live first, its `def` requests hit renderers that don't have `def` yet → 410 → re-upload → retry, per request, until the new renderer catches up. Roll the renderer out first and that never happens.

### On Control Plane (and other multi-workload platforms)

Rails and the Node Renderer are **separate workloads** with independent deploy lifecycles, readiness checks, and warmup periods. Deploying both at once does **not** guarantee the renderer wins the race — the two can have different warmup/readiness settings, so Rails may begin taking traffic before the renderer's new revision is ready.

Make the ordering explicit in your pipeline rather than relying on timing:

1. Deploy/promote the **Node Renderer** workload (new image, cache pre-seeded during its build).
2. Wait until its new revision is **live and healthy** — readiness passing and all new renderer instances up.
3. Only then deploy/promote the **Rails** workload.

The invariant to enforce is **renderer-ready-before-Rails-live**: gate the Rails workload's release on the renderer workload's release completing (sequence them as separate steps in your deploy pipeline), and/or tune the renderer's readiness probe and Rails' startup so Rails does not accept traffic until the renderer reports ready. The exact wiring depends on your deploy tooling.

## Verify your setup with `react_on_rails:doctor`

`react_on_rails:doctor` probes the configured `rolling_deploy_adapter` and reports:

- ✅ Whether it responds to all three required methods.
- ✅ Whether `previous_bundle_hashes` returns successfully within 10 seconds, and how many hashes it returned.
- ⚠️ Empty-list returns (often indicates the upload side has never run on a prior deploy).
- ℹ️ The resolved renderer cache dir and how many bundle-hash subdirectories are present.
- ℹ️ Whether `PREVIOUS_BUNDLE_HASHES` env override is set.

Doctor never calls `fetch` or `upload` — those have side effects.

## Need your own artifact store?

The HTTP adapter assumes the previous deployment is still running and reachable from your build. Reach for a **custom adapter** instead when:

- Builds run where they can't reach the running app (isolated CI, different VPC).
- The previous deployment may already be torn down by the time the next one builds.
- You want bundle artifacts to persist independently of any deployment's lifetime (for example, in S3).

The protocol is small — three class methods — and ships with copy-pasteable S3, Control Plane, and Filesystem reference implementations.

→ **[Custom rolling-deploy adapters](./rolling-deploy-custom-adapters.md)**

## Relationship to `remote_bundle_cache_adapter`

These two adapters solve different problems and are complementary:

|              | `remote_bundle_cache_adapter`                 | `rolling_deploy_adapter`                  |
| ------------ | --------------------------------------------- | ----------------------------------------- |
| **Scope**    | Webpack build outputs (pre-compile caching)   | Deployed bundle hashes (rolling deploy)   |
| **When**     | Build phase (`assets:precompile`)             | Post-precompile + pre-seed phase          |
| **Avoids**   | Rebuilding webpack when source hasn't changed | 410 retries for draining-version requests |
| **Keyed by** | Source digest                                 | Bundle hash                               |

You can configure both; they don't interact.
