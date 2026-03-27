# Changelog Guidelines

**This is a monorepo with a SINGLE unified changelog:** `/CHANGELOG.md` — for both react_on_rails (open source) and react_on_rails_pro.

## Where to add entries

- Open-source features/fixes → Add to the regular category sections (`#### Added`, `#### Fixed`, etc.)
- Pro-only features/fixes → Add to the regular category sections with an inline `**[Pro]**` tag prefix (e.g., `- **[Pro]** **Feature name**: Description...`)
- Changes affecting both → Add to the regular sections; prefix with `**[Pro]**` if the change is primarily Pro-specific

All entries live in a single chronological flow within each release. Pro entries are identified by their `**[Pro]**` inline tag, not by separate subsections.

## Rules

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Before a release**: Run `/update-changelog release` (or `rc`/`beta`) to stamp a version header; then `rake release` reads it automatically and creates the GitHub release
- **Version management**: `bundle exec rake "update_changelog[release]"` (or `rc`/`beta`/explicit version) for header-only updates
- **After releasing without changelog**: Run `bundle exec rake "sync_github_release[VERSION]"` to create the GitHub release from CHANGELOG.md
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples
- **Prerelease curation**: See `.claude/commands/update-changelog.md` for prerelease-to-stable consolidation process
