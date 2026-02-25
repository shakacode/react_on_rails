# Update Changelog

You are helping to add an entry to the CHANGELOG.md file for the React on Rails project.

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
- `#### Pro License Features` - React on Rails Pro features

**Prefer standard headings.** Only use custom headings when the change needs more specific categorization.

**Only include section headings that have entries.**

### Version Management

After adding entries, use the rake task to manage version headers:

```bash
bundle exec rake update_changelog
```

This will:

- Add headers for the new version right after `### [Unreleased]`
- Update version diff links at the bottom of the file

**When to use which tool:**

- **`/update-changelog` (Claude Code)**: Full automation - analyzes commits, writes changelog entries, and creates a PR. Use this for comprehensive changelog updates.
- **`bundle exec rake update_changelog`**: Quick version header addition only. Use this if you just want the version header added and plan to write entries manually.

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

#### Step 4: Verify and finalize

1. **Verify formatting**:
   - Bold description with period
   - Proper PR link (NO hash symbol)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character
2. **Verify version sections are in order** (Unreleased → newest tag → older tags)
3. **Verify version diff links** at the bottom of the file are correct
4. **Show the user** a summary of what was done:
   - Which version sections were created
   - Which entries were moved from Unreleased
   - Which new entries were added
   - Which PRs were skipped (and why)

### For Beta to Non-Beta Version Release

When releasing from beta to a stable version (e.g., git tag `v16.1.0.beta.3` → `v16.1.0`):

1. **Remove all beta version labels** from the changelog:
   - Change `### [16.1.0.beta.1]`, `### [16.1.0.beta.2]`, etc. to a single `### [16.1.0]` section
   - Combine all beta entries into the stable release section

2. **Consolidate duplicate entries**:
   - If bug fixes or changes were made to features introduced in earlier betas, keep only the final state
   - Remove redundant changelog entries for fixes to beta features
   - Keep the most recent/accurate description of each change

3. **Update version diff links** using `bundle exec rake update_changelog`

### For New Beta Version Release

When a new beta version is released (e.g., `16.2.0.beta.20`):

1. **Check the latest git tag** to confirm the new version:

   ```bash
   git tag --sort=-v:refname | head -5
   ```

   This shows the latest tags (e.g., `v16.2.0.beta.20`). Strip the `v` prefix for changelog use.

2. **Find the most recent version** in the changelog by looking for the first `### [VERSION] - DATE` after `### [Unreleased]`

3. **Insert the new version header immediately after `### [Unreleased]`**:

   ```markdown
   ### [Unreleased]

   ### [16.2.0.beta.20] - 2025-12-12

   ### [16.2.0.beta.19] - 2025-12-10
   ```

4. **Update the version diff links at the bottom of the file**:
   - Change the `[unreleased]:` link to compare from the new version to master
   - Add a new link for the new version comparing to the previous version:

   ```markdown
   [unreleased]: https://github.com/shakacode/react_on_rails/compare/16.2.0.beta.20...master
   [16.2.0.beta.20]: https://github.com/shakacode/react_on_rails/compare/16.2.0.beta.19...16.2.0.beta.20
   [16.2.0.beta.19]: https://github.com/shakacode/react_on_rails/compare/16.1.1...16.2.0.beta.19
   ```

5. **For changelog entries**, ask the user which approach to take:

   **Option 1: Process changes since last beta**
   - Only add entries for commits since the previous beta version
   - Maintains detailed history of what changed in each beta

   **Option 2: Collapse all prior betas into current beta**
   - Combine all beta changelog entries into the new beta version
   - Removes previous beta version sections
   - Cleaner changelog with less version noise

After the user chooses, proceed with that approach.

**CRITICAL**: The new version header must be inserted **immediately after `### [Unreleased]`**, NOT after "Changes since the last non-beta release." or any other text. This ensures correct ordering of version headers.

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

## Beta Release Changelog Curation

When consolidating beta versions into a stable release, carefully curate entries to include only user-facing changes:

**Remove these types of entries:**

1. **Developer-only tooling**:
   - yalc publish fixes (local development tool)
   - Git dependency support (contributor workflow)
   - CI/build script improvements
   - Internal tooling changes

2. **Beta-specific fixes**:
   - Bugs introduced during the beta cycle (not present in last stable)
   - Fixes for new beta-only features (e.g., bin/dev in 16.2.0.beta)
   - Generator handling of beta/RC version formats

3. **Pro-specific features** (move to Pro changelog):
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

1. Check git history: `git log --oneline <last_stable>..<current_beta> -- <file>`
2. Determine when bug was introduced (stable vs beta cycle)
3. Verify whether fix applies to stable users or only beta users
4. Check PR description for context about what was broken

**Example reference:** See [PR #2072](https://github.com/shakacode/react_on_rails/pull/2072) for a complete example of beta changelog curation with detailed investigation notes.

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
- See CHANGELOG.md lines 15-18 for additional contributor guidelines
