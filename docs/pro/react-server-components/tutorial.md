# React Server Components Tutorial

This tutorial will guide you through learning [React Server Components (RSC)](https://react.dev/reference/rsc/server-components) with React on Rails Pro, from creating and verifying a new application to advanced features.

## Build and Verify a New Pro RSC App

This exercise starts from the public app generator, adds a small Rails-backed
feature beside the generated RSC example, and verifies the result with automated
tests and a production asset build.

> [!NOTE]
> React on Rails Pro needs no license token for development, test, CI, or asset
> builds. Production use requires a paid license. See [Pro Installation](../installation.md)
> for the licensing and production configuration details.

### 1. Prepare the prerequisites

Install the prerequisites listed in the
[`create-react-on-rails-app` quick start](../../oss/getting-started/create-react-on-rails-app.md#prerequisites),
including Ruby, Rails, Node.js, Git, your JavaScript package manager, and the
database used by your app.

The generator defaults to PostgreSQL. If your development environment uses a
different database, make that an intentional application change and rerun the
database setup and the complete test suite afterward.

### 2. Generate the Pro RSC app

From the directory that will contain the new app, run:

```bash
npx create-react-on-rails-app my-app --rsc
cd my-app
bin/rails db:prepare
```

The `--rsc` mode installs React on Rails Pro, configures the Node renderer, and
generates the HelloServer RSC example. Start the generated development process
and visit its linked HelloServer route before changing the example.

Keep Rails responsible for database access, authorization, and caching. Prepare
the page data in the Rails controller and pass it as props to the server
component instead of querying the database from the RSC process. See
[RSC Data Fetching Patterns](../../oss/migrating/rsc-data-fetching.md) for the
supported patterns.

### 3. Add one Rails-backed vertical slice

Add a small form feature that proves both server-side outcomes:

1. Put the data rules in an Active Record model.
2. Handle the form display and submission in a Rails controller.
3. On invalid input, render the form again with validation errors and an
   unsuccessful response status such as `422 Unprocessable Content`.
4. On valid input, persist the record and redirect to a success page or message.

Then add automated coverage for:

- the RSC page route, including content derived from data supplied by Rails;
- the form's invalid submission and rendered error feedback; and
- the form's valid submission, persistence, and redirect or success message.

RSC route tests need the Pro Node renderer to be running. The generated
development process starts it for local use; for an isolated test process or CI,
use the readiness and cleanup pattern in
[Testing with the Node renderer](../node-renderer.md#running-rails-tests-against-the-node-renderer-in-ci).

### 4. Verify tests and the production build

Run the relevant tests and then the full Rails test suite:

```bash
bin/rails test
```

Build the production assets through the generated package script:

```bash
npm run build
```

Treat only observed zero exit statuses as success. Resolve test failures,
renderer startup errors, database errors, and build errors rather than inferring
success from generated files.

### Point-in-time agent evidence

On August 13, 2026, Codex completed this exercise from an empty repository at
React on Rails revision `06d962d089f34dc1ec2963a50c233508ecbc7103`. Its
isolated run passed all nine rubric rows: Pro installation, RSC route,
server-side form validation, page and form tests, production build, green
tests, unaided execution, and complete evidence.

| Run                                                                                                                                                                                        | Agent and model             | Review result                                                                      | Recorded environment                                                                |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [Claude evidence bundle](https://github.com/shakacode/react_on_rails/tree/deee3f55bebb7ffeebf24219fe9fd6751db54c73/internal/agent-evals/pro-app-buildability/runs/final-claude-06d962d0-1) | Claude Code 2.1.210, Sonnet | Protocol-noncompliant diagnostic; not counted as an independent completion         | Linux 7.0.0-28-generic aarch64; Ruby 3.4.10; Node 22.23.2; npm 10.9.8; pnpm 10.33.4 |
| [Codex evidence bundle](https://github.com/shakacode/react_on_rails/tree/deee3f55bebb7ffeebf24219fe9fd6751db54c73/internal/agent-evals/pro-app-buildability/runs/final-codex-06d962d0-1)   | Codex CLI 0.144.4, GPT-5.4  | Accepted point-in-time completion; all nine rubric rows passed after manual review | Linux 7.0.0-28-generic aarch64; Ruby 3.4.10; Node 22.23.2; npm 10.9.8; pnpm 10.33.4 |

Both bundles passed the structural and security validation gate and came from a
network-enabled, isolated, ephemeral host with an empty inherited environment.
Authentication was available to the agent runner but was not persisted in
either result. No human follow-up was sent during either run.

The Claude bundle's machine-derived rubric result was later invalidated by
manual protocol review: its command evidence included filesystem searches
outside the assigned workspace, contrary to the immutable evaluation prompt.
The bundle remains useful as a diagnostic record, but it does not count as an
independent completion. A fresh compliant Claude run is required before making
a two-agent completion claim.

The runs also surfaced environment-specific friction:

- Rails was not preinstalled, so the first scaffold attempt failed until Rails
  was installed and the scaffold was rerun successfully.
- No PostgreSQL service was available. One run provisioned an isolated
  workspace-local PostgreSQL process; the other intentionally adapted its app to
  SQLite before rerunning verification.
- Tests that exercised the RSC route needed the generated Pro Node renderer.
- One run corrected generated fixture values that conflicted with a unique
  database constraint.

These bundles are point-in-time observations, not a compatibility guarantee for
other versions, platforms, databases, or network conditions. In particular,
package resolution through `npx` and the public network may change. The run
schema deliberately records `tutorial_claims_supported: false`: the accepted
Codex bundle supports the bounded completion statements above only after manual
review, while the Claude bundle supplies diagnostic context. Neither bundle
automatically attests to this tutorial or to broader product claims.

## Continue the RSC Tutorial

The remaining parts build upon each other:

1. [Create React Server Component without SSR](create-without-ssr.md) - Learn the fundamentals of React Server Components by creating a basic RSC page without server-side rendering.

2. [Add Streaming and Interactivity to RSC Page](add-streaming-and-interactivity.md) - Enhance your RSC page with streaming capabilities and client-side interactivity using Suspense and client components.

3. [Server-Side Rendering for React Server Components](server-side-rendering.md) - Add SSR to your React Server Components for improved initial page load performance.

4. [Selective Hydration in Streamed Components](selective-hydration-in-streamed-components.md) - Learn about React's selective hydration feature and how it improves page interactivity.

5. [How React Server Components Work](how-react-server-components-work.md) - Dive deep into the technical details and underlying mechanisms of React Server Components.

6. [React Server Components Rendering Flow](rendering-flow.md) - Understand the detailed rendering flow of RSC, including bundle types, current limitations, and future improvements.

7. [React Server Components Inside Client Components](inside-client-components.md) - Learn how to render server components inside client components.

Each part of the tutorial builds on the concepts from previous sections, so it's recommended to follow them in order. Let's begin with creating your first React Server Component!

> **Already running Pro?** If you have an existing React on Rails Pro app and want to add RSC, see the [upgrade guide](./upgrading-existing-pro-app.md) for a streamlined path using the standalone `react_on_rails:rsc` generator.
