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

### Migration Checklist

If you have not already completed Sections 1–4 below (start at [Section 1](#1-customize-bindev)), do that first so
`bin/dev`, `config/shakapacker.yml`, your Procfiles, and your build commands are in place before you start removing
duplicates.

When moving custom build work out of `precompile_hook`, make the ownership change in one commit so the same task cannot run twice. The checklist uses letters (A–E) so the steps are easy to distinguish from the numbered Implementation sections referenced above.

A. Add (or uncomment, if already present) custom one-time tasks to the `run_precompile_tasks` method in `bin/dev`
(see [Section 1](#1-customize-bindev) for the generator-provided template).

B. Ensure `build_test_command` and `build_production_command` each include every one-time build task those lifecycles
need, such as ReScript builds, TypeScript checks or compilation, and locale generation. `bin/dev` is not invoked in
CI or production, so these commands are the only mechanism those lifecycles have.

C. After verifying the updated commands work locally, remove one-time build commands from individual Procfile process
entries. If those same commands appear as standalone steps in CI/CD pipeline scripts, remove those duplicate
invocations too. For example, remove a bare `yarn res:build` GitHub Actions step only after `build_test_command` or
`build_production_command` includes it. Do not delete entire `.github/workflows`, `.circleci/config.yml`, or Heroku
`app.json` files unless they exist solely for the migrated build step.

D. Confirm `precompile_hook` has been removed from `config/shakapacker.yml` (per
[Section 2](#2-configure-shakapackeryml)) so the same task does not also run during webpack compiles.

E. Keep long-running watchers, such as `rescript: yarn res:watch`, as separate Procfile processes.

The goal is one owner per lifecycle: `bin/dev` owns development startup, Procfile processes own long-running watchers, and React on Rails build commands own test and production compilation.

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

Remove the `precompile_hook` from `config/shakapacker.yml`, since `bin/dev` now handles precompile tasks directly:

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
  # precompile_hook not configured - handled by bin/dev instead

```

### 3. Clean Procfiles

Remove precompile logic from your Procfiles:

**Before (embedded precompile logic):**

```procfile
# Procfile.dev - Old approach with duplicated precompile
rescript: yarn res:watch
rails: bundle exec rails server -p 3000
wp-client: sleep 15 && bundle exec rake react_on_rails:locale && bin/shakapacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=true bin/shakapacker --watch
```

**After (clean and simple):**

```procfile
# Procfile.dev - Clean approach with precompile in bin/dev
rescript: yarn res:watch
rails: bundle exec rails server -p 3000
wp-client: bin/shakapacker-dev-server
wp-server: SERVER_BUNDLE_ONLY=true bin/shakapacker --watch
```

### 4. Configure Build Commands

Handle test and production builds in `config/initializers/react_on_rails.rb`. These commands must include every build step that production deploys and CI test runs require, because `bin/dev` is not part of those lifecycles:

In CI, ReactOnRails::TestHelper runs `build_test_command` when test assets need compilation. See
[testing configuration](testing-configuration.md#quick-start) for the RSpec/Minitest wiring. During
`assets:precompile`, React on Rails runs `build_production_command`.

Choose one of the following configuration styles. Use only one: Option A sets the commands directly, while Option B
points both commands at the helper script.

#### Option A - Inline commands

```ruby
ReactOnRails.configure do |config|
  # Build commands should include all necessary steps.
  # Shakapacker auto-derives NODE_ENV from RAILS_ENV, so the test command leaves NODE_ENV implicit.
  # The production command sets NODE_ENV=production explicitly as a belt-and-suspenders safeguard
  # against any pre-shakapacker step (e.g. a custom yarn script) that reads NODE_ENV directly.
  config.build_test_command = "yarn res:build && RAILS_ENV=test bin/shakapacker"
  config.build_production_command = "yarn res:build && RAILS_ENV=production NODE_ENV=production bin/shakapacker"
end
```

#### Option B - Script wrapper (recommended for multi-step builds)

If your build needs more than one pre-shakapacker step, such as a TypeScript check and a ReScript compile, prefer a small
Ruby script over a very long command string. Create `bin/build-react-on-rails`:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "rbconfig"

# Pin the working directory to the Rails application root so the relative paths below resolve correctly even when
# `config.node_modules_location` is a subdirectory. React on Rails prepends `cd "<node_modules_location>"` to
# `build_test_command` and `build_production_command`, which would otherwise leave the script looking for
# `bin/shakapacker` under that subdirectory. See the note under the configuration example below for invoking the
# wrapper itself from a custom `node_modules_location`.
Dir.chdir(File.expand_path("..", __dir__))

mode = ARGV.first

unless %w[test production].include?(mode)
  abort "Usage: bin/build-react-on-rails test|production\nGot: #{mode.inspect}"
end

# Add your app's pre-build step(s) here. They run for both test and production.
# Leave this section empty if shakapacker is the only build step.
# If a pre-build command needs env vars, pass them via a hash:
#   system({ "SOME_VAR" => "value" }, "yarn", "custom:build") || abort("custom:build failed")
# The mode-specific env hashes below are intentionally scoped to each shakapacker call.
# For example, to run TypeScript then ReScript:
#   # --noEmit type-checks only; ts-loader/babel-loader handle transpilation during webpack bundling.
#   system("yarn", "tsc", "--noEmit") || abort("tsc type-check failed")
#   system("yarn", "res:build")       || abort("res:build failed")

# Mode-specific invocation below. `RbConfig.ruby` runs shakapacker with the same Ruby interpreter that launched this
# wrapper, and the `Dir.chdir` above keeps `bin/shakapacker` resolvable from the Rails application root. The
# shakapacker binstub is a Ruby file by convention, so passing it to `RbConfig.ruby` is portable; if your project
# replaces `bin/shakapacker` with a shell wrapper, drop `RbConfig.ruby` and invoke the binstub directly (after
# ensuring the right Ruby is on `PATH`). Add shared steps above, not inside the case blocks.
case mode
when "test"
  env = { "RAILS_ENV" => "test" }
  system(env, RbConfig.ruby, "bin/shakapacker") || abort("shakapacker (test) failed")
when "production"
  env = { "RAILS_ENV" => "production", "NODE_ENV" => "production" }
  system(env, RbConfig.ruby, "bin/shakapacker") || abort("shakapacker (production) failed")
end
```

On Unix-like filesystems, make the script executable so it can run locally, then stage the file so Git records the
executable bit for CI and other checkouts:

```bash
chmod +x bin/build-react-on-rails
git add bin/build-react-on-rails
```

`git add --chmod=+x bin/build-react-on-rails` (Git 2.9 or newer) is a useful shortcut, but it only updates the
executable bit in Git's index — the file mode on disk is left unchanged. The script will still not be runnable from
this checkout until `chmod +x` is also applied. Use the shortcut when CI is the only consumer that needs the
executable bit; otherwise keep the two-step `chmod +x` then `git add` so the file is executable both locally and in
committed history.

<details>
<summary>Windows and Docker bind mounts</summary>

On Windows or Docker bind mounts backed by a Windows filesystem, the filesystem may not preserve Unix modes, so `chmod`
may not make the current checkout runnable. Record the executable bit in Git for CI and other checkouts, and invoke the
script through Ruby when running it from that local filesystem:

```bash
git update-index --chmod=+x bin/build-react-on-rails
ruby bin/build-react-on-rails test
```

If the file has not been staged yet, use `git update-index --add --chmod=+x bin/build-react-on-rails` instead. Use
`production` instead of `test` for the production build command. The `git update-index` command only updates Git metadata;
it does not change the current working-tree file mode.

Configure `react_on_rails.rb` once. Prefix the helper with `ruby` so the same commands work on Unix, macOS, CI, and
Windows or Windows-backed Docker bind-mount checkouts without relying on the current filesystem's executable bit.
The outer `ruby` is resolved via `PATH` when Rails runs the build command, which works under rbenv/asdf/mise and
standard CI images. For hermetic environments where `PATH` may not select the project's interpreter (e.g. some Docker
base images without active version-manager shims), invoke through Bundler or substitute an absolute Ruby path — for
example `bundle exec ruby bin/build-react-on-rails test` or `$(rbenv which ruby) bin/build-react-on-rails test`.
Inside the script, `RbConfig.ruby` already pins shakapacker to the same interpreter that launched the wrapper.

</details>

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "ruby bin/build-react-on-rails test"
  config.build_production_command = "ruby bin/build-react-on-rails production"
end
```

> **If you set `config.node_modules_location`:** React on Rails prepends `cd "<node_modules_location>"` to both
> build commands, so the bare `ruby bin/build-react-on-rails …` invocation above will not find the wrapper from a
> subdirectory. Interpolate an absolute path from `Rails.root` so the script is locatable regardless of the
> prepended `cd`. React on Rails passes these command strings to a shell, so escape the interpolated path with
> `Shellwords.escape` (Ruby stdlib) — a bare `#{wrapper}` would break on any `Rails.root` containing spaces or
> other shell metacharacters (e.g. `/Users/jane doe/my app`):
>
> ```ruby
> require "shellwords"
>
> wrapper = Shellwords.escape(Rails.root.join("bin", "build-react-on-rails").to_s)
> config.build_test_command       = "ruby #{wrapper} test"
> config.build_production_command = "ruby #{wrapper} production"
> ```
>
> The `Dir.chdir` inside the wrapper then re-pins the working directory to the Rails root for the inner
> `bin/shakapacker` call.

This keeps the migration reviewable and avoids duplicating custom build logic across `bin/dev`, Procfiles, and deploy scripts.

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

## Execution Timing

With this pattern, precompile tasks run:

- Once when you start `bin/dev`
- On manual restarts of `bin/dev`
- **Not** on file changes during development
- **Not** on webpack hot reload

For file-watching behavior (e.g., ReScript watch mode), add a separate Procfile process instead.
For production builds, ensure all tasks are included in `build_production_command`.

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

This pattern requires **React on Rails 16.4.0+** and works with any version of Shakapacker. The `ReactOnRails::Locales.compile` API has been available since React on Rails introduced i18n support and is the same method used internally by the `react_on_rails:locale` rake task.

## See Also

- [Process Managers](./process-managers.md) - Using Overmind/Foreman with bin/dev
- [Internationalization](./i18n.md) - i18n configuration and locale generation
- [Auto-Bundling](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md) - Automatic component pack generation
