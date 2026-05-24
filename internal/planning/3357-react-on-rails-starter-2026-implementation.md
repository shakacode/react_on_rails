# Implementation Plan: React on Rails Starter 2026 (Issue #3357)

**Status:** Draft — 2026-05-22. Ready for AI-sub-agent execution after Phase 0 spike confirms stack compatibility.
**Parent plan:** [3357-react-on-rails-starter-2026.md](./3357-react-on-rails-starter-2026.md)
**Tracking issue:** https://github.com/shakacode/react_on_rails/issues/3357

This document is the executable companion to the strategic plan. Each task is scoped for a single AI sub-agent session (~15–45 min CC time), with explicit inputs, outputs, acceptance criteria, and dependencies. Tasks within the same phase are parallel-safe unless their `Depends on:` lines say otherwise.

---

## Kickoff (read this first)

If you're a coordinator or sub-agent picking this up cold on a fresh machine:

1. **Read both planning docs** in order:
   - `internal/planning/3357-react-on-rails-starter-2026.md` (strategic plan — what we're building and why)
   - This file (implementation plan — how to build it)
2. **Confirm coordinator decisions** are locked: see the "Coordinator Decisions — Locked 2026-05-22" section at the bottom of this file. Repo name, a11y target, surface split, dashboard narrative, spike approval mode are all decided.
3. **Start at T0.1.** Phase 0 is sequential (T0.1 → T0.2 → T0.3 → T0.4 → T0.5) and produces a `SPIKE.md` with a GREEN / AMBER / RED verdict.
4. **Per coordinator decision #6** (spike approval = full auto): if `SPIKE.md` lands GREEN, dispatch Phase 1 immediately. If AMBER, apply the named fallback decision tree (see the strategic plan's Required-Before-Implementation #3) and dispatch Phase 1 with the fallback in place. If RED, stop and escalate to Justin.
5. **Phase 1 onwards:** fan out parallel-safe tasks across multiple sub-agents (the "Parallel-safe with:" field on each task card identifies what can co-run).
6. **No skill names from gstack appear in any task.** All tasks are framework-neutral and can be executed by any capable agent.

Repo location for the spike: a new throwaway local branch (`spike/starter-tanstack-stack-validation`) on the existing `react_on_rails` repo. Do NOT create the public `react-on-rails-starter-tanstack` repo until T1.1 (after the spike passes).

---

## How to Use This Plan

### Task IDs

Format: `T<phase>.<number>` — e.g. `T2.4` is Phase 2, Task 4. IDs are stable; never renumber. New tasks get the next available number in their phase.

### Task card format

```
### T<phase>.<num>: <Title>

**Depends on:** <task IDs, or "none">
**Parallel-safe with:** <task IDs in same phase>
**Est. CC time:** <minutes>

**Goal:** <1–2 sentences>

**Inputs:**
- <file paths or spec sections to read>

**Outputs:**
- <files created or modified>

**Acceptance criteria:**
- [ ] <testable condition>
- [ ] <testable condition>

**Notes:**
<gotchas, references, decisions to make inline>
```

### Dispatching tasks

A coordinator (human or top-level agent) picks tasks where `Depends on:` is satisfied and dispatches them. Within a phase, multiple `Parallel-safe with:` tasks can run concurrently. Each sub-agent gets only the task card plus the named inputs — no shared conversation history needed.

### Phase gates

A phase is "done" when every task in it passes its acceptance criteria AND the phase's PR has green CI. The next phase doesn't start until the prior one is merged. (Within a phase, all task PRs can stack on a single phase branch and merge as one squash.)

### Conventions in effect everywhere

- Ruby: `bundle exec` prefix on all gem tools. Lint with `(cd <project_root> && bundle exec rubocop)`.
- JS: `pnpm` for package management. `bun` only for `bunx shadcn add ...`.
- File endings: every file ends with a newline.
- Commits: small, focused, conventional-commit style (`feat:`, `fix:`, `docs:`, `test:`, `chore:`).
- Test framework: RSpec for backend, Playwright for cross-stack, Vitest for non-trivial JS units.
- Marker comments on canonical reference patterns: `# REFERENCE PATTERN: <name> — see AGENTS.md §<N>` (Ruby) or `// REFERENCE PATTERN: ...` (JS).

---

## Phase 0 — Spike PR (mandatory precondition)

**Goal:** Validate that the three open compatibility risks all work together before public scaffold commits.

**Mode:** SEQUENTIAL. One throwaway branch. No public repo activity yet.

**Gate to Phase 1:** every task below must pass. If any fails, follow the fallback decision tree in the strategic plan, then re-spike.

### T0.1: Throwaway scaffold

**Depends on:** none
**Parallel-safe with:** none (the throwaway branch starts here)
**Est. CC time:** 30 min

**Goal:** Bootstrap a throwaway Rails 8 + RoR Pro app with RSC and Rspack enabled, on its own branch.

**Inputs:**

- `packages/create-react-on-rails-app/` (CLI source — to understand flags)

**Outputs:**

- A new local branch `spike/starter-tanstack-stack-validation` containing a fresh app produced by `create-react-on-rails-app --rsc --rspack`.
- `SPIKE.md` at the app root with a "what we're testing" section.

**Acceptance criteria:**

- [ ] `bin/setup` runs clean on a fresh macOS clone.
- [ ] `bin/dev` boots web + Rspack + Node renderer without errors.
- [ ] `localhost:3000` shows the generated welcome page.
- [ ] `SPIKE.md` lists the four validation goals (see T0.2–T0.5).

### T0.2: TanStack Router under a Rails shell route

**Depends on:** T0.1
**Parallel-safe with:** none (sequential spike)
**Est. CC time:** 45 min

**Goal:** Confirm TanStack Router mounts cleanly under a Rails-served shell route with SSR loaders and clean hydration.

**Inputs:**

- TanStack Router docs (SSR setup): https://tanstack.com/router/latest/docs/framework/react/guide/ssr
- RoR Pro Node renderer config in the scaffolded app.

**Outputs:**

- A `/spike/tan-router` Rails route serving a TanStack Router shell.
- One nested TanStack child route (`/spike/tan-router/child`).
- SSR loader that reads a piece of data and renders it.

**Acceptance criteria:**

- [ ] First paint of `/spike/tan-router` includes the loader's data (no flash of unloaded content).
- [ ] Browser console shows zero hydration mismatch errors.
- [ ] Client-side navigation to `/child` works without a full page reload.
- [ ] CSRF token from Rails meta tag is available to TanStack Router via a shared reader.

**Notes:** This is the single highest-risk integration. If it fails, the whole kit identity is at risk — escalate before continuing.

### T0.3: TanStack Query against Rails JSON

**Depends on:** T0.2
**Parallel-safe with:** none
**Est. CC time:** 30 min

**Goal:** Confirm TanStack Query can read from a Rails JSON endpoint with CSRF, with independent loading/error states per query.

**Inputs:**

- T0.2 outputs.

**Outputs:**

- `/api/spike/ping` Rails JSON endpoint.
- Two independent TanStack Query hooks on `/spike/tan-router` rendering separate cards, each with its own loading + error state.

**Acceptance criteria:**

- [ ] Both queries fire on mount; slow one doesn't block the fast one.
- [ ] Forced 500 response renders just-that-card's error state, not a global error.
- [ ] CSRF token sent correctly (verify via Rails request log).

### T0.4: shadcn/ui on Tailwind v4 inside an RSC component

**Depends on:** T0.1
**Parallel-safe with:** T0.2, T0.3 (after T0.1)
**Est. CC time:** 30 min

**Goal:** Confirm shadcn/ui blocks render correctly when used inside a Pro RSC bundle on Tailwind v4.

**Inputs:**

- shadcn/ui docs (Tailwind v4 path): https://ui.shadcn.com/docs/tailwind-v4
- The Pro RSC config in the scaffolded app.

**Outputs:**

- A `/spike/rsc-shadcn` Rails route that renders a Pro RSC component (`rsc: true`).
- The RSC component uses one shadcn block (e.g. `Card`).
- A nested client component (e.g. `Button` with `onClick`) inside the RSC tree.

**Acceptance criteria:**

- [ ] First HTML response includes the rendered shadcn Card markup (server-rendered, not blank).
- [ ] The Button hydrates on the client and responds to clicks.
- [ ] No console errors related to `'use client'` boundaries.
- [ ] Tailwind v4 CSS reaches the page (visible styling).

**Notes:** If Tailwind v4 fails, fall back to v3 per the strategic plan's decision tree. Document the fallback choice in `SPIKE.md`.

### T0.5: All three together + outcome report

**Depends on:** T0.2, T0.3, T0.4
**Parallel-safe with:** none
**Est. CC time:** 30 min

**Goal:** Render one throwaway route that uses TanStack Router + TanStack Query + Pro RSC + shadcn on Tailwind v4 simultaneously. Document the outcome.

**Outputs:**

- `/spike/all-the-things` route.
- Updated `SPIKE.md` with: what worked, what didn't, fallback decisions (if any), recommended adjustments to the strategic plan's stack.

**Acceptance criteria:**

- [ ] The combined route works end-to-end (server render → hydrate → query → user interaction → state update).
- [ ] `SPIKE.md` includes a verdict: GREEN (proceed with planned stack), AMBER (proceed with named fallbacks), or RED (escalate before Phase 1).
- [ ] If AMBER or RED, the doc names each affected `Required-Before-Implementation` item that needs revision.

**Notes:** This is the gate to Phase 1. Do not start any Phase 1 work until T0.5 lands GREEN or AMBER with named, accepted fallbacks.

---

## Phase 1 — Repo Bootstrap

**Goal:** Public template repo with a working scaffold, CI, dev tooling, and the "first-5-minutes error budget" copy.

**Parallel tracks:**

- Track A (sequential): T1.1 → T1.2 → T1.3
- Track B (parallel after T1.2): T1.4, T1.5, T1.6, T1.7, T1.8

### T1.1: Create GitHub Template Repository

**Depends on:** Phase 0 GREEN/AMBER
**Parallel-safe with:** none
**Est. CC time:** 15 min

**Goal:** Create the public GitHub repository configured as a template, with a placeholder README pointing at the tracking issue.

**Outputs:**

- New repo at `shakacode/react-on-rails-starter-tanstack` (name locked by Justin 2026-05-22).
- Repository setting: "Template repository" = enabled.
- `README.md` with: "Scaffolding in progress — see #3357" and a link to the strategic plan.
- `LICENSE` (MIT, matching ShakaCode convention).

**Acceptance criteria:**

- [ ] Repo is public.
- [ ] "Use this template" button visible on the repo page.
- [ ] README placeholder visible at the URL.

### T1.2: Initial scaffold + push

**Depends on:** T1.1
**Parallel-safe with:** none
**Est. CC time:** 30 min

**Goal:** Run `create-react-on-rails-app --rsc --rspack`, apply the spike's findings, push first commit.

**Inputs:**

- Phase 0 `SPIKE.md` (apply any AMBER fallback choices).

**Outputs:**

- First commit to the new repo with a working scaffold.
- `CHANGELOG.md` initialized.
- `.github/` directory with placeholder issue + PR templates.

**Acceptance criteria:**

- [ ] `git clone` + `bin/setup` + `bin/dev` on a fresh macOS laptop boots the welcome page (TTHW measurement starts here — target ≤ 3 min from clone).
- [ ] `git log` shows one initial commit signed by the implementer.

### T1.3: GitHub Actions CI skeleton

**Depends on:** T1.2
**Parallel-safe with:** T1.4, T1.5, T1.6, T1.7, T1.8
**Est. CC time:** 30 min

**Goal:** CI runs RSpec + Playwright on every push and PR. Tests can be empty stubs — the goal is green CI infrastructure.

**Outputs:**

- `.github/workflows/ci.yml` with two jobs: `rspec` and `playwright`.
- One stub RSpec test (passes trivially).
- One stub Playwright test (passes trivially).
- Branch protection: `main` requires both jobs green to merge.

**Acceptance criteria:**

- [ ] First PR can't merge without CI green.
- [ ] CI run takes < 5 min on a no-change PR.

### T1.4: `bin/doctor` preflight

**Depends on:** T1.2
**Parallel-safe with:** T1.3, T1.5, T1.6, T1.7, T1.8
**Est. CC time:** 30 min

**Goal:** A script that checks every prerequisite a dev needs to boot the app, with actionable error messages.

**Outputs:**

- `bin/doctor` (Ruby or Bash, implementer's choice).
- Checks: Ruby version (matches `.ruby-version`), Postgres reachable, Node version (≥ 20), pnpm installed, bun installed.
- Each failed check prints: problem + cause + concrete fix command.

**Acceptance criteria:**

- [ ] Running `bin/doctor` on a healthy macOS dev box prints "all checks passed" and exits 0.
- [ ] Failing any one check exits non-zero with a fix message.
- [ ] `bin/doctor` runs in < 3 seconds.

### T1.5: `bin/setup` wrapping doctor + db prep + seed

**Depends on:** T1.4
**Parallel-safe with:** T1.3, T1.6, T1.7, T1.8
**Est. CC time:** 20 min

**Goal:** Single command that primes a fresh clone — runs doctor, installs deps, prepares db, seeds dev data.

**Outputs:**

- `bin/setup` (overrides the default Rails one).
- Calls: `bin/doctor`, `bundle install`, `pnpm install`, `bin/rails db:prepare`, `bin/rails db:seed`.

**Acceptance criteria:**

- [ ] On a fresh clone, `bin/setup` exits 0 and `bin/dev` then boots the app.
- [ ] If `bin/doctor` fails, `bin/setup` aborts with the doctor message.

### T1.6: `Procfile.dev` with the four processes

**Depends on:** T1.2
**Parallel-safe with:** T1.3, T1.4, T1.5, T1.7, T1.8
**Est. CC time:** 15 min

**Goal:** `bin/dev` boots web + Rspack-watch + SolidQueue + Node renderer via Foreman/Overmind.

**Outputs:**

- `Procfile.dev` defining: `web`, `rspack`, `worker` (SolidQueue), `renderer` (Pro Node renderer).
- `bin/dev` script (the standard Rails one is fine if it reads Procfile.dev).

**Acceptance criteria:**

- [ ] `bin/dev` boots all four processes; killing one logs the failure without taking down the others.
- [ ] All four are reachable: web at :3000, renderer at its port, etc.

### T1.7: First-5-minutes error budget copy

**Depends on:** T1.2
**Parallel-safe with:** T1.3, T1.4, T1.5, T1.6, T1.8
**Est. CC time:** 45 min

**Goal:** The 6–8 predictable evaluator failures each surface with problem + cause + fix.

**Outputs:**

- Dev-only middleware in `config/initializers/development_error_hints.rb` that:
  - Detects `User.count == 0` and renders "no demo user — run `bin/rails db:seed`" inline.
  - Detects SolidQueue not running (check the worker process via the same Procfile mechanism) and shows a banner.
- `bin/dev` preflight: checks port 3000 is free, Postgres is reachable, Node renderer port is free — prints a fix message before booting.
- `docs/05-troubleshooting.md` lists every predictable failure mode with copy-pasteable fixes (stub now; flesh out in T9.8).

**Acceptance criteria:**

- [ ] Manually breaking each known failure (kill Postgres, run on port-taken, skip seed) produces a clear actionable message.
- [ ] None of the messages contain raw stack traces as the primary content — stack traces are a follow-on detail, not the headline.

### T1.8: `.env.example` with required vars

**Depends on:** T1.2
**Parallel-safe with:** T1.3, T1.4, T1.5, T1.6, T1.7
**Est. CC time:** 15 min

**Goal:** Document every ENV var the kit reads.

**Outputs:**

- `.env.example` with: `RAILS_MASTER_KEY`, `DATABASE_URL`, `SOLID_QUEUE_IN_PUMA`, `SENTRY_DSN`, mail-provider vars (`SMTP_*` or `MAILGUN_API_KEY` etc.).
- Each var has an inline comment explaining purpose and dev-vs-prod expectations.
- `.gitignore` entry for `.env` (just `.env.example` is tracked).

**Acceptance criteria:**

- [ ] `cp .env.example .env` produces a usable dev config (the dev-mode defaults work).

---

## Phase 2 — Auth Surface + Verification Funnel

**Goal:** Rails 8 auth generator + custom signup + email verification (per Required-Before-Implementation #1 spec) + WelcomeMailer, re-skinned with shadcn/ui.

**Parallel tracks** (after T2.1, T2.2):

- Track A: T2.3 → T2.8 (signup controller + view re-skin)
- Track B: T2.4 → T2.10 → T2.11 (verification controller + throttling + tests)
- Track C: T2.5 (verification mailer)
- Track D: T2.6 (welcome mailer)
- Track E: T2.7 (gate middleware) — after T2.4
- Track F: T2.9 (verification UX funnel) — after T2.4, T2.5

### T2.1: Run Rails 8 auth generator

**Depends on:** Phase 1 complete
**Parallel-safe with:** none (must be first in phase)
**Est. CC time:** 15 min

**Goal:** Commit the baseline `bin/rails generate authentication` output before any custom changes.

**Outputs:**

- One commit containing the generator's raw emit (controllers, views, migration, models).

**Acceptance criteria:**

- [ ] Commit message: `feat(auth): run Rails 8 authentication generator (baseline)`.
- [ ] No edits to the generated files in this commit — they get edited in T2.2+.

### T2.2: Edit the User migration before first run

**Depends on:** T2.1
**Parallel-safe with:** none
**Est. CC time:** 20 min

**Goal:** Add `name`, `email_verification_token_digest`, `email_verified_at`, `verification_sent_at` columns to the generator's `CreateUsers` migration before any `db:migrate`.

**Outputs:**

- Edited migration file in `db/migrate/`.
- Updated `app/models/user.rb` with the new attributes + validations.
- `bin/rails db:migrate` runs clean.

**Acceptance criteria:**

- [ ] Migration version unchanged (still the generator's original number; we edit, not re-emit).
- [ ] `User.new(email_address: "x@y.com", password: "z", name: "X")` is valid.
- [ ] Index exists on `email_verification_token_digest`.

**Notes:** The strategic plan documents this approach in `AGENTS.md` so adopters who re-run the generator know why their migration diverges.

### T2.3: Signup controller + view

**Depends on:** T2.2
**Parallel-safe with:** T2.4, T2.5, T2.6
**Est. CC time:** 30 min

**Goal:** `RegistrationsController` (the generator does NOT provide this) with `new` and `create`, view at `/signup`.

**Outputs:**

- `app/controllers/registrations_controller.rb` (marked `# REFERENCE PATTERN: signup-controller — see AGENTS.md §2`).
- `app/views/registrations/new.html.erb` (initial scaffold; re-skin in T2.8).
- Route: `resource :registration, only: [:new, :create]` (or `get/post '/signup'` — pick the more idiomatic).
- On successful create: triggers `EmailVerificationMailer.welcome(...).deliver_later` (the verification mailer also acts as the post-signup mail; no duplicate).
- On successful create: triggers `WelcomeMailer.welcome(...).deliver_later`.
- Renders `/email_verifications/sent` after create.

**Acceptance criteria:**

- [ ] GET `/signup` shows the form.
- [ ] POST `/signup` with valid params creates a user with `email_verified_at: nil` and a generated verification token.
- [ ] POST `/signup` with invalid params re-renders with errors.
- [ ] CSRF protection active (default Rails — verify `protect_from_forgery` is in `ApplicationController`).

### T2.4: EmailVerificationsController per spec

**Depends on:** T2.2
**Parallel-safe with:** T2.3, T2.5, T2.6
**Est. CC time:** 60 min

**Goal:** Full implementation of the email verification token lifecycle per Required-Before-Implementation #1.

**Outputs:**

- `app/controllers/email_verifications_controller.rb` with:
  - `#create` — generates a fresh token, stores digest only, sets `verification_sent_at`, sends mail, returns identical UX whether email exists or not (enumeration defense).
  - `#show` (the email-click endpoint) — looks up by digest, checks TTL (24h), checks single-use (not already consumed), on success: sets `email_verified_at`, nulls the token digest, rotates the session.
  - Audit logging via `Rails.logger.tagged("auth")`.
- Routes: `resources :email_verifications, only: [:create, :show]`.
- Token generation helper: `SecureRandom.urlsafe_base64(32)`, digest via `Digest::SHA256.hexdigest`, comparison via `ActiveSupport::SecurityUtils.secure_compare`.

**Acceptance criteria:**

- [ ] Visiting a valid token URL marks the user verified and rotates the session (verify via session ID change).
- [ ] Visiting a stale (>24h) token URL shows "expired — request a new one" (no token consumed).
- [ ] Visiting a previously-consumed token URL shows the same expired message (replay-safe).
- [ ] Verification events appear in logs tagged `[auth]`.

### T2.5: EmailVerificationMailer

**Depends on:** T2.2
**Parallel-safe with:** T2.3, T2.4, T2.6
**Est. CC time:** 30 min

**Goal:** Mailer + view templates for the verification email.

**Outputs:**

- `app/mailers/email_verification_mailer.rb` with `welcome(user)` method.
- `app/views/email_verification_mailer/welcome.html.erb` and `.text.erb`.
- Copy: friendly, branded, with a single CTA button + plain-text fallback URL.
- Marked `# REFERENCE PATTERN: mailer — see AGENTS.md §6`.

**Acceptance criteria:**

- [ ] `EmailVerificationMailer.welcome(user).deliver_now` works in dev (visible via `letter_opener`).
- [ ] HTML and text variants both render.
- [ ] Mailer preview at `/rails/mailers/email_verification_mailer/welcome` renders.

### T2.6: WelcomeMailer

**Depends on:** T2.2
**Parallel-safe with:** T2.3, T2.4, T2.5
**Est. CC time:** 20 min

**Goal:** Generic welcome email triggered on signup (separate from verification).

**Outputs:**

- `app/mailers/welcome_mailer.rb`.
- HTML + text templates.

**Acceptance criteria:**

- [ ] Sends on signup (after verification email).
- [ ] Mailer preview renders.

### T2.7: `require_verified_email` gate

**Depends on:** T2.4
**Parallel-safe with:** T2.5, T2.6, T2.8
**Est. CC time:** 20 min

**Goal:** A `before_action` that redirects unverified users away from protected routes.

**Outputs:**

- Concern at `app/controllers/concerns/verified_authentication.rb` defining `require_verified_email`.
- Applied to a base controller that the dashboard, projects, and settings controllers will inherit from.
- Redirects unverified users to `email_verifications#sent` (the "check your email" landing).

**Acceptance criteria:**

- [ ] Authenticated-but-unverified user visiting `/dashboard` redirects to "check your email."
- [ ] Verified user reaches `/dashboard`.
- [ ] Anonymous user redirects to `/session/new` (not "check your email") — different failure modes get different redirects.

### T2.8: Re-skin auth views with shadcn/ui

**Depends on:** T2.3, generator's session/passwords views
**Parallel-safe with:** T2.7
**Est. CC time:** 60 min

**Goal:** Replace the generator's raw scaffold styling with shadcn/ui blocks across login, signup, password reset, and password reset request views.

**Outputs:**

- All `app/views/sessions/`, `app/views/registrations/`, `app/views/passwords/`, `app/views/email_verifications/` views using shadcn blocks (`Card`, `Input`, `Button`, `Label`).
- One canonical login view marked `# REFERENCE PATTERN: form — see AGENTS.md §4`.
- Each view ships with the four states (empty/error/loading/success) where applicable.
- `aria-live="polite"` on flash messages, `aria-describedby` on input errors.

**Acceptance criteria:**

- [ ] Visual: signup, login, password reset all look polished and consistent.
- [ ] Keyboard nav: tab order works, Enter submits, focus rings visible.
- [ ] Screen reader: form errors announced via `aria-live`.

### T2.9: Post-signup verification UX funnel

**Depends on:** T2.4, T2.5
**Parallel-safe with:** T2.7, T2.8
**Est. CC time:** 60 min

**Goal:** The "highest-friction touchpoint in the funnel" (Design review) as a designed UX, not a backend gate.

**Outputs:**

- `/email_verifications/sent` page rendered after signup: shows the target email (masked partially: `j***@gmail.com`), resend button (with cooldown), "change email" link, spam-folder hint, "open `letter_opener`" link in dev.
- Resend cooldown: 60 seconds client-side, enforced server-side via Rack::Attack (T2.10).
- "Expired or already-used token" landing with a "request a new link" CTA that doesn't require an authenticated session for 24 hours post-signup.

**Acceptance criteria:**

- [ ] Signup → "check your email" page with the user's email visible.
- [ ] Resend button disables for 60s after click, re-enables, can be clicked again.
- [ ] Clicking an expired token URL lands on the expired page with a resend CTA.
- [ ] Spam-folder hint copy reads natural, not legalistic.

### T2.10: Rack::Attack throttling

**Depends on:** T2.4
**Parallel-safe with:** T2.7, T2.8, T2.9
**Est. CC time:** 30 min

**Goal:** Rate-limit verification-email sends per Required-Before-Implementation #1.

**Outputs:**

- `config/initializers/rack_attack.rb` with two throttles:
  - 5 verification-email-sends per IP per hour.
  - 3 per email per hour.
- 429 response with a clear "too many requests — try again in N minutes" body.

**Acceptance criteria:**

- [ ] Manual test: hitting `POST /email_verifications` 6 times from the same IP returns 429 on attempt 6.
- [ ] Throttle clears after the window.

### T2.11: Verification + auth test suite

**Depends on:** T2.4, T2.10
**Parallel-safe with:** T2.7, T2.8, T2.9
**Est. CC time:** 75 min

**Goal:** Request and model specs covering token expiry, single-use, replay, throttling, session rotation, enumeration defense.

**Outputs:**

- `spec/requests/email_verifications_spec.rb` — happy path, expired token, consumed token, throttle hit, enumeration probe.
- `spec/requests/registrations_spec.rb` — happy path, duplicate email, weak password, mail-provider-down scenario (mock).
- `spec/models/user_spec.rb` — verification token methods, digest comparison, expiry.
- `spec/system/signup_to_dashboard_spec.rb` — full Capybara flow.
- Factories with traits: `:unverified`, `:expired_token`, `:verified`.

**Acceptance criteria:**

- [ ] All specs pass.
- [ ] CI green.
- [ ] Coverage report shows ≥ 90% line coverage on the auth code paths.

---

## Phase 3 — Projects Model + CRUD + JSON API

**Goal:** The Project resource: model, controllers (HTML and JSON), reference form pattern, factories, specs.

**Parallel tracks** (after T3.1, T3.2):

- Track A: T3.3 (HTML controller) + T3.4 (reference form view)
- Track B: T3.5 (JSON API controller)
- Track C: T3.6 (factories)
- Track D: T3.7, T3.8 (specs) — after Track A

### T3.1: Projects migration

**Depends on:** Phase 2 complete
**Parallel-safe with:** none
**Est. CC time:** 15 min

**Outputs:** Migration adding `projects` table: `name`, `description`, `status` (integer enum), `user_id` (FK), `last_activity_at`, timestamps.

**Acceptance criteria:**

- [ ] `bin/rails db:migrate` runs clean.
- [ ] Index on `user_id`, `last_activity_at`, `status`.

### T3.2: Project model

**Depends on:** T3.1
**Parallel-safe with:** none
**Est. CC time:** 20 min

**Outputs:** `app/models/project.rb` with: `belongs_to :user`, status enum (active/paused/completed/archived), name validation (presence, length), scope `active`, scope `recent`.

**Acceptance criteria:**

- [ ] Model spec passes.
- [ ] `Project.statuses` returns the enum hash.

### T3.3: HTML ProjectsController + reference form view

**Depends on:** T3.2
**Parallel-safe with:** T3.5, T3.6
**Est. CC time:** 75 min

**Goal:** The HTML controller is the **canonical reference pattern** for "Rails controller + server-side validation + shadcn form + flash success."

**Outputs:**

- `app/controllers/projects_controller.rb` with `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`. Marked `# REFERENCE PATTERN: controller — see AGENTS.md §2`.
- `app/views/projects/_form.html.erb` marked `# REFERENCE PATTERN: form — see AGENTS.md §4` — server-side validation errors render inline with `aria-describedby`, success redirects with a flash toast.
- All views (`index`, `show`, `new`, `edit`) use shadcn blocks.
- `before_action :authenticate_user`, `before_action :require_verified_email`, `before_action :set_project, only: [:show, :edit, :update, :destroy]`.
- Authorization: `Project.find` scoped to `current_user.projects`.

**Acceptance criteria:**

- [ ] Manual: signup → verify → `/projects/new` → submit empty → see inline errors → submit valid → redirect to `/projects/:id` with flash toast.
- [ ] Authorization: User A cannot view User B's project (404, not 403).

### T3.4: Delete confirmation flow

**Depends on:** T3.3
**Parallel-safe with:** T3.5, T3.6
**Est. CC time:** 30 min

**Outputs:** Confirm dialog (shadcn AlertDialog) on Project destroy. Soft-delete via `archive!` rather than DELETE for the demo? (Implementer decision — but the destroy reference pattern must be visible.)

**Acceptance criteria:**

- [ ] Cancel button dismisses the dialog without action.
- [ ] Confirm button archives the project, redirects with flash.

### T3.5: JSON API ProjectsController

**Depends on:** T3.2
**Parallel-safe with:** T3.3, T3.6
**Est. CC time:** 45 min

**Outputs:**

- `app/controllers/api/projects_controller.rb` namespaced under `/api`.
- Routes: `namespace :api { resources :projects, only: [:index, :show] }`.
- Endpoints: `GET /api/projects` (list, supports `status`, `sort`, `page`, `per_page` query params), `GET /api/projects/:id`, `GET /api/projects/:id/metrics` (4 metric values for the dashboard cards).
- JSON shape: each project includes id, name, status, last_activity_at, computed fields.
- Same `authenticate_user` + `require_verified_email` before_actions.
- CSRF: standard Rails (not skipped) — TanStack Query will pass the meta-tag token.

**Acceptance criteria:**

- [ ] `GET /api/projects?status=active` returns only active projects for the current user.
- [ ] `GET /api/projects?sort=last_activity_at&dir=desc` orders correctly.
- [ ] `GET /api/projects/:id/metrics` returns 4 fields: total, active_count, completed_this_week, avg_cycle_time.
- [ ] Without auth: 401.

### T3.6: Project factory

**Depends on:** T3.2
**Parallel-safe with:** T3.3, T3.5
**Est. CC time:** 15 min

**Outputs:** `spec/factories/projects.rb` with traits: `:active`, `:paused`, `:completed`, `:archived`, `:stale` (old `last_activity_at`).

**Acceptance criteria:**

- [ ] `FactoryBot.lint` passes.

### T3.7: Projects request specs

**Depends on:** T3.3, T3.5, T3.6
**Parallel-safe with:** T3.8
**Est. CC time:** 60 min

**Outputs:** `spec/requests/projects_spec.rb` covering all HTML and JSON endpoints, happy + error paths, authorization scoping.

**Acceptance criteria:**

- [ ] All specs pass.
- [ ] Authorization tests confirm user-A-can't-see-user-B for every endpoint.

### T3.8: Projects system spec (signup → create-project flow)

**Depends on:** T3.3, T3.6
**Parallel-safe with:** T3.7
**Est. CC time:** 45 min

**Outputs:** `spec/system/full_signup_to_project_flow_spec.rb` — Capybara flow: signup → verify (intercept mailer) → dashboard → new project → fill form → submit → see in list.

**Acceptance criteria:**

- [ ] Passes headless and headed.

### T3.9: Seed data

**Depends on:** T3.2
**Parallel-safe with:** T3.3, T3.5, T3.6
**Est. CC time:** 15 min

**Outputs:** `db/seeds.rb` (guarded by `Rails.env.development? || Rails.env.test?`) creating `demo@example.com / password` pre-verified + 12 sample projects across all four statuses with varied `last_activity_at`.

**Acceptance criteria:**

- [ ] `bin/rails db:seed` works in dev.
- [ ] `RAILS_ENV=production bin/rails db:seed` is a no-op (and logs the skip reason).

---

## Phase 4 — TanStack-Driven Authenticated Surface

**Goal:** The kit's structural moat — TanStack Router + Query + Table operationalized end-to-end on a single dashboard.

**Parallel tracks** (after T4.1, T4.2):

- Track A: T4.3 + T4.4 (dashboard) — depends on T4.1, T4.2
- Track B: T4.5 (settings routes) — depends on T4.1
- Track C: T4.6 (projects routes) — depends on T4.1
- Track D: T4.7 (rendering-mode drawer) — parallel
- Track E: T4.8 (error/Suspense boundaries) — after T4.3, T4.4

### T4.1: TanStack Router setup + SSR shell

**Depends on:** Phase 3 complete
**Parallel-safe with:** T4.2
**Est. CC time:** 90 min

**Goal:** Install and configure TanStack Router with SSR loaders, mounted under a single Rails shell controller.

**Outputs:**

- `pnpm add @tanstack/react-router @tanstack/router-vite-plugin @tanstack/router-devtools` etc.
- `app/controllers/authenticated_controller.rb` — base controller with auth + verification gates, renders an empty Rails view that mounts the TanStack app.
- `app/javascript/routes/__root.tsx` — the TanStack root route.
- `app/javascript/routes/dashboard.tsx` — placeholder route.
- TanStack Router config wired into the Pro Node renderer for SSR.
- A shared `getCsrfToken()` helper that reads the Rails meta tag.

**Acceptance criteria:**

- [ ] `/dashboard` first paint includes server-rendered content (view source shows the rendered HTML, not just a `<div id="root">`).
- [ ] Browser console: zero hydration mismatch errors.
- [ ] Tab to `/settings` (via TanStack Link) is a client-side navigation (no Rails round-trip).
- [ ] Marked `// REFERENCE PATTERN: tanstack-route — see AGENTS.md §2`.

### T4.2: TanStack Query setup with CSRF

**Depends on:** Phase 3 complete
**Parallel-safe with:** T4.1
**Est. CC time:** 45 min

**Goal:** `QueryClient`, provider, and a shared `apiFetch` wrapper that injects CSRF token from the meta tag.

**Outputs:**

- `pnpm add @tanstack/react-query @tanstack/react-query-devtools`.
- `app/javascript/lib/queryClient.ts` exporting a configured QueryClient.
- `app/javascript/lib/apiFetch.ts` — wraps `fetch` with CSRF + JSON + error normalization.
- `<QueryClientProvider>` wired in the root route.

**Acceptance criteria:**

- [ ] A test query against `/api/projects` succeeds in dev.
- [ ] Without the CSRF token, the request fails with a clear Rails 422 — confirms CSRF is on.
- [ ] React Query Devtools loads in dev.

### T4.3: `/dashboard` with metric cards (TanStack Query)

**Depends on:** T4.1, T4.2
**Parallel-safe with:** T4.4, T4.5, T4.6
**Est. CC time:** 60 min

**Outputs:**

- `/dashboard` TanStack route renders 4 metric cards.
- Each card is an independent `useQuery` against `/api/projects/:id/metrics` (or a per-metric endpoint).
- Per-card loading skeleton, error state, success render.

**Acceptance criteria:**

- [ ] Slow-throttle one query: that card shows skeleton, others show data.
- [ ] Force one query to 500: that card shows error, others render.
- [ ] `/dashboard` renders via `react_component` (classic SSR through the Pro Node renderer) — NOT `rsc: true`. RSC lives on the public landing where its TTFB / SEO / cold-load wins apply; behind auth it doesn't earn its keep. Verify the page source contains the rendered HTML and that hydration is clean (no console errors).

### T4.4: Projects list with TanStack Table

**Depends on:** T4.1, T4.2
**Parallel-safe with:** T4.3, T4.5, T4.6
**Est. CC time:** 90 min

**Goal:** The Projects list demonstrates the kit's signature pattern — server-driven sort/filter/paginate with URL state.

**Outputs:**

- `pnpm add @tanstack/react-table`.
- Projects list rendered with TanStack Table.
- Columns: name, status, last_activity_at, actions.
- Server-side sort/filter/paginate via query params on `/api/projects`.
- URL state reflects table state (TanStack Router search params).
- Marked `// REFERENCE PATTERN: tanstack-table — see AGENTS.md §7`.

**Acceptance criteria:**

- [ ] Sorting a column updates the URL and re-fetches.
- [ ] Filtering by status updates the URL.
- [ ] Pagination updates the URL.
- [ ] Pasting the URL with `?sort=last_activity_at&dir=desc&status=active` loads the right state.

### T4.5: `/settings/*` nested routes

**Depends on:** T4.1
**Parallel-safe with:** T4.3, T4.4, T4.6
**Est. CC time:** 60 min

**Outputs:**

- `/settings` overview route.
- `/settings/profile` — edit name + email (email change triggers re-verification).
- `/settings/security` — change password (uses Rails password reset flow under the hood).
- All TanStack routes with loaders.

**Acceptance criteria:**

- [ ] Tab navigation between profile and security is client-side.
- [ ] Email change triggers a new verification email and logs the user out / re-gates.

### T4.6: `/projects/new`, `/projects/:id`, `/projects/:id/edit` routes

**Depends on:** T4.1
**Parallel-safe with:** T4.3, T4.4, T4.5
**Est. CC time:** 60 min

**Outputs:**

- Three TanStack routes wrapping the Rails-served forms (or fully client-side — implementer's call; recommended: keep the form server-rendered to preserve the reference pattern from T3.3, but navigate to it via TanStack Link).

**Acceptance criteria:**

- [ ] Create flow works end-to-end via TanStack-routed pages.

### T4.7: Rendering-mode drawer

**Depends on:** T4.3
**Parallel-safe with:** T4.4, T4.5, T4.6
**Est. CC time:** 30 min

**Goal:** A small "what's rendering this page" drawer that names the rendering path (RSC streaming) and links to the demo portfolio for the other modes.

**Outputs:**

- Drawer component triggered by a small "i" icon in the dashboard header.
- Content: "This page renders via React Server Components + streaming. Other render paths: [Hacker News demo →] [Gumroad Inertia comparison →]".

**Acceptance criteria:**

- [ ] Drawer opens/closes, links work.
- [ ] Keyboard accessible (Escape closes, focus trap).

### T4.8: Error + Suspense boundaries

**Depends on:** T4.3, T4.4
**Parallel-safe with:** T4.5, T4.6, T4.7
**Est. CC time:** 45 min

**Outputs:**

- Route-level error boundary on `/dashboard` and `/settings/*`.
- `<Suspense>` boundaries per metric card and per Projects-list segment.
- Loader-failure UX: "this section is unavailable — retry" with a retry CTA.

**Acceptance criteria:**

- [ ] Force loader exception: boundary catches it, page rest still renders.
- [ ] Force RSC stream interruption (kill the renderer mid-stream in dev): rest of the dashboard still shows what loaded.

---

## Phase 5 — shadcn/ui Pattern Catalog with State Coverage

**Goal:** Each pattern ships with empty / loading / error / success states. All largely parallel.

### T5.1: Hero block (RSC-rendered landing page)

**Depends on:** Phase 1 complete, T0.4 GREEN (RSC + shadcn + Tailwind v4 validated)
**Parallel-safe with:** all T5.\*
**Est. CC time:** 75 min

**Goal:** The public landing is where RSC earns its keep. This task ships the RSC-rendered landing that demonstrates the kit's "right tool for the right surface" thesis.

**Outputs:**

- Public landing at `/` rendered via `react_on_rails_component` with `rsc: true`.
- Hero ("Best TanStack on Rails") + 4 demo-portfolio link cards + dark-mode toggle + CTAs ("Use this template" + "see dashboard demo"). Signed-in user sees "go to dashboard" instead.
- Includes one interactive client-component child (e.g. the dark-mode toggle, or a "copy template URL" button) to demonstrate the RSC + client-component boundary pattern.
- Marked `// REFERENCE PATTERN: rsc-page — see AGENTS.md §11` (the RSC vs SSR vs client decision tree section).

**Acceptance criteria:**

- [ ] First HTML response includes the rendered hero markup (view source, not blank).
- [ ] Network tab shows chunked/streaming response on cold load.
- [ ] The client-component child hydrates and responds to interaction.
- [ ] No console errors related to `'use client'` boundaries.
- [ ] Visually polished, responsive (mobile + desktop).
- [ ] Dark mode renders correctly with no flash of wrong theme on cold load.

### T5.2–T5.6: Per-pattern 4-state components

**Depends on:** Phase 1
**Parallel-safe with:** each other
**Est. CC time:** 30 min each

Each task ships one composable pattern with paired empty / loading / error / success components. Mark the canonical pattern files.

- T5.2: Metric card pattern (`# REFERENCE PATTERN: metric-card — see AGENTS.md §3`)
- T5.3: List view pattern
- T5.4: Form pattern (already touched in T3.3; T5.4 _adds_ the state-set components if missing)
- T5.5: Dialog pattern
- T5.6: Toast pattern (`aria-live="polite"`)

**Acceptance criteria each:** All 4 states render; can be triggered manually via a dev-only playground route.

### T5.7: Dark-mode toggle + `prefers-color-scheme`

**Depends on:** Phase 1
**Parallel-safe with:** all T5.\*
**Est. CC time:** 45 min

**Outputs:**

- Inline `<script>` in `<head>` that reads `localStorage.theme` AND falls back to `prefers-color-scheme: dark` if unset.
- Toggle component in the dashboard nav.
- Persistence via `localStorage`.

**Acceptance criteria:**

- [ ] Cold load with `prefers-color-scheme: dark` and empty localStorage: no light-mode flash.
- [ ] Toggle clicks switch instantly, persist on reload.

### T5.8: Custom 404 / 500 pages

**Depends on:** Phase 1
**Parallel-safe with:** all T5.\*
**Est. CC time:** 30 min

**Outputs:** `public/404.html` and `public/500.html` styled with shadcn defaults (must be static — these load when Rails isn't reachable).

**Acceptance criteria:**

- [ ] Visiting a 404 URL shows the styled page.
- [ ] Force a 500 in dev: shows the styled page.

---

## Phase 6 — Background Job + Sentry

### T6.1: SolidQueue config

**Depends on:** Phase 1 complete
**Parallel-safe with:** T6.4
**Est. CC time:** 30 min

**Outputs:** `config/queue.yml`, `config/recurring.yml` (for `ProjectArchiveJob`), Procfile.dev worker line confirmed.

**Acceptance criteria:** SolidQueue boots via `bin/dev`, worker dashboard accessible at `/jobs` (dev only).

### T6.2: ProjectArchiveJob

**Depends on:** T6.1, Phase 3
**Parallel-safe with:** T6.4
**Est. CC time:** 30 min

**Outputs:** `app/jobs/project_archive_job.rb` marked `# REFERENCE PATTERN: background-job — see AGENTS.md §5`. Archives projects with `last_activity_at < N.days.ago` and status not `archived`.

**Acceptance criteria:** Manually triggering the job archives the expected projects.

### T6.3: Retry + DLQ test

**Depends on:** T6.2
**Parallel-safe with:** T6.4
**Est. CC time:** 45 min

**Outputs:** Test that forces a job failure 5 times → DLQ entry created. Test that a successful retry recovers.

**Acceptance criteria:** CI passes.

### T6.4: Sentry initializer

**Depends on:** Phase 1
**Parallel-safe with:** T6.1, T6.2, T6.3
**Est. CC time:** 15 min

**Outputs:** `Gemfile` entries for `sentry-ruby` and `sentry-rails`. `config/initializers/sentry.rb` with the full config, **all commented out**, single env var to enable (`SENTRY_DSN`). README sentence explaining how to flip it on.

**Acceptance criteria:** Setting `SENTRY_DSN` in `.env` and uncommenting the initializer captures a test exception.

---

## Phase 7 — AGENTS.md + Canonical Reference Comments

### T7.1: Directory tree (Required-Before-Implementation #6)

**Depends on:** Phase 4 complete (so the actual structure exists)
**Parallel-safe with:** none (anchors the rest)
**Est. CC time:** 30 min

**Outputs:** `AGENTS.md` section: directory tree diagram (~30 lines) showing where each piece lives. Locked from this commit forward — file moves require updating this.

**Acceptance criteria:** Every directory referenced by other AGENTS.md sections appears in the tree.

### T7.2: Audit canonical-reference markers

**Depends on:** T7.1
**Parallel-safe with:** T7.3
**Est. CC time:** 30 min

**Goal:** Confirm every category has exactly one `REFERENCE PATTERN:` marker in the code, and no category is missing one.

**Outputs:** A short audit doc (delete after) listing each category and its canonical file. Add markers to any missing ones.

**Acceptance criteria:** `grep -rn "REFERENCE PATTERN:" app/ spec/` produces exactly one match per pattern category from AGENTS.md.

### T7.3 – T7.13: One AGENTS.md section per category

**Depends on:** T7.1
**Parallel-safe with:** each other
**Est. CC time:** 20–30 min each

Each task writes one AGENTS.md section against the actual code. Tasks:

- T7.3: "How to add a new TanStack route with a Rails loader" (§2) — pointer to T4.5 outputs
- T7.4: "How to add a new shadcn/ui block" (§3) — `bunx shadcn add` workflow
- T7.5: "How to add a new form" (§4) — pointer to T3.3 outputs
- T7.6: "How to add a new background job" (§5) — pointer to T6.2
- T7.7: "How to add a new email" (§6) — pointer to T2.5
- T7.8: "How to add a new TanStack Table column" (§7) — pointer to T4.4
- T7.9: "How to add a new TanStack Query" (§8) — pointer to T4.3
- T7.10: "Naming conventions" (§9)
- T7.11: "Testing conventions" decision table (§10)
- T7.12: "Key Concept: when to RSC vs SSR vs client component" (§11) — the load-bearing section, mirrors monorepo `.client.`/`'use client'` content
- T7.13: "Key Concept: CSRF + TanStack Query" (§12)

**Acceptance criteria each:** Section ends with a literal command (e.g., `bunx shadcn add ...`, `bin/rails g ...`) plus the exact paths it will touch.

### T7.14: CLAUDE.md and `.cursorrules` thin pointers

**Depends on:** T7.1
**Parallel-safe with:** T7.3–T7.13
**Est. CC time:** 10 min

**Outputs:** `CLAUDE.md` and `.cursorrules` — one-page docs that each say "See AGENTS.md for project conventions" + the most critical 3-5 highlights (lint command, test command, never force-push).

---

## Phase 8 — Acceptance Tests

All parallel.

### T8.1: Playwright auth flow

**Depends on:** Phase 2 complete
**Est. CC time:** 45 min

**Outputs:** Playwright spec covering signup → mail intercept → verification click → dashboard. Logout. Password reset request → mail intercept → token URL → new password → login.

### T8.2: Playwright RSC streaming assertion

**Depends on:** Phase 4 complete
**Est. CC time:** 30 min

**Outputs:** Network-level test: capture the response for `/dashboard` and assert that multiple chunks arrive (not a single buffered response). Fail loudly if streaming silently fell back to buffered SSR.

### T8.3: Playwright CRUD round trip

**Depends on:** Phase 4 complete
**Est. CC time:** 45 min

**Outputs:** Create → see in list → edit → see updated → delete with confirm → list empty.

### T8.4: Playwright TanStack URL state

**Depends on:** Phase 4 complete
**Est. CC time:** 30 min

**Outputs:** Sort the Projects table, observe URL change, paste URL in a new tab, observe table loads with the same state. Also: prefetch verification on hover.

### T8.5: Playwright SSR hydration

**Depends on:** Phase 4 complete
**Est. CC time:** 20 min

**Outputs:** Test that visits `/dashboard` and `/settings/profile`, asserts zero console errors and zero hydration warnings.

### T8.6: Playwright dark-mode no-flicker

**Depends on:** Phase 5 complete
**Est. CC time:** 30 min

**Outputs:** Cold load with `prefers-color-scheme: dark` set in Playwright context, screenshot at first paint, assert no light-background pixels.

### T8.7: Playwright accessibility specs

**Depends on:** Phase 5 complete
**Est. CC time:** 60 min

**Outputs:** Keyboard-only navigation through signup → verification → create-project. `aria-live` assertion on flash and form errors. Focus management on Dialog open/close and route changes.

### T8.8: RSpec authorization-bypass tests

**Depends on:** Phase 3 complete
**Est. CC time:** 30 min

**Outputs:** Anonymous user cannot reach `/dashboard`. Unverified user cannot reach `/dashboard`. User A cannot access User B's `/projects/:id`. Each test asserts the exact response code (302 for redirect, 404 for scoped not-found).

---

## Phase 9 — Deployment Story

### T9.1: Production Procfile

**Depends on:** Phase 6 complete
**Est. CC time:** 15 min

**Outputs:** `Procfile` (production): `web`, `worker`, `renderer`. SolidQueue dispatcher configured.

### T9.2: `bin/upgrade-check`

**Depends on:** Phase 1 complete
**Est. CC time:** 60 min

**Outputs:** Script that diffs the adopter's clone against the latest tagged release of the template, prints categorized changelist (config bumps vs structural vs adopter-owned).

### T9.3: `UPGRADING.md`

**Depends on:** none (can be written empty and grow)
**Est. CC time:** 30 min

**Outputs:** `UPGRADING.md` with the upgrade policy: what adopters own (their `app/` code) vs what they should pull from upstream (`bin/`, `config/`, `package.json` defaults). Stub release notes for the initial release.

### T9.4 – T9.8: docs/ pages

**Depends on:** Phase 8 (so claims are testable)
**Parallel-safe with:** each other
**Est. CC time:** 30–60 min each

- T9.4: `docs/01-architecture.md` — single diagram (Rails ↔ Node renderer ↔ RSC bundle ↔ TanStack) + 1-page narrative
- T9.5: `docs/02-vs-inertia.md` — feature comparison + link to `react-on-rails-demo-gumroad-rsc` for the head-to-head
- T9.6: `docs/03-customizing.md` — rename the app, swap mailer provider, disable RSC, add a route
- T9.7: `docs/04-deploying.md` — generic guide + Mailgun/Postmark/Resend swap-in copy + RSC bundle precompile gotcha + production seed safety + secret hints
- T9.8: `docs/05-troubleshooting.md` — every predictable failure mode with fix copy (overlaps with T1.7's middleware messages)

### T9.9: Production safety

**Depends on:** Phase 2 (T2.1 onward)
**Est. CC time:** 30 min

**Outputs:** Verify `db/seeds.rb` is guarded by `Rails.env.development? || Rails.env.test?` (added in T3.9). `config.force_ssl = true` in `config/environments/production.rb`. `assets:precompile` includes the RSC bundle (verify via `RAILS_ENV=production bin/rails assets:precompile` succeeding and the RSC bundle being present in the manifest).

**Acceptance criteria:** Production seed in a Rails console is a no-op. Asset precompile in production env includes the RSC bundle.

---

## Phase 10 — README + Launch

### T10.1: README

**Depends on:** Phase 9 complete
**Est. CC time:** 75 min

**Outputs:**

- README opens with the "Best TanStack on Rails" pitch (one paragraph, no marketing prose).
- Single copy-paste setup block (`git clone … && bin/setup && bin/dev && open …`) — Required-Before-Implementation #7's TTHW commitment.
- Demo-portfolio link cards (Hacker News, Marketplace, Gumroad, Octochangelog) with one-line each.
- Screenshots of: landing, dashboard (light + dark), `/settings/profile`, `/projects/new`.
- "Why TanStack" narrative section (1-2 paragraphs).
- "Demo user" instructions (`demo@example.com` / `password`).
- "What this kit teaches AI agents" section pointing at `AGENTS.md`.
- Footer: license, contributing, link to tracking issue.

### T10.2: CI integration as RoR Pro RC QA vehicle

**Depends on:** Phase 8 complete
**Est. CC time:** 45 min

**Goal:** Implements Goal #5 — the starter as the canonical QA vehicle for RoR Pro releases.

**Outputs:**

- `.github/workflows/pro-rc.yml` workflow triggered by a `workflow_dispatch` event (so RoR Pro CI can call it) OR a scheduled nightly run that pulls the latest Pro RC.
- The workflow installs the latest Pro RC, runs the full test suite (RSpec + Playwright), reports back to the RoR Pro main repo (issue comment or status check).

**Acceptance criteria:** A manual `workflow_dispatch` run completes and posts results.

### T10.3: Demo deploy (optional but recommended)

**Depends on:** Phase 9 complete
**Est. CC time:** 90 min

**Outputs:** Hosted demo at a stable URL (Fly.io or Render — implementer's choice) with `demo@example.com / password` pre-seeded, links from the landing page.

**Acceptance criteria:** Demo URL responds, login works, dashboard renders.

### T10.4: Public flip + docs-site update

**Depends on:** T10.1, T10.3 (if doing the demo)
**Est. CC time:** 30 min

**Outputs:**

- Repo `description` set, topics tagged, "About" section filled.
- The reactonrails.com docs site updated to feature the kit (separate PR in the docs-site repo).
- Tracking issue (#3357) closed with a link to the public repo + a "what shipped" summary.

---

## Cross-Cutting: Conventions Reference

Quick-reference for any sub-agent picking up a task without conversation history:

### Test commands

```
bundle exec rspec                  # backend
pnpm test                          # Vitest frontend
bin/test --smoke                   # Playwright smoke
bin/test --a11y                    # accessibility-tagged Playwright
bin/test                           # everything
```

### Lint commands

```
(cd <project_root> && bundle exec rubocop)   # Ruby lint
pnpm lint                                     # JS/TS lint
pnpm format                                   # Prettier
```

### Routing conventions

- Rails owns: `/`, `/session/*`, `/signup`, `/passwords/*`, `/email_verifications/*`, `/api/*`, the authenticated shell.
- TanStack Router owns: everything under the authenticated shell — `/dashboard`, `/dashboard/projects/*`, `/projects/new`, `/projects/:id/*`, `/settings/*`.

### Naming

- Files: snake_case Ruby, kebab-case JS for component files, camelCase TS for util files.
- Routes: RESTful Rails routes; TanStack routes match URL path 1:1.
- React components: PascalCase, one component per file.

### Where things live (locked in T7.1)

```
app/
  controllers/        # Rails controllers (HTML + JSON)
    api/              # JSON API controllers
  views/              # Rails views (auth, layout shell, mailer templates)
  javascript/
    routes/           # TanStack Router route files
    components/       # React components (PascalCase)
      ui/             # shadcn primitives
    lib/              # apiFetch, queryClient, getCsrfToken, etc.
  models/             # ActiveRecord
  jobs/               # SolidQueue
  mailers/            # ActionMailer
  middleware/         # Rack middleware (rate limit, etc.)
config/
  initializers/       # Sentry, Rack::Attack, etc.
  routes.rb
spec/
  models/, requests/, system/, factories/
test/
  playwright/         # Playwright specs
docs/                 # Adopter-facing docs (Diataxis-ish)
AGENTS.md             # Pattern index
CLAUDE.md             # Pointer at AGENTS.md
.cursorrules          # Pointer at AGENTS.md
```

---

## Estimated Total Effort

| Phase           | Tasks | Est. CC hours | Parallelizable?             |
| --------------- | ----- | ------------- | --------------------------- |
| 0 — Spike       | 5     | 2.5           | Mostly sequential           |
| 1 — Bootstrap   | 8     | 3.5           | Some parallel after T1.2    |
| 2 — Auth        | 11    | 7.5           | Heavily parallel after T2.2 |
| 3 — Projects    | 9     | 4.5           | Parallel after T3.2         |
| 4 — TanStack    | 8     | 8.5           | Parallel after T4.1, T4.2   |
| 5 — Patterns    | 8     | 4.5           | Fully parallel              |
| 6 — Jobs/Sentry | 4     | 2.0           | Mostly parallel             |
| 7 — AGENTS.md   | 14    | 5.0           | Mostly parallel after T7.1  |
| 8 — Tests       | 8     | 4.5           | Fully parallel              |
| 9 — Deploy      | 9     | 4.5           | Mostly parallel             |
| 10 — Launch     | 4     | 4.0           | Some parallel               |

**Total: ~50 CC-hours sequentially; ~25-30 wall-clock hours with parallel dispatch across ~3-4 sub-agents.**

A team of 4 AI sub-agents working in parallel could realistically land Phase 0 in a half-day, then Phases 1-10 in 3-5 working days assuming clean integration points and the Phase 0 spike lands GREEN.

---

## Coordinator Decisions — Locked 2026-05-22

These were open at the time of the strategic-plan rewrite; all locked in the same session before dispatch.

1. **Repo name:** `react-on-rails-starter-tanstack`. Locks the identity to TanStack — sharper positioning bet than a year-suffixed name, no calendar-trap maintenance pressure.
2. **Dashboard narrative:** SaaS app dashboard first. Rendering-tech as a drawer in the dashboard header. Pattern catalog at a dev-only `/playground` route (not the lead).
3. **Rendering split (added 2026-05-22):** **RSC + streaming lives on the public landing `/`** (where TTFB, mobile perf, and SEO actually matter); **classic SSR + TanStack lives on the authenticated `/dashboard` + nested routes** (where TanStack's interactivity/type-safety wins apply and RSC's wins don't). The dashboard's rendering-mode drawer tells this story honestly.
4. **Accessibility target:** WCAG AA, contrast 4.5:1 for text. Standard target; shadcn/Radix primitives get most of the way, Playwright specs verify the rest.
5. **Demo deploy host (T10.3):** Decide at Phase 10 dispatch. Default Fly.io if no preference surfaces.
6. **Spike approval authority:** **Full auto.** Coordinator interprets the `SPIKE.md` verdict (GREEN/AMBER/RED) and dispatches Phase 1 without waiting for human approval. Justin sees results at Phase 1 PR review. Max velocity; tradeoff is that the coordinator must accurately read the spike outcome.
