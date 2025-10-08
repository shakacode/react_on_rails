# Install and Release

We're releasing this as a combined Ruby gem plus two NPM packages. We keep the version numbers in sync across all packages.

## Testing the Gem before Release from a Rails App

See [Contributing](https://github.com/shakacode/react_on_rails/tree/master/CONTRIBUTING.md)

## Releasing a New Version

Run `rake -D release` to see instructions on how to release via the rake task.

### Release Command

```bash
rake release[gem_version,dry_run]
```

**Arguments:**

- `gem_version`: The new version in rubygem format (no dashes). Pass no argument to automatically perform a patch version bump.
- `dry_run`: Optional. Pass `true` to see what would happen without actually releasing.

**Example:**

```bash
rake release[16.2.0]        # Release version 16.2.0
rake release[16.2.0,true]   # Dry run to preview changes
rake release                # Auto-bump patch version
```

### What Gets Released

The release task publishes three packages with the same version number:

1. **react-on-rails** NPM package
2. **react-on-rails-pro** NPM package
3. **react_on_rails** Ruby gem

### Version Synchronization

The task updates versions in all the following files:

- `lib/react_on_rails/version.rb` (source of truth)
- `package.json` (root workspace)
- `packages/react-on-rails/package.json`
- `packages/react-on-rails-pro/package.json` (both version field and react-on-rails dependency)
- `spec/dummy/Gemfile.lock`

**Note:** The `react-on-rails-pro` package declares an exact version dependency on `react-on-rails` (e.g., `"react-on-rails": "16.2.0"`). This ensures users install compatible versions of both packages.

### Pre-release Versions

For pre-release versions, the gem version format is automatically converted to NPM semver format:

- Gem: `3.0.0.beta.1`
- NPM: `3.0.0-beta.1`

### Release Process

When you run `rake release[X.Y.Z]`, the task will:

1. Check for uncommitted changes (will abort if found)
2. Pull latest changes from the remote repository
3. Clean up example directories
4. Bump the gem version in `lib/react_on_rails/version.rb`
5. Update all package.json files with the new version
6. Update the Pro package's dependency on react-on-rails
7. Update the dummy app's Gemfile.lock
8. Commit all version changes with message "Bump version to X.Y.Z"
9. Create a git tag `vX.Y.Z`
10. Push commits and tags to the remote repository
11. Publish `react-on-rails` to NPM (requires 2FA token)
12. Publish `react-on-rails-pro` to NPM (requires 2FA token)
13. Publish `react_on_rails` to RubyGems (requires 2FA token)

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

This task depends on the `gem-release` Ruby gem, which is installed via `bundle install`.

For NPM publishing, you must be logged in to npm and have publish permissions for both packages:

```bash
npm login
```

## Troubleshooting

### Dry Run First

Always test with a dry run before actually releasing:

```bash
rake release[16.2.0,true]
```

This shows you exactly what would be updated without making any changes.

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
