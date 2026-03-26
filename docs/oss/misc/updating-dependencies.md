# Updating Ruby and JavaScript Dependencies

If you frequently update dependencies in small batches, you will avoid large and painful updates later. Then again, if you don't have good test coverage, it's hazardous to update dependencies at any time.

## Ruby

Delete any unwanted version constraints from your Gemfile and run:

```bash
bundle update
```

## Node Dependencies

Run the commands below from the directory that contains your `package.json`. In current React on
Rails apps, that is usually the app root rather than a `client/` subdirectory.

### Checking for Outdated Packages

Check for outdated versions of packages:

```bash
pnpm outdated
```

Use the equivalent `npm outdated` or `yarn outdated` command if your app uses a different package
manager. Read CHANGELOGs of major updated packages before you update. You might not be ready for
some updates.

### Updating All Dependencies

**Option 1: Using npm-check-updates (Recommended)**

Run these commands. You may or may not need to `rm -rf` your `node_modules` directory.

```bash
pnpm dlx npm-check-updates -u -a
pnpm install
```

Some combinations that I often run:

- Remove old installed `node_modules` so you only get what corresponds to `package.json`:

  ```bash
  pnpm dlx npm-check-updates -u -a && rm -rf node_modules && pnpm install
  ```

Use the equivalent `npx npm-check-updates -u -a && npm install` or `npx npm-check-updates -u -a && yarn install` flow if your app does not use `pnpm`.

**Option 2: Using your package manager's upgrade command**

To update all dependencies:

```bash
pnpm up --latest
```

To upgrade a specific package:

```bash
pnpm up [package] --latest
```

Equivalent commands for other package managers are `npm install <package>@latest` and `yarn add <package>@latest`.
Note that `npm update` is not the same as `pnpm up --latest` because it respects existing semver
ranges instead of updating package.json to the latest available versions.

### Adding New Dependencies

Typically, you can add your Node dependencies as you normally would:

```bash
pnpm add module_name@version
# or for dev dependencies
pnpm add -D module_name@version
```

If your app uses `npm` or `yarn`, use the corresponding `npm install` or `yarn add` command in the
same directory as `package.json`.

### Verify After Updates

Confirm that the hot replacement dev server and the Rails server both work after updating dependencies.
