# Manual Dev Environment Testing

Automated tests can pass while the development environment is completely broken. CI starts services explicitly and runs in a controlled environment — it does not exercise `bin/dev`, Procfile orchestration, or the actual browser experience. This guide ensures agents verify the dev environment works end-to-end before submitting a PR.

**Related:** [PR Testing Guide](pr-testing-guide.md), [Testing Build Scripts](testing-build-scripts.md)

## The Rule

> Automated tests passing is necessary but not sufficient. Any PR that changes how the app starts, builds, or serves must include manual dev environment verification.

## When Manual Testing Is Required

If your PR touches **any** of these, you must run through the applicable checklist phases below:

- `Procfile.dev` or process manager config
- Webpack, Rspack, or Shakapacker configuration
- `Gemfile` or `package.json` (dependency changes)
- Rails initializers or environment config
- SSR configuration, Node renderer, or server bundle setup
- Routes that add new pages
- Environment variables used at startup

If your PR only touches test files, docs, or CI workflows, manual dev testing is optional (but still recommended).

## Checklist Phases

### Phase 1: Dev Server Startup (BLOCKING)

Nothing else matters if the dev server won't start.

```bash
# 1. Install dependencies
bundle install
pnpm install  # or your project's required JS package manager

# 2. Start the dev server
bin/dev
```

Verify:

- [ ] `bin/dev` does not exit immediately with an error
- [ ] All processes defined in `Procfile.dev` start successfully
- [ ] No process crashes within the first 30 seconds
- [ ] Asset compilation completes (look for "compiled successfully" in output)
- [ ] The app responds at its configured port (typically `http://localhost:3000`)
- [ ] No "can't find X in manifest.json" or similar asset resolution errors

### Phase 2: Page Smoke Test

Visit the primary routes and every route touched by your PR. For each page:

- [ ] Page loads without 500/404 errors
- [ ] React components are visible (not empty containers waiting for JS)
- [ ] Browser console has no JavaScript errors
- [ ] Navigation links work

If your PR adds a new route, verify it appears in navigation and renders correctly.

### Phase 3: SSR Verification

If the app uses server-side rendering, verify it actually works:

- [ ] View page source shows rendered component markup (not empty `<div>` containers)
- [ ] Disabling JavaScript in the browser still shows meaningful content
- [ ] No timeout errors in the Rails server logs (e.g., `Net::ReadTimeout`)
- [ ] No SSR error stack traces in server output

### Phase 4: Interactive Functionality

- [ ] Forms submit and produce expected results
- [ ] Client-side navigation works without full page reloads (for SPA routes)
- [ ] Interactive elements respond (toggles, buttons, modals)
- [ ] Hot reload works: edit a component file and see the change in the browser without manual refresh

### Phase 5: Process Health

After running for 1-2 minutes:

- [ ] No process has crashed and restarted
- [ ] `Ctrl+C` cleanly stops all processes
- [ ] Starting `bin/dev` a second time works (no stale port locks or zombie processes)

## Which Phases to Run

| Change type                                | Required phases            |
| ------------------------------------------ | -------------------------- |
| Process/Procfile changes                   | 1, 2, 5                    |
| Webpack/bundler config                     | 1, 2, 3                    |
| Dependency changes (Gemfile, package.json) | 1, 2                       |
| SSR / Node renderer changes                | 1, 2, 3                    |
| Rails initializer or env config            | 1, 2, 3                    |
| Environment variables used at startup      | 1, 2, 3                    |
| New routes or pages                        | 1, 2, 3, 4                 |
| React component changes                    | 1, 2, 4                    |
| CI workflow only                           | None (Phase 1 recommended) |

## Common Failure Modes

These are real failures that have shipped because agents relied solely on automated tests:

**`bin/dev` won't start** — A new service was added to `Procfile.dev` but its startup config was broken. Rspec passed because CI starts services independently, not through `bin/dev`.

**Tests pass, app doesn't render** — Webpack config changes produce bundles that work in test mode but fail in development mode, or `manifest.json` becomes stale between runs.

**SSR silently disabled** — The SSR service isn't running or its config guard excludes the current environment. Pages load via client rendering only, which looks fine in a quick glance but breaks the expected user experience.

**Port conflicts** — A previous `bin/dev` instance is still running, or a new service was hardcoded to a port already in use.

## Reporting Results

Include a dev environment verification section in your PR description:

```markdown
## Dev Environment Verification

- [x] `bin/dev` starts all processes without errors
- [x] Asset compilation completes successfully
- [x] All routes load without errors
- [x] SSR verified via view-source
- [x] No browser console errors
- [x] Interactive features work
- [x] Clean shutdown with Ctrl+C
```

If you **cannot** run `bin/dev` (missing database, credentials, services), say so explicitly:

```markdown
⚠️ **DEV ENVIRONMENT UNTESTED** — Could not run `bin/dev` because [reason].
Automated tests pass but manual dev server verification is required before merge.
```

Include this section for every PR: if manual dev testing was required or run, provide checklist results; if skipped (for optional cases), state that it was skipped and why.
