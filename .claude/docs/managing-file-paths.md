# Managing File Paths in Configuration Files

**CRITICAL: Hardcoded paths are a major source of bugs, especially after refactors.**

## Before Committing Path Changes

1. **Verify the path actually exists:**

   ```bash
   ls -la <the-path-you-just-added>
   ```

2. **Test operations that use the path:**

   ```bash
   # If it's a build artifact path in package-scripts.yml:
   yarn run prepack
   yarn run yalc.publish

   # If it's a webpack output path:
   yarn build && ls -la <output-path>
   ```

3. **Search for ALL references to old paths if renaming:**
   ```bash
   # Example: if renaming node_package/ to packages/
   grep -r "node_package" . --exclude-dir=node_modules --exclude-dir=.git
   grep -r "packages/react-on-rails" . --exclude-dir=node_modules
   ```

## Files That Commonly Have Path References

**Always check these after directory structure changes:**

- `package-scripts.yml` - build artifact paths in prepack/prepare scripts
- `package.json` - "files", "main", "types", "exports" fields
- `webpack.config.js` / `config/webpack/*` - output.path, resolve.modules
- `.github/workflows/*.yml` - cache paths, artifact paths, working directories
- `lib/generators/**/templates/**` - paths in generated code
- Documentation files - example paths and installation instructions

## Post-Refactor Validation Checklist

After any directory structure change, run this checklist:

```bash
# 1. Find any lingering references to old paths
grep -r "old/path/name" . --exclude-dir=node_modules --exclude-dir=.git

# 2. Verify build artifacts are in expected locations
yarn build
find . -name "ReactOnRails.full.js" -type f
find . -name "package.json" -type f

# 3. Test package scripts
yarn run prepack
yarn run yalc.publish

# 4. Test clean install
rm -rf node_modules && yarn install

# 5. Run full test suite
rake
```

## Real Example: The package-scripts.yml Bug

**What happened:**

- Path was changed from `node_package/lib/` to `packages/react-on-rails/lib/`
- Later, the actual directory structure was reverted to `lib/` at root
- But package-scripts.yml still referenced `packages/react-on-rails/lib/`
- This caused yalc publish to fail silently for 7 weeks

**How to prevent:**

1. After changing directory structure, search for ALL references to old paths
2. Always run `yarn run yalc.publish` manually to verify it works
3. Check that paths in package-scripts.yml match actual file locations
4. Use `ls -la <path>` to verify paths exist before committing
