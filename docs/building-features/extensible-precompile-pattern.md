# Extensible bin/dev Precompile Pattern

This guide describes an alternative approach to handling precompile tasks that provides more flexibility than the default `precompile_hook` mechanism. This pattern is especially useful for projects with custom build requirements.

## Overview

React on Rails offers two approaches for running tasks before webpack compilation:

| Approach                      | Best For                                                   | Complexity |
| ----------------------------- | ---------------------------------------------------------- | ---------- |
| **Default (precompile_hook)** | Simple projects, single precompile task                    | Low        |
| **Extensible (bin/dev)**      | Custom build steps, multiple tasks, version manager issues | Medium     |

## When to Use This Pattern

Consider this approach if you:

- Have multiple precompile tasks (ReScript, TypeScript compilation, custom locale generation)
- Experience version manager issues (mise, asdf, rbenv) with rake tasks
- Want cleaner Procfiles without embedded precompile logic
- Need direct Ruby API access for faster execution
- Want a single place to manage all precompile tasks

## Implementation

### 1. Customize bin/dev

The React on Rails generator creates a `bin/dev` script with an extensible precompile pattern. Uncomment and customize the `run_precompile_tasks` method:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

def run_precompile_tasks
  require_relative "../config/environment"

  puts "📦 Running precompile tasks..."

  # Example: Build ReScript files
  print "   ReScript build... "
  unless system("yarn res:build")
    puts "❌"
    exit(1)
  end
  puts "✅"

  # Locale generation via direct Ruby API (faster, no shell issues)
  # compile handles all edge cases gracefully: prints warnings if no locale
  # files found, skips if output files are up-to-date, safe to call always.
  # Exceptions (e.g., missing directories) bubble up and stop the server,
  # which surfaces configuration issues early.
  print "   Locale generation... "
  ReactOnRails::Locales.compile if ReactOnRails.configuration.i18n_dir.present?
  puts "✅"

  # Add more custom tasks as needed
  # print "   Custom task... "
  # YourCustomModule.run
  # puts "✅"

  puts ""
end

require "bundler/setup"
require "react_on_rails/dev"

DEFAULT_ROUTE = "hello_world"

argv_with_defaults = ARGV.dup
argv_with_defaults.push("--route=#{DEFAULT_ROUTE}") unless argv_with_defaults.any? { |arg| arg.start_with?("--route") }

# Run precompile tasks before starting server (except for kill/help commands)
unless ARGV.include?("kill") || ARGV.include?("-h") || ARGV.include?("--help") || ARGV.include?("help")
  run_precompile_tasks
end

ReactOnRails::Dev::ServerManager.run_from_command_line(argv_with_defaults)
```

### 2. Configure shakapacker.yml

Remove or comment out the `precompile_hook` in `config/shakapacker.yml`, since `bin/dev` now handles precompile tasks directly:

**Before (default precompile_hook approach):**

```yaml
default: &default # ... other settings ...
  precompile_hook: 'bundle exec rake react_on_rails:locale'
```

**After (extensible bin/dev approach):**

```yaml
default: &default
  # ... other settings ...

  # precompile_hook is not used here because:
  # - In development: bin/dev runs precompile tasks before starting processes
  # - In production: build_production_command includes all build steps
  # precompile_hook: (not configured)

```

### 3. Clean Procfiles

Remove precompile logic from your Procfiles:

**Before (embedded precompile logic):**

```procfile
# Procfile.dev - Old approach with duplicated precompile
rescript: yarn res:watch
rails: bundle exec rails server -p 3000
wp-client: sleep 15 && bundle exec rake react_on_rails:locale && bin/shakapacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch
```

**After (clean and simple):**

```procfile
# Procfile.dev - Clean approach with precompile in bin/dev
rescript: yarn res:watch
rails: bundle exec rails server -p 3000
wp-client: bin/shakapacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=yes bin/shakapacker --watch
```

### 4. Configure Build Commands

Handle production builds in `config/initializers/react_on_rails.rb`:

```ruby
ReactOnRails.configure do |config|
  # Build commands should include all necessary steps
  config.build_test_command = "yarn res:build && RAILS_ENV=test bin/shakapacker"
  config.build_production_command = "yarn res:build && RAILS_ENV=production NODE_ENV=production bin/shakapacker"
end
```

## Direct Ruby API Reference

### ReactOnRails::Locales.compile

Generates locale files for i18n support.

```ruby
# Basic usage - skips if files are up-to-date
ReactOnRails::Locales.compile

# Force regeneration
ReactOnRails::Locales.compile(force: true)
```

This method:

- Reads YAML locale files from `config.i18n_yml_dir` (or Rails i18n load path)
- Generates JavaScript/JSON files in `config.i18n_dir`
- Skips generation if output files are newer than source files (unless `force: true`)
- Supports both JSON and JavaScript output formats based on `config.i18n_output_format`

### ReactOnRails::PacksGenerator

Generates webpack pack files for auto-bundling.

```ruby
# Generate packs if stale (used by bin/dev automatically)
ReactOnRails::PacksGenerator.instance.generate_packs_if_stale
```

## Benefits Comparison

| Aspect                            | Default (precompile_hook)            | Extensible (bin/dev)                          |
| --------------------------------- | ------------------------------------ | --------------------------------------------- |
| **Custom build steps**            | Modify hook script (mixing concerns) | Add to `run_precompile_tasks` method          |
| **Procfile clarity**              | May need embedded shell commands     | Clean, single-purpose processes               |
| **Locale generation**             | Via rake task (slow, shell issues)   | Direct `ReactOnRails::Locales.compile` (fast) |
| **Version manager compatibility** | Rake task may use wrong Ruby         | Direct Ruby call uses correct version         |
| **Debugging**                     | Multiple indirection layers          | Clear sequential execution                    |
| **When precompile runs**          | Before each webpack compile          | Once at dev server startup                    |

## Troubleshooting

### Version Manager Issues

If you experience issues where rake tasks use the wrong Ruby version (common with mise, asdf, or rbenv in non-interactive shells):

1. Use the direct Ruby API in `bin/dev` instead of rake tasks
2. The Rails environment loaded in `bin/dev` will use the correct Ruby version

### Missing Environment

If you see "uninitialized constant ReactOnRails" errors:

```ruby
# Ensure Rails environment is loaded before using React on Rails APIs
require_relative "../config/environment"
```

### Precompile Tasks Running Multiple Times

If using this pattern, ensure you:

1. Remove the `precompile_hook` from `shakapacker.yml`
2. Remove precompile commands from Procfile entries
3. Only call `run_precompile_tasks` once in `bin/dev`

## FAQ

### When should I NOT use this pattern?

Stick with the default `precompile_hook` approach if:

- You only have a single precompile task (e.g., locale generation)
- Your version manager works fine with rake tasks in all contexts
- You prefer Shakapacker to handle precompile timing automatically

The extensible pattern adds configuration overhead that isn't justified for simple setups.

## Compatibility

This pattern requires **React on Rails 16.2+** and works with any version of Shakapacker. The `ReactOnRails::Locales.compile` API has been available since React on Rails introduced i18n support and is the same method used internally by the `react_on_rails:locale` rake task.

## See Also

- [Process Managers](./process-managers.md) - Using Overmind/Foreman with bin/dev
- [Internationalization](./i18n.md) - i18n configuration and locale generation
- [Auto-Bundling](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md) - Automatic component pack generation
