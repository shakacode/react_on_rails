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

Entries should be organized under these section headings. The project uses both standard and custom headings:

**Standard headings** (from keepachangelog.com) - use these for most changes:

- `#### Added` - New features
- `#### Changed` - Changes to existing functionality
- `#### Deprecated` - Deprecation notices
- `#### Removed` - Removed features
- `#### Fixed` - Bug fixes
- `#### Security` - Security-related changes
- `#### Improved` - Improvements to existing features

**Custom headings** (project-specific) - use sparingly when standard headings don't fit:

- `#### Breaking Changes` - Breaking changes with migration guides
- `#### API Improvements` - API changes and improvements
- `#### Developer Experience` - Developer workflow improvements
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

- Add headers for the new version
- Update version diff links at the bottom of the file

### Version Links

After adding an entry to the `## [Unreleased]` section, ensure the version diff links at the bottom of the file are correct.

The format at the bottom should be:

```markdown
[Unreleased]: https://github.com/shakacode/react_on_rails/compare/v16.0.0...master
[v16.0.0]: https://github.com/shakacode/react_on_rails/compare/v15.0.0...v16.0.0
```

When a new version is released:

1. Change `[Unreleased]` heading to `## [vX.Y.Z] - Month Day, Year`
2. Add a new `## [Unreleased]` section at the top
3. Update the `[Unreleased]` link to compare from the new version
4. Add a new version link for the released version

## Process

### For Regular Changelog Updates

1. **ALWAYS fetch latest changes first**:

   - **CRITICAL**: Run `git fetch origin master` to ensure you have the latest commits
   - The workspace may be behind origin/master, causing you to miss recently merged PRs
   - After fetching, use `origin/master` for all comparisons, NOT local `master` branch

2. **Determine the correct version tag to compare against**:

   - First, check the tag dates: `git log --tags --simplify-by-decoration --pretty="format:%ai %d" | head -10`
   - Find the latest version tag and its date
   - Compare origin/master branch date to the tag date
   - If the tag is NEWER than origin/master, it means the branch needs to be updated to include the tag's commits
   - **CRITICAL**: Always use `git log TAG..BRANCH` to find commits that are in the tag but not in the branch, as the tag may be ahead

3. **Check commits and version boundaries**:

   - **IMPORTANT**: Use `origin/master` in all commands below, not local `master`
   - Run `git log --oneline LAST_TAG..origin/master` to see commits since the last release
   - Also check `git log --oneline origin/master..LAST_TAG` to see if the tag is ahead of origin/master
   - If the tag is ahead, entries in "Unreleased" section may actually belong to that tagged version
   - **Extract ALL PR numbers** from commit messages using grep: `git log --oneline LAST_TAG..origin/master | grep -oE "#[0-9]+" | sort -u`
   - For each PR number found, check if it's already in CHANGELOG.md using: `grep "PR XXX" CHANGELOG.md` (note: no hash in search since React on Rails uses no hash)
   - Identify which commits contain user-visible changes (look for keywords like "Fix", "Add", "Feature", "Bug", etc.)
   - Extract author information from commit messages
   - **Never ask the user for PR details** - get them from the git history or use WebFetch on the PR URL

4. **Validate** that changes are user-visible (per the criteria above). If not user-visible, skip those commits.

5. **Read the current CHANGELOG.md** to understand the existing structure and formatting.

6. **Determine where entries should go**:

   - If the latest version tag is NEWER than origin/master branch, move entries from "Unreleased" to that version section
   - If origin/master is ahead of the latest tag, add new entries to "Unreleased"
   - Always verify the version date in CHANGELOG.md matches the actual tag date

7. **Add or move entries** to the appropriate section under appropriate category headings.

   - **CRITICAL**: When moving entries from "Unreleased" to a version section, merge them with existing entries under the same category heading
   - **NEVER create duplicate section headings** (e.g., don't create two "### Fixed" sections)
   - If the version section already has a category heading (e.g., "### Fixed"), add the moved entries to that existing section
   - Maintain the category order as defined above

8. **Verify formatting**:

   - Bold description with period
   - Proper PR link (NO hash symbol)
   - Proper author link
   - Consistent with existing entries
   - File ends with a newline character

9. **Run linting** after making changes:

   ```bash
   yarn lint
   ```

10. **Show the user** the added or moved entries and explain what was done.

### For Beta to Non-Beta Version Release

When releasing from beta to a stable version (e.g., v16.1.0-beta.3 → v16.1.0):

1. **Remove all beta version labels** from the changelog:

   - Change `### [v16.1.0-beta.1]`, `### [v16.1.0-beta.2]`, etc. to a single `### [v16.1.0]` section
   - Combine all beta entries into the stable release section

2. **Consolidate duplicate entries**:

   - If bug fixes or changes were made to features introduced in earlier betas, keep only the final state
   - Remove redundant changelog entries for fixes to beta features
   - Keep the most recent/accurate description of each change

3. **Update version diff links** using `bundle exec rake update_changelog`

### For New Beta Version Release

When creating a new beta version, ask the user which approach to take:

**Option 1: Process changes since last beta**

- Only add entries for commits since the previous beta version
- Maintains detailed history of what changed in each beta

**Option 2: Collapse all prior betas into current beta**

- Combine all beta changelog entries into the new beta version
- Removes previous beta version sections
- Cleaner changelog with less version noise

After the user chooses, proceed with that approach.

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

## Additional Notes

- Keep descriptions concise but informative
- Focus on the "what" and "why", not the "how"
- Use past tense for the description
- Be consistent with existing formatting in the changelog
- Always ensure the file ends with a trailing newline
- See CHANGELOG.md lines 15-18 for additional contributor guidelines
