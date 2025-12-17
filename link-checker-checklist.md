# Link Checker Cleanup Checklist

**Branch:** `ihabadham/link-checker-cleanup`
**Issue:** #2232
**PR:** #2237
**Last updated:** 2025-12-17

---

## Actual CI Errors (16 total)

Based on CI run #20290267104 on branch `ihabadham/link-checker-cleanup`.

### File Path Errors (2)

| Status | File                               | Error                                              | Fix      |
| ------ | ---------------------------------- | -------------------------------------------------- | -------- |
| [ ]    | CHANGELOG.md                       | `file://...generators/.../react_on_rails.rb#L27`   | PR #2236 |
| [ ]    | react_on_rails_pro/CONTRIBUTING.md | `file://...packages/node-renderer/tests/helper.ts` | PR #2236 |

### Network/Connection Errors (4)

| Status | URL                                      | File                                                                | Action                       |
| ------ | ---------------------------------------- | ------------------------------------------------------------------- | ---------------------------- |
| [ ]    | `http://www.reactrails.com/`             | CHANGELOG.md                                                        | Site down - remove or update |
| [ ]    | `https://questlab.pro/blog-posts/...`    | react_on_rails_pro/docs/release-notes/v4-react-server-components.md | Site down - remove           |
| [ ]    | `https://ror-spec-dummy.reactrails.com/` | README.md                                                           | Site down - remove or update |
| [ ]    | `http://www.pivotaltracker.com/`         | PROJECTS.md                                                         | Timeout - test manually      |

### Timeouts (3)

| Status | URL                                  | File                                               | Action                  |
| ------ | ------------------------------------ | -------------------------------------------------- | ----------------------- |
| [ ]    | `https://devchat.tv/ruby-rogues/...` | NEWS.md                                            | Timeout - test manually |
| [ ]    | `https://undeveloped.com/`           | PROJECTS.md                                        | Timeout - test manually |
| [ ]    | `http://chlg.co/1GV2m9p`             | react_on_rails_pro/docs/contributors-info/style.md | Timeout - test manually |

### 403 Forbidden (1)

| Status | URL                                       | File      | Action                      |
| ------ | ----------------------------------------- | --------- | --------------------------- |
| [ ]    | `https://badge.fury.io/js/react-on-rails` | README.md | Blocks bots - add exclusion |

### 404 Not Found (6)

| Status | URL                                                   | File                                       | Fix                                             |
| ------ | ----------------------------------------------------- | ------------------------------------------ | ----------------------------------------------- |
| [ ]    | `react-webpack-rails-tutorial/.../webpacker.yml`      | docs/upgrading/upgrading-react-on-rails.md | File deleted from tutorial repo                 |
| [ ]    | `shakacode.com/work/index.html`                       | NEWS.md                                    | Page removed                                    |
| [ ]    | `docs/basics/generator-functions-and-railscontext.md` | react_on_rails_pro/docs/caching.md         | Path changed - find new location                |
| [ ]    | `docs/configuration.md`                               | react_on_rails_pro/docs/home-pro.md        | Path changed - find new location                |
| [ ]    | `pro-package-tests.yml/badge.svg`                     | react_on_rails_pro/README.md               | Workflow renamed → pro-test-package-and-gem.yml |
| [ ]    | `shakacode.com/.../generator-details#rspack-support`  | README.md                                  | Page/anchor missing                             |

---

## Already Fixed (in this PR or PR #2236)

| Category                    | Count | Details                                                                   |
| --------------------------- | ----- | ------------------------------------------------------------------------- |
| Deleted GitHub users        | 7     | Added to .lychee.toml exclusions                                          |
| Missing git tags            | 10    | 4 exclusions + 6 CHANGELOG tag prefix fixes                               |
| Workflow badges (README.md) | 2     | main.yml → integration-tests.yml, rspec-package-specs.yml → gem-tests.yml |
| Dead Heroku badge           | 1     | Replaced with shields.io                                                  |

---

## False Positives Removed

These were in the original checklist but are NOT actual CI errors:

| Item                                           | Reason                                   |
| ---------------------------------------------- | ---------------------------------------- |
| `INSTALLATION_MD_CHANGES_REPORT.md` (3 errors) | Untracked local file - CI never sees it  |
| `angularjs.org`                                | Works in CI (successful redirect)        |
| `deliveroo.co.uk`                              | Works in CI (successful redirect)        |
| `hawaiichee.com`                               | Works in CI (redirects to hichee.com)    |
| `yourmechanic.com`                             | Not in CI errors                         |
| `reactjs/redux/issues/1335`                    | Works in CI (redirects to reduxjs/redux) |
| `loadable-client` Pro files (2)                | Already excluded by Pro repo pattern     |

---

## Summary

| Status                  | Count |
| ----------------------- | ----- |
| Already fixed           | 20    |
| Remaining CI errors     | 16    |
| False positives removed | 9     |

---

## Related PRs

- **PR #2236** (pending): Fixes 2 file path errors
- **PR #2237** (this PR): Main cleanup PR
- **PR #2238** (pending): Adds bin/check-links script
- **PR #2229** (merged): Fixed docs reorg paths
- **PR #2230** (merged): Added SSL exclusions
- **PR #2219** (merged): Migrated to lychee
