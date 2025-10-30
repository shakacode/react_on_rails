import { expect } from '@playwright/test';
import {
  redisReceiverPageController,
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
(
  [
    ['RedisReceiver', redisReceiverPageTest],
    ['RedisReceiver inside router page', redisReceiverInsideRouterPageTest],
    ['RedisReceiver inside router after navigation', redisReceiverPageAfterNavigationTest],
    [
      'RedisReceiver with Async Toggle Container Client Component',
      redisReceiverPageWithAsyncClientComponentTest,
    ],
  ] as const
).forEach(([pageName, test]) => {
  test(`incremental rendering of page: ${pageName}`, async ({ matchPageSnapshot, sendRedisItemValue }) => {
    await matchPageSnapshot('stage0');

    await sendRedisItemValue(0, 'Incremental Value1');
    await matchPageSnapshot('stage1');

    await sendRedisItemValue(3, 'Incremental Value4');
    await matchPageSnapshot('stage2');

    await sendRedisItemValue(1, 'Incremental Value2');
    await matchPageSnapshot('stage3');

    await sendRedisItemValue(2, 'Incremental Value3');
    await matchPageSnapshot('stage4');

    await sendRedisItemValue(4, 'Incremental Value5');
    await matchPageSnapshot('stage5');
  });

  test(`early hydration of page: ${pageName}`, async ({
    page,
    waitForConsoleMessage,
    matchPageSnapshot,
    sendRedisItemValue,
  }) => {
    await waitForConsoleMessage('ToggleContainer with title');

    await page.click('.toggle-button');
    await expect(page.getByText(/Waiting for the key "Item\d"/)).not.toBeVisible();

    await page.click('.toggle-button');
    const fallbackElements = page.getByText(/Waiting for the key "Item\d"/);
    await expect(fallbackElements).toHaveCount(5);
    await Promise.all((await fallbackElements.all()).map((el) => expect(el).toBeVisible()));
    await matchPageSnapshot('stage0');

    await sendRedisItemValue(0, 'Incremental Value1');
    await matchPageSnapshot('stage1');

    await sendRedisItemValue(3, 'Incremental Value4');
    await matchPageSnapshot('stage2');

    await sendRedisItemValue(1, 'Incremental Value2');
    await matchPageSnapshot('stage3');

    await sendRedisItemValue(2, 'Incremental Value3');
    await matchPageSnapshot('stage4');

    await sendRedisItemValue(4, 'Incremental Value5');
    await matchPageSnapshot('stage5');
  });
});

redisReceiverInsideRouterPageTest(
  'no RSC payload request is made when the page is server side rendered',
  async ({ getNetworkRequests }) => {
    expect(await getNetworkRequests(/rsc_payload/)).toHaveLength(0);
  },
);

redisReceiverPageAfterNavigationTest(
  'RSC payload request is made on navigation',
  async ({ getNetworkRequests }) => {
    expect(await getNetworkRequests(/rsc_payload/)).toHaveLength(1);
  },
);

redisReceiverPageController(
  'client side rendered router fetches RSC payload',
  async ({ page, getNetworkRequests }) => {
    await page.goto('/server_router_client_render/simple-server-component');

    await expect(page.getByText('Post 1')).toBeVisible();
    await expect(page.getByText('Toggle')).toBeVisible();
    expect(await getNetworkRequests(/rsc_payload/)).toHaveLength(1);
  },
);
