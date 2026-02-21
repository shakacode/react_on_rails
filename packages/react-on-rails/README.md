# react-on-rails

The client-side JavaScript package for [React on Rails](https://github.com/shakacode/react_on_rails) — the integration layer between Rails and React. This package handles component registration, client-side hydration, and server-side rendering support.

## Installation

```bash
npm install react-on-rails
# or
yarn add react-on-rails
# or
pnpm add react-on-rails
```

**Using React on Rails Pro?** Install [`react-on-rails-pro`](https://www.npmjs.com/package/react-on-rails-pro) instead. The Pro package re-exports everything from this package plus Pro-exclusive features. The `react_on_rails_pro` gem requires the Pro npm package.

## Quick Start

### Register Components

```javascript
import ReactOnRails from 'react-on-rails';
import HelloWorld from './HelloWorld';

// Register components so Rails views can render them
ReactOnRails.register({ HelloWorld });
```

### Use in Rails Views

```erb
<%# app/views/hello_world/index.html.erb %>
<%= react_component("HelloWorld", props: { name: "World" }, prerender: true) %>
```

### Server-Side Rendering

For SSR, create a server bundle entry that registers the same components:

```javascript
// app/javascript/packs/server-bundle.js
import ReactOnRails from 'react-on-rails';
import HelloWorld from '../src/HelloWorld';

ReactOnRails.register({ HelloWorld });
```

## API

### `ReactOnRails.register(components)`

Register React components for use in Rails views.

```javascript
ReactOnRails.register({
  HelloWorld,
  UserProfile,
  Dashboard,
});
```

### Render Functions

For advanced SSR control, register render functions instead of components:

```javascript
ReactOnRails.register({
  MyApp: (props, railsContext) => {
    return { renderedHtml: '<div>...</div>' };
  },
});
```

## Exports

| Export Path | Description |
|------------|-------------|
| `react-on-rails` | Full build with SSR utilities |
| `react-on-rails/client` | Client-only build (smaller, no SSR) |
| `react-on-rails/types` | TypeScript type exports |

## Rails-Side Setup

This npm package works with the `react_on_rails` Ruby gem:

```ruby
# Gemfile
gem "react_on_rails"
```

Use the generator for automated setup:

```bash
rails generate react_on_rails:install
```

## Documentation

- [Getting Started](https://www.shakacode.com/react-on-rails/docs/getting-started/quick-start/)
- [Installation Guide](https://www.shakacode.com/react-on-rails/docs/getting-started/installation-into-an-existing-rails-app/)
- [API Reference](https://www.shakacode.com/react-on-rails/docs/api-reference/)
- [Configuration](https://www.shakacode.com/react-on-rails/docs/configuration/)

## License

See [LICENSE.md](https://github.com/shakacode/react_on_rails/blob/master/LICENSE.md).
