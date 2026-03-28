# React on Rails Documentation Templates

Project-specific template examples for React on Rails documentation. These complement the generic templates in the shared docs skill by providing React on Rails-specific code samples and patterns.

## README Hello World Example

The README Hello World section should use the `react_component` helper:

```ruby
# In your Rails view
<%= react_component("HelloWorld", props: { name: "Reader" }, prerender: false) %>
```

```typescript
// In your component file
import React from 'react';

const HelloWorld = ({ name }: { name: string }) => (
  <h1>Hello, {name}!</h1>
);

export default HelloWorld;
```

## API Reference Entry Example

When documenting API methods, use `react_component` as the canonical example:

```ruby
method_name(component_name, options = {}) -> String
```

### Parameters

| Parameter        | Type     | Required | Default | Description                                |
| ---------------- | -------- | -------- | ------- | ------------------------------------------ |
| `component_name` | `String` | Yes      | -       | The registered name of the React component |
| `options`        | `Hash`   | No       | `{}`    | Configuration options (see below)          |

### Options

| Key          | Type      | Default | Description                         |
| ------------ | --------- | ------- | ----------------------------------- |
| `:props`     | `Hash`    | `{}`    | Props passed to the React component |
| `:prerender` | `Boolean` | `false` | Enable server-side rendering        |
| `:trace`     | `Boolean` | `false` | Add HTML comments for debugging     |

### Usage examples

```ruby
<%= react_component("UserProfile", props: { user: @user }) %>
```

```ruby
<%= react_component("UserProfile",
  props: { user: @user.as_json(only: [:id, :name, :email]) },
  prerender: true
) %>
```

Note: Component must be registered with `ReactOnRails.register({ UserProfile })` before rendering.

## Configuration Reference Example

Configuration is set in `config/initializers/react_on_rails.rb`:

```ruby
ReactOnRails.configure do |config|
  config.server_bundle_js_file = "server-bundle.js"
  config.prerender = false
end
```

### Ruby Options

| Option                  | Type      | Default | Description                                                                                                 |
| ----------------------- | --------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| `server_bundle_js_file` | `String`  | `""`    | JS bundle used for server rendering. Relative to `generated_assets_dir`.                                    |
| `prerender`             | `Boolean` | `false` | Default SSR setting for all components. Can be overridden per-component.                                    |
| `random_dom_id`         | `Boolean` | `true`  | Generate random DOM IDs for component containers. Set to `false` for deterministic IDs (useful in testing). |

### JavaScript Options

```typescript
import ReactOnRails from 'react-on-rails';

ReactOnRails.setOptions({
  traceTurbolinks: true,
});
```

| Option            | Type      | Default | Description                          |
| ----------------- | --------- | ------- | ------------------------------------ |
| `traceTurbolinks` | `boolean` | `false` | Log Turbolinks events for debugging. |

### Environment Variables

| Variable               | Default | Description            |
| ---------------------- | ------- | ---------------------- |
| `TRACE_REACT_ON_RAILS` | -       | Enable verbose logging |

## Troubleshooting Examples

### Component not rendering

**What you see:** The page loads but the React component area is blank or shows raw HTML.

**Common causes:**

1. Component not registered — call `ReactOnRails.register({ MyComponent })` in your entry file
2. Entry file not included in the page — check `javascript_pack_tag` or Shakapacker configuration

**Fix:**

```javascript
// app/javascript/packs/application.js
import ReactOnRails from 'react-on-rails';
import MyComponent from '../components/MyComponent';

ReactOnRails.register({ MyComponent });
```

### SSR fails with "ReferenceError: window is not defined"

**Cause:** Component or dependency accesses browser APIs during the initial render pass, which runs in Node/ExecJS where those globals do not exist.

**Fix:** Guard browser-only code:

```typescript
const isBrowser = typeof window !== 'undefined';

useEffect(() => {
  // Safe to use window here (only runs in browser)
}, []);
```

## Requirements Section

When documenting requirements, use:

- Ruby >= 3.0
- Rails >= 6.1
- Node >= 18
- Shakapacker >= 6.0 (or Rspack)
