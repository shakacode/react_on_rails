# Install and Release

We're releasing this as a unified release with 5 packages total. We keep the version numbers in sync across all packages using unified versioning.

## Testing the Gem before Release from a Rails App

See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md)

## Releasing a New Version

Run `rake -D release` to see instructions on how to release via the rake task.

### Release Command

```bash
rake release[version,dry_run,registry,skip_push]
```

**Arguments:**

1. **`version`** (required): Version bump type or explicit version
   - Bump types: `patch`, `minor`, `major`
   - Explicit: `16.2.0`
   - Pre-release: `16.2.0.beta.1` (rubygem format with dots, converted to `16.2.0-beta.1` for NPM)

2. **`dry_run`** (optional): `true` to preview changes without releasing
   - Default: `false`

3. **`registry`** (optional): Publishing registry for testing
   - `verdaccio`: Publish all NPM packages to local Verdaccio (skips RubyGems)
   - `npm`: Normal release to npmjs.org + rubygems.org (default)

4. **`skip_push`** (optional): Skip git push to remote
   - `skip_push`: Don't push commits/tags to remote
   - Default: pushes to remote

**Examples:**

```bash
rake release[patch]                          # Bump patch version (16.1.1 → 16.1.2)
rake release[minor]                          # Bump minor version (16.1.1 → 16.2.0)
rake release[major]                          # Bump major version (16.1.1 → 17.0.0)
rake release[16.2.0]                         # Set explicit version
rake release[16.2.0.beta.1]                  # Set pre-release version (→ 16.2.0-beta.1 for NPM)
rake release[16.2.0,true]                    # Dry run to preview changes
rake release[16.2.0,false,verdaccio]         # Test with local Verdaccio
rake release[patch,false,npm,skip_push]      # Release but don't push to GitHub
```

### What Gets Released

The release task publishes 5 packages with unified versioning:

**PUBLIC (npmjs.org + rubygems.org):**

1. **react-on-rails** - NPM package
2. **react-on-rails-pro** - NPM package
3. **react-on-rails-pro-node-renderer** - NPM package
4. **react_on_rails** - RubyGem
5. **react_on_rails_pro** - RubyGem

### Version Synchronization

The task updates versions in all the following files:

**Core package:**

- `lib/react_on_rails/version.rb` (source of truth for all packages)
- `package.json` (root workspace)
- `packages/react-on-rails/package.json`
- `Gemfile.lock` (root)
- `spec/dummy/Gemfile.lock`

**Pro package:**

- `react_on_rails_pro/lib/react_on_rails_pro/version.rb` (VERSION only, not PROTOCOL_VERSION)
- `react_on_rails_pro/package.json` (node-renderer)
- `packages/react-on-rails-pro/package.json` (+ dependency version)
- `react_on_rails_pro/Gemfile.lock`
- `react_on_rails_pro/spec/dummy/Gemfile.lock`

**Note:**

- `react_on_rails_pro.gemspec` dynamically references `ReactOnRails::VERSION`
- `react-on-rails-pro` NPM dependency is pinned to exact version (e.g., `"react-on-rails": "16.2.0"`)

### Pre-release Versions

For pre-release versions, the gem version format is automatically converted to NPM semver format:

- Gem: `3.0.0.beta.1`
- NPM: `3.0.0-beta.1`

### Pre-Release Checklist

Before running the release command, verify:

1. **NPM authentication**: Run `npm whoami` to confirm you're logged in
   - If not logged in, the release script will automatically run `npm login` for you

2. **RubyGems authentication**: Ensure you have valid credentials for `gem push`

3. **No uncommitted changes**: Run `git status` to verify clean working tree

### Release Process

When you run `rake release[X.Y.Z]`, the task will:

1. Check for uncommitted changes (will abort if found)
2. Verify NPM authentication (will run `npm login` if needed)
3. Pull latest changes from the remote repository
4. Clean up example directories
5. Bump the gem version in `lib/react_on_rails/version.rb`
6. Update all package.json files with the new version
7. Update the Pro package's dependency on react-on-rails
8. Update the dummy app's Gemfile.lock
9. Commit all version changes with message "Bump version to X.Y.Z"
10. Create a git tag `vX.Y.Z`
11. Push commits and tags to the remote repository
12. Publish `react-on-rails` to NPM (requires 2FA token)
13. Publish `react-on-rails-pro` to NPM (requires 2FA token)
14. Publish `react_on_rails` to RubyGems (requires 2FA token)

### Two-Factor Authentication

You'll need to enter OTP tokens when prompted:

- Once for publishing `react-on-rails` to NPM
- Once for publishing `react-on-rails-pro` to NPM
- Once for publishing `react_on_rails` to RubyGems

### Post-Release Steps

After a successful release, you'll see instructions to:

1. Update the CHANGELOG.md:

   ```bash
   bundle exec rake update_changelog
   ```

2. Update the dummy app's Gemfile.lock:

   ```bash
   cd spec/dummy && bundle update react_on_rails
   ```

3. Commit the CHANGELOG and Gemfile.lock:
   ```bash
   cd /path/to/react_on_rails
   git commit -a -m 'Update CHANGELOG.md and spec/dummy Gemfile.lock'
   git push
   ```

## Requirements

### NPM Publishing

You must be logged in and have publish permissions:

**For public packages (npmjs.org):**

```bash
npm login
```

**For private packages (GitHub Packages):**

- Get a GitHub personal access token with `write:packages` scope
- Add to `~/.npmrc`:
  ```ini
  //npm.pkg.github.com/:_authToken=<TOKEN>
  always-auth=true
  ```
- Set environment variable:
  ```bash
  export GITHUB_TOKEN=<TOKEN>
  ```

### RubyGems Publishing

**For public gem (rubygems.org):**

- Standard RubyGems credentials via `gem push`

**For private gem (GitHub Packages):**

- Add to `~/.gem/credentials`:
  ```
  :github: Bearer <GITHUB_TOKEN>
  ```

### Ruby Version Management

The script automatically detects and switches Ruby versions when needed:

- Supports: RVM, rbenv, asdf
- Set via `RUBY_VERSION_MANAGER` environment variable (default: `rvm`)
- Example: Pro dummy app requires Ruby 3.3.7, script auto-switches from 3.3.0

### Dependencies

This task depends on the `gem-release` Ruby gem, which is installed via `bundle install`.

## Testing with Verdaccio

Before releasing to production, test the release process locally:

1. Install and start Verdaccio:

   ```bash
   npm install -g verdaccio
   verdaccio
   ```

2. Run release with verdaccio registry:

   ```bash
   rake release[patch,false,verdaccio]
   ```

3. This will:
   - Publish all 3 NPM packages to local Verdaccio
   - Skip RubyGem publishing
   - Update version files (revert manually after testing)

4. Test installing from Verdaccio:
   ```bash
   npm set registry http://localhost:4873/
   npm install react-on-rails@16.2.0
   # Reset when done:
   npm config delete registry
   ```

## Troubleshooting

### Dry Run First

Always test with a dry run before actually releasing:

```bash
rake release[16.2.0,true]
```

This shows you exactly what would be updated without making any changes.

### NPM Authentication Issues

If you see errors like "Access token expired" or "E404 Not Found" during NPM publish:

1. Your NPM token has expired (tokens now expire after 90 days)
2. Run `npm login` to refresh your credentials
3. Retry the release

The release script now checks NPM authentication at the start and will automatically run `npm login` if needed, so this issue will be caught and handled before any changes are made.

### If Release Fails

If the release fails partway through (e.g., during NPM publish):

1. Check what was published:
   - NPM: `npm view react-on-rails@X.Y.Z`
   - RubyGems: `gem list react_on_rails -r -a`

2. If the git tag was created but packages weren't published:
   - Delete the tag: `git tag -d vX.Y.Z && git push origin :vX.Y.Z`
   - Revert the version commit: `git reset --hard HEAD~1 && git push -f`
   - Start over with `rake release[X.Y.Z]`

3. If some packages were published but not others:
   - You can manually publish the missing packages:
     ```bash
     cd packages/react-on-rails && yarn publish --new-version X.Y.Z
     cd ../react-on-rails-pro && yarn publish --new-version X.Y.Z
     gem release
     ```

## Version History

Running `rake release[X.Y.Z]` will create a commit that looks like this:

```
commit abc123...
Author: Your Name <your.email@example.com>
Date:   Mon Jan 1 12:00:00 2024 -0500

    Bump version to 16.2.0

diff --git a/lib/react_on_rails/version.rb b/lib/react_on_rails/version.rb
index 1234567..abcdefg 100644
--- a/lib/react_on_rails/version.rb
+++ b/lib/react_on_rails/version.rb
@@ -1,3 +1,3 @@
 module ReactOnRails
-  VERSION = "16.1.1"
+  VERSION = "16.2.0"
 end

diff --git a/package.json b/package.json
index 2345678..bcdefgh 100644
--- a/package.json
+++ b/package.json
@@ -1,6 +1,6 @@
 {
   "name": "react-on-rails-workspace",
-  "version": "16.1.1",
+  "version": "16.2.0",
   ...
}
```
