# Migrate from Next.js

This guide is for teams running a **Next.js frontend against a Rails backend** (or evaluating that split) who want to collapse the two apps into a single Rails application with React on Rails — keeping modern React (server components, streaming, `'use client'`) while deleting the duplicated auth, API, and deployment layers.

It has two parts:

1. A [capability mapping](#capability-mapping-nextjs--react-on-rails-pro) from Next.js App Router concepts to their React on Rails (and React on Rails Pro) equivalents — restricted to what is shipped today, with a short, explicit roadmap list for the rest.
2. An [incremental migration strategy](#collapse-the-two-app-stack-incremental-migration-behind-a-reverse-proxy) for moving a Next.js app into Rails route-by-route behind a reverse proxy, with no big-bang cutover.

For the architectural decision itself (one app vs. two), see [Next.js with a Separate Rails Backend: Pros and Drawbacks](../getting-started/nextjs-with-separate-rails-backend.md) and [Comparing React on Rails to Alternatives](../getting-started/comparing-react-on-rails-to-alternatives.md).

## When this migration makes sense

- You run (or are about to run) **two apps** — a Next.js frontend and a Rails API — and are paying for it twice: two deploys, two runtimes to monitor and patch, duplicated session/CSRF/auth handling, and an API contract whose only consumer is your own frontend.
- Your team is **Rails-strong** and the API exists mostly to feed the Next.js app, not external clients.
- You want React Server Components, streaming SSR, and component caching, and would rather get them inside Rails than maintain a second framework's mental model. These are [React on Rails Pro](../../pro/react-on-rails-pro.md) features.

## When to stay on Next.js

Be honest about the cases where this migration is the wrong move:

- **No Rails team.** If Rails is not already a first-class part of your stack, adopting it to host React is a bigger change than this guide covers.
- **Your API has many external consumers.** If mobile apps and partners consume the same API, the two-app split is carrying real architectural weight (see the [decision checklist](../getting-started/nextjs-with-separate-rails-backend.md#decision-checklist)).
- **You depend on Vercel-specific edge features** (edge middleware/functions at the CDN, ISR served from Vercel's CDN). React on Rails runs on any Rack host; it does not replicate Vercel's edge network.

## Capability mapping: Next.js → React on Rails (Pro)

Every row in this table maps to a feature that is **shipped and documented today**. Rows marked **[Pro]** require [React on Rails Pro](../../pro/react-on-rails-pro.md); RSC and streaming additionally require the [Node renderer](../../pro/node-renderer.md).

| Next.js (App Router)                                         | React on Rails (Pro)                                                                                                                       | Docs                                                                                                                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| React Server Components (server-first pages)                 | **[Pro]** `registerServerComponent` to register, `RSCRoute` to embed server components inside client trees                                 | [RSC hub](../../pro/react-server-components/index.md), [RSC inside client components](../../pro/react-server-components/inside-client-components.md)      |
| `'use client'` directive                                     | Same directive, unchanged. **[Pro]** auto-bundling reads it to choose between `ReactOnRails.register` and `registerServerComponent`        | [Auto-bundling with RSC](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#auto-bundling-with-react-server-components)      |
| Streaming SSR + `<Suspense>` (`loading.tsx`)                 | **[Pro]** `stream_react_component` and `stream_react_component_with_async_props`                                                           | [Streaming SSR](../../pro/streaming-ssr.md)                                                                                                               |
| Data fetching in server components (`fetch` to your own API) | **In-process data access** — ActiveRecord in the controller or in async-props blocks; no HTTP hop, no API layer to maintain                | [RSC data fetching](./rsc-data-fetching.md), **[Pro]** [DB queries in async props](../../pro/async-props-database-queries.md)                             |
| Full Route Cache / component caching                         | **[Pro]** `cached_react_component` (fragment caching) and one-line prerender caching                                                       | [Caching](../building-features/caching.md), [Fragment caching](../../pro/fragment-caching.md)                                                             |
| Metadata API (`metadata` export, `generateMetadata`)         | React 19 native metadata — `<title>`/`<meta>`/`<link>` rendered in components are hoisted to `<head>`; works with SSR, streaming, and RSC  | [React 19 Native Metadata](../building-features/react-19-native-metadata.md)                                                                              |
| `next/font/local`                                            | `react_on_rails_font_face` view helper — self-hosted `.woff2` preload, `@font-face` with `font-display`, metric-matched fallback           | [Font Optimization](../building-features/fonts.md)                                                                                                        |
| `next/link` + client-side routing                            | React Router or TanStack Router integration (your routes, SSR-compatible)                                                                  | [React Router](../building-features/react-router.md), [TanStack Router](../building-features/tanstack-router.md)                                          |
| `middleware.ts` (auth gating, redirects, headers)            | Rack middleware and Rails controller filters — auth runs in the same process as the data it protects (Devise/Warden and friends)           | [Rails on Rack](https://guides.rubyonrails.org/rails_on_rack.html)                                                                                        |
| `next dev` (HMR dev server)                                  | `bin/dev` — Rails plus webpack-dev-server with HMR by default                                                                              | [HMR and dev server modes](../building-features/dev-server-and-testing.md)                                                                                |
| Vercel deploy / self-hosted `next start`                     | Any Rack host: one Rails deploy, standard Rails 7.1+ Dockerfile; **[Pro]** Node renderer ships as a sidecar container when you use SSR/RSC | [Docker deployment](../deployment/docker-deployment.md), [Node renderer container deployment](../building-features/node-renderer/container-deployment.md) |

The headline row is data access. In the two-app stack, a "server component" in Next.js still fetches from your Rails API over HTTP, with auth forwarded across the boundary. After the migration the same component's data comes from ActiveRecord in-process — the API endpoints that existed only to feed the frontend get deleted, not rewritten.

### On the roadmap (not shipped yet)

These Next.js capabilities do not have a first-party React on Rails equivalent today. Each is tracked in an open issue; the table lists the interim approach.

| Next.js capability                            | Status                                                                                                                                                |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Server Actions (`'use server'`)               | Tracked in [#3867](https://github.com/shakacode/react_on_rails/issues/3867). Today: Rails controller actions receiving regular form posts             |
| `use cache` tags / `revalidateTag`            | Tracked in [#3871](https://github.com/shakacode/react_on_rails/issues/3871). Today: key-based cache expiry via the `cache_key` option                 |
| `useForm`-style form/mutation helpers         | Tracked in [#3872](https://github.com/shakacode/react_on_rails/issues/3872). Today: standard `fetch`/form submission to Rails controllers             |
| File-system routing, nested layouts, prefetch | Tracked in [#3873](https://github.com/shakacode/react_on_rails/issues/3873). Today: Rails routes + React Router/TanStack Router                       |
| `next/image` optimization analog              | Tracked in [#3874](https://github.com/shakacode/react_on_rails/issues/3874). Today: webpack asset pipeline ([images](../building-features/images.md)) |

## Collapse the two-app stack: incremental migration behind a reverse proxy

You do not need a big-bang rewrite. Because the two-app stack already routes browser traffic through a reverse proxy (or can trivially be put behind one), you can migrate **one route group at a time**: Rails takes over a path prefix, Next.js keeps serving everything else, and users never notice the seam.

### Step 0: Prerequisites

- Your Rails app (today's API backend) gets React on Rails installed: [Installation into an Existing Rails App](../getting-started/installation-into-an-existing-rails-app.md). For RSC/streaming parity with Next.js, add [React on Rails Pro](../../pro/installation.md) and the Node renderer.
- Both apps must be reachable from one reverse proxy you control: nginx, Caddy, HAProxy, an ALB, or your CDN's origin routing all work. If Next.js and Rails are on separate subdomains (`app.example.com` + `api.example.com`), plan to serve the migrated routes from the main domain — same-origin is what lets you delete the cross-origin auth plumbing later.

### Step 1: One domain, one proxy

Route all browser traffic through the proxy, with Next.js as the default upstream and Rails opted in per path:

```nginx
upstream nextjs { server 127.0.0.1:3000; }
upstream rails  { server 127.0.0.1:3001; }

server {
  listen 443 ssl;
  ssl_certificate     /etc/ssl/certs/example.com.pem;   # replace with your cert path
  ssl_certificate_key /etc/ssl/private/example.com.key; # replace with your key path
  server_name example.com;
  # Terminate TLS at the proxy so both upstreams speak plain HTTP internally.

  # nginx proxies upstream over HTTP/1.0 by default, which lacks chunked
  # transfer encoding (required for streaming SSR) and disables keep-alive.
  # Use HTTP/1.1 and clear the Connection header.
  proxy_http_version 1.1;
  proxy_set_header Connection "";

  # Required for streaming SSR (stream_react_component, RSC async props):
  # nginx buffers the full response by default, defeating streaming. If you
  # prefer to keep buffering on globally, Rails can instead disable it per
  # response with an `X-Accel-Buffering: no` header.
  proxy_buffering off;

  # Streaming SSR and RSC async-props responses can hold connections open
  # longer than nginx's default 60s proxy_read_timeout. Tune to match your
  # slowest expected stream.
  # proxy_read_timeout 120s;

  # Forward the browser-facing origin so both apps generate correct URLs
  # and the shared session cookie stays on example.com.
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

  # Migrated route groups go to Rails (grows over time). Match the exact
  # path plus its subpaths — a bare prefix like `location /account` would
  # also capture /accounting.
  location = /account  { proxy_pass http://rails; }
  location /account/   { proxy_pass http://rails; }
  location = /settings { proxy_pass http://rails; }
  location /settings/  { proxy_pass http://rails; }

  # Rails also keeps serving the existing API for not-yet-migrated pages
  location /api/ { proxy_pass http://rails; }

  # Everything else stays on Next.js until migrated. Re-enable buffering
  # here: only the Rails streaming responses need it off.
  location / {
    proxy_pass http://nextjs;
    proxy_buffering on;
  }
}
```

Each migrated route group is a two-line proxy change — and a two-line rollback if something goes wrong.

:::caution proxy_set_header inheritance
nginx only inherits `server`-level `proxy_set_header` directives into `location` blocks that define **none** of their own. If you later add a `proxy_set_header` inside a `location`, repeat all of the headers above in that block.
:::

### Step 2: Share the session

Pick the Rails session as the source of truth for authentication:

- Set the Rails session cookie on the shared domain. Since the proxy serves both apps from one origin, the browser sends the same cookie to both upstreams. If the cookie was previously scoped to an API subdomain, set the domain explicitly:

  ```ruby
  # config/initializers/session_store.rb
  Rails.application.config.session_store :cookie_store,
                                          key: "_example_session",
                                          domain: "example.com" # the shared, browser-facing domain
  ```

- Next.js pages that need auth state already forward cookies to the Rails API for data fetching; that keeps working unchanged.
- Avoid migrating _half_ of an auth flow. Move login/logout/signup to Rails early (they are usually plain forms — the easiest pages to port), so there is exactly one place that writes the session.

### Step 3: Migrate one route group at a time

Pick a self-contained route group (start with a low-risk one). For each:

1. **Add the Rails route and controller.** The controller loads data with ActiveRecord directly — this replaces the API call the Next.js page was making.
2. **Port the page component.** Your React components move largely as-is (see [porting notes](#porting-component-code) below). Render with `react_component` in the view, or `stream_react_component` / `RSCRoute` with Pro for streaming and server components.
3. **Verify behind the proxy locally**, then flip the `location` block for that path prefix from the Next.js upstream to Rails.
4. **Watch error rates and Core Web Vitals** for the migrated paths; roll back by reverting the proxy line if needed.

### Step 4: Retire redundant API endpoints

After each route group moves, the API endpoints that existed only to feed those Next.js pages have no callers left. Delete them (or log access first to confirm). This is where the maintenance win compounds: every migrated route shrinks the API surface you version, document, and secure.

### Step 5: Final cutover checklist

When the last route group flips to Rails:

- [ ] All `location` blocks point at Rails; the Next.js upstream receives no traffic (verify with proxy access logs).
- [ ] Remove the Next.js app from CI/CD and infrastructure; archive the repo or directory.
- [ ] Delete frontend-only API endpoints, CORS configuration, and token-exchange/refresh plumbing that existed for the cross-app split.
- [ ] Move redirects that lived in `next.config.js` / `middleware.ts` into the proxy config or Rails routes.
- [ ] Re-point sitemap/robots generation, health checks, and uptime monitoring at the Rails app.
- [ ] Collapse the two deploy pipelines into one.

## Porting component code

Most of your React code is framework-agnostic and moves unchanged. The Next.js-specific imports are the work:

- **`'use client'`** — keep it. With Pro RSC auto-bundling, the directive determines registration (client component vs. server component) exactly as it determines the boundary in Next.js. Without RSC, every component is a client component and the directive is inert but harmless.
- **`next/link`, `useRouter`, `usePathname`** — replace with plain `<a>` tags (Rails-routed pages) or your client router's equivalents ([React Router](../building-features/react-router.md), [TanStack Router](../building-features/tanstack-router.md)).
- **`next/head` / Metadata API** — replace with React 19 native `<title>`/`<meta>`/`<link>` tags rendered directly in components ([guide](../building-features/react-19-native-metadata.md)).
- **`next/image`** — replace with `<img>` plus webpack-pipeline assets ([images](../building-features/images.md)); a first-party optimization helper is tracked in [#3874](https://github.com/shakacode/react_on_rails/issues/3874).
- **`next/font`** — replace with the [`react_on_rails_font_face` helper](../building-features/fonts.md) for the `next/font/local` use case (self-hosted `.woff2`, preload, metric-matched fallback).
- **`fetch` in server components** — delete the HTTP hop: pass props from the controller, or query ActiveRecord in async-props blocks ([RSC data fetching](./rsc-data-fetching.md)).
- **`process.env.NEXT_PUBLIC_*`** — pass values as props from Rails, or configure them in your webpack build (e.g., `EnvironmentPlugin`/`DefinePlugin`).
- **CSS Modules / global CSS** — supported via Shakapacker's webpack setup; for server components see [CSS and styling with RSC](../../pro/react-server-components/css-and-styling.md).

If you are adopting server components as part of the move, the [RSC migration series](./migrating-to-rsc.md) covers component restructuring, context/state, and data-fetching patterns in depth — it applies directly to components arriving from Next.js.

## Related reading

- [Next.js with a Separate Rails Backend: Pros and Drawbacks](../getting-started/nextjs-with-separate-rails-backend.md) — the architecture decision this guide assumes you've made
- [Comparing React on Rails to Alternatives](../getting-started/comparing-react-on-rails-to-alternatives.md)
- [React on Rails Pro](../../pro/react-on-rails-pro.md) — RSC, streaming SSR, caching, Node renderer
- [RSC Migration Series](./migrating-to-rsc.md)
- [Example Migrations](./example-migrations.md)
