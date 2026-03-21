# Install and Release

We're releasing this as a unified release with 6 packages total. We keep the version numbers in sync across all packages using unified versioning.

## Testing the Gem before Release from a Rails App

See [Contributing](https://github.com/shakacode/react_on_rails/tree/main/CONTRIBUTING.md)

## Release Process

### 1. Update the Changelog (BEFORE releasing)

**Always update CHANGELOG.md before running the release task.** The release task reads the version from CHANGELOG.md and automatically creates a GitHub release from the changelog section.

1. Ensure all desired changes are merged to `main` branch
2. Run `/update-changelog release` (or `rc` or `beta` for prereleases) to:
   - Find merged PRs missing from the changelog
   - Add changelog entries under the appropriate category headings
   - Auto-compute the next version based on changes (breaking -> major, features -> minor, fixes -> patch)
   - Stamp the version header (e.g., `### [16.5.0] - 2026-03-08`)
3. Review the changelog entries and verify the computed version
4. Commit and push CHANGELOG.md

If you forget this step, the release task will print a warning and the GitHub release will need to be created manually afterward using `sync_github_release`.

#### Why changelog comes BEFORE the release

- `rake release` automatically creates a GitHub release if a changelog section exists -- no separate `sync_github_release` step needed
- The release task warns if no changelog section is found for the target version
- A premature version header (if release fails) is harmless -- you'll release eventually
- A missing changelog after release means the GitHub release must be created manually

### 2. Run the Release Task

The simplest way to release is with no arguments -- the task reads the version from CHANGELOG.md:

```bash
# Recommended: reads version from CHANGELOG.md (requires step 1)
bundle exec rake release

# For a specific version (overrides CHANGELOG.md detection)
bundle exec rake "release[16.2.0]"

# For a pre-release version (note: use period, not dash)
bundle exec rake "release[16.2.0.beta.1]"  # Creates npm package 16.2.0-beta.1

# For a release candidate
bundle exec rake "release[16.5.0.rc.0]"

# Dry run to test without publishing
bundle exec rake "release[16.2.0,true]"

# Override version policy checks (monotonic + changelog/bump consistency)
RELEASE_VERSION_POLICY_OVERRIDE=true bundle exec rake "release[16.2.0]"
bundle exec rake "release[16.2.0,false,true]"
```

When called with no arguments, `rake release`:

1. Reads the first versioned header from CHANGELOG.md (e.g., `### [16.5.0]`)
2. Compares it to the current gem version
3. If the changelog version is newer, prompts for confirmation and uses it
4. If no new version is found, falls back to a patch bump

Dry runs use a temporary git worktree so version bumps and installs do not modify your current checkout.

`rake release` validates release-version policy before publishing:

- Target version must be greater than the latest tagged release.
- If the versioned target changelog section exists (`### [X.Y.Z...]`; not `Unreleased`), it maps to expected bump type:
  - Breaking changes => major bump
  - Added/New Features/Features/Enhancements => minor bump
  - Fixed/Fixes/Bug Fixes/Security/Improved/Deprecated => patch bump
  - Other headings => no inferred bump level (consistency check is skipped)

Use override only when needed:

- `RELEASE_VERSION_POLICY_OVERRIDE=true`
- Or task arg override (`bundle exec rake "release[..., ..., true]"`)

**Full argument list:**

```bash
bundle exec rake "release[version,dry_run,override_version_policy]"
```

1. **`version`** (optional): Version bump type or explicit version
   - Bump types: `patch`, `minor`, `major`
   - Explicit: `16.2.0`
   - Pre-release: `16.2.0.beta.1` (rubygem format with dots, converted to `16.2.0-beta.1` for NPM)
   - Empty (auto): use latest CHANGELOG.md version if newer, else patch bump

2. **`dry_run`** (optional): `true` to preview changes without releasing (default: `false`)

3. **`override_version_policy`** (optional): `true` to override version policy checks (default: `false`)

**Environment variables:**

```bash
VERBOSE=1                    # Enable verbose logging (shows all output)
NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
RELEASE_VERSION_POLICY_OVERRIDE=true # Override release version policy checks
GEM_RELEASE_MAX_RETRIES=<n>  # Override max retry attempts (default: 3)
```

**Examples:**

```bash
bundle exec rake release                                  # Use CHANGELOG.md version or patch bump
bundle exec rake "release[patch]"                         # Bump patch version (16.1.1 → 16.1.2)
bundle exec rake "release[minor]"                         # Bump minor version (16.1.1 → 16.2.0)
bundle exec rake "release[major]"                         # Bump major version (16.1.1 → 17.0.0)
bundle exec rake "release[16.2.0]"                        # Set explicit version
bundle exec rake "release[16.2.0.beta.1]"                 # Set pre-release version (→ 16.2.0-beta.1 for NPM)
bundle exec rake "release[patch,true]"                    # Dry run
VERBOSE=1 bundle exec rake "release[patch]"               # Release with verbose logging
NPM_OTP=123456 RUBYGEMS_OTP=789012 bundle exec rake "release[patch]"  # Skip OTP prompts
```

### 3. What the Release Task Does

The `rake release` task automatically:

1. **Validates release prerequisites**:
   - Checks for uncommitted changes (will abort if found)
   - Verifies NPM authentication (will run `npm login` if needed)
   - Warns if CHANGELOG.md section is missing for the target version
   - Validates version policy (monotonic + changelog/bump consistency)
2. **Pulls latest changes** from the repository
3. **Bumps version numbers** in:
   - `react_on_rails/lib/react_on_rails/version.rb` (Ruby gem version)
   - All `package.json` files (npm package versions - converted from Ruby format)
   - Pro version files
4. **Updates Gemfile.lock files** across the monorepo
5. **Commits, tags, and pushes** all version changes
6. **Publishes to npm** (requires 2FA token):
   - `react-on-rails`
   - `react-on-rails-pro`
   - `react-on-rails-pro-node-renderer`
   - `create-react-on-rails-app`
7. **Publishes to RubyGems** (requires 2FA token):
   - `react_on_rails`
   - `react_on_rails_pro`
8. **Creates GitHub release** from CHANGELOG.md (if the matching section exists)

### What Gets Released

The release task publishes 6 packages with unified versioning:

**PUBLIC (npmjs.org + rubygems.org):**

1. **react-on-rails** - NPM package
2. **react-on-rails-pro** - NPM package
3. **react-on-rails-pro-node-renderer** - NPM package
4. **create-react-on-rails-app** - NPM package
5. **react_on_rails** - RubyGem
6. **react_on_rails_pro** - RubyGem

### Version Synchronization

The task updates versions in all the following files:

**Core package:**

- `react_on_rails/lib/react_on_rails/version.rb` (source of truth for all packages)
- `package.json` (root workspace)
- `packages/react-on-rails/package.json`
- `Gemfile.lock` (root)
- `react_on_rails/spec/dummy/Gemfile.lock`

**Pro package:**

- `react_on_rails_pro/lib/react_on_rails_pro/version.rb` (VERSION only, not PROTOCOL_VERSION)
- `packages/react-on-rails-pro/package.json` (+ dependency version)
- `packages/react-on-rails-pro-node-renderer/package.json`
- `packages/create-react-on-rails-app/package.json`
- `react_on_rails_pro/Gemfile.lock`
- `react_on_rails_pro/spec/dummy/Gemfile.lock`

**Note:**

- `react_on_rails_pro.gemspec` dynamically references `ReactOnRails::VERSION`
- `react-on-rails-pro` NPM dependency is pinned to exact version (e.g., `"react-on-rails": "16.2.0"`)

### 4. Version Format

**Important:** Use Ruby gem version format (no dashes) when passing versions to the rake task:

- Correct: `16.1.0`, `16.2.0.beta.1`, `16.0.0.rc.2`
- Wrong: `16.1.0-beta.1`, `16.0.0-rc.2`

The task automatically converts Ruby gem format to npm semver format:

- Ruby: `16.2.0.beta.1` -> npm: `16.2.0-beta.1`
- Ruby: `16.0.0.rc.2` -> npm: `16.0.0-rc.2`

**CHANGELOG.md headers** use RubyGems dot format (without `v` prefix):

- `### [16.5.0.rc.1]` -- correct (matches gem version format)

### 5. During the Release

1. When prompted for **npm OTP**, enter your 2FA code from your authenticator app
2. When prompted for **RubyGems OTP**, enter your 2FA code
3. If using `rake release` with no version, confirm the version detected from CHANGELOG.md (or the computed patch version)
4. The script will automatically commit and push version bumps
5. The script will automatically create a GitHub release (if CHANGELOG.md section exists)

### 6. After Release

1. Verify the release on:
   - [npm](https://www.npmjs.com/package/react-on-rails)
   - [RubyGems](https://rubygems.org/gems/react_on_rails)
   - [GitHub releases](https://github.com/shakacode/react_on_rails/releases)

2. If the changelog was updated before release (recommended), verify the GitHub release was auto-created with the correct notes.

3. If the changelog was NOT updated before release, update it now:

   **Option A - Use Claude Code (recommended):**

   Run `/update-changelog` to analyze commits, write changelog entries, and create a PR. Then sync the GitHub release:

   ```bash
   bundle exec rake "sync_github_release[16.5.0]"
   ```

   **Option B - Manual (headers only, you must write entries):**

   ```bash
   bundle exec rake "update_changelog[16.5.0]"
   # Write entries manually, then:
   git commit -a -m 'Update CHANGELOG.md'
   git push
   bundle exec rake "sync_github_release[16.5.0]"
   ```

### Syncing GitHub Releases Manually

If the automatic GitHub release creation was skipped (e.g., CHANGELOG.md section was missing during release), you can create it manually after updating the changelog:

1. Update `CHANGELOG.md` with the published version section
2. Commit and push `CHANGELOG.md`
3. Run:

```bash
# Stable
bundle exec rake "sync_github_release[16.5.0]"

# Prerelease
bundle exec rake "sync_github_release[16.5.0.rc.1]"

# Dry run
bundle exec rake "sync_github_release[16.5.0,true]"
```

`sync_github_release` reads release notes from the matching `CHANGELOG.md` section and creates/updates the GitHub release for the corresponding tag.

### Pre-Release Checklist

Before running the release command, verify:

1. **GitHub CLI**: Run `gh auth login` and ensure your account/token has write access to the repository (required for automatic GitHub release creation)

2. **NPM authentication**: Run `npm whoami` to confirm you're logged in
   - If not logged in, the release script will automatically run `npm login` for you

3. **RubyGems authentication**: Ensure you have valid credentials for `gem push`

4. **No uncommitted changes**: Run `git status` to verify clean working tree

### Two-Factor Authentication

You'll need to enter OTP tokens when prompted:

- Once for publishing `react-on-rails` to NPM (reused for subsequent NPM packages if valid)
- Once for publishing `react_on_rails` to RubyGems (reused for `react_on_rails_pro` if valid)

## Requirements

### NPM Publishing

You must be logged in and have publish permissions:

**For public packages (npmjs.org):**

```bash
npm login
```

### RubyGems Publishing

**For public gem (rubygems.org):**

- Standard RubyGems credentials via `gem push`

### Ruby Version Management

The script automatically detects and switches Ruby versions when needed:

- Supports: RVM, rbenv, asdf
- Set via `RUBY_VERSION_MANAGER` environment variable (default: `rvm`)
- Example: Pro dummy app requires Ruby 3.3.7, script auto-switches from 3.3.0

### Dependencies

This task depends on the `gem-release` Ruby gem, which is installed via `bundle install`.

## Testing with Dry Run

Before releasing to production, always preview with a dry run:

```bash
bundle exec rake "release[16.5.0,true]"
```

This uses a temporary git worktree to show exactly what would be updated without making any changes.

## Troubleshooting

### Dry Run First

Always test with a dry run before actually releasing:

```bash
bundle exec rake "release[16.2.0,true]"
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
   - Start over with `bundle exec rake "release[X.Y.Z]"`

3. If GitHub release creation fails after successful publishing:
   - Fix GitHub auth (`gh auth login`) or permissions
   - Ensure `CHANGELOG.md` has matching header `### [X.Y.Z]`
   - Rerun only: `bundle exec rake "sync_github_release[X.Y.Z]"`

4. If some packages were published but not others:
   - You can manually publish the missing packages:
     ```bash
     cd packages/react-on-rails && pnpm version X.Y.Z && pnpm publish
     cd ../react-on-rails-pro && pnpm version X.Y.Z && pnpm publish
     gem release
     ```
     `pnpm publish -r` will publish all packages where current version isn't published yet.

## Version History

Running `bundle exec rake "release[X.Y.Z]"` will create a commit that looks like this:

```
commit abc123...
Author: Your Name <your.email@example.com>
Date:   Mon Jan 1 12:00:00 2024 -0500

    Bump version to 16.2.0

diff --git a/react_on_rails/lib/react_on_rails/version.rb b/react_on_rails/lib/react_on_rails/version.rb
index 1234567..abcdefg 100644
--- a/react_on_rails/lib/react_on_rails/version.rb
+++ b/react_on_rails/lib/react_on_rails/version.rb
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
