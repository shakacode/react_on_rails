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

Equivalents for other package managers:

- npm: `npm outdated`
- yarn: `yarn outdated`
- bun: `bun outdated`

Read CHANGELOGs of major updated packages before you update. You might not be ready for
some updates.

### Updating All Dependencies

**Option 1: Using npm-check-updates (Recommended)**

Run these commands. You may or may not need to `rm -rf` your `node_modules` directory.

```bash
pnpm dlx npm-check-updates -u -a
pnpm install
```

To also remove old `node_modules` so you only get what corresponds to `package.json`:

```bash
pnpm dlx npm-check-updates -u -a && rm -rf node_modules && pnpm install
```

Equivalents for other package managers:

- npm: `npx npm-check-updates -u -a && npm install`
- yarn: `npx npm-check-updates -u -a && yarn install`
- bun: `bunx npm-check-updates -u -a && bun install`

**Option 2: Using your package manager's upgrade command**

To update all dependencies within their existing semver ranges:

```bash
pnpm up
```

To ignore ranges and update everything to the absolute latest versions:

```bash
pnpm up --latest
```

To upgrade a specific package to its latest version:

```bash
pnpm up [package] --latest
```

Equivalents for other package managers:

| Action                     | npm                        | yarn (v1)               | bun                    |
| -------------------------- | -------------------------- | ----------------------- | ---------------------- |
| Update within ranges       | `npm update`               | `yarn upgrade`          | `bun update`           |
| Update to latest           | _(use ncu from Option 1)_  | `yarn upgrade --latest` | `bun update --latest`  |
| Specific package to latest | `npm install <pkg>@latest` | `yarn add <pkg>@latest` | `bun add <pkg>@latest` |

Note that `npm update` does not modify `package.json` by default (only the lockfile). Add `--save`
if you want it to update version ranges. The other package managers update `package.json` by default.

### Adding New Dependencies

Typically, you can add your Node dependencies as you normally would:

```bash
pnpm add module_name@version
# or for dev dependencies
pnpm add -D module_name@version
```

Equivalents for other package managers:

- npm: `npm install module_name@version` / `npm install -D module_name@version`
- yarn: `yarn add module_name@version` / `yarn add --dev module_name@version`
- bun: `bun add module_name@version` / `bun add -D module_name@version`

### Verify After Updates

Confirm that the hot replacement dev server and the Rails server both work after updating dependencies.
