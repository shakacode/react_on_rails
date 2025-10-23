# Generator Details

The `react_on_rails:install` generator combined with the example pull requests of generator runs will get you up and running efficiently. There's a fair bit of setup with integrating Webpack with Rails. Defaults for options are such that the default is for the flag to be off. For example, the default for `-R` is that `redux` is off.

Run `rails generate react_on_rails:install --help` for descriptions of all available options:

```
Usage:
  rails generate react_on_rails:install [options]

Options:
  -R, [--redux], [--no-redux]                      # Install Redux package and Redux version of Hello World Example. Default: false
      [--ignore-warnings], [--no-ignore-warnings]  # Skip warnings. Default: false

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist

Description:

The react_on_rails:install generator integrates webpack with rails with ease. You
can pass the redux option if you'd like to have redux setup for you automatically.

* Redux

    Passing the --redux generator option causes the generated Hello World example
    to integrate the Redux state container framework. The necessary node modules
    will be automatically included for you.

*******************************************************************************


Then you may run

    `rails s`
```

Another good option is to create a simple test app per the [Tutorial](../getting-started/tutorial.md).

## Understanding the Organization of the Generated Client Code

The React on Rails generator creates different directory structures depending on whether you use the `--redux` option.

### Default Structure (Without Redux)

The basic generator creates a simple, flat structure optimized for auto-bundling:

```
app/javascript/
└── src/
    └── HelloWorld/
        └── ror_components/          # Components auto-registered by React on Rails
            ├── HelloWorld.jsx       # Your React component
            ├── HelloWorld.module.css
            └── HelloWorld.server.js # Optional: separate server rendering logic
```

- **`src/`**: Source directory for all React components
- **`ror_components/`**: Directory name is configurable via `config.components_subdirectory` in `config/initializers/react_on_rails.rb`
- **Auto-registration**: Components in `ror_components/` directories are automatically discovered and registered when using `auto_load_bundle: true`

For components that need different client vs. server implementations, use `.client.jsx` and `.server.jsx` suffixes (e.g., `HelloWorld.client.jsx` and `HelloWorld.server.jsx`).

### Redux Structure (With `--redux` Option)

The Redux generator creates a more structured organization with familiar Redux patterns:

```
app/javascript/
└── src/
    └── HelloWorldApp/
        ├── actions/                 # Redux action creators
        │   └── helloWorldActionCreators.js
        ├── components/              # Presentational components
        │   ├── HelloWorld.jsx
        │   └── HelloWorld.module.css
        ├── constants/               # Action type constants
        │   └── helloWorldConstants.js
        ├── containers/              # Connected components (smart components)
        │   └── HelloWorldContainer.js
        ├── reducers/                # Redux reducers
        │   └── helloWorldReducer.js
        ├── ror_components/          # Auto-registered entry points
        │   ├── HelloWorldApp.client.jsx
        │   └── HelloWorldApp.server.jsx
        └── store/                   # Redux store configuration
            └── helloWorldStore.js
```

This structure follows Redux best practices:

- **`components/`**: Presentational "dumb" components that receive data via props
- **`containers/`**: Container "smart" components connected to Redux store
- **`actions/`** and **`reducers/`**: Standard Redux patterns
- **`ror_components/`**: Entry point files that initialize Redux and render the app

### TypeScript Support

The generator also supports a `--typescript` option for generating TypeScript files:

```bash
rails generate react_on_rails:install --typescript
```

This creates `.tsx` files instead of `.jsx` and adds TypeScript configuration.

### Auto-Bundling and Component Registration

Modern React on Rails uses auto-bundling to eliminate manual webpack configuration. Components placed in the configured `components_subdirectory` (default: `ror_components`) are automatically:

1. Discovered by the generator
2. Bundled into separate webpack entry points
3. Registered for use with `react_component` helper
4. Loaded on-demand when used in views

For detailed information on auto-bundling, see the [Auto-Bundling Guide](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md).
