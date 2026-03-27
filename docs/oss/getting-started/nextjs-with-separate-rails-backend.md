# Next.js with a Separate Rails Backend: Pros and Drawbacks

Teams evaluating React on Rails often ask whether they should instead run Next.js as a standalone frontend and Rails as a separate backend API.

This guide outlines the tradeoffs so you can decide based on architecture and team constraints, not trend pressure.

## What This Architecture Means

In this model:

- Next.js owns the web UI, frontend routing, and frontend SSR.
- Rails exposes JSON/GraphQL APIs and usually owns business rules, persistence, and background jobs.
- Frontend and backend become independent deployables with an explicit API contract between them.

## Pros

- Clear frontend/backend ownership boundaries
- API reuse for additional clients (mobile apps, partner integrations, internal tools)
- Frontend release cadence can move independently from backend release cadence
- Strong fit for organizations already staffed like separate frontend and platform teams

## Drawbacks

- Two deploy pipelines and two production runtimes to monitor
- Cross-app authentication/session complexity (cookies, CSRF, token flows, refresh behavior)
- More contract maintenance between teams (versioning, schema drift, backwards compatibility)
- Extra integration testing burden to catch frontend/backend contract regressions
- More distributed debugging across service boundaries

## Where React on Rails Differs

React on Rails keeps Rails and React integrated in one app boundary:

- React components can be rendered directly from Rails views
- You can avoid mandatory API-first architecture for server-rendered pages
- End-to-end debugging and deployment are often simpler for Rails-first teams

This is often a better fit when your primary goal is substantial React UI in a Rails app without taking on full frontend/backend split complexity.

## Decision Checklist

Choose **Next.js + separate Rails backend** if most of these are true:

- You explicitly want API-first boundaries as a long-term architecture
- You already operate with independent frontend/backend ownership
- You need the same API consumed by multiple external clients

Choose **React on Rails** if most of these are true:

- You want one integrated deployment and ownership model
- Your team is Rails-heavy and wants React without full stack separation
- You want to incrementally adopt React within existing Rails views/pages

## Related Reading

- [Comparing React on Rails to alternatives](./comparing-react-on-rails-to-alternatives.md)
- [Comparison with alternatives (feature matrix and benchmarks)](./comparison-with-alternatives.md)
- [Installation into an Existing Rails App](./installation-into-an-existing-rails-app.md)
