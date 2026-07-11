# Context Map

## Contexts

- [React on Rails Pro (RSC)](./packages/react-on-rails-pro/CONTEXT.md) — React Server Components integration: payload generation, embedding, caching, and client-router prefetch
- [React on Rails Pro (Rolling Deploy)](./react_on_rails_pro/CONTEXT.md) — warming the Node Renderer bundle cache across a rolling deploy: pre-seed source, build-time vs. release-time seed, staging-to-production promotion

Other contexts (core gem, node renderer, generators) are not yet documented; add them here when their first term is resolved.

## Relationships

- **Rolling Deploy → RSC**: when RSC is enabled, each deploy has two **draining bundles** (server + RSC); the pre-seed stages each hash independently and must carry the RSC companion manifests or hydration breaks.
