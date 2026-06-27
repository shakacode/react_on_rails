---
sidebar_label: 'Decision Guide'
description: Narrative decision guide for choosing React on Rails vs Hotwire, Inertia, Next.js, TanStack Start, Vite, and react-rails.
---

# Comparing React on Rails to Alternatives

If you are evaluating frontend approaches for a Rails application, the right choice depends on how much of your UI should live in React, how much Rails should keep rendering, and whether server rendering is a requirement from day one.

This page is intentionally practical. It focuses on the tradeoffs teams usually care about when choosing between React on Rails, Hotwire/Turbo, Inertia Rails, a Next.js frontend with a separate Rails backend API, TanStack Start, react-rails, and Vite as a build tool.

## Short Version

Choose **React on Rails** when you want Rails and React tightly integrated, you expect a meaningful amount of React UI, and you want server rendering and fast builds provided by Rspack, or a path to React on Rails Pro features such as React Server Components and streaming SSR.

Choose **Hotwire/Turbo** when Rails-rendered HTML is still your preferred model and you only need modest JavaScript sprinkles or progressive enhancement.

Choose **Inertia Rails** when you want its controller-to-page-props protocol and a frontend shell as the main rendering model. Be aware that every page navigation requires a server round-trip, code splitting is limited to route-level lazy loading (no component-level splitting with SSR), and adopting Inertia replaces your Rails views at the per-route level rather than letting you integrate React incrementally into existing templates.

Choose **Next.js + separate Rails backend** when you want a hard frontend/backend boundary and are prepared to run two apps with an explicit API contract between them.

Choose **TanStack Start** when you are greenfield with no existing Rails backend, want a single language across client and server, and are optimizing for raw velocity. If you have, or want, Rails, adopt the TanStack client libraries (Query, Router, Table) on top of Rails instead.

If you are currently on **react-rails**, prefer the migration path to React on Rails rather than starting new work on react-rails.

## At a Glance

| Option                   | Primary view model                                                  | Best fit                                                                                   | What to watch                                                                                                                                         |
| ------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **React on Rails**       | Rails views rendering React components with tight Rails integration | Existing Rails apps, SSR, mixed Rails + React pages, progressive adoption                  | More setup than lightweight helper-based integrations                                                                                                 |
| **Hotwire/Turbo**        | Rails renders HTML, Turbo updates the page                          | Rails-first apps with minimal client-side complexity                                       | Not a React solution, so React ecosystem reuse is limited                                                                                             |
| **Inertia Rails**        | Controllers return page props to a client-rendered frontend shell   | Teams that want SPA-style page transitions without building a separate JSON API first      | Every navigation is a server round-trip; replaces Rails views per-route rather than incremental adoption; review current SSR support in official docs |
| **Next.js + Rails API**  | Next.js app consumes Rails API responses                            | Teams prioritizing frontend autonomy, edge delivery, or multi-client API reuse             | Two deployables, duplicated auth/session concerns, and stricter API lifecycle management                                                              |
| **TanStack Start**       | Full-stack React framework (client-first; SSR opt-in per route)     | Greenfield React apps with no existing backend; one-language teams optimizing for velocity | Bring-your-own backend (database, ORM, auth, jobs); business logic runs in the JS runtime                                                             |
| **react-rails (legacy)** | Rails views mount React components with helper-based integration    | Existing legacy apps already on react-rails                                                | Maintenance-focused path; plan migration to React on Rails for newer capabilities                                                                     |

## React on Rails vs Hotwire/Turbo

Hotwire/Turbo is strongest when your team wants to keep Rails fully in charge of the HTML response lifecycle. It is a good fit for CRUD-heavy applications, low-JavaScript back offices, and teams that prefer Stimulus plus server-rendered views over a React-centric frontend architecture.

React on Rails is the better fit when your product already benefits from React's component model, third-party React libraries, complex client-side state, or reusable frontend architecture across many pages. It lets you keep Rails as the backend and routing layer while still using React as the main UI model where needed.

Choose Hotwire/Turbo if your goal is "stay mostly Rails views."

Choose React on Rails if your goal is "build substantial React UI without splitting Rails away from the app."

Official docs:

- [Hotwire Turbo handbook](https://turbo.hotwired.dev/handbook/introduction)

## React on Rails vs Inertia Rails

Inertia Rails uses Rails controllers to feed props into a frontend-driven page shell. That can feel closer to an SPA workflow while still avoiding a fully separate API for many use cases.

However, the two frameworks make fundamentally different integration and performance tradeoffs.

### Integration model

React on Rails lets you drop a `react_component` call into any ERB or Haml template. Props flow directly from the controller or view — no API layer, no JSON endpoint, no frontend shell. You can add React to a single section of a single page and leave the rest of your Rails views untouched. This makes incremental adoption straightforward: start with one interactive widget and expand from there.

Inertia replaces the Rails view layer on a per-route basis. A controller action either returns an Inertia response or a traditional Rails response. You cannot embed a React component into part of an existing ERB template through Inertia — the entire page for that route becomes an Inertia page. For existing Rails applications with many views, this is a much larger adoption commitment.

### Performance tradeoffs

Every standard Inertia page navigation requires a round-trip to a Rails controller action that serializes the page props as JSON. (Back/forward browser navigation may use cached page state, but all forward navigations — link clicks, `router.visit()` calls — hit the server.) This means:

- **Server round-trip on every navigation.** Perceived performance depends on Rails response time for every page transition, not just the initial load.
- **Full page props serialized by default.** Inertia v2 adds [partial reloads](https://inertia-rails.dev/guide/partial-reloads) to request a subset of props, but the server round-trip is still required for every navigation and large prop sets still add serialization overhead.
- **Code splitting limited to route-level lazy loading.** Inertia supports lazy-loaded page bundles via dynamic imports, but there is no component-level code splitting with SSR. React on Rails **Pro** supports granular code splitting via Loadable Components, so individual components within a page can be split and SSR'd independently. (This is a Pro feature, not available in the OSS gem.)
- **No streaming SSR.** Inertia's opt-in SSR renders the complete page before sending any HTML to the browser. React on Rails **Pro** streams progressively with `renderToPipeableStream`, so users see content faster on complex pages. (This is a Pro feature, not available in the OSS gem.)

With React on Rails and a client-side router (for example TanStack Router in Pro), after the initial server-rendered page load, subsequent navigations can be handled entirely in JavaScript — fetching only the data each component needs and loading route-specific bundles on demand.

### Other differences

- **Controller coupling.** Inertia controllers return `inertia:` responses tied to the Inertia protocol. Switching to a different frontend approach later requires rewriting those controller actions. React on Rails uses standard Rails rendering with a view helper, so your controllers stay conventional.
- **No React Server Components or fragment caching.** Inertia has no path to RSC or per-component caching. React on Rails Pro supports both.
- **Multi-framework vs React-focused.** Inertia supports React, Vue, and Svelte, which is useful if your team works across frameworks. React on Rails is purpose-built for deep React integration with Rails.

### When to choose which

Choose Inertia Rails if you are building a new app from scratch, want SPA-style page transitions, and are comfortable replacing the Rails view layer entirely.

Choose React on Rails if you want to integrate React into existing Rails views incrementally, need server rendering with code splitting or streaming, or want the upgrade path to React on Rails Pro features like React Server Components.

Ready to switch? See the [Inertia Rails migration guide](../migrating/migrating-from-inertia-rails.md) — both gems can coexist in one app, so you can migrate route by route.

Official docs:

- [Inertia Rails documentation](https://inertia-rails.dev/)
- [Inertia Rails SSR guide](https://inertia-rails.dev/guide/server-side-rendering)

## React on Rails vs Next.js + Separate Rails Backend

This is a common architecture question for teams that want React but are unsure whether to keep a tightly integrated Rails stack or split frontend and backend into separate apps.

**Next.js + separate Rails backend:**

- Pros: strong frontend autonomy, clean ownership boundaries, and easier reuse of the same backend API across web/mobile clients.
- Drawbacks: two deployments, separate observability surfaces, cross-app auth/session complexity, and ongoing API contract/versioning work.

**React on Rails:**

- Pros: unified Rails + React architecture, no mandatory separate API layer for server-rendered pages, and simpler end-to-end debugging through one app boundary.
- Potential performance advantages: fewer cross-service hops for server-rendered requests, less API serialization/deserialization overhead, and easier coordination of caching across the stack.
- Drawbacks: less organizational separation than a hard API split, and fewer opportunities to isolate frontend/backend release trains.

Choose Next.js + separate Rails backend when your priority is platform separation and API-first product architecture.

Choose React on Rails when your priority is delivering substantial React UI while keeping Rails views/helpers and one integrated deployment model.

If this architecture is central to your evaluation, see the dedicated guide: [Next.js with a Separate Rails Backend: Pros and Drawbacks](./nextjs-with-separate-rails-backend.md).

If React Server Components are central to your evaluation, see how the two stacks implement RSC at the architecture level — and the one ownership difference that drives the rest — in [React on Rails Pro and Next.js: RSC Architectures Compared](../../pro/react-server-components/nextjs-comparison.md).

## React on Rails vs TanStack Start

TanStack Start is a full-stack React framework built on TanStack Router and Vite. Unlike the Next.js App Router model, it is client-first: client-side interactivity is the default, and you opt into server-side rendering per route. Server logic lives in colocated **server functions**, and the data layer is bring-your-own — Start ships no ORM or database integration of its own.

That makes this less of an "either/or" than it first looks, because the libraries TanStack publishes do not all play the same role for a Rails team:

- **TanStack Query, Router, and Table are complementary.** They work well in front of a Rails backend, and React on Rails Pro can server-render TanStack Router (see the [TanStack Router guide](../building-features/tanstack-router.md)). Adopting them does not require leaving Rails.
- **TanStack Start's server functions are the part that overlaps with Rails.** They put business logic, authorization, and data access into TypeScript functions on a Node server — the job Rails already does. If you have, or want, Rails, that is the layer you are choosing between.

**TanStack Start:**

- Pros: one language end to end, type safety across the client/server boundary, fine-grained per-route rendering, and a fast Vite dev loop. A strong fit for greenfield apps with no existing backend and a small team optimizing for velocity.
- Drawbacks: you still assemble and own the backend — database, ORM, auth, background jobs — from separate libraries, and your business logic shares a runtime with your UI.

**React on Rails:**

- Pros: keep Rails for business logic, persistence, authorization, and jobs, with React — and the TanStack client libraries — as the view layer. React Server Components in React on Rails Pro give the same colocation benefit server functions are known for (server work next to the component, no `/api` round-trip or serializer for that view), except the data comes from Rails: your controller prepares it and passes it as props or streams it as async props.
- Drawbacks: two languages (Ruby and TypeScript) rather than one, and an untyped JSON boundary between Rails and the client unless you generate types from your API.

Choose TanStack Start when you are greenfield, have no Rails investment, want a single language end to end, and are optimizing for raw velocity.

Choose React on Rails when you want a real backend — Rails — under a modern React frontend, and would rather adopt the TanStack client libraries on top of Rails than move your business logic into JavaScript.

A runnable example of this architecture — React on Rails Pro with TanStack Query, Router, and Table against a Rails backend — is the [React on Rails Pro + TanStack starter](https://github.com/shakacode/react-on-rails-starter-tanstack). React Server Components require React on Rails Pro with the Node renderer.

Official docs:

- [TanStack Start documentation](https://tanstack.com/start/latest)
- [TanStack Router on React on Rails](../building-features/tanstack-router.md)

## React on Rails vs react-rails (Legacy Path)

react-rails is a good baseline comparison because it also helps you render React from Rails. The main difference is how much framework and workflow support you want around that integration.

react-rails is lighter-weight and helper-oriented, but in practice it is mostly relevant for existing legacy integrations rather than new builds.

React on Rails goes further on the Rails + React integration story: generator workflows, flexible bundler support (Shakapacker/webpack or Rspack), server rendering support, richer integration patterns, and a clearer path to advanced features through React on Rails Pro.

If you are already on react-rails, use the [migration guide](../migrating/migrating-from-react-rails.md) to move incrementally to React on Rails.

For new projects, choose React on Rails if your requirement is "treat React as a first-class frontend architecture inside Rails."

Official docs:

- [react-rails README](https://github.com/reactjs/react-rails)

## Vite Considerations

Vite is important in this decision space, but it answers a different question than React on Rails itself.

- Vite answers "which bundler/dev-server model do we want?"
- React on Rails answers "how do Rails and React integrate at rendering, routing, and deployment boundaries?"

In practice:

- If you want primarily a fast bundler + HMR workflow and you are comfortable managing integration patterns yourself, Vite-centric setups can be appealing.
- If you want stronger Rails + React integration conventions (for example helper-driven rendering, migration guidance, and integrated SSR paths), React on Rails is the broader framework choice.
- If your decision depends on Vite performance tradeoffs, review the benchmark and matrix details in [Detailed Feature Matrix and Benchmarks](./comparison-with-alternatives.md).

Official docs:

- [Vite Ruby documentation](https://vite-ruby.netlify.app/)
- [Vite documentation](https://vite.dev/guide/)

## Common Decision Patterns

If you are adding React to an existing Rails application page by page, start with [installation into an existing Rails app](./installation-into-an-existing-rails-app.md).

If you want to validate React on Rails quickly in a fresh app, use the [quick start](./quick-start.md).

If your team is considering a hard frontend/backend split, read [Next.js with a Separate Rails Backend: Pros and Drawbacks](./nextjs-with-separate-rails-backend.md) before deciding.

If you are currently on `react-rails`, see the dedicated [migration guide](../migrating/migrating-from-react-rails.md).

If you expect React Server Components, streaming SSR, or faster production SSR to matter soon, review [OSS vs Pro](./oss-vs-pro.md) and the [upgrade to Pro guide](../../pro/upgrading-to-pro.md) early so your evaluation includes the full path.

## Verify Current Capabilities in the Official Docs

These projects continue to evolve. Before making a final architectural decision, verify the current feature set, version support, and SSR story in the official docs for the option you are evaluating.

That is especially important if your decision depends on:

- server-side rendering behavior
- Rails version support
- Vite or bundler expectations
- React version support
- upgrade and maintenance posture

## Next Steps

- [Quick Start](./quick-start.md)
- [Installation into an Existing Rails App](./installation-into-an-existing-rails-app.md)
- [Next.js with a Separate Rails Backend: Pros and Drawbacks](./nextjs-with-separate-rails-backend.md)
- [OSS vs Pro](./oss-vs-pro.md)
- [Upgrading to Pro](../../pro/upgrading-to-pro.md)
- [Detailed Feature Matrix and Benchmarks](./comparison-with-alternatives.md)
