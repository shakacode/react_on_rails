import { expect } from '@playwright/test';
import {
  redisReceiverPageTest,
  redisReceiverInsideRouterPageTest,
  redisReceiverPageAfterNavigationTest,
  redisReceiverPageWithAsyncClientComponentTest,
} from './fixture';

// Snapshot testing the best testing strategy for our use case
// Because we need to ensure that any transformation done on the HTML or RSC payload stream won't affect
//   - Order of fallback or components at the page
//   - Any update chunk won't affect previously rendered parts of the page
//   - Rendered component won't get back to its fallback component at any stage of the page
//   - Snapshot testing saves huge number of complex assertions
([
  ['RedisReceiver', redisReceiverPageTest],
  ['RedisReceiver inside router page', redisReceiverInsideRouterPageTest],
  ['RedisReceiver inside router after navigation', redisReceiverPageAfterNavigationTest],
  ['RedisReceiver with Async Toggle Container Client Component', redisReceiverPageWithAsyncClientComponentTest],
] as const).forEach(([pageName, test]) => {
  test(`incremental rendering of page: ${pageName}`, async ({ matchPageSnapshot, sendRedisItemValue }) => {
    await matchPageSnapshot('stage0');

    sendRedisItemValue(0, 'Incremental Value1');
    await matchPageSnapshot('stage1');

    sendRedisItemValue(3, 'Incremental Value4');
    await matchPageSnapshot('stage2');

    sendRedisItemValue(1, 'Incremental Value2');
    await matchPageSnapshot('stage3');

    sendRedisItemValue(2, 'Incremental Value3');
    await matchPageSnapshot('stage4');

    sendRedisItemValue(4, 'Incremental Value5');
    await matchPageSnapshot('stage5');
  });

  test(`early hydration of page: ${pageName}`, async ({ page, waitForConsoleMessage, matchPageSnapshot, sendRedisItemValue }) => {
    waitForConsoleMessage('ToggleContainer with title');

    await page.click('.toggle-button');
    await expect(page.getByText(/Waiting for the key "Item\d"/)).not.toBeVisible();

    await page.click('.toggle-button');
    const fallbackElements = page.getByText(/Waiting for the key "Item\d"/);
    await expect(fallbackElements).toHaveCount(5);
    for (const el of await fallbackElements.all()) {
      await expect(el).toBeVisible();
    }
    await matchPageSnapshot('stage0');

    sendRedisItemValue(0, 'Incremental Value1');
    await matchPageSnapshot('stage1');

    sendRedisItemValue(3, 'Incremental Value4');
    await matchPageSnapshot('stage2');

    sendRedisItemValue(1, 'Incremental Value2');
    await matchPageSnapshot('stage3');

    sendRedisItemValue(2, 'Incremental Value3');
    await matchPageSnapshot('stage4');

    sendRedisItemValue(4, 'Incremental Value5');
    await matchPageSnapshot('stage5');
  })
})
