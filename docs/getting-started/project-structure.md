# Recommended Project Structure

React on Rails supports two main organizational approaches for your React components.

## Modern Auto-Bundling Structure (Recommended)

The current React on Rails generator creates a component-based structure optimized for automatic bundle generation:

```text
app/javascript/
├── src/
│   ├── HelloWorld/
│   │   ├── HelloWorld.module.css
│   │   └── ror_components/          # Auto-discovered by React on Rails
│   │       ├── HelloWorld.jsx       # Client & server rendering
│   │       └── HelloWorld.server.js # Optional: server-only code
│   └── AnotherComponent/
│       └── ror_components/
│           ├── AnotherComponent.client.jsx  # Client-only rendering
│           └── AnotherComponent.server.jsx  # Server-only rendering
└── packs/
    ├── generated/                   # Auto-generated entry points (gitignored)
    │   ├── HelloWorld.js
    │   └── AnotherComponent.js
    └── server-bundle.js             # Server rendering entry point
```

**Key features:**

- Components in `ror_components/` directories are automatically discovered and registered
- Each component gets its own webpack bundle for optimal code splitting
- No manual `ReactOnRails.register()` calls needed
- Supports separate `.client.jsx` and `.server.jsx` files for different rendering logic (these control **bundle placement**, not [React Server Components](../../react_on_rails_pro/docs/react-server-components/glossary.md))

For details, see [Auto-Bundling Guide](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md) and [Generator Details](../api-reference/generator-details.md).

## Traditional Manual Structure (Legacy)

For projects requiring explicit control over webpack entry points:

```text
app/javascript/
├── bundles/
│   └── HelloWorld/
│       ├── components/
│       │   └── HelloWorld.jsx
│       └── startup/
│           └── registration.js      # Manual ReactOnRails.register()
└── packs/
    └── hello-world-bundle.js        # Webpack entry point
```

This approach requires manual component registration and webpack configuration but offers complete control over bundling strategy.

## Choosing Your Structure

**Use modern auto-bundling if:**

- Starting a new project
- Want automatic code splitting per component
- Prefer convention over configuration
- Want to minimize boilerplate

**Use traditional manual structure if:**

- Have complex custom webpack requirements
- Need fine-grained control over bundle composition
- Migrating from older React on Rails versions

For most projects, we recommend the modern auto-bundling approach.

## Steps to convert from the generator defaults to use a `/client` directory for source code

1. Move the directory:

```bash
mv app/javascript client
```

2. Edit your `/config/shakapacker.yml` file. Change the `default/source_path`:

```yml
source_path: client
```

## Styling Your Components

React on Rails supports multiple approaches for styling your components. The modern recommended approach uses **CSS Modules** with co-located stylesheets.

### Modern Approach: CSS Modules (Recommended)

The generator creates components with CSS Module support out of the box:

```text
app/javascript/src/HelloWorld/
├── ror_components/
│   ├── HelloWorld.client.jsx
│   └── HelloWorld.module.css    # Co-located with component
```

**Example usage:**

```jsx
import React from 'react';
import * as style from './HelloWorld.module.css';

const HelloWorld = () => <label className={style.bright}>Hello World</label>;
```

**Benefits:**

- **Scoped styles**: Class names are automatically scoped to prevent conflicts
- **Co-location**: Styles live next to their components for better organization
- **Type safety**: Works seamlessly with TypeScript
- **Hot reloading**: Style changes reload instantly without page refresh
- **Zero configuration**: Works out of the box with the generator

### Alternative: Rails Asset Pipeline

You can continue using Rails' traditional asset pipeline with [sass-rails](https://rubygems.org/gems/sass-rails) or similar gems:

```erb
<%# app/views/layouts/application.html.erb %>
<%= stylesheet_link_tag 'application', media: 'all' %>
```

**Use this approach when:**

- You have existing Rails stylesheets you want to keep
- You prefer keeping styles completely separate from JavaScript
- You don't need component-scoped styling

### Advanced: Global Styles with Webpack

For global styles (fonts, resets, variables), you can create additional webpack entry points:

```text
app/javascript/
├── packs/
│   ├── application.css    # Global styles
│   └── server-bundle.js
└── src/
    └── HelloWorld/
        └── ror_components/
            ├── HelloWorld.jsx
            └── HelloWorld.module.css
```

Import global styles in your layout:

```erb
<%= stylesheet_pack_tag 'application' %>
```
