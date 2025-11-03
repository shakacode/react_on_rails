# Issue: Add Playwright Test to Catch Turbo Navigation Regression

## Summary

A regression was discovered where JavaScript fails to work after navigating between pages using Turbo links (only works on hard refresh). This issue existed in the codebase for over a year but wasn't caught by automated tests.

## Background

### What Happened

**Bug introduced in:** PR #1620 (commit 56ee2bd9, ~1 year ago)

- Added Turbo (Hotwire) support to replace Turbolinks
- Updated client-bundle.js to import `@hotwired/turbo-rails`
- Set `turbo: true` in ReactOnRails options
- **Forgot to update layout file** from `data-turbolinks-track` to `data-turbo-track`

**Bug fixed in:** PR #XXXX (commit f03b935d)

- Updated `spec/dummy/app/views/layouts/application.html.erb`
- Changed `data-turbolinks-track: true` to `data-turbo-track: 'reload'`
- Re-added `defer: true` for proper Turbo compatibility

### Impact

Users experienced broken JavaScript when:

1. Landing on a page (hard refresh) → ✅ JavaScript works
2. Clicking a link to navigate → ❌ JavaScript breaks
3. Hard refreshing again → ✅ JavaScript works again

This severely degraded the user experience with Turbo navigation.

## The Test Gap

This bug went undetected for over a year, indicating a gap in test coverage for:

- Turbo navigation flows
- JavaScript execution after client-side navigation
- React component hydration after Turbo page loads

## Proposed Solution: Playwright E2E Test

Add a Playwright test that verifies:

### Test Scenario

```javascript
test('React components work after Turbo navigation', async ({ page }) => {
  // 1. Hard refresh - load first page
  await page.goto('/react_router');

  // 2. Verify JavaScript works on initial load
  await expect(page.locator('input#name')).toBeVisible();
  await page.fill('input#name', 'Initial Page');
  await expect(page.locator('h3')).toContainText('Initial Page');

  // 3. Click a Turbo link to navigate to second page
  await page.click('a[href="/react_router/second_page"]');
  await page.waitForURL('/react_router/second_page');

  // 4. Verify JavaScript STILL works after Turbo navigation
  await expect(page.locator('input#name')).toBeVisible();
  await page.fill('input#name', 'After Turbo Navigation');
  await expect(page.locator('h3')).toContainText('After Turbo Navigation');

  // 5. Navigate back
  await page.click('a[href="/react_router"]');
  await page.waitForURL('/react_router');

  // 6. Verify JavaScript works after navigating back
  await expect(page.locator('input#name')).toBeVisible();
  await page.fill('input#name', 'After Back Navigation');
  await expect(page.locator('h3')).toContainText('After Back Navigation');
});
```

### What This Test Catches

✅ JavaScript execution after Turbo navigation
✅ React component hydration on client-side page loads
✅ Proper data attributes for Turbo compatibility
✅ Component lifecycle management with Turbo

## Verification Steps

To verify the Playwright test works correctly:

### Step 1: Ensure Test Passes with Fix

```bash
# Current state (with fix) - test should PASS
npm run test:e2e -- --grep "Turbo navigation"
```

### Step 2: Revert the Fix

```bash
# Revert to broken state
git show f03b935d:spec/dummy/app/views/layouts/application.html.erb > spec/dummy/app/views/layouts/application.html.erb

# Change line 13 back to:
# <%= javascript_pack_tag('client-bundle', 'data-turbolinks-track': true) %>
```

### Step 3: Verify Test Fails

```bash
# With reverted fix - test should FAIL
npm run test:e2e -- --grep "Turbo navigation"

# Expected failure:
# Error: Timeout waiting for element 'input#name' after Turbo navigation
```

### Step 4: Restore the Fix

```bash
# Restore the fix
git checkout HEAD spec/dummy/app/views/layouts/application.html.erb

# Test should PASS again
npm run test:e2e -- --grep "Turbo navigation"
```

## Implementation Checklist

- [ ] Create Playwright test file: `spec/dummy/spec/playwright/turbo_navigation.spec.js`
- [ ] Add test that verifies React components work after Turbo navigation
- [ ] Verify test passes with current fix in place
- [ ] Manually revert fix and confirm test fails (proves test is effective)
- [ ] Restore fix and confirm test passes again
- [ ] Add test to CI pipeline
- [ ] Document in CONTRIBUTING.md that Turbo navigation must be tested

## Additional Test Cases to Consider

1. **Multiple navigations**: Navigate through 3-4 pages to ensure no memory leaks
2. **Back/forward buttons**: Test browser back/forward with Turbo
3. **Turbo Frames**: Test components inside turbo frames
4. **Turbo Streams**: Test components updated via turbo streams (Pro feature)
5. **Redux stores**: Verify store state persists/resets appropriately

## Files to Create/Modify

```tree
spec/dummy/spec/playwright/
  ├── turbo_navigation.spec.js          (new)
  └── support/
      └── turbo_helpers.js              (new - optional helper functions)

.github/workflows/
  └── playwright.yml                    (update to run new tests)

docs/contributor-info/
  └── testing-turbo-navigation.md       (new - documentation)
```

## Success Criteria

- [ ] Playwright test exists and passes in CI
- [ ] Test catches the regression when fix is reverted
- [ ] Test is documented and maintainable
- [ ] Test runs in <30 seconds
- [ ] No false positives in CI

## References

- **Original Turbo PR**: #1620 (56ee2bd9)
- **Fix commit**: f03b935d
- **Turbo documentation**: docs/building-features/turbolinks.md
- **Related issue**: This regression went undetected for 1+ year

## Notes for Implementer

- Use React on Rails Pro dummy app for testing (has more Turbo features)
- Consider using Playwright's `page.route()` to simulate slow networks
- Add `data-testid` attributes to components if needed for reliable selectors
- Test both development and production webpack builds
- Ensure test works with different Turbo Drive settings (`turbo: true/false`)

---

**Priority**: High - This prevents regressions in core Turbo functionality

**Estimated effort**: 2-4 hours (including documentation and verification)

**Labels**: testing, playwright, turbo, e2e, regression-prevention
