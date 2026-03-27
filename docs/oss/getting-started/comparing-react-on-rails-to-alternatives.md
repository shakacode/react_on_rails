# Comparing React on Rails to Alternatives

If you are evaluating frontend approaches for a Rails application, the right choice depends on how much of your UI should live in React, how much Rails should keep rendering, and whether server rendering is a requirement from day one.

This page is intentionally practical. It focuses on the tradeoffs teams usually care about when choosing between React on Rails, Hotwire/Turbo, Inertia Rails, a Next.js frontend with a separate Rails backend API, and react-rails.

## Short Version

Choose **React on Rails** when you want Rails and React tightly integrated, you expect a meaningful amount of React UI, and you want server rendering or a path to React on Rails Pro features such as React Server Components and streaming SSR.

Choose **Hotwire/Turbo** when Rails-rendered HTML is still your preferred model and you only need modest JavaScript sprinkles or progressive enhancement.

Choose **Inertia Rails** when you specifically want its controller-to-page-props protocol and a frontend shell as the main rendering model. A page-oriented SPA flow can also be implemented in React on Rails with a supported frontend router, but the integration model is different.

Choose **Next.js + separate Rails backend** when you want a hard frontend/backend boundary and are prepared to run two apps with an explicit API contract between them.

If you are currently on **react-rails**, prefer the migration path to React on Rails rather than starting new work on react-rails.

## At a Glance

| Option                   | Primary view model                                                  | Best fit                                                                              | What to watch                                                                                       |
| ------------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **React on Rails**       | Rails views rendering React components with tight Rails integration | Existing Rails apps, SSR, mixed Rails + React pages, progressive adoption             | More setup than lightweight helper-based integrations                                               |
| **Hotwire/Turbo**        | Rails renders HTML, Turbo updates the page                          | Rails-first apps with minimal client-side complexity                                  | Not a React solution, so React ecosystem reuse is limited                                           |
| **Inertia Rails**        | Controllers return page props to a client-rendered frontend shell   | Teams that want SPA-style page transitions without building a separate JSON API first | Different rendering model than traditional Rails views; review current SSR support in official docs |
| **Next.js + Rails API**  | Next.js app consumes Rails API responses                            | Teams prioritizing frontend autonomy, edge delivery, or multi-client API reuse        | Two deployables, duplicated auth/session concerns, and stricter API lifecycle management            |
| **react-rails (legacy)** | Rails views mount React components with helper-based integration    | Existing legacy apps already on react-rails                                           | Maintenance-focused path; plan migration to React on Rails for newer capabilities                   |

## React on Rails vs Hotwire/Turbo

Hotwire/Turbo is strongest when your team wants to keep Rails fully in charge of the HTML response lifecycle. It is a good fit for CRUD-heavy applications, low-JavaScript back offices, and teams that prefer Stimulus plus server-rendered views over a React-centric frontend architecture.

React on Rails is the better fit when your product already benefits from React's component model, third-party React libraries, complex client-side state, or reusable frontend architecture across many pages. It lets you keep Rails as the backend and routing layer while still using React as the main UI model where needed.

Choose Hotwire/Turbo if your goal is "stay mostly Rails views."

Choose React on Rails if your goal is "build substantial React UI without splitting Rails away from the app."

Official docs:

- [Hotwire Turbo handbook](https://turbo.hotwired.dev/handbook/introduction)

## React on Rails vs Inertia Rails

Inertia Rails gives you a different tradeoff. Instead of embedding React within Rails views, it uses Rails controllers to feed props into a frontend-driven page shell. That can feel closer to an SPA workflow while still avoiding a fully separate API for many use cases.

React on Rails keeps Rails views and helpers directly in play. That matters if you are incrementally adopting React inside an established Rails application, embedding React in only part of the UI, or relying on React component rendering from ERB/Haml without changing the app's page model.

Choose Inertia Rails if you want a page-oriented SPA style and are comfortable centering the frontend runtime in the request/response flow.

Choose React on Rails if you want deeper Rails-view integration, easier incremental adoption in existing apps, or the React on Rails Pro upgrade path for advanced rendering features.

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

## React on Rails vs react-rails (Legacy Path)

react-rails is a good baseline comparison because it also helps you render React from Rails. The main difference is how much framework and workflow support you want around that integration.

react-rails is lighter-weight and helper-oriented, but in practice it is mostly relevant for existing legacy integrations rather than new builds.

React on Rails goes further on the Rails + React integration story: generator workflows, flexible bundler support (Shakapacker/webpack, Rspack, or Vite), server rendering support, richer integration patterns, and a clearer path to advanced features through React on Rails Pro.

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
