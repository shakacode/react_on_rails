import { test, expect } from '@playwright/test';

// Regression test for issue #3211: CSS imported behind a `'use client'` boundary
// in a true RSC tree must be preloaded via `<link rel="stylesheet" precedence>`
// emitted from the RSC payload, so React 19 hoists it into the SSR'd <head> and
// the browser blocks first paint until it loads. Without the fix the stylesheet
// only loads as a side effect of the JS chunk evaluating, producing a flash of
// unstyled content (FOUC).
//
// `UseClientCssProbe` ('use client', imports a CSS module) is rendered by
// `RSCPostsPage` on the streaming RSC route below.
test.describe('RSC use-client CSS (#3211 FOUC fix)', () => {
  test('preloads the use-client stylesheet (hoisted into SSR <head>) and styles the probe', async ({
    page,
  }) => {
    const response = await page.goto('/rsc_posts_page_over_http', { waitUntil: 'commit' });
    const ssrHtml = (await response?.text()) ?? '';

    // No-FOUC guarantee: the renderer hoists the use-client stylesheet into the
    // server-rendered <head> with our precedence group, so the browser will not
    // paint the boundary until the stylesheet has loaded.
    expect(ssrHtml).toMatch(/<link[^>]*rel="stylesheet"[^>]*data-precedence="ror-rsc"[^>]*>/);

    const probe = page.getByTestId('rsc-css-probe');
    await expect(probe).toBeVisible();

    // The precedence-grouped stylesheet resource is present in the live document
    // (React keeps it as it manages the loaded stylesheet).
    await expect(page.locator('link[rel="stylesheet"][data-precedence="ror-rsc"]').first()).toBeAttached();

    // End result: the probe paints with the background color from its CSS module
    // (UseClientCssProbe.module.scss: background-color: rgb(212 250 236)).
    await expect(probe).toHaveCSS('background-color', 'rgb(212, 250, 236)');
  });
});
