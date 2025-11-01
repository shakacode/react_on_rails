import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });

test('Redis client connects successfully', async () => {
  await redisClient.connect();
  expect(redisClient.isOpen).toBe(true);
  await redisClient.quit();
});

test('calls connect after quit', async () => {
  await redisClient.connect();
  expect(redisClient.isOpen).toBe(true);
  await redisClient.quit();

  await redisClient.connect();
  expect(redisClient.isOpen).toBe(true);
  await redisClient.quit();
});

test('calls quit before connect is resolved', async () => {
  const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  const connectPromise = client.connect();
  await client.quit();
  await connectPromise;
  expect(client.isOpen).toBe(false);
});

test('multiple connect calls', async () => {
  const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  const connectPromise1 = client.connect();
  const connectPromise2 = client.connect();
  await expect(connectPromise2).rejects.toThrow('Socket already opened');
  await expect(connectPromise1).resolves.toMatchObject({});
  expect(client.isOpen).toBe(true);
  await client.quit();
});
