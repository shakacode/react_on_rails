/**
 * Issue #3211 — RSC CSS FOUC regression trap.
 *
 * When a true RSC tree contains a `'use client'` boundary that imports CSS, React on Rails
 * Pro must hoist a `<link rel="stylesheet">` for the client component's CSS into `<head>`
 * via React 19's stylesheet API. With the bug, the only CSS-loading mechanism is
 * mini-css-extract-plugin's runtime, which inserts a `<link>` *as a side effect of the JS
 * chunk evaluating* — without a `data-precedence` attribute and several hundred ms after
 * first paint. This test pins the post-fix behavior:
 *
 *   1. A `<link rel="stylesheet" data-precedence>` for the client component's CSS module
 *      is present in `<head>` after the RSC payload is processed.
 *   2. The styled element has its expected computed background-color.
 */

import { test, expect } from '@playwright/test';

const COMPONENT_RENDER_TIMEOUT = 15_000;
const EXPECTED_BACKGROUND_COLOR = 'rgb(255, 0, 128)';

test.describe('RSC FOUC Demo (issue #3211)', () => {
  test('hoists stylesheet for use-client boundary into <head> with data-precedence', async ({ page }) => {
    await page.goto('/rsc_fouc_demo', { waitUntil: 'commit' });

    const card = page.getByTestId('styled-client-card');
    await expect(card).toBeVisible({ timeout: COMPONENT_RENDER_TIMEOUT });

    const linkInHead = page.locator('head link[rel="stylesheet"][data-precedence][href*="StyledClientCard"]');
    await expect(linkInHead).toHaveCount(1);
  });

  test('styled element has expected computed background-color', async ({ page }) => {
    await page.goto('/rsc_fouc_demo', { waitUntil: 'commit' });

    const card = page.getByTestId('styled-client-card');
    await expect(card).toBeVisible({ timeout: COMPONENT_RENDER_TIMEOUT });
    await expect(card).toHaveCSS('background-color', EXPECTED_BACKGROUND_COLOR);
  });
});
