import { test, expect, Page } from '@playwright/test';

// Expected background colors for each probe component
const EXPECTED_COLORS = {
  // Client probes (used in both SSR and RSC pages)
  'css-probe-plain': 'rgb(255, 228, 196)',
  'css-probe-modules': 'rgb(173, 216, 230)',
  'css-probe-scss': 'rgb(255, 182, 193)',
  'css-probe-tailwind': 'rgb(254, 243, 199)',
  'css-probe-inline': 'rgb(200, 230, 201)',
  'css-probe-styled-components': 'rgb(255, 218, 185)',
  'css-probe-emotion': 'rgb(176, 224, 230)',
  // Server probes (RSC page only)
  'css-probe-server-modules': 'rgb(221, 214, 254)',
  'css-probe-server-tailwind': 'rgb(254, 202, 202)',
  'css-probe-server-inline': 'rgb(200, 200, 230)',
};

const CLIENT_PROBES = [
  'css-probe-plain',
  'css-probe-modules',
  'css-probe-scss',
  'css-probe-tailwind',
  'css-probe-inline',
  'css-probe-styled-components',
  'css-probe-emotion',
] as const;

const SERVER_PROBES = [
  'css-probe-server-modules',
  'css-probe-server-tailwind',
  'css-probe-server-inline',
] as const;

async function verifyProbeStyle(page: Page, testId: string) {
  const probe = page.getByTestId(testId);
  await expect(probe).toBeVisible();
  await expect(probe).toHaveCSS('background-color', EXPECTED_COLORS[testId]);
}

test.describe('CSS Showcase — Traditional SSR', () => {
  test('all CSS approaches render with correct styles', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));

    await page.goto('/css_showcase_ssr');
    await expect(page.getByTestId('css-showcase-ssr')).toBeVisible();

    for (const testId of CLIENT_PROBES) {
      await verifyProbeStyle(page, testId);
    }

    expect(errors).toHaveLength(0);
  });

  test('no hydration mismatch warnings', async ({ page }) => {
    const consoleMessages: string[] = [];
    page.on('console', (msg) => {
      if (msg.text().includes('hydrat') || msg.text().includes('mismatch')) {
        consoleMessages.push(msg.text());
      }
    });

    await page.goto('/css_showcase_ssr');
    await expect(page.getByTestId('css-showcase-ssr')).toBeVisible();

    // Wait a bit for any delayed hydration warnings
    await page.waitForTimeout(1000);
    expect(consoleMessages).toHaveLength(0);
  });
});

test.describe('CSS Showcase — RSC', () => {
  test('server component CSS approaches render correctly', async ({ page }) => {
    await page.goto('/css_showcase_rsc', { waitUntil: 'commit' });
    await expect(page.getByTestId('css-showcase-rsc')).toBeVisible();

    for (const testId of SERVER_PROBES) {
      await verifyProbeStyle(page, testId);
    }
  });

  test('client component CSS approaches render correctly in RSC tree', async ({ page }) => {
    await page.goto('/css_showcase_rsc', { waitUntil: 'commit' });
    await expect(page.getByTestId('css-showcase-rsc')).toBeVisible();

    for (const testId of CLIENT_PROBES) {
      await verifyProbeStyle(page, testId);
    }
  });

  test('SSR HTML contains styled content before JS execution', async ({ request }) => {
    const response = await request.get('/css_showcase_rsc');
    expect(response.ok()).toBe(true);
    const html = await response.text();

    // Server component CSS Modules: class names should be in SSR HTML
    expect(html).toContain('data-testid="css-probe-server-modules"');
    // Server component inline styles: style attribute should be in SSR HTML
    expect(html).toContain('data-testid="css-probe-server-inline"');
    // Server component Tailwind: class names should be in SSR HTML
    expect(html).toContain('data-testid="css-probe-server-tailwind"');
    // Client probes should also appear in SSR HTML (streamed)
    expect(html).toContain('data-testid="css-probe-modules"');
  });

  test('no hydration or console errors', async ({ page }) => {
    const errors: string[] = [];
    const hydrationWarnings: string[] = [];

    page.on('pageerror', (err) => errors.push(err.message));
    page.on('console', (msg) => {
      if (msg.text().includes('hydrat') || msg.text().includes('mismatch')) {
        hydrationWarnings.push(msg.text());
      }
    });

    await page.goto('/css_showcase_rsc', { waitUntil: 'commit' });
    await expect(page.getByTestId('css-showcase-rsc')).toBeVisible();

    // Wait for hydration to complete
    await page.waitForTimeout(2000);

    expect(errors).toHaveLength(0);
    expect(hydrationWarnings).toHaveLength(0);
  });
});
