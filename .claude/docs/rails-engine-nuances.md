# Rails Engine Development Nuances

React on Rails is a **Rails Engine**, which has important implications for development.

## Automatic Rake Task Loading

**CRITICAL**: Rails::Engine automatically loads all `.rake` files from `lib/tasks/` directory. **DO NOT** use a `rake_tasks` block to explicitly load them, as this causes duplicate task execution.

```ruby
# WRONG - Causes duplicate execution
module ReactOnRails
  class Engine < ::Rails::Engine
    rake_tasks do
      load File.expand_path("../tasks/generate_packs.rake", __dir__)
      load File.expand_path("../tasks/assets.rake", __dir__)
      load File.expand_path("../tasks/locale.rake", __dir__)
    end
  end
end

# CORRECT - Rails::Engine loads lib/tasks/*.rake automatically
module ReactOnRails
  class Engine < ::Rails::Engine
    # Rake tasks are automatically loaded from lib/tasks/*.rake by Rails::Engine
    # No explicit loading needed
  end
end
```

**When to use `rake_tasks` block:**

- Tasks are in a **non-standard location** (not `lib/tasks/`)
- You need to **programmatically generate** tasks
- You need to **pass context** to the tasks

**Historical Context**: PR #1770 added explicit rake task loading, causing webpack builds and pack generation to run twice during `rake assets:precompile`. This was fixed in PR #2052. See `analysis/rake-task-duplicate-analysis.md` for full details.

## Engine Initializers and Hooks

Engines have specific initialization hooks that run at different times:

```ruby
module ReactOnRails
  class Engine < ::Rails::Engine
    # Runs after Rails initializes but before routes are loaded
    config.to_prepare do
      ReactOnRails::ServerRenderingPool.reset_pool
    end

    # Runs during Rails initialization, use for validations
    initializer "react_on_rails.validate_version" do
      config.after_initialize do
        # Validation logic here
      end
    end
  end
end
```

## Engine vs Application Code

- **Engine code** (`lib/react_on_rails/`): Runs in the gem context, has limited access to host application
- **Host application code**: The Rails app that includes the gem
- **Generators** (`lib/generators/react_on_rails/`): Run in host app context during setup

## Testing Engines

- **Dummy app** (`react_on_rails/spec/dummy/`): Full Rails app for integration testing
- **Unit tests** (`react_on_rails/spec/react_on_rails/`): Test gem code in isolation
- Always test both contexts: gem code alone and gem + host app integration

## Common Pitfalls

1. **Assuming host app structure**: Don't assume `app/javascript/` exists—it might not in older apps
2. **Path resolution**: Use `Rails.root` for host app paths, not relative paths
3. **Autoloading**: Engine code follows Rails autoloading rules but with a different load path
4. **Configuration**: Engine config is separate from host app config—use `ReactOnRails.configure`
