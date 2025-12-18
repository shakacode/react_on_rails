# Link Checker Cleanup Checklist

**Branch:** `ihabadham/link-checker-cleanup`
**Issue:** #2232
**PR:** #2237
**Last updated:** 2025-12-19

---

## CI Errors Status

### File Path Errors (2) - Pending PR #2236

| Status | File                               | Error                                              | Fix      |
| ------ | ---------------------------------- | -------------------------------------------------- | -------- |
| [ ]    | CHANGELOG.md                       | `file://...generators/.../react_on_rails.rb#L27`   | PR #2236 |
| [ ]    | react_on_rails_pro/CONTRIBUTING.md | `file://...packages/node-renderer/tests/helper.ts` | PR #2236 |

### Fixed in This PR (14)

| Status | Error                                                 | File                                  | Fix                                      |
| ------ | ----------------------------------------------------- | ------------------------------------- | ---------------------------------------- |
| [x]    | `http://www.reactrails.com/`                          | CHANGELOG.md                          | Changed to `https://reactrails.com`      |
| [x]    | `https://questlab.pro/blog-posts/...`                 | Pro docs/release-notes                | Replaced with Wayback Machine archive    |
| [x]    | `https://ror-spec-dummy.reactrails.com/`              | README.md                             | Added to lychee exclusions               |
| [x]    | `http://www.pivotaltracker.com/`                      | PROJECTS.md                           | Added to lychee exclusions               |
| [x]    | `https://devchat.tv/ruby-rogues/...`                  | NEWS.md                               | Added to lychee exclusions               |
| [x]    | `https://undeveloped.com/`                            | PROJECTS.md                           | Added to lychee exclusions               |
| [x]    | `http://chlg.co/1GV2m9p`                              | Pro docs/style.md                     | Added to lychee exclusions               |
| [x]    | `https://badge.fury.io/js/react-on-rails`             | README.md                             | Added to lychee exclusions               |
| [x]    | `react-webpack-rails-tutorial/.../webpacker.yml`      | docs/upgrading                        | Updated to v9-rc-generator link          |
| [x]    | `shakacode.com/work/index.html`                       | NEWS.md                               | Removed outdated coaching line           |
| [x]    | `docs/basics/generator-functions-and-railscontext.md` | Pro docs/caching.md                   | Updated to new path                      |
| [x]    | `docs/configuration.md`                               | Pro docs/home-pro.md                  | Updated to new path                      |
| [x]    | `pro-package-tests.yml/badge.svg`                     | Pro README.md                         | Updated to pro-test-package-and-gem.yml  |
| [x]    | `shakacode.com/.../generator-details#rspack-support`  | README.md                             | Fixed URL path                           |

### Additional Fixes Found During Cleanup

| Status | Error                                  | File    | Fix                           |
| ------ | -------------------------------------- | ------- | ----------------------------- |
| [x]    | `https://github.com/reactjs/redux/...` | NEWS.md | Updated to `reduxjs/redux`    |

---

## Previously Fixed (Earlier in PR or Related PRs)

| Category                    | Count | Details                                                                   |
| --------------------------- | ----- | ------------------------------------------------------------------------- |
| Deleted GitHub users        | 7     | Added to .lychee.toml exclusions                                          |
| Missing git tags            | 10    | 4 exclusions + 6 CHANGELOG tag prefix fixes                               |
| Workflow badges (README.md) | 2     | main.yml → integration-tests.yml, rspec-package-specs.yml → gem-tests.yml |
| Dead Heroku badge           | 1     | Replaced with shields.io                                                  |

---

## False Positives (Not Actual Errors)

| Item                                           | Reason                                  |
| ---------------------------------------------- | --------------------------------------- |
| `INSTALLATION_MD_CHANGES_REPORT.md` (3 errors) | Untracked local file - CI never sees it |
| `angularjs.org`                                | Works in CI (successful redirect)       |
| `deliveroo.co.uk`                              | Works in CI (successful redirect)       |
| `hawaiichee.com`                               | Works in CI (redirects to hichee.com)   |
| `yourmechanic.com`                             | Not in CI errors                        |
| `loadable-client` Pro files (2)                | Already excluded by Pro repo pattern    |

---

## Summary

| Status                       | Count |
| ---------------------------- | ----- |
| Fixed in this PR             | 15    |
| Previously fixed             | 20    |
| Pending (PR #2236)           | 2     |
| False positives removed      | 8     |

---

## Related PRs

- **PR #2236** (pending): Fixes 2 file path errors
- **PR #2237** (this PR): Main cleanup PR - fixes 15 broken links
- **PR #2238** (merged): Added bin/check-links script
- **PR #2229** (merged): Fixed docs reorg paths
- **PR #2230** (merged): Added SSL exclusions
- **PR #2219** (merged): Migrated to lychee
