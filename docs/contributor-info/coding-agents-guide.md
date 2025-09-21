# React on Rails Guide for Coding Agents

This guide provides structured instructions for AI coding agents working with React on Rails projects.

## Table of Contents

- [Quick Reference](#quick-reference)
- [Installation Workflows](#installation-workflows)
- [Upgrade Workflows](#upgrade-workflows)
- [Troubleshooting Patterns](#troubleshooting-patterns)
- [Error Detection and Auto-fixes](#error-detection-and-auto-fixes)
- [Best Practices for Agents](#best-practices-for-agents)

## Quick Reference

### Version Compatibility Matrix

| react_on_rails | Shakapacker | Webpack | Node.js | Ruby |
| -------------- | ----------- | ------- | ------- | ---- |
| v16.x          | >= 6.0      | v5      | 20-22   | 3.2+ |
| v14.x          | >= 6.0      | v5      | 18-20   | 2.7+ |
| v13.x          | >= 6.0      | v5      | 16-18   | 2.7+ |

### Essential Files to Check

- `Gemfile` - React on Rails gem version
- `package.json` - React on Rails npm package version
- `config/webpack/` - Webpack configuration
- `app/javascript/` - JavaScript source files
- `app/javascript/utils/routes.js` - Generated routes file (critical)

### Common Commands

```bash
# Generate JavaScript routes (critical step)
bundle exec rails js:export

# Install generator (review before applying)
rails generate react_on_rails:install

# Build assets
npm run build

# Start development server
bin/dev
```

## Installation Workflows

### New Rails Application

```bash
# 1. Create Rails app
rails new PROJECT_NAME --skip-javascript
cd PROJECT_NAME

# 2. Install Shakapacker
bundle add shakapacker --strict
rails shakapacker:install

# 3. Install React on Rails
bundle add react_on_rails --version=16.0.0 --strict

# 4. Run generator
rails generate react_on_rails:install

# 5. Install JavaScript dependencies
npm install

# 6. Generate routes (if using js-routes)
bundle exec rails js:export

# 7. Test build
npm run build
```

### Existing Rails Application

```bash
# 1. Check prerequisites
ls Gemfile | grep -q shakapacker || echo "⚠️  Shakapacker required"

# 2. Add React on Rails
bundle add react_on_rails --version=16.0.0 --strict

# 3. Run generator (REVIEW CHANGES)
rails generate react_on_rails:install --dry-run
# If acceptable:
rails generate react_on_rails:install

# 4. Install dependencies
bundle install
npm install

# 5. Generate routes (if using js-routes gem)
bundle exec rails js:export

# 6. Test
npm run build
```

## Upgrade Workflows

### v14 to v16 Upgrade

```bash
# 1. Update versions
sed -i 's/react_on_rails.*~> 14\.0/react_on_rails", "~> 16.0/' Gemfile
sed -i 's/"react-on-rails": "^14\./"react-on-rails": "^16./' package.json

# 2. Install updates
bundle update react_on_rails
npm install

# 3. Generate routes (if using js-routes gem)
bundle exec rails js:export

# 4. Test build
npm run build

# 5. Check for errors (see troubleshooting section)
```

### Pre-upgrade Checklist

```bash
#!/bin/bash
echo "=== Pre-upgrade Checklist ==="

# Check current versions
echo "Current react_on_rails gem:"
bundle show react_on_rails 2>/dev/null | grep "react_on_rails" || echo "Not installed"

echo "Current react-on-rails npm:"
npm list react-on-rails 2>/dev/null | grep "react-on-rails" || echo "Not installed"

# Check Shakapacker
echo "Shakapacker version:"
bundle show shakapacker 2>/dev/null | grep "shakapacker" || echo "⚠️  Shakapacker not found"

# Check Node.js version
echo "Node.js version: $(node --version)"

# Check for routes file
[ -f "app/javascript/utils/routes.js" ] && echo "✓ Routes file exists" || echo "⚠️  Routes file missing"

# Test current build
echo "Testing current build..."
npm run build >/dev/null 2>&1 && echo "✓ Build succeeds" || echo "⚠️  Build fails"
```

## Troubleshooting Patterns

### Error Pattern Recognition

```bash
# Function to detect common error patterns
detect_error_type() {
  local log_file="$1"

  if grep -q "Cannot read properties of undefined.*reading 'module'" "$log_file"; then
    echo "MISSING_ROUTES_FILE"
  elif grep -q "Error: Can't resolve.*\$app" "$log_file"; then
    echo "WEBPACK_ALIAS_ERROR"
  elif grep -q "Module not found.*react-on-rails" "$log_file"; then
    echo "DEPENDENCY_MISSING"
  elif grep -q "webpack.*incompatible" "$log_file"; then
    echo "VERSION_INCOMPATIBLE"
  else
    echo "UNKNOWN"
  fi
}
```

### Auto-fix Strategies

```bash
# Auto-fix missing routes (only if using js-routes gem)
fix_missing_routes() {
  if [ ! -f "app/javascript/utils/routes.js" ]; then
    echo "🔧 Generating missing routes file (js-routes gem)..."
    bundle exec rails js:export
    return $?
  fi
  return 0
}

# Auto-fix dependency issues
fix_dependencies() {
  echo "🔧 Updating dependencies..."
  bundle update react_on_rails
  npm install
}

# Auto-fix webpack cache
fix_webpack_cache() {
  echo "🔧 Clearing webpack cache..."
  rm -rf node_modules/.cache tmp/cache
}
```

## Error Detection and Auto-fixes

### Common Error Scenarios

#### 1. Missing Routes File (js-routes gem)

**Detection:**

```regex
/Cannot read properties of undefined.*reading 'module'/
/ProvidedDependencyTemplate\.apply/
```

**Auto-fix:**

```bash
bundle exec rails js:export
```

#### 2. ProvidePlugin Module Missing

**Detection:**

```regex
/Error: Can't resolve.*\$app/
/Module not found.*utils\/routes/
```

**Auto-fix:**

```bash
# Check if file exists, generate if missing
[ -f "app/javascript/utils/routes.js" ] || bundle exec rails js:export

# Check webpack aliases
grep -q "\$app" config/webpack/*.js || echo "⚠️  Missing webpack alias"
```

#### 3. Version Incompatibility

**Detection:**

```regex
/webpack.*incompatible/
/peer dep.*react-on-rails/
```

**Auto-fix:**

```bash
# Update to compatible versions
npm install react-on-rails@^16.0.0
bundle update react_on_rails
```

### Diagnostic Script

```bash
#!/bin/bash
# react_on_rails_diagnostic.sh
echo "=== React on Rails Diagnostic ==="

# 1. Version check
echo "📋 Checking versions..."
RAILS_VERSION=$(bundle show react_on_rails | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "not found")
NPM_VERSION=$(npm list react-on-rails 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "not found")
echo "Gem version: $RAILS_VERSION"
echo "NPM version: $NPM_VERSION"

# 2. File existence
echo "📁 Checking critical files..."
[ -f "app/javascript/utils/routes.js" ] && echo "✓ Routes file exists" || echo "❌ Routes file missing"
[ -f "config/webpack/webpack.config.js" ] && echo "✓ Webpack config exists" || echo "❌ Webpack config missing"

# 3. Webpack configuration
echo "⚙️  Checking webpack configuration..."
if grep -q "ProvidePlugin" config/webpack/*.js; then
  echo "✓ ProvidePlugin found"
  if grep -q "Routes.*\$app" config/webpack/*.js; then
    echo "✓ Routes provider configured"
  else
    echo "❌ Routes provider not configured"
  fi
else
  echo "❌ ProvidePlugin not found"
fi

# 4. Build test
echo "🔨 Testing build..."
if npm run build >/dev/null 2>&1; then
  echo "✓ Build successful"
else
  echo "❌ Build failed"
  echo "Running auto-fixes..."

  # Auto-fix missing routes (only if using js-routes gem)
  if [ ! -f "app/javascript/utils/routes.js" ]; then
    echo "🔧 Generating routes (js-routes gem)..."
    bundle exec rails js:export
  fi

  # Retry build
  if npm run build >/dev/null 2>&1; then
    echo "✓ Build successful after auto-fix"
  else
    echo "❌ Build still failing - manual intervention required"
  fi
fi
```

## Best Practices for Agents

### 1. Always Verify Before Modifying

```bash
# Before making changes, always check current state
bundle show react_on_rails
npm list react-on-rails
git status
```

### 2. Use Dry-run When Available

```bash
# Test generator changes before applying
rails generate react_on_rails:install --dry-run
```

### 3. Incremental Changes

```bash
# Make one change at a time for easier rollback
git add -A && git commit -m "Update react_on_rails gem"
# Test, then continue
git add -A && git commit -m "Update react_on_rails npm package"
```

### 4. Error Recovery

```bash
# If upgrade fails, provide rollback instructions
git log --oneline -5  # Show recent commits for rollback reference
git checkout HEAD~1 -- Gemfile package.json  # Rollback versions
```

### 5. Environment Considerations

- Always run `rails js:export` in a Rails environment
- Database warnings during `rails js:export` are usually non-fatal
- Test builds don't require database connectivity

### 6. Formatting Requirements

**⚠️ CRITICAL**: Always use Prettier for formatting - never manually format code.

**Merge conflict resolution workflow:**
1. Resolve logical conflicts only (ignore formatting)
2. `git add .` (or specific files)
3. `rake autofix` (fixes all formatting + linting)
4. `git add .` (if autofix made changes)
5. Continue rebase: `git rebase --continue`

**Never manually format during conflict resolution** - this causes formatting wars.

### 7. Communication with Users

When reporting status to users:

```bash
echo "✅ React on Rails upgrade successful"
echo "📊 Build metrics: $(npm run build 2>&1 | grep -o '[0-9]\+ errors\|successfully')"
echo "⚠️  Note: Some TypeScript errors may be unrelated to react_on_rails"
echo "🔗 Next steps: Test your application with 'bin/dev'"
```

### 8. Documentation Updates

After successful upgrades, suggest:

- Update README with new version requirements
- Update CI/CD configurations if needed
- Document any custom webpack configurations

---

## Emergency Procedures

### If Build Completely Breaks

1. **Rollback immediately:**

   ```bash
   git checkout HEAD~1 -- Gemfile package.json Gemfile.lock package-lock.json
   bundle install
   npm install
   ```

2. **Identify the issue:**

   ```bash
   npm run build 2>&1 | tee build-error.log
   ```

3. **Apply targeted fixes:**

   - Missing routes: `rails js:export`
   - Cache issues: `rm -rf node_modules/.cache tmp/cache`
   - Dependencies: `bundle update && npm install`

4. **Document the issue** for future reference

### If Rails Environment Unavailable

Use minimal commands:

```bash
# Skip database operations
DATABASE_URL=sqlite3:tmp/minimal.db rails js:export

# Or use test environment
RAILS_ENV=test rails js:export
```

---

This guide ensures consistent, reliable React on Rails operations for coding agents while providing clear error recovery paths.
