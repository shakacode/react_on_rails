import { randomUUID } from 'crypto';
import { test as base, Response, expect, Request } from '@playwright/test';
import { createClient, RedisClientType } from 'redis';

type RedisClientFixture = {
  redisClient: RedisClientType;
};

type RedisRequestIdFixture = {
  redisRequestId: string;
  nonBlockingNavigateWithRequestId: (path: string) => Promise<Response | null>;
};

type PageFixture = {
  pagePath: string;
};

export type RedisReceiverControllerFixture = {
  sendRedisValue: (key: string, value: unknown) => Promise<void>;
  sendRedisItemValue: (itemIndex: number, value: unknown) => Promise<void>;
  endRedisStream: () => Promise<void>;
  matchPageSnapshot: (snapshotPath: string) => Promise<void>;
  waitForConsoleMessage: (msg: string) => Promise<void>;
  getNetworkRequests: (requestUrlPattern: RegExp) => Promise<Request[]>;
};

const redisControlledTest = base.extend<RedisRequestIdFixture, RedisClientFixture>({
  redisClient: [
    async ({}, use, workerInfo) => {
      console.log(`Creating Redis Client at Worker ${workerInfo.workerIndex}`);
      const url = process.env.REDIS_URL || 'redis://localhost:6379';
      const client = createClient({ url });
      await client.connect();
      await use(client as RedisClientType);
      await client.quit();
    },
    { scope: 'worker' },
  ],

  redisRequestId: async ({ redisClient }, use) => {
    const id = randomUUID();
    try {
      await use(id);
    } finally {
      // cleanup of the stream for this request
      await redisClient.del(`stream:${id}`);
    }
  },

  nonBlockingNavigateWithRequestId: async ({ redisRequestId, page }, use) => {
    await use((path) => {
      const requestIdParam = `request_id=${redisRequestId}`;
      const fullPath = path.includes('?') ? `${path}&${requestIdParam}` : `${path}?${requestIdParam}`;
      return page.goto(fullPath, { waitUntil: 'commit' });
    });
  },
});

const redisReceiverPageController = redisControlledTest.extend<RedisReceiverControllerFixture>({
  sendRedisValue: async ({ redisClient, redisRequestId }, use) => {
    await use(async (key, value) => {
      await redisClient.xAdd(`stream:${redisRequestId}`, '*', { [`:${key}`]: JSON.stringify(value) });
    });
  },
  sendRedisItemValue: async ({ sendRedisValue }, use) => {
    await use(async (itemIndex, value) => {
      await sendRedisValue(`Item${itemIndex}`, value);
    });
  },
  endRedisStream: async ({ redisClient, redisRequestId }, use) => {
    await use(async () => {
      await redisClient.xAdd(`stream:${redisRequestId}`, '*', { end: 'true' });
    });
  },
  matchPageSnapshot: async ({ page }, use) => {
    await use(async (snapshotPath) => {
      await expect(page.locator('.redis-receiver-container:visible')).toBeVisible();
      await expect(page.locator('.redis-receiver-container:visible').first()).toMatchAriaSnapshot({
        name: `${snapshotPath}.aria.yml`,
      });
    });
  },
  waitForConsoleMessage: async ({ page }, use) => {
    await use(async (msg) => {
      if ((await page.consoleMessages()).find((consoleMsg) => consoleMsg.text().includes(msg))) {
        return;
      }

      await page.waitForEvent('console', {
        predicate: (consoleMsg) => consoleMsg.text().includes(msg),
      });
    });
  },
  getNetworkRequests: async ({ page }, use) => {
    await use(async (requestUrlPattern) => {
      return (await page.requests()).filter((request) => request.url().match(requestUrlPattern));
    });
  },
});

const redisReceiverPageTest = redisReceiverPageController.extend<PageFixture>({
  pagePath: [
    async ({ nonBlockingNavigateWithRequestId }, use) => {
      const pagePath = '/redis_receiver_for_testing';
      await nonBlockingNavigateWithRequestId(pagePath);
      await use(pagePath);
    },
    { auto: true },
  ],
});

const asyncPropsAtRouterPageTest = redisReceiverPageController.extend<PageFixture>({
  pagePath: [
    async ({ nonBlockingNavigateWithRequestId }, use) => {
      const pagePath = '/server_router/async-props-component-for-testing';
      await nonBlockingNavigateWithRequestId(pagePath);
      await use(pagePath);
    },
    { auto: true },
  ],
});

const redisReceiverPageWithAsyncClientComponentTest = redisReceiverPageController.extend<PageFixture>({
  pagePath: [
    async ({ page, nonBlockingNavigateWithRequestId, sendRedisValue }, use) => {
      const pagePath = '/redis_receiver_for_testing?async_toggle_container=true';
      await nonBlockingNavigateWithRequestId(pagePath);

      await expect(page.getByText('Loading ToggleContainer')).toBeVisible();
      await expect(page.locator('.toggle-button')).not.toBeVisible();

      await sendRedisValue('ToggleContainer', 'anything');
      await expect(page.locator('.toggle-button')).toBeVisible();
      await use(pagePath);
    },
    { auto: true },
  ],
});

const redisReceiverInsideRouterPageTest = redisReceiverPageController.extend<PageFixture>({
  pagePath: [
    async ({ nonBlockingNavigateWithRequestId }, use) => {
      const pagePath = '/server_router/redis-receiver-for-testing';
      await nonBlockingNavigateWithRequestId(pagePath);
      await use(pagePath);
    },
    { auto: true },
  ],
});

const redisReceiverPageAfterNavigationTest = redisReceiverPageController.extend<PageFixture>({
  pagePath: [
    async ({ nonBlockingNavigateWithRequestId, page }, use) => {
      await nonBlockingNavigateWithRequestId('/server_router/simple-server-component');
      await expect(page.getByText('Post 1')).toBeVisible({ timeout: 3000 });
      await page.getByText('Redis Receiver For Testing').click();
      await use('/server_router/redis-receiver-for-testing');
    },
    { auto: true },
  ],
});

export {
  asyncPropsAtRouterPageTest,
  redisReceiverPageController,
  redisReceiverPageTest,
  redisReceiverInsideRouterPageTest,
  redisReceiverPageAfterNavigationTest,
  redisReceiverPageWithAsyncClientComponentTest,
};
