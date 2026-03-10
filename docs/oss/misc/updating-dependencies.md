# Updating Ruby and JavaScript Dependencies

If you frequently update dependencies in small batches, you will avoid large and painful updates later. Then again, if you don't have good test coverage, it's hazardous to update dependencies at any time.

## Ruby

Delete any unwanted version constraints from your Gemfile and run:

```bash
bundle update
```

## Node/Yarn

### Checking for Outdated Packages

Check for outdated versions of packages:

```bash
cd client
yarn outdated
```

Read CHANGELOGs of major updated packages before you update. You might not be ready for some updates.

### Updating All Dependencies

**Option 1: Using npm-check-updates (Recommended)**

1. Install [npm-check-updates](https://www.npmjs.com/package/npm-check-updates)
2. Run these commands. You may or may not need to `rm -rf` your `node_modules` directory.

   ```bash
   cd client
   ncu -u -a
   yarn
   ```

Some combinations that I often run:

- Remove old installed `node_modules` so you only get what corresponds to `package.json`:

  ```bash
  ncu -u -a && rm -rf node_modules && yarn
  ```

**Option 2: Using yarn upgrade**

To update all dependencies:

```bash
cd client
yarn upgrade
```

To upgrade a specific package:

```bash
yarn upgrade [package]
```

### Adding New Dependencies

Typically, you can add your Node dependencies as you normally would:

```bash
cd client
yarn add module_name@version
# or for dev dependencies
yarn add --dev module_name@version
```

### Verify After Updates

Confirm that the hot replacement dev server and the Rails server both work after updating dependencies.
