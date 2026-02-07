# Troubleshooting Build Errors

This guide covers common webpack build errors encountered when using react_on_rails and how to resolve them.

## Table of Contents

- [Missing Routes File Error](#missing-routes-file-error-js-routes-gem)
- [ProvidePlugin Module Resolution Errors](#provideplugin-module-resolution-errors)
- [Environment Setup Dependencies](#environment-setup-dependencies)
- [Shakapacker Compatibility Issues](#shakapacker-compatibility-issues)
- [Duplicate Build Execution (Versions < 16.2.0)](#duplicate-build-execution-versions--1620)
- [For Coding Agents](#for-coding-agents)

## Missing Routes File Error (js-routes gem)

**Note:** This error only occurs if you're using the optional `js-routes` gem to access Rails routes in JavaScript.

### Error Message

```
Cannot read properties of undefined (reading 'module')
TypeError: Cannot read properties of undefined (reading 'module')
    at ProvidedDependencyTemplate.apply
```

### Root Cause

This error occurs when:

1. Your webpack config references Rails routes via ProvidePlugin
2. The `js-routes` gem hasn't generated the JavaScript routes file
3. You're using `js-routes` integration but missing the generated file

### When You Need js-routes

`js-routes` is **optional** and typically used when:

- Rails-heavy apps with React components that need to navigate to Rails routes
- Server-side rendered apps mixing Rails and React routing
- Legacy Rails apps migrating ERB views to React
- Apps using Rails routing patterns for RESTful APIs

### When You DON'T Need js-routes

Most modern React apps use:

- Client-side routing (React Router) instead of Rails routes
- Hardcoded API endpoints or environment variables
- SPA (Single Page App) architecture with API-only Rails backend

### Solution (if using js-routes)

1. **Generate JavaScript routes file:**

   ```bash
   bundle exec rails js:export
   ```

2. **Verify the routes file was created:**

   ```bash
   ls app/javascript/utils/routes.js
   ```

3. **Check webpack configuration includes ProvidePlugin:**
   ```javascript
   new webpack.ProvidePlugin({
     Routes: '$app/utils/routes',
   });
   ```

### Alternative Solution (if NOT using js-routes)

Remove the Routes ProvidePlugin from your webpack configuration:

```javascript
// Remove this line if you don't use js-routes
new webpack.ProvidePlugin({
  Routes: '$app/utils/routes', // ← Remove this
});
```

## ProvidePlugin Module Resolution Errors

### Common Error Patterns

- `Cannot read properties of undefined (reading 'module')`
- `Module not found: Error: Can't resolve 'module_name'`
- `ERROR in ./path/to/file.js: Cannot find name 'GlobalVariable'`

### Debugging Steps

1. **Check file existence:**

   ```bash
   find app/javascript -name "routes.*" -type f
   find app/javascript -name "*global*" -type f
   ```

2. **Verify webpack aliases:**

   ```javascript
   // In your webpack config
   console.log('Webpack aliases:', config.resolve.alias);
   ```

3. **Test module resolution:**

   ```bash
   # Run webpack with debug output
   bin/shakapacker --debug-shakapacker
   ```

4. **Check for circular dependencies:**
   ```bash
   # Install circular dependency plugin
   npm install --save-dev circular-dependency-plugin
   ```

### Common Fixes

1. **Missing global modules:** Ensure all modules referenced in ProvidePlugin exist
2. **Incorrect paths:** Verify alias paths are correct relative to project root
3. **File extensions:** Make sure webpack can resolve the file extension

## Environment Setup Dependencies

### Rails Environment Required

Some operations require a working Rails environment:

- `rails js:export` (generates routes - **only needed if using js-routes gem**)
- Asset precompilation
- Server-side rendering

### Common Issues

1. **Database Connection Errors:**

   ```
   MONGODB | Error checking localhost:27017: Connection refused
   ```

   **Solution:** These are usually warnings and don't prevent operation. To silence:

   ```bash
   # Run with minimal environment
   RAILS_ENV=development bundle exec rails js:export
   ```

2. **Missing Dependencies:**

   ```
   sidekiq-pro is not installed
   ```

   **Solution:** This is typically a warning for optional gems and won't affect builds.

### Workarounds

1. **Skip database initialization:**

   ```bash
   DATABASE_URL=sqlite3:tmp/db.sqlite3 rails js:export
   ```

2. **Use test environment:**
   ```bash
   RAILS_ENV=test rails js:export
   ```

## Shakapacker Compatibility Issues

### Version Compatibility Matrix

| react_on_rails | Shakapacker | Webpack | Node.js |
| -------------- | ----------- | ------- | ------- |
| v16.x          | >= 6.0      | v5      | 20-22   |
| v14.x          | >= 6.0      | v5      | 18-20   |
| v13.x          | >= 6.0      | v5      | 16-18   |

### Common Upgrade Issues

1. **Webpacker to Shakapacker migration incomplete:**

   ```bash
   # Remove webpacker references
   grep -r "webpacker" config/
   ```

2. **Old webpack configuration:**
   ```bash
   # Check for deprecated webpack configs
   find config/webpack -name "*.js" -exec grep -l "webpacker" {} \;
   ```

### Migration Steps

1. Follow the [Shakapacker upgrade guide](https://github.com/shakacode/shakapacker/blob/main/docs/v6_upgrade.md)
2. Update webpack configurations
3. Regenerate configurations with `rails generate react_on_rails:install`

## Duplicate Build Execution (Versions < 16.2.0)

### Symptom

If you're using React on Rails **versions before 16.2.0**, you may notice:

- Asset precompilation takes twice as long as expected
- Webpack build runs twice during `rake assets:precompile`
- Console output shows duplicate webpack compilation messages
- CI builds are slower than necessary

### Root Cause

In versions prior to 16.2.0, a bug in the Rails Engine caused rake task files to be loaded twice:

1. Once via explicit `load` calls in the Engine's `rake_tasks` block
2. Once via Rails Engine's automatic file loading from `lib/tasks/`

This resulted in tasks like `react_on_rails:assets:webpack`, `react_on_rails:generate_packs`, and `react_on_rails:locale` executing twice.

### Solution

**Upgrade to React on Rails 16.2.0 or later:**

```bash
# Update Gemfile
gem 'react_on_rails', '~> 16.2'

# Install
bundle update react_on_rails
```

The issue is fixed in version 16.2.0 ([PR #2052](https://github.com/shakacode/react_on_rails/pull/2052)).

### Workaround for Older Versions

If you cannot upgrade immediately, you can temporarily work around this by creating an initializer:

```ruby
# config/initializers/react_on_rails_fix.rb
Rails.application.config.after_initialize do
  # Only apply if using affected versions
  next unless ReactOnRails::VERSION < '16.2.0'

  # Remove duplicate task actions
  %w[
    react_on_rails:assets:webpack
    react_on_rails:generate_packs
    react_on_rails:locale
  ].each do |task_name|
    next unless Rake::Task.task_defined?(task_name)

    task = Rake::Task[task_name]
    task.actions.uniq! if task.actions.length > 1
  end
end
```

**Note:** This workaround is not recommended for production. Upgrade to 16.2.0+ for the proper fix.

## For Coding Agents

### Automated Diagnostics

When encountering build errors, run this diagnostic script:

```bash
#!/bin/bash
echo "=== React on Rails Build Diagnostics ==="

echo "1. Checking versions..."
bundle show react_on_rails | grep "react_on_rails"
npm list react-on-rails 2>/dev/null | grep "react-on-rails"

echo "2. Checking required files..."
[ -f "app/javascript/utils/routes.js" ] && echo "✓ Routes file exists" || echo "✗ Routes file missing - run 'rails js:export'"

echo "3. Checking webpack config..."
grep -q "ProvidePlugin" config/webpack/*.js && echo "✓ ProvidePlugin found" || echo "✗ ProvidePlugin not found"

echo "4. Checking aliases..."
grep -q "\$app" config/webpack/*.js && echo "✓ App alias found" || echo "✗ App alias missing"

echo "5. Testing build..."
npm run build 2>&1 | head -20
```

### Quick Fixes Checklist

For agents encountering build errors:

1. ✅ **Generate routes:** `rails js:export`
2. ✅ **Check file existence:** Verify all ProvidePlugin modules exist
3. ✅ **Update dependencies:** `bundle update react_on_rails && npm install`
4. ✅ **Clear cache:** `rm -rf tmp/cache node_modules/.cache`
5. ✅ **Regenerate config:** `rails generate react_on_rails:install` (review before applying)

### Error Pattern Recognition

Common error patterns for automated detection:

```regex
# Missing routes file
/Cannot read properties of undefined.*reading 'module'/

# ProvidePlugin issues
/Error: Can't resolve.*\$app/

# Version compatibility
/webpack.*incompatible/

# Missing dependencies
/Module not found.*react-on-rails/
```

### Automated Solutions

```bash
# Auto-fix missing routes
if ! [ -f "app/javascript/utils/routes.js" ]; then
  echo "Generating missing routes file..."
  bundle exec rails js:export
fi

# Auto-fix dependency issues
if grep -q "Cannot read properties" build.log; then
  echo "Updating dependencies..."
  bundle update react_on_rails
  npm install
fi
```

---

## Need More Help?

- Check the [general troubleshooting guide](../deployment/troubleshooting-when-using-shakapacker.md)
- Review [webpack configuration guide](../core-concepts/webpack-configuration.md)
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) for professional support
