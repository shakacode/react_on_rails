# Architecture Rewrite: Executive Summary

## Goal

Reduce internal complexity across `react_on_rails`, `react_on_rails_pro`, `react-on-rails`, `react-on-rails-pro`, and `react-on-rails-pro-node-renderer` while maintaining **100% backward compatibility** for end users.

## Constraints

- **Public API is frozen**: `react_component`, `react_component_hash`, `redux_store`, `server_render_js`, `ReactOnRails.register`, `ReactOnRails.registerStore`, render function signatures, renderer function signatures — all unchanged.
- **Internal protocols can break**: Communication between the Ruby gem and Node renderer, internal module boundaries, internal data formats — all fair game.
- **react_on_rails + node_renderer upgrade together**: Users always upgrade both simultaneously, so internal protocol changes are safe.

## Core Problems Identified

1. **Runtime conditional delegation** — `react_on_rails_pro?` checked at 7+ call sites to decide which code path runs. Creates invisible coupling and makes both packages hard to reason about independently.

2. **String-template JS code generation** — Ruby heredocs build JavaScript as strings with `#{}` interpolation. Two divergent implementations (core vs Pro) with no shared structure.

3. **Mixin-based method overriding** — `ProHelper` is `include`d into `Helper`, silently replacing methods. No explicit interface contract.

4. **Stub-throw pattern for optional features** — Core defines methods that throw "requires Pro" errors. Pro replaces them via `Object.assign`. Adding Pro features requires modifying core.

5. **Dual orthogonal classification systems** — File suffixes (`.client`/`.server`) and RSC directives (`'use client'`) are independent but generate interacting pack files.

6. **Monolithic rendering pipeline** — A single `server_rendered_react_component` method handles sync SSR, streaming SSR, RSC payload, caching, error handling, and console replay.

## Proposed Architecture

Replace the current delegation/override patterns with:

1. **Strategy pattern** for rendering backends (replaces runtime `react_on_rails_pro?` checks)
2. **Structured render request/response objects** (replaces string-built JS)
3. **Explicit extension points** via a `RenderingPipeline` (replaces mixin overrides)
4. **Capability-based feature discovery** (replaces stub-throw pattern on JS side)
5. **Unified component classifier** (replaces dual classification systems)
6. **Composable middleware pipeline** for rendering (replaces monolithic method)

## Impact Assessment

| Area                    | Files Changed | Risk   | Benefit                                         |
| ----------------------- | ------------- | ------ | ----------------------------------------------- |
| Ruby rendering pipeline | ~8 files      | Medium | High — removes all `react_on_rails_pro?` checks |
| JS code generation      | ~3 files      | Low    | High — structured, testable, debuggable         |
| JS factory/registry     | ~6 files      | Medium | High — removes stub-throw, enables tree-shaking |
| Pack generation         | ~2 files      | Low    | Medium — simpler classification                 |
| Node renderer protocol  | ~4 files      | Low    | Medium — cleaner contract                       |
| Helper methods          | ~3 files      | Low    | High — clear extension boundary                 |

## Documents

- `01-current-architecture-problems.md` — Detailed analysis of each problem with code references
- `02-rendering-pipeline.md` — The new rendering pipeline design (Ruby side)
- `03-js-code-generation.md` — Structured JS code generation
- `04-js-package-architecture.md` — New JS package design with capability-based features
- `05-node-renderer-protocol.md` — Simplified communication protocol
- `06-component-classification.md` — Unified component classification
- `07-migration-plan.md` — Step-by-step migration with backward compatibility verification
