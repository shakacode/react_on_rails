import { test, expect } from '@playwright/test';

test.describe('React on Rails Basic Components', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should render server-side rendered React component', async ({ page }) => {
    // Check for server-rendered Redux component
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();

    // Verify it has content
    const heading = reduxApp.locator('h3');
    await expect(heading).toContainText('Redux');
  });

  test('should render React component without Redux', async ({ page }) => {
    // Check for HelloWorld component
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    await expect(helloWorld).toBeVisible();

    // Verify it has content
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Hello');
  });

  test('should handle client-side interactivity', async ({ page }) => {
    // Find the HelloWorld component
    const helloWorld = page.locator('#HelloWorld-react-component-1');

    // Find the input field and type a new name
    const input = helloWorld.locator('input');
    await input.clear();
    await input.fill('Playwright Test');

    // Verify the heading updates
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Playwright Test');
  });

  test('should handle Redux state changes', async ({ page }) => {
    // Find the Redux app component
    const reduxApp = page.locator('#ReduxApp-react-component-0');

    // Interact with the input
    const input = reduxApp.locator('input');
    await input.clear();
    await input.fill('Redux with Playwright');

    // Verify the state change is reflected
    const heading = reduxApp.locator('h3');
    await expect(heading).toContainText('Redux with Playwright');
  });
});

test.describe('React on Rails Navigation', () => {
  test('should navigate to different example pages', async ({ page }) => {
    await page.goto('/');

    // Check if we can navigate to other pages (if available)
    const pageTitle = await page.title();
    expect(pageTitle).toBeTruthy();

    // Verify the React on Rails meta tag is present
    const metaTag = await page.locator('meta[name="react-on-rails-version"]').getAttribute('content');
    expect(metaTag).toBeTruthy();
  });
});

test.describe('React on Rails Server Rendering', () => {
  test('should have server-rendered content in initial HTML', async ({ page }) => {
    // Disable JavaScript to verify server rendering
    await page.route('**/*.js', (route) => route.abort());
    await page.goto('/');

    // Check that server-rendered components are visible even without JS
    const reduxApp = page.locator('#ReduxApp-react-component-0');
    await expect(reduxApp).toBeVisible();

    // The content should be present
    const heading = reduxApp.locator('h3');
    await expect(heading).toBeVisible();
  });

  test('should properly hydrate server-rendered components', async ({ page }) => {
    await page.goto('/');

    // Wait for hydration
    await page.waitForLoadState('networkidle');

    // Check that components are interactive after hydration
    const helloWorld = page.locator('#HelloWorld-react-component-1');
    const input = helloWorld.locator('input');

    // Should be able to interact with the input
    await expect(input).toBeEnabled();
    await input.fill('Hydrated Component');

    // Check the update works
    const heading = helloWorld.locator('h3');
    await expect(heading).toContainText('Hydrated Component');
  });
});
