# Link Checker Cleanup Checklist

**Branch:** `ihabadham/link-checker-cleanup`
**Issue:** #2232
**Last updated:** 2025-12-17
**Fresh lychee run:** 48 total issues (45 errors + 3 timeouts)

---

## Category 1: Local File Paths (4 errors)

| Status | File | Error | Fix |
|--------|------|-------|-----|
| [ ] | CHANGELOG.md:1743 | `file://...generators/.../react_on_rails.rb#L27` | PR #2236 fixes |
| [ ] | INSTALLATION_MD_CHANGES_REPORT.md | `file://...configuration.md` | Investigate |
| [ ] | INSTALLATION_MD_CHANGES_REPORT.md | `file://...node-renderer/js-configuration.md` | Investigate |
| [ ] | react_on_rails_pro/CONTRIBUTING.md:279 | `file://...packages/node-renderer/tests/helper.ts` | PR #2236 fixes |

---

## Category 2: Deleted GitHub Users (7 errors)

| Status | User | Verified 404? |
|--------|------|---------------|
| [ ] | alleycat-at-git | Yes |
| [ ] | Conturbo | Yes |
| [ ] | jblasco3 | Yes |
| [ ] | nostophilia | Yes |
| [ ] | railsme | Yes |
| [ ] | samphilipd | Yes |
| [ ] | wouldntsavezion | Yes |

**Fix:** Add regex to `.lychee.toml`

---

## Category 3: Missing Git Tags (10 errors)

| Status | Compare Link | File |
|--------|--------------|------|
| [ ] | `8.0.6...8.0.7` | CHANGELOG.md |
| [ ] | `8.0.7...9.0.0` | CHANGELOG.md |
| [ ] | `10.1.1...10.1.2` | CHANGELOG.md |
| [ ] | `10.1.2...10.1.3` | CHANGELOG.md |
| [ ] | `16.1.1...16.2.0.beta.19` | CHANGELOG.md |
| [ ] | `16.2.0.beta.19...16.2.0.beta.20` | CHANGELOG.md |
| [ ] | `16.2.0.beta.20...master` | CHANGELOG.md |
| [ ] | `v1.2.2...v2.0.0` | CHANGELOG.md |
| [ ] | `v2.0.0...v2.0.1` | CHANGELOG.md |
| [ ] | `4.0.0-rc.14...4.0.0-rc.15` | react_on_rails_pro/CHANGELOG.md |

---

## Category 4: Workflow Badges (3 errors)

| Status | Badge | File |
|--------|-------|------|
| [ ] | `main.yml/badge.svg` | README.md |
| [ ] | `rspec-package-specs.yml/badge.svg` | README.md |
| [ ] | `pro-package-tests.yml/badge.svg` | react_on_rails_pro/README.md |

---

## Category 5: Network/Connection Errors (5 errors)

| Status | URL | File |
|--------|-----|------|
| [ ] | `http://www.reactrails.com/` | CHANGELOG.md |
| [ ] | `https://angularjs.org/` | docs/migrating/angular-js-integration-migration.md |
| [ ] | `http://www.pivotaltracker.com/` | PROJECTS.md |
| [ ] | `https://questlab.pro/blog-posts/...` | react_on_rails_pro/docs/release-notes/v4-react-server-components.md |
| [ ] | `https://ror-spec-dummy.reactrails.com/` | README.md |

---

## Category 6: Timeouts (3 errors)

| Status | URL | File |
|--------|-----|------|
| [ ] | `https://devchat.tv/ruby-rogues/...` | NEWS.md |
| [ ] | `https://undeveloped.com/` | PROJECTS.md |
| [ ] | `http://chlg.co/1GV2m9p` | react_on_rails_pro/docs/contributors-info/style.md |

---

## Category 7: 403 Forbidden (5 errors)

| Status | URL | File |
|--------|-----|------|
| [ ] | `https://badge.fury.io/js/react-on-rails` | README.md |
| [ ] | `https://stackoverflow.com/questions/58316109/...` | INSTALLATION_MD_CHANGES_REPORT.md |
| [ ] | `https://deliveroo.co.uk/` | PROJECTS.md |
| [ ] | `https://www.hawaiichee.com/` | PROJECTS.md |
| [ ] | `https://www.yourmechanic.com/` | PROJECTS.md |

---

## Category 8: Other 404s - Path/Repo Changes (11 errors)

| Status | URL | File | Issue |
|--------|-----|------|-------|
| [ ] | `react-webpack-rails-tutorial/.../webpacker.yml` | docs/upgrading/upgrading-react-on-rails.md | File deleted |
| [ ] | `shakacode.com/work/index.html` | NEWS.md | Page removed |
| [ ] | `reactjs/redux/issues/1335` | NEWS.md | Repo renamed to reduxjs |
| [ ] | `react_on_rails_pro/blob/more_test_and_docs/...` | react_on_rails_pro/CONTRIBUTING.md | PR #2236 fixes |
| [ ] | `docs/basics/generator-functions-and-railscontext.md` | react_on_rails_pro/docs/caching.md | Path changed |
| [ ] | `spec/dummy/.../loadable-client.imports-hmr.js` | react_on_rails_pro/docs/code-splitting-loadable-components.md | Check Pro repo |
| [ ] | `spec/dummy/.../loadable-client.imports-loadable.jsx` | react_on_rails_pro/docs/code-splitting-loadable-components.md | Check Pro repo |
| [ ] | `docs/configuration.md` | react_on_rails_pro/docs/home-pro.md | Path changed |
| [ ] | `ruby-gem-downloads-badge.herokuapp.com` | README.md | Service dead |
| [ ] | `shakacode.com/.../generator-details#rspack-support` | README.md | Page/anchor missing |

---

## Summary

| Category | Count | Action |
|----------|-------|--------|
| 1. Local file paths | 4 | Fix paths (2 in PR #2236) |
| 2. Deleted GitHub users | 7 | Add exclusions |
| 3. Missing git tags | 10 | Investigate & fix/remove |
| 4. Workflow badges | 3 | Check workflows, update/remove |
| 5. Network errors | 5 | Test & exclude/remove |
| 6. Timeouts | 3 | Test & exclude/remove |
| 7. 403 Forbidden | 5 | Test in browser, exclude |
| 8. Other 404s | 11 | Fix paths or remove |
| **TOTAL** | **48** | |

---

## PRs That Will Fix Some Issues

- **PR #2236** (pending): Fixes 3 errors (Categories 1 and 8)
- **PR #2229** (merged): Fixed docs reorg paths
- **PR #2230** (merged): Added SSL exclusions

---

## Commands

```bash
# Run fresh check (delete cache first)
rm -f .lycheecache
lychee --config .lychee.toml docs/ *.md react_on_rails_pro/docs/ react_on_rails_pro/*.md

# Count errors
lychee ... 2>&1 | grep -c "^\[ERROR\]\|^\[404\]\|^\[403\]\|^\[TIMEOUT\]"

# Test specific URL
curl -sI "URL" | head -5
```
