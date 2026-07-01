import { test, expect } from '@playwright/test';

test.describe('Typed Rails action example', () => {
  test('submits the dummy contact form through createRailsAction', async ({ page }) => {
    const responsePromise = page.waitForResponse(
      (response) => response.url().endsWith('/contact_messages') && response.request().method() === 'POST',
    );

    await page.goto('/typed_rails_action');

    await page.getByLabel('Name').fill('Ada Lovelace');
    await page.getByLabel('Email').fill('ada@example.com');
    await page.getByLabel('Message').fill('Please send more typed Rails actions.');
    await page.getByRole('button', { name: 'Send' }).click();

    const response = await responsePromise;
    expect(response.status()).toBe(201);
    await expect(page.locator('.success-message')).toContainText(
      'Thanks, Ada Lovelace! Your message has been received.',
    );
  });
});
