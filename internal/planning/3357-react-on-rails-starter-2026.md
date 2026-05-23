<!-- /autoplan restore point: /Users/justin/.gstack/projects/shakacode-react_on_rails/jg-conductor-3357-autoplan-restore-20260521-155332.md -->

# Plan: React on Rails Starter 2026 (Issue #3357)

**Status:** Draft — design approved 2026-05-21; revised 2026-05-22 after `/autoplan` multi-voice review (CEO + Design + Eng + DX, each dual-voice via Claude subagent + Codex).
**Tracking issue:** https://github.com/shakacode/react_on_rails/issues/3357
**Public repo (to be created):** `shakacode/react-on-rails-starter-tanstack`

## Autoplan Review Outcome (2026-05-22)

Two strategic reframes adopted after dual-voice review surfaced cross-phase convergent dissent on the original framing:

1. **Demo portfolio framing.** The 2026 starter is the _greenfield seed_ at the head of an existing demo portfolio (`react-on-rails-demo-marketplace-rsc`, `react-on-rails-demo-hacker-news-rsc`, `react-on-rails-demo-gumroad-rsc`, `react_on_rails-demo-octochangelog-on-rails-pro`). The demos carry the proof points (RSC streaming, performance under traffic, Inertia head-to-head, migration story). The starter doesn't re-prove what the demos prove.

2. **"Best TanStack on Rails" positioning.** Reframed from "Inertia counter-kit" to a category claim. Two structural reasons it's defensible: (a) Inertia _is_ a routing model — adding TanStack Router on top fights what Inertia owns; (b) RSC plus streaming is hard to ship correctly — Inertia is unlikely to bring up its own RSC-streaming plumbing, and if it ever does, it would most naturally do so on top of React on Rails Pro (a separate, intriguing discussion: "Inertia on Pro" as a bridge product, captured in #3144's neighborhood). So the moat is the combination — incremental React, full-page React, RSC streaming via Pro, AND a deep TanStack integration — not any one piece.

The review also surfaced 7+ engineering and DX gaps that survived the reframes — see [Required Before Implementation](#required-before-implementation) below.

Findings traceability: see `~/.gstack/projects/shakacode-react_on_rails/` for the full dual-voice transcripts. Restore point for pre-review plan: see the HTML comment above this file's title.

## Problem Statement

The Evil Martians [Inertia Rails React Starter Kit](https://evilmartians.com/opensource/inertia-rails-react-starter-kit), the [official Inertia Rails starter kits](https://inertia-rails.dev/guide/starter-kits) (React / Vue / Svelte), and similar polished kits such as [GrowthX Starter](https://github.com/growthxai/starter) (Rails 8 + React 19 + shadcn/ui) are the most visible front door into "Rails + React in 2026" for new teams.

`create-react-on-rails-app` exists and is solid, but does not currently lead with the same modern stack defaults (shadcn/ui, TanStack ecosystem, RSC, Rails 8 auth) — so a developer in a 30-minute side-by-side evaluation sees Inertia as the more "batteries-included" choice for greenfield work, even though React on Rails has a deeper feature set under the hood.

This plan ships **the best TanStack-on-Rails starter kit** — a public greenfield seed at the head of the React on Rails demo portfolio. The category claim is structural, not derivative: Inertia _is_ a routing model and therefore cannot host TanStack Router as a peer; React on Rails Pro can and does. The starter operationalizes that claim end-to-end (Router + Query + Table as a coherent surface) while the existing demo repos (Hacker News, Marketplace, Gumroad, Octochangelog) carry the orthogonal proof points (perf, RSC streaming, Inertia head-to-head, migration story).

Beyond the front-door positioning, the kit serves three additional purposes the dual-voice review surfaced as material:

1. **Canonical reference for AI agents extending Rails + React + RSC + TanStack apps.** AI coding tools (Claude Code, Cursor, etc.) clone the kit's patterns when extending downstream user apps. The kit's job is to teach the right defaults, not just demo features.
2. **Demonstration of superior TanStack integration** — the kit is the canonical answer to "how do I use TanStack Router/Query/Table with Rails + RSC?" No other Rails+React kit owns this.
3. **QA vehicle for React on Rails releases** — the starter runs CI against every RoR Pro release candidate. Regressions are caught at the dogfood level before public release, and adopters who ship from this template inherit the same safety net. This is ongoing operational value, not one-time marketing.

## Audience

Two audiences with different leverage points:

**Primary: Developers using AI agents to bootstrap and iterate on a Rails + React SaaS** ("vibe coders"). The agent is the proximate reader; it learns this kit's patterns and extrapolates them across the user's future work. Implication: ship **complete patterns the agent can clone** (auth, mailer, background job, form, CRUD, nested route, system spec) — and let the _code structure itself_ be the load-bearing teaching artifact. `AGENTS.md` documents the patterns but isn't the load-bearing primitive; the canonical reference files are.

**Secondary but consequential: The senior Rails/React maintainer doing a 30-minute side-by-side eval against Inertia/GrowthX.** Dual-voice review flagged this audience as more decision-making than the original framing acknowledged. Implication: surface polish, TTHW, error message quality, deployment readiness, and the "why TanStack" narrative all matter — the human evaluator never gets to the AI-agent value if they bounce in the first 5 minutes.

Both audiences are served by the same core decision: an opinionated TanStack-first surface with concrete, copy-pasteable reference patterns.

## Goals

1. **Establish "best TanStack on Rails" as a category claim** with end-to-end operationalization: TanStack Router as the routing primitive for the authenticated surface, TanStack Query for client-side data fetching, TanStack Table for the Projects list. Structural moat: Inertia owns its routing model (TanStack can't be a peer), RSC + streaming is hard to bring up correctly (Inertia is unlikely to ship its own — and if it does, naturally lands on top of Pro). The combination — incremental React, full-page React, RSC streaming via Pro, AND deep TanStack integration — is the moat, not any single piece.
2. **Be the polished greenfield seed of the React on Rails demo portfolio.** Link out to `react-on-rails-demo-hacker-news-rsc` for public-traffic perf, `react-on-rails-demo-marketplace-rsc` for e-commerce, `react-on-rails-demo-gumroad-rsc` for direct Inertia head-to-head, `react_on_rails-demo-octochangelog-on-rails-pro` for migration from a real Rails app. The starter doesn't re-prove what the demos prove.
3. **Win the human evaluator's 30-minute eval** — TTHW ≤ 3 min on a primed macOS laptop, clean error UX on the predictable first-5-minutes failures (forgot to seed, port conflict, Postgres not up, Node renderer not running), README that opens with the "why TanStack on Rails" narrative.
4. **Give AI agents extending the kit cloneable patterns** via the code structure itself (canonical reference files with marker comments + colocated specs and factories), with `AGENTS.md` as the _index_, not the strategy pillar.
5. **Serve as the canonical QA / dogfood vehicle for React on Rails Pro release candidates.** CI runs the full kit (RSpec + Playwright + Lighthouse) against every RoR Pro RC. Regressions detected here gate public RoR Pro releases. Adopters inherit this safety net implicitly.

## Non-Goals

- **Not** a `--flagship` variant flag on `create-react-on-rails-app` for Tier 1. (Revisit at Tier 2 — see Required-Before-Implementation #4.)
- **Not** a sibling generator package.
- **Not** a benchmark/positioning artifact (those live in #3144, #3128, and `react-on-rails-demo-gumroad-rsc`).
- **Not** an Inertia-bridge product (captured separately in #3144).
- **Not** auto-generated — users clone the repo (via GitHub's "Use this template") and rename, the same delivery model every Inertia kit uses.
- **Not** a place to re-prove what the demo portfolio already proves (RSC streaming, public-traffic perf, direct Inertia head-to-head, migration story). Those stay in the demo repos; the starter links out.
- **Not** an "Inertia on top of Pro" bridge product. That idea is _intriguing_ (Inertia's hard problem is RSC streaming, which Pro solves; Inertia-on-Pro could be the natural shape if Inertia ever wants RSC) but it is a separate strategic conversation, not in scope here. Tracked separately.

## Delivery Decision

**Standalone public GitHub repo, `shakacode/react-on-rails-starter-tanstack`, public from commit 1, configured as a GitHub Template Repository** (so adopters get a fresh tree via "Use this template," not a stale clone).

Considered alternatives:

- A new flag on `create-react-on-rails-app`: deferred to Tier 2 review, not rejected. Original argument ("no Inertia kit ships as a CLI") is competitor-mimicry rather than user reasoning. The real argument is CLI-matrix bloat + Pro-heavy maintenance burden, which is legitimate but not load-bearing. After Tier 1 ships, if the maintained template proves stable, fold its defaults back into `create-react-on-rails-app --template tanstack` (the flag clones the maintained template repo, doesn't re-generate every permutation).
- A sibling generator package (`create-react-on-rails-flagship`): rejected — duplicates the maintenance burden of both the CLI and the template repo.
- Private-first, public when polished: rejected; the credibility cost of a messy public commit log is small enough to accept in exchange for "build in public" signal.
- Fork the Evil Martians Inertia kit and swap Inertia for RoR Pro: rejected — TanStack-on-Rails is a _different_ product, not a recoloring of their kit.

The kit is bootstrapped via `create-react-on-rails-app --rsc --rspack` and then heavily customized; downstream improvements to that CLI flow benefit both projects.

**Naming decision (2026-05-22):** the repo is `react-on-rails-starter-tanstack`. The `-tanstack` suffix locks the kit's identity to its strongest positioning rather than a calendar year — sharper claim, no maintenance trap. If TanStack momentum stalls in the future the name becomes a softer "the modern Rails+React starter" identity, which is a survivable downside. Either way the name doesn't expire on a fixed date.

## Scope: Tier 1 ("B-prime")

Tier 1 is what ships in the first public release. Tier 2 is deferred (listed below).

### Surfaces

- **Public landing** — **RSC-rendered + streamed** (this is where RSC earns its keep: cold-load TTFB matters, mobile perf matters, SEO matters, the visitor hasn't downloaded the app shell yet). Pro RSC + shadcn/ui hero, "Best TanStack on Rails" hero narrative (positioning, not feature blurbs), 4 demo-portfolio link cards (Hacker News, Marketplace, Gumroad, Octochangelog) each scoped to its proof point, dark-mode toggle, CTAs for "Use this template" and "see the dashboard demo." Signed-in users see a "go to dashboard" CTA on the landing.
- **Auth surface** — built on top of `bin/rails generate authentication` plus custom additions:
  - **From the Rails 8 generator (no changes):** login at `POST /session` (singular `resource :session`), logout at `DELETE /session`, password reset at `/passwords/new` and `/passwords/:token/edit`, `PasswordsMailer`, `User` / `Session` / `Current` models, `Authentication` concern auto-included in `ApplicationController`.
  - **Custom on top (vibe-coder pattern catalog):** signup (`RegistrationsController` + view at `/signup` — the generator does NOT provide this), email verification (token column on `User`, `EmailVerificationsController`, `EmailVerificationMailer`, `email_verified_at` gate that blocks the dashboard until verified), profile edit at `/settings/profile`, password change at `/settings/security`.
  - **Email verification UX as a designed funnel, not a backend gate.** Post-signup confirmation screen with visible target email, resend button with cooldown, "change email" affordance, expired-token recovery flow, spam-folder hint, dev-mode `letter_opener` link surfaced. (Both Design voices flagged this as the highest-friction touchpoint in the funnel; full spec lives in Required-Before-Implementation #1.)
  - `letter_opener` for dev mail.
  - Views are re-skinned with shadcn/ui blocks; the generator's raw scaffold views are replaced.
- **Authenticated TanStack-routed surface** (the structural moat — operationalized end-to-end). **Rendered via classic SSR through the Pro Node renderer**, not RSC. Rationale: RSC's headline wins (TTFB on cold load, reduced client JS, streaming SEO content) don't apply behind auth — the visitor has already loaded the app, JS is cached, search engines don't index gated pages. TanStack's wins (type-safe routing, prefetch-on-hover, URL-state interop, Query's fan-out, Table's interactivity) all show up most on the authenticated surface. RSC stays on the public landing where it pays off.
  - `/dashboard` — single canonical dashboard. **TanStack Table** drives the Projects list (column sort, status filter, pagination, persisted view). **TanStack Query** fans out the 4 metric cards as independent fetches with per-card loading/error states, no head-of-line blocking. **TanStack Router** owns navigation to `/projects/:id` with route-level loader prefetch. A small "rendering mode" drawer in the dashboard header tells the honest surface-split story: _"This authenticated surface is TanStack-driven, classic SSR via the Pro Node renderer — chosen for type safety + interactivity. The public landing uses RSC for cold-load and SEO. The full RSC streaming story lives in the [Hacker News demo →] and [Marketplace demo →]; the Inertia head-to-head lives in the [Gumroad demo →]."_
  - `/settings` overview, `/settings/profile`, `/settings/security` — TanStack Router nested routes with SSR loaders, same primitive as the dashboard.
  - `/projects/:id`, `/projects/:id/edit`, `/projects/new` — TanStack-routed, with route-level loaders.
  - Auth + email-verification gates run server-side on the Rails shell route before any TanStack code mounts.
- **Projects CRUD** — `new`, `show`, `edit`, `destroy`. Reference form pattern: Rails server-side validation as the source of truth, inline error display per field, optimistic-pending state on submit, marked with a canonical-reference comment header (see Required-Before-Implementation #6). TanStack Form is **not** in Tier 1 scope — deferred to Tier 2 as a second TanStack-ecosystem milestone.
- **State coverage commitment** (Design review surfaced as catastrophic gap): every surface above ships with explicit empty, loading, error, and success states. The pattern catalog (below) ships paired empty/loading/error/success components per category, not just the happy path.
- **shadcn/ui pattern catalog** — hero block, list view, metric cards, form, dialog, toast, plus the four-state set (empty / loading / error / success) for each composable surface, plus dark-mode toggle. Each pattern marked with a canonical-reference comment so AI agents grep-find the right one.
- **Background job demo** — SolidQueue + `ProjectArchiveJob` (archives projects whose `last_activity_at` is older than N days). Retry policy + DLQ behavior + Sentry capture all spec'd; tests cover retry exhaustion.
- **Mailer demo** — `WelcomeMailer` (sent on signup, custom), the Rails 8 generator's `PasswordsMailer` (reset), and a custom `EmailVerificationMailer` (the generator does not provide one).
- **Sentry** — wired in `Gemfile`, initializer commented out, single env var (`SENTRY_DSN`) to enable. README documents how to flip it on.
- **Accessibility floor** (Design review surfaced as 0/10): WCAG AA contrast on all surfaces, keyboard nav verified in Playwright, `aria-live` on flash + form errors, focus management on dialog open/close + route changes, reduced-motion handling on transitions, touch targets ≥ 44px. Not a section in `AGENTS.md` — a property of every shipped surface.

### Stack

- Ruby 3.4+, Rails 8.0+, PostgreSQL
- Shakapacker + Rspack
- React 19 + TypeScript 5
- React on Rails Pro (RSC mode)
- **TanStack Router with SSR** — routing primitive for the entire authenticated surface (Pro-supported)
- **TanStack Query** — client-side data fetching against Rails JSON endpoints, with per-component loading/error states
- **TanStack Table** — Projects list (sort, filter, paginate, persisted view state)
- TanStack Form — **deferred to Tier 2** (less mature than Router/Query/Table, less differentiated, adds learning curve at the wrong time)
- shadcn/ui + Tailwind v4
- SolidQueue (background jobs)
- Rack::Attack (rate limiting — needed for the email verification spec; see Required-Before-Implementation #1)
- `letter_opener` (dev mail)
- Sentry-ruby + sentry-rails (commented-out initializer)
- RSpec + factory_bot + Capybara (backend & system)
- Playwright (cross-stack smoke, with `aria-` + keyboard nav assertions)
- Vitest (frontend unit, light)

## Data Model

```
User (Rails 8 generator emits email_address + password_digest; remaining columns are this kit's additions)
  - email_address (string, NOT NULL, uniquely indexed)   # from generator
  - password_digest (string, NOT NULL)                   # from generator
  - name (string)                                        # custom (for signup + profile)
  - email_verification_token (string, nullable, indexed) # custom
  - email_verified_at (datetime, nullable)               # custom
  - timestamps

Session (from Rails 8 generator; database-backed sessions)
  - user_id (FK)
  - ip_address (string)
  - user_agent (string)
  - timestamps

Project
  - name (string)
  - description (text)
  - status (integer enum: active / paused / completed / archived)
  - user_id (FK)
  - last_activity_at (datetime)
  - timestamps
```

`Current` is a Rails `ActiveSupport::CurrentAttributes` class also emitted by the generator (not a database table). Holds the request-scoped `Current.user` and `Current.session`.

The auth generator's password-reset token lives on the `Session` row indirectly via the `PasswordsController` flow — no separate `password_reset_token` column is required.

### Seed Data

`db/seeds.rb` creates:

- One demo user: `demo@example.com` / `password`, pre-verified.
- 12 sample projects distributed across all four statuses, varied `last_activity_at` values.

## Data Flow

- Rails routes (`config/routes.rb`) handle the **public landing** (RSC-rendered), the auth surface (classic Rails views), and the **single** authenticated shell route. Everything under that shell is TanStack-Router-driven.
- **Public landing (`/`)** renders via `react_on_rails_component` with `rsc: true` — RSC + streaming. This is the surface where RSC's headline wins (TTFB, mobile perf, SEO content streaming) actually apply. Cold visitors land on a fast, search-indexable, low-JS first paint.
- The Rails auth + verification gates run server-side on the shell controller, _before_ any TanStack code mounts. Specifically: `Authentication` concern (`before_action :require_authentication`) + `before_action :require_verified_email` on the shell controller. Unverified users never reach the TanStack mount point.
- TanStack Router owns `/dashboard`, `/dashboard/projects/:id`, `/projects/new`, `/settings`, `/settings/profile`, `/settings/security`. SSR loaders run server-side via the Pro Node renderer so first paint is correct; client takes over for subsequent navigations with prefetch.
- **Authenticated `/dashboard` renders via `react_component` (classic SSR through the Pro Node renderer)**, not RSC. Rationale: behind auth, RSC's TTFB / SEO / cold-load wins don't apply; TanStack's interactivity / type-safety / URL-state wins do. The RSC streaming story is carried by the public landing here and by the demo portfolio (Hacker News, Marketplace) externally.
- Per-component data fetching uses **TanStack Query** against thin Rails JSON endpoints (`/api/projects`, `/api/projects/:id/metrics`). Each metric card on `/dashboard` is an independent query — one slow query never blocks the rest of the dashboard.
- The Projects list uses **TanStack Table** with server-side sort/filter/page params reflected in URL state via TanStack Router search params. AI agents extending the kit get a single canonical pattern for "list with server-driven sort/filter/paginate."
- CSRF: TanStack Query and TanStack Router both honor the Rails CSRF token via a shared `getCsrfToken()` reader (meta tag on the Rails shell). Documented in `AGENTS.md` as the one cross-cutting subtlety.

## Error Handling

- Custom 404 and 500 pages styled with shadcn (overrides `public/404.html`, `public/500.html`).
- Server-side validation on `Project` and `User` models. The Project form is the reference pattern: validation errors render inline next to fields with `aria-live`, success redirects with a flash toast.
- SolidQueue retry policy on `ProjectArchiveJob` (max 5, exponential backoff). Failed jobs land in DLQ + are captured by Sentry when enabled. Spec'd test: forced failure → 5 retries → DLQ entry.
- **TanStack Router SSR loader failure** — loader exceptions caught by a route-level error boundary that renders a "this section is unavailable" panel with a retry CTA. Tests cover loader-throws-on-SSR and client-side-retry-recovers.
- **RSC stream interruption** — `<Suspense>` boundaries scoped per metric card + per Projects-list segment, with error boundaries that allow the rest of the dashboard to render. Spec'd Playwright test: mid-stream connection cut → other cards still appear.
- **Node renderer crash** — Rails falls back to the empty-shell + client-side TanStack mount (degraded but functional) and emits a `react_on_rails.node_renderer_down` Sentry event. README documents the operational signal.
- **Email provider down on signup** — user sees "we couldn't send your verification email; try resend" instead of being silently locked out. The resend route accepts a recently-signed-up email without an authenticated session for a 24-hour window.
- **First-5-minutes error budget** — the predictable evaluator failures (port 3000 conflict, Postgres not running, `bin/rails db:seed` not run, SolidQueue not started, Node renderer not running, missing `RAILS_MASTER_KEY`) each get a problem + cause + fix message. `bin/doctor` checks preflight; dev-only middleware surfaces the "no demo user — run `bin/rails db:seed`" hint inline when `Rails.env.development? && User.count == 0`.
- Email delivery failure in dev: `letter_opener` shows the message in a browser tab. Production: README documents Mailgun / Postmark / Resend swap-in with both the one-line ActionMailer config AND the relevant ENV vars.

## Testing

Test types AND specific acceptance targets — "at least one spec per category" is not enough for a kit whose value prop is "agents clone these patterns."

- **RSpec** for backend
  - Model specs for `User`, `Project`.
  - Request specs for sessions, registrations, projects, email verifications (token expiry, single-use, replay rejection, resend throttle).
  - System specs (Capybara + headless Chrome) for the full signup → verification → dashboard → create-project flow.
  - Authorization-bypass tests: anonymous user can't reach `/dashboard`; unverified user can't reach `/dashboard`; user A can't access user B's `/projects/:id`.
- **Playwright** for cross-stack acceptance
  - Auth flow (signup, login, logout, password reset, email verification with mock-mail interception).
  - **RSC streaming assertion** — network-trace assertion that response chunks arrive progressively (not the bare "page rendered" assertion, which passes even if streaming silently fell back to full SSR).
  - Project CRUD round trip including optimistic state, validation error display, delete confirmation flow.
  - TanStack Router navigation: `/dashboard` → `/projects/:id` → back, with prefetch verification and URL-state-reflects-table-state assertions.
  - **TanStack SSR hydration**: console-errors-fail-the-test, plus explicit "no hydration mismatch" assertion on `/dashboard` and `/settings/profile`.
  - **Dark mode no-flicker**: cold load with `prefers-color-scheme: dark` shows no light-mode frame before paint.
  - **Accessibility**: keyboard-only navigation through signup → verification → create-project, `aria-live` on flash messages and form errors, focus-trap on dialog open/close.
- **Vitest** for non-trivial frontend unit logic (TanStack Table column definitions, TanStack Query key factory, etc.).
- **Factories** via `factory_bot` for `User`, `Project`. Verification-token factory traits: `:unverified`, `:expired_token`, `:verified`.
- **CI** via GitHub Actions: RSpec + Playwright on push and PR. **Lighthouse run** on `/dashboard` (logged-in seeded user) with budgets defined in Required-Before-Implementation #2.
- **Local helpers**: `bin/test` runs everything, `bin/test --smoke` runs Playwright only, `bin/test --a11y` runs only the accessibility-tagged Playwright specs.

## `AGENTS.md` (Index, Not Strategy)

The kit's root `AGENTS.md` is the index that points AI agents at the canonical reference files. It is _not_ the load-bearing teaching artifact — the code structure (with marker comments + colocated specs and factories) is. Dual-voice review explicitly challenged the original "AGENTS.md as load-bearing" framing: AI agents extract patterns from code, not docs; the docs index those patterns, the code teaches them.

Density target: match the monorepo's existing `AGENTS.md` (concrete commands, exact file paths, key concept deep-dives where they matter). Every "How to add X" section ends with a literal command the agent can execute (`bunx shadcn add card`, `bin/rails g migration AddXToProjects`) plus the exact paths it will touch.

Contents (sections, each with a working code reference + canonical-marker comment in the kit):

1. **File layout tree** — concrete directory diagram with what lives where. Defined now in this plan (see Required-Before-Implementation #6), not back-filled at Phase 8.
2. **How to add a new TanStack route with a Rails data loader** — the kit's signature pattern. Pointer to `/settings/profile` as canonical.
3. **How to add a new shadcn/ui block** — `bunx shadcn add ...` workflow, where the block lives, RSC-vs-client decision tree (see below).
4. **How to add a new form** — pointer to the Project form (validation + error display + flash + a11y).
5. **How to add a new background job** — pointer to `ProjectArchiveJob` (SolidQueue, retry, DLQ, Sentry).
6. **How to add a new email** — pointer to `WelcomeMailer` (mailer, view, preview, spec, throttle pattern).
7. **How to add a new TanStack Table column** — pointer to the Projects list.
8. **How to add a new TanStack Query** — pointer to a metric card on the dashboard.
9. **Naming conventions** — file naming, route naming, component naming, model naming.
10. **Testing conventions** — decision table (RSpec vs Playwright vs Vitest), not prose.
11. **Key Concept: when to RSC vs SSR vs client component in this kit** — mirrors the monorepo's `.client.`/`'use client'` block. THE most valuable single decision tree the kit can ship. Includes the shadcn-on-Tailwind-v4-inside-RSC boundary placement guidance.
12. **Key Concept: CSRF + TanStack Query** — the one cross-cutting subtlety the data flow introduces.
13. **Pointer to canonical references** — absolute paths to every canonical example, indexed by category.

## Default Decisions

1. **TanStack Router mount strategy** — Rails serves a single authenticated shell route; TanStack Router owns everything under it. SSR loaders run via the Pro Node renderer. If `react_on_rails_pro` has a canonical alternative pattern, match it.
2. **Dark mode** — default light, toggle persisted in `localStorage`, inline `<script>` in `<head>` to prevent flicker, **also check `prefers-color-scheme` on first visit if no `localStorage` value is set**. Palette = shadcn defaults for Tier 1 (full brand system deferred to Tier 2).
3. **Demo user in seeds** — yes, `demo@example.com` / `password`, pre-verified. `db/seeds.rb` is guarded by `Rails.env.development? || Rails.env.test?` to prevent the seed running in production (dual-voice Eng review flagged this as a takeover vector). Production seed (if any) lives in `db/seeds/production.rb` and is opt-in.
4. **Repo creation timing** — create the GitHub repo as the first step of execution, configured as a Template Repository, with a placeholder README that says "scaffolding in progress; see [tracking issue]." Avoids a public-empty-repo window.
5. **Email verification design** — see Required-Before-Implementation #1 for the full spec. Default: `urlsafe_base64(32)` token, stored as `digest`, 24-hour TTL, single-use, throttled at 5/hour/IP + 3/hour/email via Rack::Attack, session rotated on verification.

## Tier 2 (Deferred — explicitly NOT in the first public release)

Listed for tracking only. Each may become its own plan doc later.

- **TanStack Form** — second TanStack-ecosystem milestone; replace the Rails-validation reference form with a TanStack-Form-driven equivalent once the library matures and the Tier 1 kit's stability is proven.
- **Full brand system** — typography scale, palette beyond shadcn defaults, illustration/iconography direction, content voice. Tier 1 ships on shadcn defaults; Tier 2 commits a visual identity.
- Kamal deploy config (delays choice of ops platform).
- Production Sentry recipe with provider examples.
- Additional UI patterns: file upload, multi-step wizard, infinite scroll, charts / data viz.
- API auth (JWT or OAuth) demo for headless consumers.
- More TanStack Router patterns: route-level data loaders, params validation, code splitting.
- i18n setup.
- Multi-tenant example.
- Vue and Svelte variants (only if usage of the React variant proves the model).
- **`create-react-on-rails-app --template tanstack` flag** — reopen the CLI question after Tier 1 ships and the maintained template proves stable; folding the starter's defaults back into the CLI flow is the natural distribution play once the maintenance burden is known.

## Freshening Cadence

Quarterly review with a **named DRI** (not "owned by the team" — dual-voice review flagged that as ownership-by-nobody). DRI named at kick-off, rotates yearly.

- Bump Rails, React, TanStack (Router/Query/Table), shadcn/ui, Tailwind, React on Rails Pro to current versions.
- Re-run the full Playwright smoke suite + Lighthouse budget check against the bumped stack.
- Update the README's "last refreshed YYYY-MM-DD" line.
- Tag a release matching the calendar quarter (`2026.Q3`, `2026.Q4`, …).
- Ship `UPGRADING.md` updates per release (what changed, migration steps for adopters).

Calendar reminder + release checklist owned by the DRI. If the DRI changes roles, the role transfers before any quarterly slot is missed. **Two missed quarters = the kit auto-archives** with a banner pointing to the next maintained alternative — better to retire honestly than rot publicly.

## Implementation Phasing (high-level — see [Detailed Implementation Plan](./3357-react-on-rails-starter-2026-implementation.md))

The detailed implementation plan is the deliverable of the next phase. High-level phases:

0. **Spike PR (required precondition, not optional).** One-day spike validating TanStack Router + TanStack Query + Pro RSC + shadcn/ui on Tailwind v4 all working together on a single throwaway route. If the spike fails on any of the three open compatibility risks, fall back per the decision tree in Required-Before-Implementation #3 BEFORE any of phases 1-10. No phase 1 work until spike is green.
1. **Repo bootstrap.** Create the GitHub Template Repository, push initial Rails 8 + RoR Pro scaffold via `create-react-on-rails-app --rsc --rspack`. Land first CI green build. `bin/doctor` and the "first-5-minutes error budget" copy ship in this phase.
2. **Auth surface + verification funnel.** Run `bin/rails generate authentication`, add `name` column + signup + email verification (full spec from Required-Before-Implementation #1), re-skin views with shadcn/ui, add `letter_opener`, ship `WelcomeMailer`. Post-signup verification UX is part of THIS phase, not back-filled later.
3. **Projects model + CRUD.** Migration, model, controller, JSON API endpoints, server-side validation reference form (marked with canonical-reference comment), factory, request + system specs.
4. **TanStack-driven authenticated surface.** Single `/dashboard` with TanStack Router + Query (metric cards) + Table (Projects list). `/settings/*` nested routes. `/projects/:id` and `/projects/new`. Rendering mode drawer + outbound links to demo portfolio.
5. **shadcn/ui pattern catalog with state coverage.** Hero, list view, metric cards, form, dialog, toast, plus paired empty/loading/error/success states per pattern, dark-mode toggle with `prefers-color-scheme` fallback.
6. **Background job + Sentry wiring.** `ProjectArchiveJob`, SolidQueue config + `Procfile.dev`, Sentry initializer (commented). Retry exhaustion + DLQ test.
7. **`AGENTS.md` + canonical-reference comments.** Authored against the actual reference implementations in the kit. Density target: monorepo's existing `AGENTS.md`.
8. **Playwright + RSpec acceptance suite.** All the test targets above, plus Lighthouse budget check, plus accessibility-tagged specs.
9. **Deployment story.** `Procfile`, `.env.example`, `bin/setup`, `bin/doctor`, `UPGRADING.md`, deploy docs (Mailgun/Postmark/Resend swap-in + RSC bundle precompile gotcha + production seed safety).
10. **README + launch.** README opens with the "Best TanStack on Rails" pitch, demo-portfolio link cards, screenshots, demo-user instructions. Flip-visible event matches docs-site update.

Each phase is one PR. Each PR ships green CI before merge. Phase 0 (spike) is non-optional and runs BEFORE the public template repo flips from placeholder to populated.

## Open Questions

All originally-listed open questions are now resolved or absorbed into the Phase 0 spike. Nothing here gates implementation.

1. ~~TanStack Router + Pro RSC interaction~~ — **CLOSED.** Validated as mandatory in the Phase 0 spike. Confirmed by Justin as non-negotiable for the kit's identity.
2. ~~shadcn/ui Tailwind v4 maturity~~ — **CLOSED.** Phase 0 spike validates; fallback to Tailwind v3 ships if v4 isn't ready.
3. ~~`AGENTS.md` vs `CLAUDE.md`~~ — **CLOSED.** Both ship. `AGENTS.md` is canonical; `CLAUDE.md` is a thin pointer.
4. ~~Tailwind v4 + Pro RSC streaming compatibility~~ — **CLOSED.** Phase 0 spike validates.
5. ~~Signup vs `User` migration~~ — **CLOSED.** Edit the generator's emitted migration before first run; documented in `AGENTS.md`.
6. ~~TanStack Form in Tier 2 timing~~ — **CLOSED.** Defer until Tier 1 ships and adopters ask for it.
7. ~~`-2026` naming~~ — **CLOSED.** Repo named `react-on-rails-starter-tanstack` (locks identity to positioning, sidesteps the calendar-suffix maintenance trap).

Active follow-up (separate discussion, NOT in this plan's scope): **"Inertia on Pro" as a bridge product.** Inertia's hard problem is RSC streaming; Pro solves it. The natural shape if Inertia ever wants RSC is on top of Pro. Worth a separate strategy conversation — likely lives in #3144's neighborhood.

## Required Before Implementation

These are pre-Phase-0 deliverables — gaps the autoplan dual-voice review surfaced that cannot ride along with implementation. Block phase 0 (spike) on items 3 and 5; block phase 1 (public scaffold push) on the rest.

### 1. Email verification token specification (Eng critical — both voices 1-3/10)

Full spec, not a column name:

- Token: `SecureRandom.urlsafe_base64(32)`, generated at signup or resend request.
- Storage: digest only (`Digest::SHA256.hexdigest(token)`). Compare via `ActiveSupport::SecurityUtils.secure_compare`.
- TTL: 24 hours via `verification_sent_at` column.
- Single-use: nulled on consume.
- Throttling: Rack::Attack — 5 verification-email-sends per IP per hour, 3 per email per hour.
- Replay: previously-consumed tokens return generic "this link has expired, request a new one."
- Enumeration defense: `EmailVerificationsController#create` returns identical UX whether email exists or not.
- Session rotation: on successful verification, the session is rotated (`reset_session` + re-issue the auth cookie).
- Audit: log verification events to `Rails.logger.tagged("auth")` with user_id and IP.
- Resend route: accepts a recently-signed-up email without an authenticated session for a 24-hour window after signup.

### 2. Performance budgets (deferred — Tier 1 ships without strict budgets)

**Justin's call: defer to post-Tier-1.** Strict perf budgets aren't a ship blocker; the demo portfolio carries the perf story (Hacker News demo specifically), and ship velocity matters more here than measured Lighthouse numbers.

Tier 1 commits to "no obviously broken behavior" — dark-mode flicker test (Playwright assertion: zero pixels of wrong-mode before paint) is the one perf-adjacent check that stays in Tier 1 because it's a correctness bug, not a budget. Everything else (TTFB targets, Lighthouse gates, bundle-size budgets, Node renderer warmup script) moves to **Required After Tier 1 Ships**:

- Tier 2 ships measured budgets after we have real adopter data on what "good" looks like.
- If evaluator complaints surface a specific perf gap in the first 90 days post-ship, fast-follow that gap; otherwise hold until Tier 2.

### 3. Phase 0 spike PR + fallback decision tree (Eng critical — three unresolved integrations)

One-day spike, one throwaway branch, validates:

- TanStack Router SSR mounting under a Rails shell controller (auth-gated, CSRF-passing, hydration-clean).
- TanStack Query reading from a Rails JSON endpoint with CSRF.
- Pro RSC streaming a component that uses a shadcn-from-Tailwind-v4 primitive.
- All three together on the same throwaway route.

Fallback decision tree (committed BEFORE the spike, so the outcome doesn't require a new decision under pressure):

- **TanStack Router + Pro RSC integration breaks:** drop RSC default for `/dashboard`; ship classic SSR via Pro Node renderer. Demo portfolio still carries the RSC story. The kit's TanStack-on-Rails identity holds.
- **shadcn/ui on Tailwind v4 breaks inside RSC bundle:** ship Tier 1 on Tailwind v3 with shadcn's v3 path; defer v4 to Tier 2 freshening.
- **Tailwind v4 CSS-streaming incompatibility:** also forces v3 fallback.
- **All three fail:** stop. Re-spec before any phase 1 work. This is a strategy-level reset, not a tactical pivot.

### 4. Deployment readiness (Eng high — both voices 2-4/10)

Tier 1 ships with:

- `Procfile.dev` defining web / Rspack-watch / SolidQueue / Node-renderer processes.
- `Procfile` for production (`web`, `worker`, `node-renderer`).
- `.env.example` with every required ENV var (`RAILS_MASTER_KEY`, `DATABASE_URL`, `SOLID_QUEUE_IN_PUMA`, `SENTRY_DSN`, mail-provider vars).
- `bin/setup` runs the full prerequisite check + db prep + seed (dev only).
- `bin/doctor` smoke-checks Ruby/Postgres/Node/pnpm/bun versions + dependencies.
- Production safety: `db/seeds.rb` guarded by `Rails.env.development?`; `config.force_ssl = true` in production.yml; production secret hints in `.env.example`.
- RSC bundle precompilation documented in `config/initializers/assets.rb` (the Pro RSC pipeline emits a separate bundle that `assets:precompile` must include).
- `docs/` set: `01-architecture.md`, `02-vs-inertia.md`, `03-customizing.md`, `04-deploying.md`, `05-troubleshooting.md`, `UPGRADING.md`.

### 5. ~~`-2026` naming resolution~~ — RESOLVED 2026-05-22

Repo named **`react-on-rails-starter-tanstack`**. Locks identity to the strongest positioning rather than a calendar year. Sidesteps the maintenance trap of a year-suffixed name without giving up the freshness signal entirely (the kit's `latest 2026.Q3` tag carries the calendar information).

If TanStack momentum stalls in some future year, the name degrades gracefully to "the modern Rails+React starter" identity — still a survivable downside.

### 6. Directory tree + canonical-reference convention (DX high)

Lock now, not back-fill at Phase 7:

- 30-line directory tree diagram (Rails + JS sides) showing where TanStack routes, shadcn blocks, RSC components, client components, factories, specs, mailers, jobs each live.
- Canonical-reference comment header convention: `# REFERENCE PATTERN: <name> — see AGENTS.md §N`. Every canonical example file has one; non-canonical files do not. AI agents grep for `REFERENCE PATTERN:` to find the source-of-truth example per pattern.
- One canonical example per pattern category. If a category has 3 instances (signup / profile-edit / project-create forms), exactly one wears the `REFERENCE PATTERN:` marker.

### 7. TTHW measurement + dev environment friction (DX medium-high)

- TTHW target: ≤ 3 minutes on a primed macOS laptop from `git clone` to dashboard visible (measured, not asserted).
- README opens with a single copy-paste block achieving TTHW: `git clone … && cd … && bin/setup && bin/dev && open http://localhost:3000`.
- Letter_opener mounted at `/letter_opener` in development + surfaced via a "Dev Tools" nav item on the dashboard (development env only) alongside the SolidQueue dashboard.
- The "first-5-minutes error budget" copy (port conflict, Postgres down, no seed user, etc.) ships in Phase 1 (not back-filled).

### 8. Accessibility floor (Design 0/10)

Pre-implementation:

- Pick a specific WCAG target (AA recommended) and a specific contrast ratio.
- Add accessibility-tagged Playwright specs to the test plan: keyboard nav, `aria-live` on flash + errors, focus management on dialog + route changes, reduced-motion.
- Cite Radix primitives (under shadcn/ui) as the keyboard-nav baseline so the implementer knows what comes free.

### 9. Dashboard narrative decision (Design)

Both Design voices: "is this a SaaS app dashboard, a rendering-tech demo, or a pattern catalog?" Pick one. Recommend: **SaaS app dashboard first, rendering-tech and pattern catalog visible as drawers/links — not the lead.** A first-time user lands on something that feels like a real product, not a lab demo. The rendering-mode drawer is for the curious; the demo-portfolio links are for the seriously evaluating.

### 10. Upgrade path for adopters (DX low-medium, but the single weakest dimension in the DX review)

- `UPGRADING.md` ships in Tier 1, not "later."
- `bin/upgrade-check` script diffs the cloned repo against the latest tag and prints categorized changelist (config bumps vs structural changes vs adopter code).
- Convention about what the adopter "owns" (their app code in `app/`) vs what they should pull from upstream (`bin/`, `config/`, `package.json` defaults).

## Related

- #3357 — this issue
- #3144 — Gumroad RSC experiment: benchmark findings and positioning
- #3128 — Gumroad public comparison repo
- `internal/planning/examples-catalog-and-repo-naming-plan.md` — naming taxonomy this plan extends
- `docs/oss/getting-started/comparison-with-alternatives.md` — Inertia vs React on Rails comparison this plan operationalizes

**Demo portfolio (the starter links to these instead of duplicating their proof points):**

- `react-on-rails-demo-hacker-news-rsc` — public-traffic perf demo (Pro + React 19 + RSC)
- `react-on-rails-demo-marketplace-rsc` — e-commerce / marketplace surface
- `react-on-rails-demo-gumroad-rsc` — creator dashboard with direct Inertia head-to-head
- `react_on_rails-demo-octochangelog-on-rails-pro` — migration of an existing Rails app to Pro + RSC

## Autoplan Findings Summary (for reviewers)

Dual-voice review (Claude subagent + Codex) ran CEO, Design, Eng, and DX phases on the pre-rewrite plan. Headline:

| Phase  | Subagent verdict                                       | Codex verdict                      |
| ------ | ------------------------------------------------------ | ---------------------------------- |
| CEO    | "Would not fund as scoped"                             | "Fund with changes"                |
| Design | "Ships the checklist of a starter, not the aesthetic"  | 2/10 overall                       |
| Eng    | "Not implementation-ready"                             | "Blocked on 6 items"               |
| DX     | "Cheap concrete fixes turn a 6/10 starter into 8.5/10" | (not run — superseded by reframes) |

Convergent dissent on the original strategic foundation (vibe-coders-as-primary, AGENTS.md-as-load-bearing, standalone-repo-as-the-artifact, two-dashboard demo, RSC-as-moat) drove the two reframes adopted at the top of this file. Convergent engineering findings (security, performance, deployment, a11y, TTHW, naming, freshening ownership) survived the reframes and live in [Required Before Implementation](#required-before-implementation).

Full dual-voice transcripts: `~/.gstack/projects/shakacode-react_on_rails/` and the conversation log from 2026-05-21 → 2026-05-22.
