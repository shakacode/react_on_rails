# Using Process Managers with React on Rails

React on Rails requires running multiple processes simultaneously during development:

- Rails server
- Webpack dev server (client bundle)
- Webpack watcher (server bundle)

## Running Your Development Server

React on Rails includes `bin/dev` which automatically uses Overmind or Foreman:

```bash
./bin/dev
```

This script will:

1. Try to use Overmind (if installed)
2. Fall back to Foreman (if installed)
3. Show installation instructions if neither is found

## Installing a Process Manager

### Overmind (Recommended)

Overmind provides easier debugging and better signal handling:

```bash
# macOS
brew install overmind

# Linux
# See: https://github.com/DarthSim/overmind#installation
```

### Foreman (Alternative)

Foreman is a widely-used Ruby-based process manager:

```bash
# Install globally (NOT in Gemfile)
gem install foreman
```

**Important:** Do NOT add Foreman to your `Gemfile`. Install it globally on your system.

**Why not in Gemfile?**

From [Foreman's documentation](https://github.com/ddollar/foreman/wiki/Don't-Bundle-Foreman):

> Foreman is not a library, and should not affect the dependency tree of your application.

Key reasons:

- **Dependency conflicts**: Including Foreman in your Gemfile can create dependency conflicts that break other projects
- **Security risk**: Loading Foreman as an application dependency creates an unnecessary security vulnerability vector
- **Stability**: Foreman is mature and stable; bundling it could introduce bugs from unnecessary dependency updates
- **Wrong abstraction**: Foreman is a system tool, not an application dependency

Install Foreman globally: `gem install foreman`

## Alternative: Run Process Managers Directly

You can also run process managers directly instead of using `bin/dev`:

```bash
# With Overmind
overmind start -f Procfile.dev

# With Foreman
foreman start -f Procfile.dev
```

## Customizing Your Setup

Edit `Procfile.dev` in your project root to customize which processes run and their configuration.

The default `Procfile.dev` includes:

```procfile
rails: bundle exec rails s -p 3000
wp-client: bin/shakapacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=true bin/shakapacker --watch
```

## See Also

- [HMR and Hot Reloading](./hmr-and-hot-reloading-with-the-webpack-dev-server.md)
- [Foreman documentation](https://github.com/ddollar/foreman)
- [Overmind documentation](https://github.com/DarthSim/overmind)
