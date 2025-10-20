import { randomUUID } from 'crypto';
import { test as base, Response, expect } from '@playwright/test';
import { createClient, RedisClientType } from 'redis';

type RedisClientFixture = {
  redisClient: RedisClientType;
};

type RedisRequestIdFixture = {
  redisRequestId: string;
  nonBlockingNavigateWithRequestId: (path: string) => Promise<Response | null>
}

type RedisReceiverPageFixture = {
  pagePath: string;
}

export type RedisReceiverControllerFixture = {
  sendRedisValue: (key: string, value: unknown) => Promise<void>;
  sendRedisItemValue: (itemIndex: Number, value: unknown) => Promise<void>;
  matchPageSnapshot: (snapshotPath: string) => Promise<void>;
}

const redisControlledTest = base.extend<RedisRequestIdFixture, RedisClientFixture>({
  redisClient: [async ({}, use, workerInfo) => {
    console.log(`Creating Redis Client at Worker ${workerInfo.workerIndex}`)
    const url = process.env.REDIS_URL || 'redis://localhost:6379';
    const client = createClient({ url });
    await client.connect();
    await use(client as RedisClientType);
    await client.close();
  }, { scope: 'worker' }],

  redisRequestId: async ({}, use) => {
    await use(randomUUID());
  },

  nonBlockingNavigateWithRequestId: async ({ redisRequestId, page }, use) => {
    await use((path) => page.goto(`${path}?request_id=${redisRequestId}`, { waitUntil: "commit" }))
  },
});

const redisReceiverPageController = redisControlledTest.extend<RedisReceiverControllerFixture>({
  sendRedisValue: async({ redisClient, redisRequestId }, use) => {
    await use(async(key, value) => {
      await redisClient.xAdd(`stream:${redisRequestId}`, '*', { [`:${key}`]: JSON.stringify(value) });
    })
  },
  sendRedisItemValue: async({ sendRedisValue }, use) => {
    await use(async(itemIndex, value) => {
      await sendRedisValue(`Item${itemIndex}`, value);
    })
  },
  matchPageSnapshot: async({ page }, use) => {
    await use(async(snapshotPath) => {
      await expect(page.locator('.redis-receiver-container:visible')).toBeVisible();
      await expect(page.locator('.redis-receiver-container:visible').first()).toMatchAriaSnapshot({ name: `${snapshotPath}.aria.yml` });
    })
  },
})

const redisReceiverPageTest = redisReceiverPageController.extend<RedisReceiverPageFixture>({
  pagePath: [async({ nonBlockingNavigateWithRequestId }, use) => {
    const pagePath = '/redis_receiver_for_testing';
    await nonBlockingNavigateWithRequestId(pagePath);
    await use(pagePath);
  }, { auto: true }]
})

const redisReceiverInsideRouterPageTest = redisReceiverPageController.extend<RedisReceiverPageFixture>({
  pagePath: [async({ nonBlockingNavigateWithRequestId }, use) => {
    const pagePath = '/server_router/redis-receiver-for-testing';
    await nonBlockingNavigateWithRequestId(pagePath);
    await use(pagePath);
  }, { auto: true }]
})

const redisReceiverPageAfterNavigationTest = redisReceiverPageController.extend<RedisReceiverPageFixture>({
  pagePath: [async({ nonBlockingNavigateWithRequestId, page }, use) => {
    await nonBlockingNavigateWithRequestId('/server_router/simple-server-component');
    await expect(page.getByText("Post 1")).toBeVisible({ timeout: 3000 });
    await page.getByText("Redis Receiver For Testing").click();
    await use('/server_router/redis-receiver-for-testing');
  }, { auto: true }]
})

export { 
  redisControlledTest,
  redisReceiverPageTest,
  redisReceiverInsideRouterPageTest,
  redisReceiverPageAfterNavigationTest,
 };
