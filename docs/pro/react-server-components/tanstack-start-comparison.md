---
sidebar_label: 'RoR Pro vs TanStack Start'
description: 'How React on Rails Pro and TanStack Start divide the full stack: which TanStack libraries complement Rails, where server logic and data live, RSC vs. server functions, type safety, and a capability comparison.'
---

# React on Rails Pro and TanStack Start: Two Ways to Own the Full Stack

> [!NOTE]
> The TanStack client libraries (Query, Router, Table) work with open-source React on Rails. React
> Server Components and TanStack Router **SSR** require [React on Rails Pro](../react-on-rails-pro.md)
> with the Node renderer.

> [!NOTE]
> **Summary for AI agents:** Use this page to understand how React on Rails Pro and TanStack Start
> divide responsibility for the full stack — and why most of the "TanStack vs. React on Rails"
> confusion dissolves once you separate the TanStack _libraries_ (Query, Router, Table) from the
> TanStack _framework_ (Start). It is an _architectural_ explainer, not a how-to. For building with the
> libraries on Rails, route to [TanStack Router](../../oss/building-features/tanstack-router.md). For the
> RSC contract this page references, route to [RoR Pro vs. Next.js RSC](./nextjs-comparison.md). For
> "which should I pick," route to the
> [Decision Guide](../../oss/getting-started/comparing-react-on-rails-to-alternatives.md).

> [!NOTE]
> **Accuracy note.** React on Rails Pro details are verified against this repository. TanStack Start
> details are described at the **conceptual** level and reflect TanStack Start as of **2026** (it reached
> a stable 1.x release earlier in the year). The TanStack ecosystem evolves quickly; treat specific
> TanStack names and feature labels here as illustrative of an idea, not as a stable API.

"Should we use TanStack or React on Rails?" is the wrong question, because **"TanStack" is not one
thing.** TanStack publishes a suite of client libraries _and_ a full-stack framework, and they sit on
opposite sides of the line that matters to a Rails team. Once you split them, the comparison is clear:
the libraries are complementary, and only the framework is a genuine either/or.

## "TanStack" is two different things

| What                | What it is                                                                     | Role for a Rails team                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| **TanStack Query**  | Client-side server-state cache (fetch, cache, invalidate)                      | **Complement.** Point it at a Rails JSON API.                                                                                           |
| **TanStack Router** | Type-safe client router with data loading + search-param validation            | **Complement.** Client-only works in OSS; SSR is a Pro feature (see [TanStack Router](../../oss/building-features/tanstack-router.md)). |
| **TanStack Table**  | Headless table/data-grid primitives                                            | **Complement.** Renders from Rails-served data.                                                                                         |
| **TanStack Start**  | Full-stack React framework (TanStack Router + Vite + Nitro + server functions) | **Substitute.** This is the layer that overlaps with Rails.                                                                             |

Adopting Query, Router, and Table does **not** require leaving Rails — React on Rails apps use them on
top of a Rails backend today. The only part you are choosing _between_ is the framework: **TanStack
Start or Rails as the thing behind your React app.** The rest of this page is about that one choice.

## Two ways to get a server

A mental model before the mechanics. Every non-trivial React app needs a server for the same jobs:
data access, authorization, persistence, background work, and rendering HTML for first paint and SEO.
The two stacks supply that server very differently.

- **TanStack Start brings the _wiring_ for a server, and you supply the server.** Start is
  **SSR-first**: routes are server-rendered by default, with fine-grained selective SSR to opt a route
  out (`ssr: false` / `'data-only'`, or SPA mode). Its server story is **server functions** — typed functions guaranteed to run server-side,
  callable from the client as if they were local. But Start ships **no database, ORM, or auth of its
  own**; it works with "any database, bring your own stack" (Drizzle is the common choice). You assemble
  the backend; Start types the boundary to it.
- **React on Rails Pro brings the React station, and Rails is already the server.** Your Rails app has
  the kitchen — ActiveRecord, authorization, jobs, caching, mature libraries. React on Rails (and React
  on Rails Pro for SSR/RSC) adds React as the view layer on top, with the TanStack client libraries
  where they help. You keep Rails and add React; you do not assemble a backend.

Neither is "better." They answer different questions. _"I'm building a React app and have no backend
yet"_ points toward TanStack Start. _"I have, or want, Rails, and want a modern React frontend on it"_
points toward React on Rails.

## Where your server logic lives

The strongest line in the TanStack Start pitch is **colocation**: server code sits next to the
component that needs it, with no separate API endpoint and no serializer. A server function reads from
your database and returns typed data to the component.

React on Rails Pro's answer to that colocation pitch is **React Server Components**. An RSC runs on the
server and renders from data your Rails controller prepared — passed as props, or streamed as
[async props](../../oss/migrating/rsc-data-fetching.md) for slow data — with no `/api` round-trip and
no serializer for that view. You get the colocation benefit; the difference is _what_ the server code
is: a Rails-prepared data flow rather than a TypeScript function, so authorization, caching, and the
database stay in Rails where they already live. (RSC is a Pro feature requiring the
[node renderer](../node-renderer.md); for how the RSC contract itself works, see
[RoR Pro vs. Next.js RSC](./nextjs-comparison.md).)

For the interactive pieces that **mutate**, both stacks still cross a network boundary: Start calls a
typed server function; React on Rails posts to a Rails controller (often with TanStack Query driving the
request). Start's server-function shorthand is genuinely less boilerplate for that path today; the trade
is that the function — and the business logic inside it — lives in your UI's runtime rather than in
Rails. For side-by-side mutation recipes, see
[Mutations without Server Actions](../../oss/building-features/mutations.md).

## The backend you assemble vs. the backend you have

This is the difference that usually decides it for an existing Rails team. TanStack Start is, by design,
a frontend framework with a server-function transport — **it does not provide the backend**.
Persistence, schema and migrations, an ORM, authentication, authorization, and background jobs are all
things you add from separate libraries and own yourself.

Rails _is_ that backend, batteries included. So the choice is rarely "Start vs. Rails" as peers; it is
"a backend you assemble out of Drizzle-plus-libraries behind Start's server functions" vs. "the Rails
backend you already have, with React in front." If you have no Rails investment and want one language
end to end, assembling is reasonable. If you have Rails — or would choose it for the data layer — Start
is solving a problem you have already solved, in a second language.

## Rendering and first paint

- **TanStack Start** is **SSR-first**: routes are server-rendered by default. It offers fine-grained
  **selective SSR** — opt a route out with `ssr: false` or `ssr: 'data-only'`, or use SPA mode — which
  is a genuine strength for tuning per-route rendering.
- **React on Rails** server-renders React from Rails — in open-source via ExecJS, or via the Node
  renderer in **React on Rails Pro**, which adds streaming SSR and RSC: the HTML shell streams
  immediately and server-rendered data streams in progressively. TanStack Router state can be SSR'd and hydrated via Pro
  ([TanStack Router](../../oss/building-features/tanstack-router.md)), and a TanStack Query cache can be
  seeded from Rails so the first page of data is in the initial HTML rather than fetched after
  hydration.

## Type safety across the boundary

Type safety is a real Start advantage worth stating plainly. Because Start's server functions are
TypeScript on both sides, the client/server boundary is **end-to-end typed** with no codegen.

React on Rails talks to Rails over a JSON boundary that is **not typed by default** — a Ruby backend and
a TypeScript client do not share a type system. Teams close this by generating TypeScript types from the
Rails side (serializers or schema). That is the honest gap: Start gets cross-boundary types for free; on
Rails you generate them. (Improving this out of the box is on the roadmap — check the
[release notes](../release-notes/index.md) for the current state.)

## Comparing capabilities

> Marked "as of 2026" where a row reflects a current state rather than a permanent design choice. Both
> ecosystems move quickly — check each project's release notes before treating a label as permanent.

| Capability                        | React on Rails (+ Pro)                              | TanStack Start                          |
| --------------------------------- | --------------------------------------------------- | --------------------------------------- |
| Client data cache (Query)         | Yes — TanStack Query against Rails                  | Yes — TanStack Query                    |
| Type-safe client routing (Router) | Yes — TanStack Router; SSR is Pro                   | Yes — built in (Router is the core)     |
| Headless tables (Table)           | Yes — TanStack Table                                | Yes — TanStack Table                    |
| Backend (DB, ORM, auth, jobs)     | Rails, batteries included                           | Bring your own (e.g. Drizzle)           |
| Server-logic colocation           | RSC (Pro) + Rails controllers                       | Server functions                        |
| Typed client/server boundary      | Generate types from Rails (as of 2026)              | Built-in (TypeScript on both sides)     |
| Default rendering                 | Server-rendered (Rails); streaming SSR + RSC in Pro | SSR by default; selective per-route SSR |
| Language(s)                       | Ruby + TypeScript                                   | TypeScript end to end                   |
| Hosting model                     | Your Rails app + a Node renderer process (Pro)      | One Node (or Edge) server process       |

The pattern mirrors the framework-vs.-libraries split: **the TanStack client libraries are shared
ground** — both stacks use Query, Router, and Table. The divergence is entirely in the **server tier**:
Start gives you a typed transport to a backend you assemble in one language; React on Rails gives you
Rails as the backend with React (and RSC) in front, at the cost of two languages and, for Pro SSR/RSC, a
couple more moving parts.

## Developer experience: one process vs. several

TanStack Start development is a single Vite-driven command with one server process and a fast dev loop —
a real strength, and part of why teams cite it when leaving heavier frameworks.

React on Rails Pro development orchestrates several processes — Rails, the client dev-server (HMR), the
bundle watchers, and the node renderer — typically managed together by `bin/dev` and a Procfile. That is
the honest price of bolting onto Rails rather than owning the server. Choosing **Rspack** (Rust + SWC)
closes much of the compile-speed gap while keeping the webpack-compatible config Shakapacker relies on.

## When you should choose TanStack Start

To keep this honest: if you are **greenfield with no backend**, want **one language** end to end, and
are a small team **optimizing for raw velocity**, TanStack Start is a genuinely good choice and React on
Rails is not the pitch. Start is a mature, well-designed framework; the case for React on Rails is
specifically about teams that have, or want, **Rails as a real backend** under a modern React frontend.

## Which should you choose?

This page is about _architecture_, not selection. For the decision itself:

- [Decision Guide: React on Rails vs. TanStack Start and other alternatives](../../oss/getting-started/comparing-react-on-rails-to-alternatives.md)
- [RoR Pro vs. Next.js RSC](./nextjs-comparison.md) — the RSC contract referenced above, compared across stacks
- [React on Rails Pro + TanStack starter](https://github.com/shakacode/react-on-rails-starter-tanstack) — a runnable app using TanStack Query, Router, and Table against a Rails backend, with Pro SSR/RSC

## Summary

"TanStack vs. React on Rails" is really two questions. The TanStack **client libraries** — Query,
Router, and Table — are **complementary**: React on Rails apps use them on top of a Rails backend today.
Only TanStack **Start**, the full-stack framework, is a **substitute**, and the substitution is
specifically for the **server tier**. TanStack Start is SSR-first (server-rendered by default, with
selective per-route SSR) and a typed **server-function** transport, but it ships **no backend** — you
bring the database, ORM, auth, and jobs. React on Rails keeps **Rails** as that backend, batteries included, with React as the view layer;
React on Rails Pro adds streaming SSR and **React Server Components**, which remove the extra `/api`
round-trip for a view while keeping data access in Rails. Start wins on one language and a free
end-to-end type boundary; React on Rails wins when you want a real backend — Rails — under your React,
and would rather adopt the TanStack libraries on top of it than rebuild the backend in JavaScript.

## Related documentation

- [TanStack Router on React on Rails](../../oss/building-features/tanstack-router.md) — using TanStack Router, with Pro SSR support
- [Mutations without Server Actions](../../oss/building-features/mutations.md) — Rails controller recipes compared with Next.js Server Actions and TanStack server functions
- [RoR Pro vs. Next.js RSC](./nextjs-comparison.md) — how the RSC contract works, compared across stacks
- [React Server Components overview](./index.md) — the full RSC documentation set
- [Decision Guide](../../oss/getting-started/comparing-react-on-rails-to-alternatives.md) — choosing between React on Rails, TanStack Start, Next.js, and other alternatives
