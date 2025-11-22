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

1. Run Shakapacker's `precompile_hook` once (if configured in `config/shakapacker.yml`)
2. Set `SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true` to prevent duplicate execution
3. Try to use Overmind (if installed)
4. Fall back to Foreman (if installed)
5. Show installation instructions if neither is found

### Precompile Hook Integration

If you have configured a `precompile_hook` in `config/shakapacker.yml`, `bin/dev` will automatically:

- Execute the hook **once** before starting development processes
- Set the `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` environment variable
- Pass this environment variable to all spawned processes (Rails, webpack, etc.)
- Prevent webpack processes from re-running the hook independently

**Note:** The `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` environment variable is supported in Shakapacker 9.4.0 and later. If you're using an earlier version, `bin/dev` will display a warning recommending you upgrade to avoid duplicate hook execution.

This eliminates the need for manual coordination in your `Procfile.dev`. For example:

**Before (manual coordination with sleep hacks):**

```procfile
# Procfile.dev
wp-server: sleep 15 && bundle exec rake react_on_rails:locale && bin/shakapacker --watch
```

**After (automatic coordination via bin/dev):**

```procfile
# Procfile.dev
wp-server: bin/shakapacker --watch
```

```yaml
# config/shakapacker.yml
default: &default
  precompile_hook: 'bundle exec rake react_on_rails:locale'
```

See the [i18n documentation](./i18n.md#internationalization) for more details on configuring the precompile hook.

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
