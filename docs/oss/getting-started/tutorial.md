# React on Rails Tutorial

_See also [Examples and migration references](./examples-and-references.md) for maintained demo apps, migration references, and current React on Rails Pro + RSC demos._

This tutorial starts from the [Quick Start](./quick-start.md) app and builds a small TypeScript component using the modern React on Rails workflow:

- TypeScript function components and React Hooks
- Auto-bundling from files in `ror_components`
- `bin/dev` with HMR during development
- Optional server rendering with `prerender: true`

Redux is still supported, but it is no longer the main path for a first React on Rails app. See [Appendix: Redux and State Choices](#appendix-redux-and-state-choices) when you need a multi-island shared client store or you are maintaining an existing Redux setup.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Start From The Quick-Start App](#start-from-the-quick-start-app)
- [Understand The Generated Files](#understand-the-generated-files)
- [Create A TypeScript Counter Component](#create-a-typescript-counter-component)
- [Render The Component From Rails](#render-the-component-from-rails)
- [Run The App With HMR](#run-the-app-with-hmr)
- [Pass Props From Rails](#pass-props-from-rails)
- [Optional: Turn On Server Rendering](#optional-turn-on-server-rendering)
- [Production Build And Deployment](#production-build-and-deployment)
- [Troubleshooting](#troubleshooting)
- [Appendix: Redux and State Choices](#appendix-redux-and-state-choices)
- [What's Next?](#whats-next)

## Prerequisites

Use current, maintained versions for new apps:

- Ruby 3.3+
- Rails 7+
- Node.js 18+ and your preferred package manager
- Foreman or Overmind for `bin/dev`

React on Rails is published as both a Ruby gem and an npm package. For exact current versions, check:

- [react_on_rails on RubyGems](https://rubygems.org/gems/react_on_rails)
- [react-on-rails on npm](https://www.npmjs.com/package/react-on-rails)

## Start From The Quick-Start App

If you already completed the [Quick Start](./quick-start.md), keep using that app. Otherwise, create a Rails app and run the TypeScript installer:

```bash
rails new test-react-on-rails --skip-javascript
cd test-react-on-rails

bundle add react_on_rails --strict
bin/rails generate react_on_rails:install --typescript
```

The installer sets up Shakapacker, React, TypeScript, the React on Rails initializer, a sample controller, and a `bin/dev` process file. Fresh installs use Rspack by default when the installed Shakapacker version supports it. To force Webpack instead, pass `--no-rspack`.

> [!TIP]
> Commit or stash your app before running generators. The diff is much easier to review when generated changes are isolated.

There is no `react_on_rails:component` generator. For new components, create the files manually under the configured `ror_components` directory and let auto-bundling discover them.

## Understand The Generated Files

The TypeScript installer creates a structure like this:

```text
app/javascript/
└── src/
    └── HelloWorld/
        └── ror_components/
            ├── HelloWorld.client.tsx
            ├── HelloWorld.module.css
            └── HelloWorld.server.tsx
```

The important pieces are:

- `config/initializers/react_on_rails.rb` configures React on Rails.
- `config/shakapacker.yml` configures the bundler and enables nested entries for generated packs.
- `app/javascript/src/**/ror_components/*` contains components that React on Rails can auto-register.
- Rails views call `react_component` to render those components.

Auto-bundling means you do not manually create a pack for every component and you do not manually call `ReactOnRails.register` for the basic component case. React on Rails generates the per-component bundles and loads the right bundle when the view helper asks for it.

## Create A TypeScript Counter Component

Create a new component directory:

```bash
mkdir -p app/javascript/src/Counter/ror_components
```

Add `app/javascript/src/Counter/ror_components/Counter.client.tsx`:

```tsx
import React, { useState } from 'react';

type CounterProps = {
  initialCount?: number;
  label?: string;
};

export default function Counter({ initialCount = 0, label = 'Counter' }: CounterProps) {
  const [count, setCount] = useState(initialCount);

  return (
    <section>
      <h2>{label}</h2>
      <p>
        Count: <strong>{count}</strong>
      </p>
      <button type="button" onClick={() => setCount((current) => current + 1)}>
        Increment
      </button>
      <button type="button" onClick={() => setCount(initialCount)}>
        Reset
      </button>
    </section>
  );
}
```

The file name controls the component name. `Counter.client.tsx` is rendered from Rails as `"Counter"`. The `.client` suffix tells auto-bundling this is the browser entry point.

## Render The Component From Rails

Add a controller action if you do not already have one:

```bash
bin/rails generate controller Dashboard show
```

In `app/controllers/dashboard_controller.rb`, set props for React. The Quick Start installer creates `react_on_rails_default`, which includes the generated bundle placeholders. If that layout is missing, use the fallback note below before copying this controller:

```ruby
class DashboardController < ApplicationController
  layout "react_on_rails_default"

  def show
    @counter_props = {
      # React props use camelCase; react_component serializes this hash to JSON.
      initialCount: 3,
      label: "Orders ready"
    }
  end
end
```

In `app/views/dashboard/show.html.erb`, render the component:

```erb
<h1>Dashboard</h1>

<%= react_component("Counter", props: @counter_props, auto_load_bundle: true) %>
```

If your app sets `config.auto_load_bundle = true` in `config/initializers/react_on_rails.rb`, you can omit `auto_load_bundle: true` from individual helper calls:

```erb
<%= react_component("Counter", props: @counter_props) %>
```

The generated `react_on_rails_default` layout includes the Shakapacker tags that auto-bundling needs. If you render from your application's default layout instead, add the same argless pack-tag calls there:

```erb
<%= stylesheet_pack_tag %>
<%= javascript_pack_tag %>
```

With no pack name, Shakapacker renders every bundle accumulated by `append_javascript_pack_tag` and `append_stylesheet_pack_tag`, which lets auto-bundling load per-component packs without hardcoding generated pack names in the layout.

If `app/views/layouts/react_on_rails_default.html.erb` is not present (for example, you added React on Rails manually to an existing app without running the installer), remove the `layout` line from the controller and add the pack-tag placeholders to your `application.html.erb` or whichever layout renders this view.

## Run The App With HMR

Start Rails and the bundler dev server together:

```bash
./bin/dev
```

Visit the route for your controller, such as [http://localhost:3000/dashboard/show](http://localhost:3000/dashboard/show). Edit `Counter.client.tsx`, save, and the page should update through HMR.

Use static bundling when you want to test the production-style compiled assets locally:

```bash
./bin/dev static
```

## Pass Props From Rails

`props:` accepts a Ruby hash or a JSON string. Prefer hashes in normal Rails views so the code stays readable:

```erb
<%= react_component(
      "Counter",
      props: {
        initialCount: current_user.notifications.unread.count,
        label: "Unread notifications"
      },
      auto_load_bundle: true
    ) %>
```

Keep props serializable. Pass IDs, strings, numbers, booleans, arrays, and hashes; fetch richer client-side data through your usual Rails JSON endpoints or GraphQL layer.

## Optional: Turn On Server Rendering

For a component that can render without browser-only APIs, add a server entry before you enable prerendering. Keep both files in the same `ror_components` directory:

```text
app/javascript/src/Counter/ror_components/
├── Counter.client.tsx
└── Counter.server.tsx
```

The server file can re-export the same component when no special server behavior is needed:

```tsx
export { default } from './Counter.client';
```

The generated TypeScript config uses bundler module resolution, so the extensionless re-export matches the installer defaults. If your app uses a stricter custom Node ESM TypeScript setup, use the relative import extension style required by that config.

Auto-bundling discovers `Counter.server.tsx` and includes it in the generated server bundle. You do not need to change `config.server_bundle_js_file` when the generated `server-bundle.js` entrypoint is already in place.

Then add `prerender: true` in the Rails view:

```erb
<%= react_component("Counter", props: @counter_props, prerender: true, auto_load_bundle: true) %>
```

> [!NOTE]
> `prerender: true` needs a server bundle. For a first local SSR check, use `./bin/dev static` or run a production precompile. If you want the dev server to serve the prerender bundle, follow the [HMR guide](../building-features/hmr-and-hot-reloading-with-the-webpack-dev-server.md) and set `config.same_bundle_for_client_and_server = true` for that mode.
>
> Server rendering runs in Node or ExecJS, which has no browser globals (`window`, `document`, `localStorage`). Guard browser-only access inside a `useEffect` hook or a conditional on `typeof window !== 'undefined'`.

For deeper SSR guidance, see [Client vs. Server Rendering](../core-concepts/client-vs-server-rendering.md) and [React Server Rendering](../core-concepts/react-server-rendering.md).

## Production Build And Deployment

Before deploying, run the production asset pipeline locally once:

```bash
RAILS_ENV=production NODE_ENV=production bin/rails assets:precompile
```

After verifying the production build locally, remove compiled assets before returning to development:

```bash
bin/rails assets:clobber
```

For deployment details, see:

- [Heroku Deployment Guide](../deployment/heroku-deployment.md)
- [General Deployment Guide](../deployment/README.md)

## Troubleshooting

### The Component Is Not Found

Check that the component lives under a directory matching `config.components_subdirectory`, which is usually `ror_components`:

```text
app/javascript/src/Counter/ror_components/Counter.client.tsx
```

Then make sure the view uses the component name without the `.client` or `.tsx` suffix:

```erb
<%= react_component("Counter", props: @counter_props, auto_load_bundle: true) %>
```

### The Bundle Is Not Loaded

Use `auto_load_bundle: true` on the helper call or set it globally:

```ruby
# config/initializers/react_on_rails.rb
config.auto_load_bundle = true
```

Also confirm that `nested_entries: true` remains enabled in `config/shakapacker.yml`.

### HMR Does Not Update The Page

Run `./bin/dev`, not only `bin/rails server`. The dev command starts both Rails and the bundler dev server.

### Server Rendering Fails

Temporarily set `prerender: false` to confirm the browser render works, then remove browser-only APIs from the server render path. You can also enable `trace: true` on `react_component` while debugging:

```erb
<%= react_component("Counter", props: @counter_props, prerender: true, auto_load_bundle: true, trace: true) %>
```

## Appendix: Redux and State Choices

Use Redux when your app already has Redux conventions, needs a shared client store across many React islands, or benefits from Redux middleware and DevTools. For most new React on Rails apps, choose the smallest state tool that matches the data:

- **Local island state:** use React Hooks such as `useState` and `useReducer`, or React Context when nearby components under one React root need the same UI state.
- **Server state:** pass initial data through Rails controller props, then refresh data through your Rails JSON endpoints, GraphQL layer, or a server-state cache such as [TanStack Query](../building-features/tanstack-query.md).
- **Multi-island shared client state:** use Redux only when separate React roots on the same page must coordinate through one client store, such as a header counter and body list that update each other without a full page refresh.

The installer has a hidden legacy Redux path for maintaining or recreating older generated apps, but this tutorial does not use it and new apps should not start with `--redux`. The legacy Redux structure has actions, reducers, store setup, presentational components, containers, and auto-registered entry points under `ror_components`.

When rendering an existing Redux-backed component, the Rails side still uses the same view helper style:

```erb
<%= react_component("HelloWorldApp", props: @hello_world_props, auto_load_bundle: true) %>
```

The component is named `HelloWorldApp` when you are working with the legacy generated Redux example. Adjust the component name and props key to match your app's controller setup.

For manually wired stores or advanced store sharing, use the [`redux_store` helper](../api-reference/redux-store-api.md) and the [legacy Redux reducer guidance](../building-features/react-and-redux.md).

## What's Next?

- [Using React on Rails](./using-react-on-rails.md)
- [Auto-Bundling](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md)
- [View Helpers API](../api-reference/view-helpers-api.md)
- [Hot Module Replacement (HMR)](../building-features/hmr-and-hot-reloading-with-the-webpack-dev-server.md)
- [Server Rendering](../core-concepts/react-server-rendering.md)
- [Production Deployment](../deployment/README.md)
