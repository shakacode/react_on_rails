import { test, expect } from '@playwright/test';

const CSS_PROBE_PATH = '/rsc_posts_page_over_http?posts_count=0';

// Regression test for issue #3211: CSS imported behind a `'use client'` boundary
// in a true RSC tree must be preloaded through React's stylesheet precedence
// stream bootstrap, so the browser waits for it before revealing the boundary.
// Without the fix the stylesheet only loads as a side effect of the JS chunk
// evaluating, producing a flash of unstyled content (FOUC).
//
// `UseClientCssProbe` ('use client', imports a CSS module) is rendered by
// `RSCPostsPage` on the streaming RSC route below.
test.describe('RSC use-client CSS (#3211 FOUC fix)', () => {
  test('preloads the use-client stylesheet and styles the probe', async ({ page, request }) => {
    const response = await request.get(CSS_PROBE_PATH);
    expect(response.ok()).toBe(true);
    const ssrHtml = await response.text();

    // No-FOUC guarantee: the stream includes CSS preloads plus React's reveal
    // bootstrap for the precedence group, so the browser waits on the stylesheet
    // before revealing the streamed boundary.
    expect(ssrHtml).toMatch(
      /<link(?=[^>]*\brel="preload")(?=[^>]*\bas="style")(?=[^>]*\bhref="[^"]*\.css")[^>]*>/,
    );
    // React serializes the precedence reveal as a ["<css href>","ror-rsc"] tuple in
    // its bootstrap stream. This tracks that internal serialization format and may
    // need updating across React minor versions.
    expect(ssrHtml).toMatch(/\[\s*"[^"]*\.css"\s*,\s*"ror-rsc"\s*\]/);

    // The probe is rendered in isolation here: `posts_count=0` makes `Posts` return
    // null (see Posts.jsx), so the FOUC fix is exercised without depending on the
    // posts data fetch. Pin that contract so a future default/guard change can't
    // silently re-render posts on this probe route. `placehold.co` is each post's
    // thumbnail (Post.jsx) and `ssrHtml` is the full stream, so this is timing-safe.
    expect(ssrHtml).not.toContain('placehold.co');

    await page.goto(CSS_PROBE_PATH, { waitUntil: 'commit' });

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
