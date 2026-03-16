# Comparing React on Rails to Alternatives

If you are evaluating frontend approaches for a Rails application, the right choice depends on how much of your UI should live in React, how much Rails should keep rendering, and whether server rendering is a requirement from day one.

This page is intentionally practical. It focuses on the tradeoffs teams usually care about when choosing between React on Rails, Hotwire/Turbo, Inertia Rails, and react-rails.

## Short Version

Choose **React on Rails** when you want Rails and React tightly integrated, you expect a meaningful amount of React UI, and you want server rendering or a path to React on Rails Pro features such as React Server Components and streaming SSR.

Choose **Hotwire/Turbo** when Rails-rendered HTML is still your preferred model and you only need modest JavaScript sprinkles or progressive enhancement.

Choose **Inertia Rails** when you want a page-oriented SPA workflow with Rails controllers and Vite, and you are comfortable making the frontend shell the main rendering model.

Choose **react-rails** when you want a smaller helper-based integration for embedding React components in Rails views and do not need the broader React on Rails feature set.

## At a Glance

| Option             | Primary view model                                                  | Best fit                                                                              | What to watch                                                                                       |
| ------------------ | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **React on Rails** | Rails views rendering React components with tight Rails integration | Existing Rails apps, SSR, mixed Rails + React pages, progressive adoption             | More setup than lightweight helper-based integrations                                               |
| **Hotwire/Turbo**  | Rails renders HTML, Turbo updates the page                          | Rails-first apps with minimal client-side complexity                                  | Not a React solution, so React ecosystem reuse is limited                                           |
| **Inertia Rails**  | Controllers return page props to a client-rendered frontend shell   | Teams that want SPA-style page transitions without building a separate JSON API first | Different rendering model than traditional Rails views; review current SSR support in official docs |
| **react-rails**    | Rails views mount React components with helper-based integration    | Smaller React islands and simpler embedding needs                                     | Fewer integrated Rails + React workflow features than React on Rails                                |

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

## React on Rails vs react-rails

react-rails is a good baseline comparison because it also helps you render React from Rails. The main difference is how much framework and workflow support you want around that integration.

react-rails is lighter-weight and helper-oriented. It can be a reasonable choice if you mostly need to mount React components in Rails views and want to keep the surrounding integration simple.

React on Rails goes further on the Rails + React integration story: generator workflows, flexible bundler support (Shakapacker/webpack, Rspack, or Vite), server rendering support, richer integration patterns, and a clearer path to advanced features through React on Rails Pro.

Choose react-rails if your requirement is "mount React in Rails with minimal ceremony."

Choose React on Rails if your requirement is "treat React as a first-class frontend architecture inside Rails."

Official docs:

- [react-rails README](https://github.com/reactjs/react-rails)

## Common Decision Patterns

If you are adding React to an existing Rails application page by page, start with [installation into an existing Rails app](./installation-into-an-existing-rails-app.md).

If you want to validate React on Rails quickly in a fresh app, use the [quick start](./quick-start.md).

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
- [OSS vs Pro](./oss-vs-pro.md)
- [Upgrading to Pro](../../pro/upgrading-to-pro.md)
