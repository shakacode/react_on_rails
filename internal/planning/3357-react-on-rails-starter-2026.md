# Plan: React on Rails Starter 2026 (Issue #3357)

**Status:** Draft — design approved 2026-05-21, awaiting implementation plan.
**Tracking issue:** https://github.com/shakacode/react_on_rails/issues/3357
**Public repo (to be created):** `shakacode/react-on-rails-starter-2026`

## Problem Statement

The Evil Martians [Inertia Rails React Starter Kit](https://evilmartians.com/opensource/inertia-rails-react-starter-kit), the [official Inertia Rails starter kits](https://inertia-rails.dev/guide/starter-kits) (React / Vue / Svelte), and similar polished kits such as [GrowthX Starter](https://github.com/growthxai/starter) (Rails 8 + React 19 + shadcn/ui) are the most visible front door into "Rails + React in 2026" for new teams.

`create-react-on-rails-app` exists and is solid, but does not currently lead with the same modern stack defaults (shadcn/ui, TanStack Router, RSC demo, Rails 8 auth) — so a developer in a 30-minute side-by-side evaluation sees Inertia as the more "batteries-included" choice for greenfield work, even though React on Rails has a deeper feature set under the hood.

This plan ships a flagship clone-target starter kit that closes the front-door perception gap and demonstrates the React on Rails Pro story end-to-end.

## Audience (Primary)

**Developers using AI agents to bootstrap and iterate on a Rails + React SaaS** — "vibe coders."

Manual evaluators (the 30-minute Inertia vs RoR comparison reader) and adopters (clone-and-build-a-real-SaaS users) are secondary audiences that this design also serves, but every contested decision in this document is resolved in favor of vibe-coding friendliness.

The practical implication: ship **complete patterns the agent can clone**, not the minimum surface needed to demonstrate a feature. Email verification, profile edit, a working background job, a working mailer, factories, system specs, and an `AGENTS.md` are all in scope because they give the downstream agent concrete reference implementations to extrapolate from.

## Goals

1. Ship a polished, public clone-target that wins the side-by-side evaluation against Inertia/GrowthX kits.
2. Demonstrate three structural advantages Inertia cannot match: TanStack Router with SSR, React Server Components, and incremental adoption via `react_component` (implicit — the kit _is_ a React on Rails app).
3. Pair with `react-on-rails-demo-gumroad-rsc` so the benchmark story and the starter story reinforce each other.
4. Give AI agents extending the kit a complete pattern catalog: at least one working reference for every common SaaS concern (auth, mailer, background job, form, CRUD, nested route, system spec).

## Non-Goals

- **Not** a `--flagship` variant flag on `create-react-on-rails-app`.
- **Not** a sibling generator package.
- **Not** a benchmark/positioning artifact (those live in #3144, #3128, and `react-on-rails-demo-gumroad-rsc`).
- **Not** an Inertia-bridge product (captured separately in #3144).
- **Not** auto-generated — users clone the repo and rename, the same delivery model every Inertia kit uses.

## Delivery Decision

**Standalone public GitHub repo, `shakacode/react-on-rails-starter-2026`, public from commit 1.**

Considered alternatives:

- A new flag on `create-react-on-rails-app`: rejected because it bloats the OSS CLI matrix with Pro-heavy choices and makes every flag combination a permanent maintenance burden.
- A sibling generator package (`create-react-on-rails-flagship`): rejected because no Inertia kit ships as a CLI — all three (official, Evil Martians, GrowthX) are clone-driven, so a CLI fails the apples-to-apples evaluation comparison.
- Private-first, public when polished: rejected; the credibility cost of a messy public commit log is small enough to accept in exchange for "build in public" signal.

The kit is bootstrapped via `create-react-on-rails-app --rsc --rspack` and then heavily customized; downstream improvements to that CLI flow benefit both projects.

Naming pattern is a new addition to the `internal/planning/examples-catalog-and-repo-naming-plan.md` taxonomy: `react-on-rails-starter-*` for opinionated greenfield clone-targets. The `-2026` suffix telegraphs "reflects current best practice" without committing the name to evergreen freshness.

## Scope: Tier 1 ("B-prime")

Tier 1 is what ships in the first public release. Tier 2 is deferred (listed below).

### Surfaces

- **Public landing** — shadcn/ui hero block, three feature blurbs (RSC, TanStack Router SSR, incremental adoption), dark-mode toggle, CTAs for signup and "view the dashboard demo."
- **Auth surface** — built on top of `bin/rails generate authentication` plus custom additions:
  - **From the Rails 8 generator (no changes):** login at `POST /session` (singular `resource :session`), logout at `DELETE /session`, password reset at `/passwords/new` and `/passwords/:token/edit`, `PasswordsMailer`, `User` / `Session` / `Current` models, `Authentication` concern auto-included in `ApplicationController`.
  - **Custom on top (vibe-coder pattern catalog):** signup (`RegistrationsController` + view at `/signup` — the generator does NOT provide this), email verification (token column on `User`, `EmailVerificationsController`, `EmailVerificationMailer`, `email_verified_at` gate that blocks the dashboard until verified), profile edit at `/settings/profile`, password change at `/settings/security`.
  - `letter_opener` for dev mail.
  - Views are re-skinned with shadcn/ui blocks; the generator's raw scaffold views are replaced.
- **Authenticated dashboard, two implementations**
  - `/dashboard/rsc` — RSC-rendered Projects view (Pro RSC mode, server components, streamed).
  - `/dashboard/ssr` — classic SSR Projects view (Pro Node renderer), identical UI, different render path.
  - Both render: Projects list with status filter, four metric cards (total / active / completed-this-week / avg cycle time), "New Project" CTA.
- **TanStack Router-driven `/settings`** (the structural-advantage demo)
  - `/settings` overview
  - `/settings/profile` (edit name + email)
  - `/settings/security` (change password)
  - Type-safe nested routing with SSR loaders. Rails serves the shell; TanStack handles `/settings/*` nesting on the client + SSR.
- **Projects CRUD** — `new`, `show`, `edit`, `destroy` with one reference form-with-validation pattern (server-side validation + inline error display).
- **Background job demo** — SolidQueue + `ProjectArchiveJob` (archives projects whose `last_activity_at` is older than N days).
- **Mailer demo** — `WelcomeMailer` (sent on signup, custom), the Rails 8 generator's `PasswordsMailer` (reset), and a custom `EmailVerificationMailer` (the generator does not provide one).
- **Sentry** — wired in `Gemfile`, initializer commented out, single env var (`SENTRY_DSN`) to enable. README documents how to flip it on.

### Stack

- Ruby 3.4+, Rails 8.0+, PostgreSQL
- Shakapacker + Rspack
- React 19 + TypeScript 5
- React on Rails Pro (RSC mode)
- TanStack Router with SSR (Pro-supported)
- shadcn/ui + Tailwind v4
- SolidQueue (background jobs)
- `letter_opener` (dev mail)
- Sentry-ruby + sentry-rails (commented-out initializer)
- RSpec + factory_bot + Capybara (backend & system)
- Playwright (cross-stack smoke)
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

- Rails routes (`config/routes.rb`) handle the landing page, auth surface, dashboard shells, project CRUD, and the `/settings` shell.
- TanStack Router mounts under the `/settings` Rails shell route and handles nested `/settings/*` paths client-side, with SSR loaders for first-paint correctness.
- Auth gate (the `Authentication` concern from the Rails 8 generator, included in `ApplicationController`) protects all `/dashboard/*`, `/settings/*`, `/projects/*` controllers via `before_action :require_authentication`.
- Email-verification gate: a separate `before_action :require_verified_email` on the dashboard / projects / settings controllers redirects unverified users to a "check your email" landing. Verification clicks set `email_verified_at` and clear the gate.
- `/dashboard/rsc` renders via `react_on_rails_component` with `rsc: true`, streaming from the server.
- `/dashboard/ssr` renders via `react_component` (classic SSR through the Pro Node renderer).
- Both dashboard routes pull `Project.where(user: current_user)` server-side, sort by `last_activity_at desc`, group by `status` for the metric cards.

## Error Handling

- Custom 404 and 500 pages styled with shadcn (overrides `public/404.html`, `public/500.html`).
- Server-side validation on `Project` and `User` models. The Project form is the reference pattern: validation errors render inline next to fields, success redirects with a flash toast.
- SolidQueue retry policy on `ProjectArchiveJob` (max 5, exponential backoff). Failed jobs surface in the dev queue dashboard; when Sentry is enabled, also captured there.
- Email delivery failure: in dev `letter_opener` shows the message in a browser tab (no failure path). README documents Mailgun / Postmark / Resend swap-in for production with one-line ActionMailer config.

## Testing

- **RSpec** for backend
  - Model specs for `User`, `Project`.
  - Request specs for sessions, registrations, projects.
  - System specs (Capybara + headless Chrome) for the full signup → dashboard → create-project flow.
  - At least one reference spec per category that agents extrapolate from.
- **Playwright** for cross-stack smoke
  - Auth flow (signup, login, logout).
  - Dashboard render on both `/dashboard/rsc` and `/dashboard/ssr`.
  - Project CRUD round trip.
  - TanStack Router nested-route navigation under `/settings`.
- **Vitest** for any non-trivial frontend unit logic (light — most logic is server-resident).
- **Factories** via `factory_bot` for `User`, `Project`.
- **CI** via GitHub Actions: RSpec + Playwright on push and PR.
- **Local helpers**: `bin/test` runs everything, `bin/test --smoke` runs Playwright only.

## `AGENTS.md` (Load-Bearing)

The kit's root `AGENTS.md` is treated as a first-class artifact, not an afterthought. It is the primary mechanism by which the kit is "vibe-coding-friendly."

Contents (sections, each with a working code reference in the kit):

1. **File layout map** — where models, controllers, views, components, routes, tests, factories, mailers, jobs each live.
2. **How to add a new route** — Rails controller + view + spec, with a pointer to `app/controllers/projects_controller.rb` as the canonical example.
3. **How to add a new shadcn/ui block** — `bunx shadcn add ...` workflow, where the block lives in the file tree, how to compose it.
4. **How to add a new form** — pointer to the Project form (validation + error display + flash success).
5. **How to add a new background job** — pointer to `ProjectArchiveJob` (SolidQueue, retry policy).
6. **How to add a new email** — pointer to `WelcomeMailer` (mailer, view, preview, spec).
7. **How to add a new TanStack Router child route** — pointer to `/settings/profile` and `/settings/security`.
8. **Naming conventions** — file naming, route naming, component naming, model naming.
9. **Testing conventions** — when to use RSpec vs Playwright vs Vitest.
10. **Pointer to the reference implementations** that agents should clone.

## Default Decisions (Q&A defaults committed during brainstorming)

These were marked "**Decision (default):** …" — answered with the recommended option unless the user pushes back at file-review time.

1. **TanStack Router mount strategy** — TanStack-under-a-Rails-shell-route (Rails serves the shell at `/settings`, TanStack handles `/settings/*` nesting). If a different pattern is already canonical in `react_on_rails_pro`, the implementation phase will match that.
2. **Dark mode** — default light. Toggle persisted in `localStorage`. Small inline `<script>` in `<head>` reads `localStorage` and sets the class before paint, to avoid SSR theme flicker.
3. **Demo user in seeds** — yes, `demo@example.com` / `password`, pre-verified. Documented in the README as the evaluation login.
4. **Repo creation timing** — create `shakacode/react-on-rails-starter-2026` as the first step of execution (not before the spec lands). Avoids a public-empty-repo window.

## Tier 2 (Deferred — explicitly NOT in the first public release)

Listed for tracking only. Each may become its own plan doc later.

- Kamal deploy config (delays choice of ops platform).
- Production Sentry recipe with provider examples (Mailgun / Postmark / Resend swap-in copy + screenshots).
- Additional UI patterns: file upload, multi-step wizard, infinite scroll, charts / data viz.
- API auth (JWT or OAuth) demo for headless consumers.
- More TanStack Router patterns: route-level data loaders, params validation, code splitting.
- i18n setup.
- Multi-tenant example.
- Vue and Svelte variants (only if usage of the React variant proves the model).

## Freshening Cadence

Quarterly review owned by the React on Rails team:

- Bump Rails, React, TanStack Router, shadcn/ui, Tailwind, React on Rails Pro to current versions.
- Re-run the full Playwright smoke suite against the bumped stack.
- Update the README's "last refreshed YYYY-MM-DD" line.
- Tag a release matching the calendar quarter (`2026.Q3`, `2026.Q4`, …).

Without this cadence the kit will look stale within 12 months and undo the front-door win.

## Implementation Phasing (high-level — detailed plan TBD via `writing-plans`)

The detailed implementation plan is the deliverable of the next phase. High-level phases:

1. **Repo bootstrap.** Create `shakacode/react-on-rails-starter-2026`, push initial Rails 8 + RoR Pro scaffold via `create-react-on-rails-app --rsc --rspack`. Land first CI green build.
2. **Auth surface.** Run `bin/rails generate authentication`, add `name` column + signup (`RegistrationsController` + view) + email verification (token column, `EmailVerificationsController`, `EmailVerificationMailer`) on top of it, re-skin views with shadcn/ui, add `letter_opener` for dev, ship `WelcomeMailer`.
3. **Projects model + CRUD.** Migration, model, controller, views, form-with-validation reference, factory, RSpec specs.
4. **Dashboard, both implementations.** `/dashboard/rsc` + `/dashboard/ssr` rendering the same Projects view.
5. **TanStack Router `/settings` nested routes.** Settings shell + `profile` + `security`.
6. **shadcn/ui pattern catalog.** Hero block, list view, metric cards, form, dialog, toast, empty state, loading state, dark-mode toggle.
7. **Background job + Sentry wiring.** `ProjectArchiveJob`, SolidQueue config, Sentry initializer (commented).
8. **`AGENTS.md` content.** Authored against the actual reference implementations in the kit.
9. **Playwright smoke suite.** Auth, dashboard, CRUD, TanStack nav.
10. **README + launch.** README, screenshots, demo-user instructions, "compare to Gumroad benchmark" footnote. Flip-visible event matches docs-site update.

Each phase is one PR. Each PR ships green CI before merge.

## Open Questions

1. **TanStack Router + Pro RSC interaction.** Issue #3357 step 3 calls this out. Skipped explicit de-risking per the brainstorm (Justin confirmed the Pro support is already there); implementation should validate end-to-end in a fresh kit and adjust this plan if needed.
2. **shadcn/ui Tailwind v4 maturity.** Confirm shadcn/ui's Tailwind v4 path is stable enough for a flagship at the time of implementation; if not, fall back to v3 for tier 1 and bump to v4 in a tier 2 freshening pass.
3. **`AGENTS.md` vs `CLAUDE.md`.** The repo's primary agent-conventions file is `AGENTS.md` because it's the cross-agent open standard. The implementation phase should also drop a thin `CLAUDE.md` that points at `AGENTS.md` (and the same for any other agent-specific convention files Claude Code or Cursor pick up), so no agent misses the conventions.
4. **Tailwind v4 + Pro RSC streaming compatibility.** Confirm Tailwind v4's CSS-first config doesn't conflict with how Pro RSC streams CSS for server-component routes. If incompatible at implementation time, fall back to Tailwind v3.
5. **Signup vs `User` migration in `db/seeds.rb`.** Since Rails 8's generator skips `CreateUsers` if `app/models/user.rb` already exists, the implementation phase must decide whether the `RegistrationsController` and `name` column are added in a separate migration on top of the generator's `CreateUsers`, or by editing the generator's emitted migration before first run. Editing the generator output is cleaner; document the choice in the AGENTS.md.

## Related

- #3357 — this issue
- #3144 — Gumroad RSC experiment: benchmark findings and positioning
- #3128 — Gumroad public comparison repo
- `internal/planning/examples-catalog-and-repo-naming-plan.md` — naming taxonomy this plan extends
- `docs/oss/getting-started/comparison-with-alternatives.md` — Inertia vs React on Rails comparison this plan operationalizes
- `react-on-rails-demo-gumroad-rsc` — benchmark repo the starter dashboard surface mirrors structurally
