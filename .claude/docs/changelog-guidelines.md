# Changelog Guidelines

**This is a monorepo with a SINGLE unified changelog:** `/CHANGELOG.md` — for both react_on_rails (open source) and react_on_rails_pro.

## Where to add entries

- Open-source features/fixes → Add to the regular category sections (`#### Added`, `#### Fixed`, etc.)
- Pro-only features/fixes → Add to the `#### Pro` section under the appropriate subcategory (`##### Added`, `##### Fixed`, etc.)
- Changes affecting both → Add to the regular sections; Pro-specific details go in the Pro section

Each release version has an optional `#### Pro` section at the end that contains Pro-specific entries organized by the same categories.

## Rules

- **Update CHANGELOG.md for user-visible changes only** (features, bug fixes, breaking changes, deprecations, performance improvements)
- **Do NOT add entries for**: linting, formatting, refactoring, tests, or documentation fixes
- **Format**: `[PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [username](https://github.com/username)` (no hash in PR number)
- **Use `/update-changelog` command** for guided changelog updates with automatic formatting
- **Version management after releases**: `bundle exec rake update_changelog`
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples
- **Beta release curation**: See `.claude/commands/update-changelog.md` for beta-to-stable consolidation process
