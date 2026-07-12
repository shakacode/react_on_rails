---
status: accepted
date: 2026-07-11
---

# Rspack answers Vite — no Vite runtime support in the 17.x cycle

The Rails ecosystem's default "modern React" stack is inertia*rails + vite_ruby, so evaluators keep asking why React on Rails runs on Shakapacker/Rspack instead of Vite. We decided **not** to build Vite runtime support in the 17.x cycle: the RSC pipeline (react-on-rails-rsc plugin, client/server manifests, flight chunk handling) is built on the webpack/rspack plugin contract, RSC-on-Vite is still experimental across the entire ecosystem, and Rspack already delivers Vite-class dev speed (~20× build improvements in our benchmarks) \_with* production RSC — which Vite cannot do. Instead we invest in Rspack DX parity (HMR speed, zero-config startup, error overlays) and publish a "Why Rspack (and not Vite)" positioning page, so the objection is answered in the open rather than dodged.

## Considered options

- **Vite RFC for 18.0** (spike on the Vite Environment API, RSC excluded initially) — rejected for now: a large parallel investment while Rspack RSC productionization (#3488) is still in flight, and it would fork engineering attention during the window where onboarding + provable performance drive Pro installs.
- **Vite for the standard (non-RSC) tier only** — rejected: permanently splits the bundler story and doubles the support/CI matrix for the tier that differentiates us least.
- **Silent no** (no positioning content) — rejected: the question is asked constantly; leaving it unanswered costs evaluator trust.

## Consequences

- Bundler-neutral config naming (#2552) stays alive and lands in 18.0 so the door to Vite (or any bundler) stays open without another breaking cycle.
- Revisit trigger: funnel evidence that bundler choice is a primary bounce reason for evaluators, or RSC-on-Vite reaching production maturity upstream. Watch items (2026-07): `@vitejs/plugin-rsc` (official under the vitejs org, pre-1.0, already the base for React Router's RSC framework mode) and Rspack 2.x's built-in experimental RSC (`react-server-dom-rspack` — a young fork of the wire packages; our webpack-package pipeline does not transfer 1:1, which informs the #3488 native-plugin pivot).
- The "Why Rspack" page becomes part of the public positioning surface and must be kept honest — if Rspack DX parity claims stop being true, the page and this decision both come up for review.
