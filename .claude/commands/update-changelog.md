# Update Changelog

You are helping to add an entry to the CHANGELOG.md file for the React on Rails project.

## Arguments

This command accepts an optional argument: `$ARGUMENTS`

- **No argument** (`/update-changelog`): Add entries to `[Unreleased]` without stamping a version header. Use this during development.
- **`release`** (`/update-changelog release`): Add entries and stamp a version header. Auto-compute the next version based on changes (breaking -> major, added features -> minor, fixes -> patch). Then `rake release` (with no args) will pick up this version automatically.
- **`rc`** (`/update-changelog rc`): Same as `release`, but stamps an RC prerelease version (e.g., `16.5.0.rc.0`). Auto-increments the RC index if prior RCs exist for the same base version.
- **`beta`** (`/update-changelog beta`): Same as `rc`, but stamps a beta prerelease version (e.g., `16.5.0.beta.0`).
- **Explicit version** (`/update-changelog 16.5.0.rc.10`): Add entries and stamp the exact version provided. Skips auto-computation — use this when you already know the target version. The version string must look like a semver version (with optional `.rc.N` or `.beta.N` suffix).

## When to Use This

This command serves three use cases at different points in the release lifecycle:

**During development** -- Add entries to `[Unreleased]` as PRs merge:

- Run `/update-changelog` to find merged PRs missing from the changelog
- Entries accumulate under `### [Unreleased]`

**Before a release** -- Stamp a version header and prepare for release:

- Run `/update-changelog release` (or `rc` or `beta`) to add entries AND stamp the version header
- The version is auto-computed from changelog content (see "Auto-Computing the Next Version" below)
- Commit and push CHANGELOG.md
- Then run `rake release` (no args needed -- it reads the version from CHANGELOG.md)
- The release task automatically creates a GitHub release from the changelog section

**After a release you forgot to update the changelog for** -- Catch-up mode:

- The command can retroactively find commits between tags and add missing entries
- Ask the user whether to stamp a version header or add to `[Unreleased]`

### Why changelog comes BEFORE the release

- `rake release` automatically creates a GitHub release if a changelog section exists -- no separate `sync_github_release` step needed
- The release task warns if no changelog section is found for the target version
- A premature version header (if release fails) is harmless -- you'll release eventually
- A missing changelog after release means the GitHub release must be created manually

## Auto-Computing the Next Version

When stamping a version header (`release`, `rc`, or `beta`), compute the next version as follows:

1. **Find the latest stable version tag** using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
   ```

2. **Determine bump type from changelog content**:
   - If changes include `#### Breaking Changes` or `#### ⚠️ Breaking Changes` -> **major** bump
   - If changes include `#### Added`, `#### New Features`, `#### Features`, or `#### Enhancements` -> **minor** bump
   - If changes only include `#### Fixed`, `#### Security`, `#### Improved`, `#### Changed`, `#### Deprecated`, or `#### Removed` -> **patch** bump

3. **Compute the version**:
   - For `release`: Apply the bump to the latest stable tag (e.g., `16.4.0` + minor -> `16.5.0`)
   - For `rc`: Apply the bump, then find the next RC index based **only on git tags** (e.g., if `v16.5.0.rc.0` tag exists -> `16.5.0.rc.1`). **Do NOT use changelog headers** to determine the next index — a version header in the changelog is a draft that may not have been released yet. Only git tags represent shipped versions.
   - For `beta`: Same as RC but with beta suffix

4. **Verify**: Check that the computed version is newer than ALL existing tags (stable and prerelease). If not, ask the user what to do.

5. **Show the computed version to the user and ask for confirmation** before stamping the header. If the bump type is ambiguous (e.g., changes could reasonably be classified as patch vs minor, or the changelog headings don't clearly signal the bump level), explain your reasoning for the suggested bump and ask the user to confirm or override before proceeding.

## Critical Requirements

1. **User-visible changes only**: Only add changelog entries for user-visible changes:
   - New features
   - Bug fixes
   - Breaking changes
   - Deprecations
   - Performance improvements
   - Security fixes
   - Changes to public APIs or configuration options

2. **Do NOT add entries for**:
   - Linting fixes
   - Code formatting
   - Internal refactoring
   - Test updates
   - Documentation fixes (unless they fix incorrect docs about behavior)
   - CI/CD changes

## Formatting Requirements

### Entry Format

Each changelog entry MUST follow this exact format:

```markdown
- **Bold description of change**. [PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username). Optional additional context or details.
```

**Important formatting rules**:

- Start with a dash and space: `- `
- Use **bold** for the main description
- End the bold description with a period before the link
- Always link to the PR: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818)` - **NO hash symbol**
- Always link to the author: `by [username](https://github.com/username)`
- End with a period after the author link
- Additional details can be added after the main entry, using proper indentation for multi-line entries

### Breaking Changes Format

For breaking changes, use this format:

```markdown
- **Feature Name**: Description of the breaking change. See migration guide below. [PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username).

**Migration Guide:**

1. Step one
2. Step two
```

### Category Organization

Entries should be organized under these section headings **in the following order** (most critical first):

**Preferred section order:**

1. `#### Breaking Changes` - Breaking changes with migration guides (FIRST - most critical for upgrading users)
2. `#### Added` - New features
3. `#### Changed` - Changes to existing functionality
4. `#### Improved` - Improvements to existing features
5. `#### Fixed` - Bug fixes
6. `#### Deprecated` - Deprecation notices
7. `#### Removed` - Removed features
8. `#### Security` - Security-related changes

**Rationale:** Breaking changes come first because they are the most critical information for anyone upgrading. Users need to know immediately if their code will break before seeing what new features are available.

**Additional custom headings** (use sparingly when standard headings don't fit):

- `#### Documentation` - Documentation improvements
- `#### Developer (Contributors Only)` - Internal tooling changes
- `#### API Improvements` - API changes and improvements
- `#### Generator Improvements` - Generator-specific changes
- `#### Performance` - Performance improvements

**Prefer standard headings.** Only use custom headings when the change needs more specific categorization.

**Pro entries**: Pro-specific changes use an inline `**[Pro]**` tag prefix within the standard category sections (e.g., `- **[Pro]** **Feature name**: Description...`). Do NOT create separate `#### Pro` subsections.

**Only include section headings that have entries.**

### Version Stamping with Rake Task

When this command is invoked with `release`, `rc`, or `beta`, **use the rake task to stamp the version header** after adding entries:

```bash
bundle exec rake "update_changelog[release]"   # stamp next stable version
bundle exec rake "update_changelog[rc]"        # stamp next RC version
bundle exec rake "update_changelog[beta]"      # stamp next beta version
```

The rake task handles:

- Auto-computing the next version from changelog headings and git tags
- Inserting the version header right after `### [Unreleased]`
- Updating version diff links at the bottom of the file
- For `rc`/`beta` modes: collapsing prior prerelease sections of the same base version into a single section

Do NOT manually insert version headers or update diff links -- the rake task does this correctly.

**When to use which tool:**

- **`/update-changelog release` (Claude Code)**: Full automation -- analyzes commits, writes changelog entries, then calls the rake task to stamp the version header. Use before a release.
- **`/update-changelog` (Claude Code, no args)**: Adds entries to `[Unreleased]` during development. Does not stamp a version header.
- **`bundle exec rake "update_changelog[mode]"`**: Header-only stamping for users who want to write entries manually.

### Finding the Most Recent Version

To determine the most recent version:

1. **Check git tags** to find the latest released version:

   ```bash
   git tag --sort=-v:refname | head -10
   ```

   This shows tags like `v16.2.0.beta.20`, `v16.2.0.beta.19`, etc.

2. **Check the CHANGELOG.md** for version headers (note: changelog uses versions WITHOUT the `v` prefix):
   - `### [16.2.0.beta.19] - 2025-12-10` (beta version)
   - `### [16.1.1] - 2025-09-24` (stable version)

3. **Use this regex pattern** to find version headers in the changelog:

   ```regex
   ^### \[([^\]]+)\] - \d{4}-\d{2}-\d{2}
   ```

4. **The first match after `### [Unreleased]`** is the most recent version in the changelog.

**IMPORTANT**: Git tags use `v` prefix (e.g., `v16.2.0.beta.20`) but the changelog and compare links use versions WITHOUT the `v` prefix (e.g., `16.2.0.beta.20`). Strip the `v` when adding to the changelog.

### Version Links

After adding an entry to the `### [Unreleased]` section, ensure the version diff links at the bottom of the file are correct.

The format at the bottom should be:

```markdown
[unreleased]: https://github.com/shakacode/react_on_rails/compare/16.2.0.beta.19...master
[16.2.0.beta.19]: https://github.com/shakacode/react_on_rails/compare/16.1.1...16.2.0.beta.19
```

When a new version is released:

1. Insert the new version header **immediately after** `### [Unreleased]`:

   ```markdown
   ### [Unreleased]

   ### [16.2.0.beta.20] - 2025-12-12
   ```

2. Update the `[unreleased]:` link to compare from the new version to master
3. Add a new version link comparing the previous version to the new version

## Process

### For Regular Changelog Updates

#### Step 1: Fetch and read current state

- **CRITICAL**: Run `git fetch origin master` to ensure you have the latest commits
- After fetching, use `origin/master` for all comparisons, NOT local `master` branch
- Read the current CHANGELOG.md to understand the existing structure

#### Step 2: Reconcile tags with changelog sections (DO THIS FIRST)

**This step catches missing version sections and is the #1 source of errors when skipped.**

1. Get the latest git tag: `git tag --sort=-v:refname | head -5`
2. Get the most recent version header in CHANGELOG.md (the first `### [VERSION] - DATE` after `### [Unreleased]`)
3. **Compare them.** If the latest git tag (minus the `v` prefix) does NOT match the latest changelog version header, there are tagged releases missing from the changelog. For example:
   - Latest tag: `v16.4.0.rc.4`
   - Latest changelog version: `### [16.4.0.rc.3]`
   - **Result: `16.4.0.rc.4` is missing and needs its own section**

4. For EACH missing tagged version (there may be multiple):
   a. Find commits in that tag vs the previous tag: `git log --oneline PREV_TAG..MISSING_TAG`
   b. Extract PR numbers and fetch details for user-visible changes
   c. Check which entries currently in `### [Unreleased]` actually belong to this tagged version (compare PR numbers against the commit list)
   d. **Create a new version section** immediately before the previous version section:

   ```markdown
   ### [16.4.0.rc.4] - 2026-02-22
   ```

   e. **Move** matching entries from Unreleased into the new section
   f. **Add** any new entries for PRs in that tag that aren't in the changelog at all
   g. **Update version diff links** at the bottom of the file:
   - Update `[unreleased]:` to compare from the newest tag to master
   - Add a link for each new version section

5. Get the tag date with: `git log -1 --format="%Y-%m-%d" TAG_NAME`

#### Step 3: Add new entries for post-tag commits

1. Run `git log --oneline LATEST_TAG..origin/master` to find commits after the latest tag
2. Extract PR numbers: `git log --oneline LATEST_TAG..origin/master | grep -oE "#[0-9]+" | sort -u`
3. For each PR number, check if it's already in CHANGELOG.md: `grep "PR XXX" CHANGELOG.md`
4. For PRs not yet in the changelog:
   - Get PR details: `gh pr view NUMBER --json title,body,author --repo shakacode/react_on_rails`
   - **Never ask the user for PR details** - get them from git history or the GitHub API
   - Validate that the change is user-visible (per the criteria above). Skip CI, lint, refactoring, test-only changes.
   - Add the entry to `### [Unreleased]` under the appropriate category heading

#### Step 4: Stamp version header (only when a version mode or explicit version is given)

If the user passed `release`, `rc`, `beta`, or an explicit version string as an argument:

**For `release`, `rc`, or `beta` keywords:**

1. Run the rake task to stamp the version header:

   ```bash
   bundle exec rake "update_changelog[release]"   # or rc, or beta
   ```

2. The rake task will:
   - Auto-compute the next version
   - Insert the header after `### [Unreleased]`
   - Update diff links at the bottom
   - For `rc`/`beta`: collapse prior prerelease sections

3. **Verify** the computed version looks correct. If not, the user can manually adjust.

**For an explicit version string** (e.g., `16.5.0.rc.10`):

1. Pass the explicit version directly to the rake task:

   ```bash
   bundle exec rake "update_changelog[16.5.0.rc.10]"
   ```

2. **Verify** the stamped header and diff links match the requested version.

If no argument was passed, skip this step -- entries stay in `### [Unreleased]`.

#### Step 5: Verify and finalize

1. **Verify formatting**:
   - Bold description with period
   - Proper PR link (NO hash symbol)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character
2. **Verify version sections are in order** (Unreleased -> newest tag -> older tags)
3. **Verify version diff links** at the bottom of the file are correct
4. **Show the user** a summary of what was done:
   - Which version sections were created
   - Which entries were moved from Unreleased
   - Which new entries were added
   - Which PRs were skipped (and why)
5. If in `release`/`rc`/`beta` mode or explicit-version mode, **automatically commit, push, and open a PR**:
   - Create a feature branch (e.g., `changelog-16.4.0.rc.10`)
   - Commit CHANGELOG.md (and the skill file if it was also modified)
   - Push and open a PR with the changelog diff as the body
   - If the push or PR creation fails, the CHANGELOG is already stamped locally — fix the issue (e.g., authentication, branch protection), then run `git push -u origin <branch>` and `gh pr create` manually
   - Remind the user to run `rake release` (no args) after merge to publish and auto-create the GitHub release

### For Prerelease Versions (RC and Beta)

When the user passes `rc` or `beta` as an argument:

1. **Find the latest tag** (stable or prerelease) using semver sort:

   ```bash
   git tag -l 'v*' --sort=-v:refname | head -10
   ```

2. **Auto-compute the next prerelease version** using the process in "Auto-Computing the Next Version" above.

3. **Always collapse prior prereleases into the current prerelease** (this is the default behavior):
   - Combine all prior prerelease changelog entries into the new prerelease version section
   - Remove previous prerelease version sections (e.g., remove `### [16.5.0.rc.0]` when creating `### [16.5.0.rc.1]`)
   - Add any new user-visible changes from commits since the last prerelease
   - Update version diff links to point from the last stable version to the new prerelease
   - This keeps the changelog clean with a single prerelease section that accumulates all changes since the last stable release

**CRITICAL**: The new version header must be inserted **immediately after `### [Unreleased]`**, NOT after "Changes since the last non-beta release." or any other text. This ensures correct ordering of version headers.

### For Prerelease to Stable Version Release

When releasing from prerelease to a stable version (e.g., `v16.5.0.rc.1` -> `v16.5.0`):

1. **Remove all prerelease version labels** from the changelog:
   - Change `### [16.5.0.rc.0]`, `### [16.5.0.rc.1]`, etc. to a single `### [16.5.0]` section
   - Also handle beta versions: `### [16.5.0.beta.1]` etc.
   - Combine all prerelease entries into the stable release section

2. **Consolidate duplicate entries**:
   - If bug fixes or changes were made to features introduced in earlier prereleases, keep only the final state
   - Remove redundant changelog entries for fixes to prerelease features
   - Keep the most recent/accurate description of each change

3. **Update version diff links** at the bottom to point to the stable version

## Examples

Run this command to see real formatting examples from the codebase:

```bash
grep -A 3 "^#### " CHANGELOG.md | head -30
```

### Good Entry Example

```markdown
- **Attribution Comment**: Added HTML comment attribution to Rails views containing React on Rails functionality. The comment automatically displays which version is in use (open source React on Rails or React on Rails Pro) and, for Pro users, shows the license status. This helps identify React on Rails usage across your application. [PR 1857](https://github.com/shakacode/react_on_rails/pull/1857) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
```

### Entry with Sub-bullets Example

```markdown
- **Server Bundle Security**: Added new configuration options for enhanced server bundle security and organization:
  - `server_bundle_output_path`: Configurable directory (relative to the Rails root) for server bundle output (default: "ssr-generated"). If set to `nil`, the server bundle will be loaded from the same public directory as client bundles. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
  - `enforce_private_server_bundles`: When enabled, ensures server bundles are only loaded from private directories outside the public folder (default: false for backward compatibility) [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
```

### Breaking Change Example

```markdown
- **React on Rails Core Package**: Several Pro-only methods have been removed from the core package and are now exclusively available in the `react-on-rails-pro` package. If you're using any of the following methods, you'll need to migrate to React on Rails Pro:
  - `getOrWaitForComponent()`
  - `getOrWaitForStore()`
  - `getOrWaitForStoreGenerator()`
  - `reactOnRailsStoreLoaded()`
  - `streamServerRenderedReactComponent()`
  - `serverRenderRSCReactComponent()`

**Migration Guide:**

To migrate to React on Rails Pro:

1. Install the Pro package:
   yarn add react-on-rails-pro

2. Update your imports from `react-on-rails` to `react-on-rails-pro`:
   // Before
   import ReactOnRails from 'react-on-rails';

   // After
   import ReactOnRails from 'react-on-rails-pro';
```

## Prerelease Changelog Curation

When consolidating prerelease versions (beta, RC) into a stable release, carefully curate entries to include only user-facing changes:

**Remove these types of entries:**

1. **Developer-only tooling**:
   - yalc publish fixes (local development tool)
   - Git dependency support (contributor workflow)
   - CI/build script improvements
   - Internal tooling changes

2. **Prerelease-specific fixes**:
   - Bugs introduced during the prerelease cycle (not present in last stable)
   - Fixes for new prerelease-only features
   - Generator handling of prerelease version formats

3. **Pro-specific features** (tag with `**[Pro]**` inline):
   - Node renderer fixes/improvements
   - Streaming-related changes
   - Async loading features (Pro-exclusive)

**Keep these types of entries:**

1. **User-facing fixes**:
   - Bugs that existed in previous stable release (e.g., 16.1.x)
   - Compatibility fixes (Rails version support, etc.)
   - Performance improvements affecting all users

2. **Breaking changes**:
   - API changes requiring migration
   - Removed methods/features
   - Configuration changes

**Investigation process:**

For each suspicious entry:

1. Check git history: `git log --oneline <last_stable>..<current_prerelease> -- <file>`
2. Determine when bug was introduced (stable vs prerelease cycle)
3. Verify whether fix applies to stable users or only prerelease users
4. Check PR description for context about what was broken

**Example reference:** See [PR 2072](https://github.com/shakacode/react_on_rails/pull/2072) for a complete example of prerelease changelog curation with detailed investigation notes.

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
- See CHANGELOG.md lines 15-18 for additional contributor guidelines
