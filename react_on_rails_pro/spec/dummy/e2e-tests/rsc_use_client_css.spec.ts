import { test, expect } from '@playwright/test';

// Regression test for issue #3211: CSS imported behind a `'use client'` boundary
// in a true RSC tree must be present in the server-rendered HTML before the
// boundary content that needs it. React 19 may serialize that as a hoisted
// precedence link or as an inline RSC stylesheet hint before the boundary; in
// either case the browser can load the stylesheet before painting the probe.
// Without the fix the stylesheet only loads as a side effect of the JS chunk
// evaluating, producing a flash of unstyled content (FOUC).
//
// `UseClientCssProbe` ('use client', imports a CSS module) is rendered by
// `RSCPostsPage` on the streaming RSC route below.
test.describe('RSC use-client CSS (#3211 FOUC fix)', () => {
  test('emits the use-client stylesheet before the SSR probe and styles the probe', async ({
    page,
    request,
  }) => {
    const response = await request.get('/rsc_posts_page_over_http');
    expect(response.ok()).toBe(true);
    const ssrHtml = await response.text();

    // No-FOUC guarantee: the server-rendered stylesheet link must appear before
    // the SSR probe that depends on it. Local and CI streams can differ between
    // our wrapper precedence and React's native RSC stylesheet hint.
    const stylesheetLinkMatch = ssrHtml.match(
      /<link(?=[^>]*\brel="stylesheet")(?=[^>]*\bdata-precedence="(?:ror-rsc|rsc-css)")(?=[^>]*\bhref="[^"]*\.css")[^>]*>/,
    );
    const stylesheetLinkIndex = stylesheetLinkMatch?.index ?? -1;
    const probeIndex = ssrHtml.indexOf('data-testid="rsc-css-probe"');

    expect(stylesheetLinkIndex).toBeGreaterThanOrEqual(0);
    expect(probeIndex).toBeGreaterThan(stylesheetLinkIndex);

    await page.goto('/rsc_posts_page_over_http', { waitUntil: 'commit' });

    const probe = page.getByTestId('rsc-css-probe');
    await expect(probe).toBeVisible();

    // The precedence-grouped stylesheet resource is present in the live document
    // (React keeps it as it manages the loaded stylesheet).
    await expect(
      page
        .locator(
          'link[rel="stylesheet"][data-precedence="ror-rsc"], link[rel="stylesheet"][data-precedence="rsc-css"]',
        )
        .first(),
    ).toBeAttached();

    // End result: the probe paints with the background color from its CSS module
    // (UseClientCssProbe.module.scss: background-color: rgb(212 250 236)).
    await expect(probe).toHaveCSS('background-color', 'rgb(212, 250, 236)');
  });
});
