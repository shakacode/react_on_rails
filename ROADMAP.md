# React on Rails Roadmap

_Last updated: 2026-07-11 · Maintained by [ShakaCode](https://www.shakacode.com) · Live status: [roadmap umbrella #4607](https://github.com/shakacode/react_on_rails/issues/4607) and [GitHub milestones](https://github.com/shakacode/react_on_rails/milestones)_

React on Rails 17.0.0 is shipping now. This document says where the project goes next and why, so evaluators and contributors can see the direction before committing.

## North star

Make **React on Rails Pro the obvious way to run modern React on a Rails backend** — for new apps, for teams migrating from Inertia or a separate Next.js frontend, and for existing React on Rails users upgrading. Pro is [trust-licensed](./REACT-ON-RAILS-PRO-LICENSE.md): freely installable, paid for production use, free for evaluation, education, and qualifying open source.

## Three commitments

Every release headlines one of these; nothing headlines anything else.

### 1. Provable performance

Performance claims ship with a public, reproducible artifact — or they don't ship.

- **Current proof:** the [Gumroad RSC comparison](https://gumroad.reactonrails.com/rsc-demo) — React Server Components vs an Inertia control on real product pages: ~48%/43% faster browser navigation, ~44% less HTML+JS delivered.
- **Structural position:** streaming SSR, React Server Components, partial hydration, and async server props with no API layer — on a persistent Node renderer wired to `Rails.cache`. The Inertia stack has none of these (synchronous `renderToString`, monolithic SSR bundle, no RSC); Next.js has them but demands its own runtime and data layer.
- **Next:** Partial Pre-Rendering on React 19.2's now-stable `prerender`/`resume` APIs. An internal prototype showed a ~36× warm-TTFB improvement; per this roadmap's own standard, that number graduates to a headline claim only when the 17.2 work ships its public, reproducible artifact ([#3571](https://github.com/shakacode/react_on_rails/issues/3571)). CSS-gated streamed reveals shipped in 17.0.0 — streamed pages no longer flash unstyled content; 17.1 adds the production CI gate that keeps it true.

### 2. Onboarding simplicity

The bar is Inertia's: one command and it works. `npx create-react-on-rails-app` (Pro-enabled by default) is that command; the roadmap tracks time-to-first-success and works-on-first-try as regressions, same as performance.

### 3. Agent-native development

AI coding agents increasingly choose the stack. React on Rails treats them as first-class developers: scaffolded `AGENTS.md` with the top runtime errors and fixes (shipped), `bin/rails react_on_rails:doctor`, `llms.txt`/`llms-full.txt`, and agent-legible error output. `llms.txt`/`llms-full.txt` generation with a CI drift guard shipped and is verified live. The 17.x cycle extends this with an agent-legible doctor, an agent-builds-the-app tutorial + eval, and an agent toolchain informed by where the ecosystem landed (Next.js 16.3's bundled version-matched docs + Skills; TanStack's and Inertia's agent Skills).

## Release plan

### 17.1 — onboarding + agent content _(target: ~6–8 weeks after 17.0.0 final)_

The "instant to start" release. Non-breaking.

- FOUC pipeline finished — production CI gate + simplification to the manifest-hint layer ([#4557](https://github.com/shakacode/react_on_rails/issues/4557); the reveal gating itself shipped in 17.0.0)
- Security hardening cluster from the 2026-07 reviews — RSC payload endpoint authorization, node-renderer hardening, log hygiene ([#4595](https://github.com/shakacode/react_on_rails/issues/4595)–[#4597](https://github.com/shakacode/react_on_rails/issues/4597))
- Agent-legible doctor and error output — structured `--format=json`, copy-promptable fixes ([#4602](https://github.com/shakacode/react_on_rails/issues/4602))
- "An agent builds a React on Rails Pro app" tutorial + scripted eval ([#4603](https://github.com/shakacode/react_on_rails/issues/4603))
- Pro license token via Rails credentials — customer-requested onboarding fix ([#4553](https://github.com/shakacode/react_on_rails/issues/4553))
- Onboarding quick wins from the 2026-07 backlog triage (`llms.txt`/`llms-full.txt` generation already shipped and verified live — [#3896](https://github.com/shakacode/react_on_rails/issues/3896))
- React 19.2 security-hardened RSC baseline (react-on-rails-rsc ≥ 19.2.x line)

### 17.2 — the numbers release

The "prove it" release. Non-breaking.

- **Partial Pre-Rendering productionized** ([#3571](https://github.com/shakacode/react_on_rails/issues/3571)) — static shell + streamed resume, on stable React 19.2 APIs, with a Gumroad-style public artifact
- Benchmark CI re-enabled as a gate with published results ([#3169](https://github.com/shakacode/react_on_rails/issues/3169))
- Rspack RSC production path ([#3488](https://github.com/shakacode/react_on_rails/issues/3488))
- Agent toolchain v2: Skills shipped in-package; minimal MCP re-evaluated against ecosystem evidence
- "Why Rspack (and not Vite)" positioning page — the decision is recorded in [internal/adr/0001](./internal/adr/0001-rspack-answers-vite.md)

### 18.0 — the breaking batch _(unscheduled; ships when the batch justifies it)_

Breaking changes are locked out of 17.x and accumulate here:

- Redux phase-out from the new-app path ([#4271](https://github.com/shakacode/react_on_rails/issues/4271), [#4274](https://github.com/shakacode/react_on_rails/issues/4274), [#4279](https://github.com/shakacode/react_on_rails/issues/4279))
- Bundler-neutral config file naming ([#2552](https://github.com/shakacode/react_on_rails/issues/2552))
- Deferred breaking cleanups collected during 17.x

### Continuous (every release)

- React feature adoption tracking ([#3865](https://github.com/shakacode/react_on_rails/issues/3865)) — 19.2 shipped; ViewTransition and the Compiler's Rust port are the next watch items
- DX parity with the Inertia stack where evaluator feedback demands it (forms, routing, image/RUM helpers)
- Docs, comparisons, and the official demo fleet

## Ecosystem watch _(2026-07 snapshot)_

| Signal                          | State                                                                                    | Our position                                                                                            |
| ------------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| React 19.2 `prerender`/`resume` | Stable                                                                                   | Foundation for PPR in 17.2                                                                              |
| React `<ViewTransition>`        | Canary; 19.2 reveal-batching prepares it                                                 | Adopt when stable; streaming already aligned                                                            |
| React Compiler                  | 1.0 stable; Rust port merged upstream                                                    | Recipe shipped; revisit default-on when frameworks do                                                   |
| Next.js 16.3                    | Instant Navigations, agent DX (bundled docs, Skills, slim MCP)                           | Direction reference for agent-native + caching discipline                                               |
| RSC on Vite / Rspack            | `@vitejs/plugin-rsc` consolidating; Rspack 2.x ships experimental native RSC             | Watch items for [ADR-0001](./internal/adr/0001-rspack-answers-vite.md); native Rspack RSC informs #3488 |
| Inertia v3 + inertia_rails      | Fast-moving (Evil Martians maintainership); still no RSC/streaming SSR/partial hydration | Match their simplicity; extend the structural performance lead                                          |

## How to influence this roadmap

Open an issue with your use case — customer evidence outranks everything else in triage. Issues are labeled by theme (`theme:performance`, `theme:onboarding`, `theme:agent-native`, …) and scheduled via the [17.1 / 17.2 / 18.0 milestones](https://github.com/shakacode/react_on_rails/milestones). Commercial support and consulting: [react_on_rails@shakacode.com](mailto:react_on_rails@shakacode.com).
