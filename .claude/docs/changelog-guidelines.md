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
- **Use the installed/shared `$update-changelog` skill** for guided mainline changelog updates with automatic formatting
- **Before a release**: Run `$update-changelog release` for ordinary mainline releases, or `$react-on-rails-update-changelog release`/`rc`/`beta` when the PR must target `release/X.Y.Z`; then `rake release` reads it automatically and creates the GitHub release
- **Version management**: `bundle exec rake "update_changelog[release]"` (or `rc`/`beta`/explicit version) for header-only updates
- **Security support window**: For minor and major releases, update `SECURITY.md` "Current support window" rows and cutoff dates to match the new release line
- **After releasing without changelog**: Run `bundle exec rake "sync_github_release[VERSION]"` to create the GitHub release from CHANGELOG.md
- **Examples**: Run `grep -A 3 "^#### " CHANGELOG.md | head -30` to see real formatting examples
- **Prerelease curation**: See `$react-on-rails-update-changelog` for release-branch targeting and the installed/shared `$update-changelog` skill for the portable prerelease-to-stable consolidation process
- **Helper signature changes**: If a `ReactOnRailsHelper` or `ReactOnRailsProHelper` method gains, loses, or renames a parameter, name both the method and the parameter in the entry — even for private or undocumented methods — so apps with a prepended override can grep for it. See `AGENTS.md` → "Changelog" → "Helper signature changes" for the copy-pasteable example (the 17.1.0 `on_chunk_errors:` miss)
- **Action-required placement**: An entry with deploy-order, memory/retention, or startup-failure implications must carry the inline `**Action required for upgraders:**` tag on the `CHANGELOG.md` entry itself — it stays in its normal category section — and, when the release has or needs a release-notes page, the same item must be repeated in that page's "Action required" section. See `AGENTS.md` → "Changelog" → "Action-required placement"
