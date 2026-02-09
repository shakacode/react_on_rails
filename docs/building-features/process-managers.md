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

1. Check database connectivity (unless disabled)
2. Check required external services (if `.dev-services.yml` exists)
3. Run Shakapacker's `precompile_hook` once (if configured in `config/shakapacker.yml`)
4. Set `SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true` to prevent duplicate execution
5. Try to use Overmind (if installed)
6. Fall back to Foreman (if installed)
7. Show installation instructions if neither is found

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

> [!TIP]
> **For HMR with SSR setups** (two webpack processes), use a script-based hook instead of a
> direct command. Script-based hooks can include a self-guard that prevents duplicate execution
> regardless of Shakapacker version. See the [i18n documentation](./i18n.md#internationalization)
> for an example.

See the [i18n documentation](./i18n.md#internationalization) for more details on configuring the precompile hook.

### Alternative: Extensible Precompile Pattern

For projects with custom build requirements (ReScript, TypeScript compilation, multiple precompile tasks), consider handling precompile tasks directly in `bin/dev` instead of using the precompile_hook mechanism.

This approach provides:

- Single place to manage all precompile tasks
- Direct Ruby API calls (faster, better version manager compatibility)
- Clean Procfiles without embedded precompile logic

See the [Extensible Precompile Pattern](./extensible-precompile-pattern.md) guide for full details.

### Service Dependency Checking

`bin/dev` can automatically verify that required external services (like Redis, PostgreSQL, Elasticsearch) are running before starting your development server. This prevents cryptic error messages and provides clear instructions on how to start missing services.

#### Configuration

Create a `.dev-services.yml` file in your project root:

```yaml
services:
  redis:
    check_command: 'redis-cli ping'
    expected_output: 'PONG'
    start_command: 'redis-server'
    install_hint: 'brew install redis (macOS) or apt-get install redis-server (Linux)'
    description: 'Redis (for caching and background jobs)'

  postgresql:
    check_command: 'pg_isready'
    expected_output: 'accepting connections'
    start_command: 'pg_ctl -D /usr/local/var/postgres start'
    install_hint: 'brew install postgresql (macOS)'
    description: 'PostgreSQL database'
```

A `.dev-services.yml.example` file with common service configurations is created when you run the React on Rails generator.

#### Configuration Fields

- **check_command** (required): Shell command to check if the service is running
- **expected_output** (optional): String that must appear in the command output
- **start_command** (optional): Command to start the service (shown in error messages)
- **install_hint** (optional): How to install the service if not found
- **description** (optional): Human-readable description of the service

#### Behavior

If `.dev-services.yml` exists, `bin/dev` will:

1. Check each configured service before starting
2. Show a success message if all services are running
3. Show helpful error messages with start commands if any service is missing
4. Exit before starting the Procfile if services are unavailable

If `.dev-services.yml` doesn't exist, `bin/dev` works exactly as before (zero impact on existing installations).

#### Example Output

**When services are running:**

```
🔍 Checking required services (.dev-services.yml)...

   ✓ redis - Redis (for caching and background jobs)
   ✓ postgresql - PostgreSQL database

✅ All services are running
```

**When services are missing:**

```
🔍 Checking required services (.dev-services.yml)...

   ✗ redis - Redis (for caching and background jobs)

❌ Some services are not running

Please start these services before running bin/dev:

redis
   Redis (for caching and background jobs)

   To start:
   redis-server

   Not installed? brew install redis (macOS) or apt-get install redis-server (Linux)

💡 Tips:
   • Start services manually, then run bin/dev again
   • Or remove service from .dev-services.yml if not needed
   • Or add service to Procfile.dev to start automatically
```

### Database Connectivity Check

`bin/dev` automatically checks that your Rails database is accessible before starting the development server. This catches common issues like a missing database or a stopped database server, and provides clear error messages with specific commands to fix the problem.

#### Behavior

When `bin/dev` starts, it runs a quick Rails runner process to verify:

1. The database exists and accepts connections
2. Migrations are up to date (warns but does not block if pending)

If the database is not accessible, `bin/dev` prints a clear error message and exits before starting any processes.

**Note:** This check adds ~1-2 seconds to startup time as it spawns a Rails runner process.

#### Disabling the Check

There are three ways to disable the database check, listed by priority:

1. **CLI flag** (highest priority):

   ```bash
   bin/dev --skip-database-check
   ```

2. **Environment variable**:

   ```bash
   SKIP_DATABASE_CHECK=true bin/dev
   ```

3. **Configuration** in `config/initializers/react_on_rails.rb`:

   ```ruby
   ReactOnRails.configure do |config|
     config.check_database_on_dev_start = false
   end
   ```

**When to disable:**

- Apps that don't use a database (API-only backends with external data stores)
- Rapid restart workflows where the 1-2 second overhead matters (e.g., TDD with guard/watchman)
- Projects where ActiveRecord is not loaded

#### Security Note

⚠️ **IMPORTANT**: Commands in `.dev-services.yml` are executed during `bin/dev` startup without shell expansion for safety. However, you should still:

- **Only add commands from trusted sources**
- **Avoid shell metacharacters** (&&, ||, ;, |, $, etc.) - they won't work and indicate an anti-pattern
- **Review changes carefully** if .dev-services.yml is committed to version control
- **Consider adding to .gitignore** if it contains machine-specific paths or sensitive information

**Recommended approach:**

- Commit `.dev-services.yml.example` to version control (safe, documentation)
- Add `.dev-services.yml` to `.gitignore` (developers copy from example)
- This prevents accidental execution of untrusted commands from compromised dependencies

**Execution order:**

1. Database connectivity check (unless disabled)
2. Service dependency checks (`.dev-services.yml`)
3. Precompile hook (if configured in `config/shakapacker.yml`)
4. Process manager starts processes from Procfile

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
