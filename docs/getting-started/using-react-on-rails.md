# Understanding React on Rails

This guide explains the core concepts of React on Rails and how everything fits together. If you've just installed React on Rails (or are about to), this will help you understand what's happening under the hood.

> **💡 New to React on Rails?** Start with the [15-Minute Quick Start](./quick-start.md) to get something working first, then come back here to understand the concepts.

---

## Installation Overview

When you install React on Rails, several things happen:

1. **Ruby gem installed** - Provides Rails integration, view helpers, and SSR support
2. **NPM package installed** - Client-side JavaScript library for registering components
3. **Generator creates files** - Component structure, webpack config, sample code
4. **Shakapacker configured** - Webpack integration for Rails (required dependency)

The generator sets up:

- Component directories (typically `app/javascript/bundles/` or with auto-bundling in `app/javascript/src/*/ror_components/`)
- Rails integration (controllers, views, initializer)
- Webpack configuration for building JavaScript bundles
- Development workflow with hot module replacement

**For detailed installation instructions, see:**

- **[Quick Start Guide](./quick-start.md)** - Fastest path (15 minutes)
- **[Installation Guide](./installation-into-an-existing-rails-app.md)** - For existing Rails apps
- **[Complete Tutorial](./tutorial.md)** - Step-by-step with Redux and routing

---

## Using React Components in Rails Views

Once installed, you render React components in Rails views using the `react_component` helper:

```erb
<%= react_component("HelloWorld", props: @some_props) %>
```

### Basic Options

**Client-side rendering only (default):**

```erb
<%= react_component("HelloWorld", props: { name: "World" }) %>
```

**Server-side rendering for SEO/performance:**

```erb
<%= react_component("HelloWorld", props: { name: "World" }, prerender: true) %>
```

The component name (`"HelloWorld"`) must match the name you registered in your JavaScript code.

### Configuration

React on Rails is configured in `config/initializers/react_on_rails.rb`:

- Server rendering settings
- Development vs production behavior
- Logging options
- Auto-bundling settings

For complete configuration options, see the [Configuration Reference](../configuration/index.md).

For all view helper options (props, HTML options, tracing, etc.), see the [View Helpers API](../api-reference/view-helpers-api.md).

---

## Auto-Bundling and Component Registration

React on Rails supports two approaches for making components available to Rails views:

### Traditional Manual Registration

```js
// app/javascript/packs/hello-world-bundle.js
import ReactOnRails from 'react-on-rails';
import HelloWorld from '../components/HelloWorld';

ReactOnRails.register({ HelloWorld });
```

You must configure webpack entry points and manually register each component.

### Modern Auto-Bundling (Recommended)

```erb
<%= react_component("HelloWorld", { name: "World" }, { auto_load_bundle: true }) %>
```

With auto-bundling enabled:

1. Place components in designated directories (e.g., `app/javascript/src/*/ror_components/`)
2. React on Rails automatically finds and bundles them
3. No manual webpack configuration needed
4. No manual `ReactOnRails.register()` calls
5. Components are loaded on-demand per page

**Configuration (in `config/initializers/react_on_rails.rb`):**

```ruby
config.components_subdirectory = "ror_components"  # Directory name for auto-discovery
config.auto_load_bundle = true                      # Enable automatic bundle loading
```

**Benefits:**

- Eliminates boilerplate configuration
- Automatic code splitting per component
- Smaller initial bundle sizes
- Components only loaded when used

For complete details, see [Auto-Bundling Guide](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md).

---

## Understanding What the Generator Creates

After running `rails generate react_on_rails:install`, you'll see:

### Component Structure

```text
app/javascript/
└── bundles/HelloWorld/          # or src/HelloWorld/ror_components/ with auto-bundling
    └── HelloWorld.jsx
```

### Rails Integration

- **Controller**: `app/controllers/hello_world_controller.rb` - Example controller
- **View**: `app/views/hello_world/index.html.erb` - Shows `react_component` helper usage
- **Route**: Added to `config/routes.rb`
- **Initializer**: `config/initializers/react_on_rails.rb` - Configuration

### Webpack Configuration

- Shakapacker handles webpack setup
- Config in `config/shakapacker.yml`
- For custom webpack needs, see [Webpack Configuration Guide](../core-concepts/webpack-configuration.md)

### Development Workflow

The generator creates `bin/dev` for starting both:

- Rails server (port 3000)
- Webpack dev server (for hot reloading)

> **Note:** You need `overmind` or `foreman` installed to run `bin/dev`. Install with `brew install overmind` (macOS) or `gem install foreman` (globally). See the [Quick Start Guide](./quick-start.md#-step-2-start-the-development-server-1-minute) for detailed installation instructions.

---

## Render-Functions and RailsContext

Sometimes you need more than just a simple React component. **Render-Functions** let you:

1. Access Rails context (current URL, locale, etc.)
2. Initialize Redux stores with props
3. Set up React Router
4. Return different components based on props

### Basic Example

```js
const MyApp = (props, railsContext) => {
  // Access Rails context
  console.log(railsContext.pathname); // Current URL
  console.log(railsContext.i18nLocale); // Current locale

  // Return a React component
  return () => <div>Hello from {railsContext.pathname}</div>;
};

export default MyApp;
```

### When to Use Render-Functions

- **Need railsContext** - Access current URL, locale, or custom Rails data
- **Redux integration** - Initialize store with server-side props
- **React Router** - Set up routing with initial URL from Rails
- **Conditional rendering** - Return different components based on props

### Server-Side Rendering with Render-Functions

For advanced server rendering (like React Router), you can return an object:

```js
({
  renderedHtml: {
    componentHtml,
    redirectLocation,
    error,
  },
});
```

Use with `react_component_hash` helper for multiple HTML strings (useful with React Helmet for meta tags).

For complete Render-Function details and examples, see the [Render-Functions Guide](../core-concepts/render-functions.md).

---

## Error Handling

- All React on Rails errors are of type `ReactOnRails::Error`
- Server rendering errors include context for HoneyBadger/Sentry
- Configure error behavior in `config/initializers/react_on_rails.rb`

For troubleshooting common issues, see the [Troubleshooting Guide](../deployment/troubleshooting.md).

---

## Next Steps

Now that you understand the core concepts, here are recommended paths forward:

### Build Features

- **[Redux Integration](../building-features/react-and-redux.md)** - Add state management
- **[React Router](../building-features/react-router.md)** - Client-side routing
- **[Server-Side Rendering](../core-concepts/react-server-rendering.md)** - Deep dive into SSR
- **[Internationalization](../building-features/i18n.md)** - Add i18n support
- **[Testing](../building-features/testing-configuration.md)** - Test your React components

### Deploy to Production

- **[Deployment Guide](../deployment/index.md)** - Production deployment strategies
- **[Heroku Deployment](../deployment/heroku-deployment.md)** - Deploy to Heroku
- **[Troubleshooting](../deployment/troubleshooting.md)** - Common deployment issues

### Advanced Topics

- **[Webpack Configuration](../core-concepts/webpack-configuration.md)** - Customize webpack
- **[Different Client/Server Code](../building-features/how-to-use-different-files-for-client-and-server-rendering.md)** - Separate bundles

### API Reference

- **[View Helpers API](../api-reference/view-helpers-api.md)** - Complete `react_component` options
- **[JavaScript API](../api-reference/javascript-api.md)** - ReactOnRails JavaScript methods
- **[Configuration](../configuration/index.md)** - All configuration options

---

**Ready to build something?** The [Tutorial](./tutorial.md) walks you through building a complete app with Redux, routing, and testing.
