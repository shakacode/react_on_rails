import { test, expect } from '@playwright/test';
import { app } from '../../support/on-rails';

const cssModulesExamplePath = '/css_modules_images_fonts_example';
const cssModulesHeadingText = 'This should be open sans light green.';
const expectedStyledColor = 'rgb(0, 128, 0)';

async function delayCompiledJavaScript(page) {
  const delayedRequests = [];
  let releaseScripts;
  const releaseGate = new Promise((resolve) => {
    releaseScripts = resolve;
  });

  await page.route(/\/webpack\/test\/.*\.js(\?.*)?$/, async (route) => {
    delayedRequests.push(route.request().url());
    await releaseGate;
    await route.continue();
  });

  return {
    delayedRequests,
    releaseScripts,
  };
}

async function readCssModulesHeadingStyle(page) {
  const heading = page.getByRole('heading', { name: cssModulesHeadingText });
  await expect(heading).toBeVisible({ timeout: 0 });

  return heading.evaluate((element, styledColor) => {
    const style = window.getComputedStyle(element);

    return {
      className: element.className,
      color: style.color,
      fontFamily: style.fontFamily,
      hasFouc: style.color !== styledColor,
    };
  }, expectedStyledColor);
}

test.describe('FOUC regression coverage', () => {
  test.beforeEach(async () => {
    await app('clean');
  });

  test('detector flags a deliberately unstyled first paint', async ({ page }) => {
    await page.route(/\/webpack\/test\/.*\.css(\?.*)?$/, (route) =>
      route.fulfill({
        status: 200,
        contentType: 'text/css',
        body: '',
      }),
    );

    const { releaseScripts } = await delayCompiledJavaScript(page);

    try {
      await page.goto(cssModulesExamplePath, { waitUntil: 'commit' });

      await expect
        .poll(async () => readCssModulesHeadingStyle(page))
        .toMatchObject({
          hasFouc: true,
        });
    } finally {
      releaseScripts();
    }
  });

  test('server-rendered CSS module content is styled before generated React packs hydrate', async ({
    page,
  }) => {
    const { delayedRequests, releaseScripts } = await delayCompiledJavaScript(page);
    const stylesheetResponse = page.waitForResponse(
      (response) =>
        response.url().includes('/webpack/test/css/generated/CssModulesImagesFontsExample') &&
        response.url().endsWith('.css') &&
        response.status() === 200,
      { timeout: 15000 },
    );

    try {
      await page.goto(cssModulesExamplePath, { waitUntil: 'commit' });
      await stylesheetResponse;

      const beforeHydration = await readCssModulesHeadingStyle(page);

      expect(delayedRequests).not.toHaveLength(0);
      expect(beforeHydration).toMatchObject({
        color: expectedStyledColor,
        hasFouc: false,
      });
    } finally {
      releaseScripts();
    }

    await page.waitForLoadState('networkidle');

    await expect
      .poll(async () => readCssModulesHeadingStyle(page))
      .toMatchObject({
        color: expectedStyledColor,
        hasFouc: false,
      });
  });
});
