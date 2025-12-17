# Link Checker Cleanup Checklist

**Branch:** `ihabadham/link-checker-cleanup`
**Issue:** #2232
**PR:** #2237
**Last updated:** 2025-12-17

---

## Category 1: Local File Paths (4 errors)

| Status | File | Error | Fix |
|--------|------|-------|-----|
| [x] | CHANGELOG.md:1743 | `file://...generators/.../react_on_rails.rb#L27` | PR #2236 |
| [ ] | INSTALLATION_MD_CHANGES_REPORT.md | `file://...configuration.md` | Investigate |
| [ ] | INSTALLATION_MD_CHANGES_REPORT.md | `file://...node-renderer/js-configuration.md` | Investigate |
| [x] | react_on_rails_pro/CONTRIBUTING.md:279 | `file://...packages/node-renderer/tests/helper.ts` | PR #2236 |

---

## Category 2: Deleted GitHub Users (7 errors) ✅ DONE

| Status | User | Fix |
|--------|------|-----|
| [x] | alleycat-at-git | Added to .lychee.toml exclusions |
| [x] | Conturbo | Added to .lychee.toml exclusions |
| [x] | jblasco3 | Added to .lychee.toml exclusions |
| [x] | nostophilia | Added to .lychee.toml exclusions |
| [x] | railsme | Added to .lychee.toml exclusions |
| [x] | samphilipd | Added to .lychee.toml exclusions |
| [x] | wouldntsavezion | Added to .lychee.toml exclusions |

---

## Category 3: Missing Git Tags (10 errors) ✅ DONE

| Status | Compare Link | Fix |
|--------|--------------|-----|
| [x] | `8.0.6...8.0.7` | Exclusion (8.0.7 never tagged) |
| [x] | `8.0.7...9.0.0` | Exclusion (8.0.7 never tagged) |
| [x] | `10.1.1...10.1.2` | Exclusion (10.1.2 never tagged) |
| [x] | `10.1.2...10.1.3` | Exclusion (10.1.2 never tagged) |
| [x] | `16.1.1...16.2.0.beta.19` | Fixed tag prefix in CHANGELOG |
| [x] | `16.2.0.beta.19...16.2.0.beta.20` | Fixed tag prefix in CHANGELOG |
| [x] | `16.2.0.beta.20...master` | Fixed tag prefix in CHANGELOG |
| [x] | `v1.2.2...v2.0.0` | Fixed tag prefix in CHANGELOG |
| [x] | `v2.0.0...v2.0.1` | Fixed tag prefix in CHANGELOG |
| [x] | `4.0.0-rc.14...4.0.0-rc.15` | Exclusion (private Pro repo) |

---

## Category 4: Workflow Badges (3 errors)

| Status | Badge | File | Fix |
|--------|-------|------|-----|
| [x] | `main.yml/badge.svg` | README.md | → integration-tests.yml |
| [x] | `rspec-package-specs.yml/badge.svg` | README.md | → gem-tests.yml |
| [ ] | `pro-package-tests.yml/badge.svg` | react_on_rails_pro/README.md | → pro-test-package-and-gem.yml |

---

## Category 5: Network/Connection Errors (5 errors)

| Status | URL | File | Action |
|--------|-----|------|--------|
| [ ] | `http://www.reactrails.com/` | CHANGELOG.md | Investigate |
| [ ] | `https://angularjs.org/` | docs/migrating/angular-js-integration-migration.md | Investigate |
| [ ] | `http://www.pivotaltracker.com/` | PROJECTS.md | Investigate |
| [ ] | `https://questlab.pro/blog-posts/...` | react_on_rails_pro/docs/release-notes/v4-react-server-components.md | Investigate |
| [ ] | `https://ror-spec-dummy.reactrails.com/` | README.md | Investigate |

---

## Category 6: Timeouts (3 errors)

| Status | URL | File | Action |
|--------|-----|------|--------|
| [ ] | `https://devchat.tv/ruby-rogues/...` | NEWS.md | Investigate |
| [ ] | `https://undeveloped.com/` | PROJECTS.md | Investigate |
| [ ] | `http://chlg.co/1GV2m9p` | react_on_rails_pro/docs/contributors-info/style.md | Investigate |

---

## Category 7: 403 Forbidden (5 errors)

| Status | URL | File | Action |
|--------|-----|------|--------|
| [ ] | `https://badge.fury.io/js/react-on-rails` | README.md | Test in browser |
| [ ] | `https://stackoverflow.com/questions/58316109/...` | INSTALLATION_MD_CHANGES_REPORT.md | Test in browser |
| [ ] | `https://deliveroo.co.uk/` | PROJECTS.md | Test in browser |
| [ ] | `https://www.hawaiichee.com/` | PROJECTS.md | Test in browser |
| [ ] | `https://www.yourmechanic.com/` | PROJECTS.md | Test in browser |

---

## Category 8: Other 404s - Path/Repo Changes (11 errors)

| Status | URL | File | Fix |
|--------|-----|------|-----|
| [ ] | `react-webpack-rails-tutorial/.../webpacker.yml` | docs/upgrading/upgrading-react-on-rails.md | File deleted |
| [ ] | `shakacode.com/work/index.html` | NEWS.md | Page removed |
| [ ] | `reactjs/redux/issues/1335` | NEWS.md | Update to reduxjs/redux |
| [x] | `react_on_rails_pro/blob/more_test_and_docs/...` | react_on_rails_pro/CONTRIBUTING.md | PR #2236 |
| [ ] | `docs/basics/generator-functions-and-railscontext.md` | react_on_rails_pro/docs/caching.md | Find new path |
| [ ] | `spec/dummy/.../loadable-client.imports-hmr.js` | react_on_rails_pro/docs/code-splitting-loadable-components.md | Check Pro repo |
| [ ] | `spec/dummy/.../loadable-client.imports-loadable.jsx` | react_on_rails_pro/docs/code-splitting-loadable-components.md | Check Pro repo |
| [ ] | `docs/configuration.md` | react_on_rails_pro/docs/home-pro.md | Find new path |
| [x] | `ruby-gem-downloads-badge.herokuapp.com` | README.md | Replaced with shields.io |
| [ ] | `shakacode.com/.../generator-details#rspack-support` | README.md | Check if page exists |

---

## Summary

| Category | Total | Fixed | Remaining |
|----------|-------|-------|-----------|
| 1. Local file paths | 4 | 2 (PR #2236) | 2 |
| 2. Deleted GitHub users | 7 | 7 | 0 ✅ |
| 3. Missing git tags | 10 | 10 | 0 ✅ |
| 4. Workflow badges | 3 | 2 | 1 |
| 5. Network errors | 5 | 0 | 5 |
| 6. Timeouts | 3 | 0 | 3 |
| 7. 403 Forbidden | 5 | 0 | 5 |
| 8. Other 404s | 11 | 2 | 9 |
| **TOTAL** | **48** | **23** | **25** |

---

## PRs

- **PR #2236** (pending): Fixes 3 local file path errors
- **PR #2237** (this PR): Fixes 20 errors (exclusions + CHANGELOG + badges)
- **PR #2229** (merged): Fixed docs reorg paths
- **PR #2230** (merged): Added SSL exclusions
