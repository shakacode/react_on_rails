# Troubleshooting Build Errors

This guide covers common webpack build errors encountered when using react_on_rails and how to resolve them.

## Table of Contents

- [Missing Routes File Error](#missing-routes-file-error)
- [ProvidePlugin Module Resolution Errors](#provideplugin-module-resolution-errors)
- [Environment Setup Dependencies](#environment-setup-dependencies)
- [Shakapacker Compatibility Issues](#shakapacker-compatibility-issues)
- [For Coding Agents](#for-coding-agents)

## Missing Routes File Error

### Error Message
```
Cannot read properties of undefined (reading 'module')
TypeError: Cannot read properties of undefined (reading 'module')
    at ProvidedDependencyTemplate.apply
```

### Root Cause
This error typically occurs when webpack's `ProvidePlugin` cannot resolve a module reference. A common case is when the Rails routes file hasn't been generated for JavaScript consumption.

### Solution
1. **Generate JavaScript routes file:**
   ```bash
   bundle exec rails js:export
   ```

2. **Verify the routes file was created:**
   ```bash
   ls app/javascript/utils/routes.js
   ```

3. **Check webpack configuration:**
   Ensure your webpack config has the correct ProvidePlugin setup:
   ```javascript
   new webpack.ProvidePlugin({
     Routes: "$app/utils/routes"
   })
   ```

4. **Verify alias configuration:**
   ```javascript
   resolve: {
     alias: {
       $app: path.join(rootPath, "app/javascript"),
     }
   }
   ```

### Prevention
- Always run `rails js:export` after initial setup
- Include this step in your development setup documentation
- Consider adding it to your `package.json` setup script:
  ```json
  {
    "scripts": {
      "setup": "bundle exec rails js:export && npm install"
    }
  }
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
Some react_on_rails operations require a working Rails environment:

- `rails js:export` (generates routes)
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
|----------------|-------------|---------|---------|
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

- Check the [general troubleshooting guide](./troubleshooting-when-using-shakapacker.md)
- Review [webpack configuration docs](./webpack.md)
- Contact [justin@shakacode.com](mailto:justin@shakacode.com) for professional support
