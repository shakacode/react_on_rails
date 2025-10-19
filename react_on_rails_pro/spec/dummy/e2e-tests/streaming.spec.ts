import { randomUUID } from 'crypto';
import { test, expect, Page } from '@playwright/test';
import { createClient } from 'redis';

const createRedisClient = async () => {
  const url = process.env.REDIS_URL || 'redis://localhost:6379';
  const client = createClient({ url });
  await client.connect();
  return client;
}

const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

const assertPageState = async(page: Page, sentValues: Number[]) => {
  const nonSentValues = [1,2,3,4,5].filter(v => !sentValues.includes(v));

  await Promise.all(sentValues.map(async (v) => {
    await expect(page.getByText(`Value of "Item${v}": Value${v}`)).toBeVisible();
    await expect(page.getByText(`Waiting for the key "Item${v}"`)).not.toBeVisible();
  }));

  await Promise.all(nonSentValues.map(async (v) => {
    await expect(page.getByText(`Value of "Item${v}": Value${v}`)).not.toBeVisible()
    await expect(page.getByText(`Waiting for the key "Item${v}"`)).toBeVisible()
  }));
}

test('incrementally render RedisReciever page', async ({ page }) => {
  const requestId = randomUUID();
  await page.goto(`http://localhost:3000/redis_receiver_for_testing?request_id=${requestId}`, { waitUntil: "commit" });

  const sentValues: Number[] = [];
  await assertPageState(page, sentValues);

  const redisClient = await createRedisClient();
  redisClient.xAdd(`stream:${requestId}`, '*', { ':Item1': JSON.stringify('Value1') });
  sentValues.push(1);
  await assertPageState(page, sentValues);

  redisClient.xAdd(`stream:${requestId}`, '*', { ':Item4': JSON.stringify('Value4') });
  sentValues.push(4);
  await assertPageState(page, sentValues);

  redisClient.xAdd(`stream:${requestId}`, '*', { ':Item2': JSON.stringify('Value2') });
  sentValues.push(2);
  await assertPageState(page, sentValues);

  redisClient.xAdd(`stream:${requestId}`, '*', { ':Item3': JSON.stringify('Value3') });
  sentValues.push(3);
  await assertPageState(page, sentValues);
});
