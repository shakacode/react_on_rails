// This test in only for documenting Redis client usage

import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });

interface RedisStreamMessage {
  id: string;
  message: Record<string, string>;
}
interface RedisStreamResult {
  name: string;
  messages: RedisStreamMessage[];
}

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

test('write to stream and read back', async () => {
  const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  await client.connect();

  const streamKey = 'test-stream';
  await client.del(streamKey);
  const messageId = await client.xAdd(streamKey, '*', { field1: 'value1' });

  const result = (await client.xRead({ key: streamKey, id: '0-0' }, { COUNT: 1, BLOCK: 2000 })) as
    | RedisStreamResult[]
    | null;
  expect(result).not.toBeNull();
  expect(result).toBeDefined();

  const [stream] = result!;
  expect(stream).toBeDefined();
  expect(stream?.messages.length).toBe(1);
  const [message] = stream!.messages;
  expect(message!.id).toBe(messageId);
  expect(message!.message).toEqual({ field1: 'value1' });

  await client.quit();
});

test('quit while reading from stream', async () => {
  const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  await client.connect();

  const streamKey = 'test-stream-quit';

  const readPromise = client.xRead({ key: streamKey, id: '$' }, { BLOCK: 0 });

  // Wait a moment to ensure xRead is blocking
  await new Promise((resolve) => {
    setTimeout(resolve, 500);
  });

  client.destroy();

  await expect(readPromise).rejects.toThrow();
});

it('expire sets TTL on stream', async () => {
  const client = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
  await client.connect();

  const streamKey = 'test-stream-expire';
  await client.del(streamKey);
  await client.xAdd(streamKey, '*', { field1: 'value1' });

  const expireResult = await client.expire(streamKey, 1); // 1 second
  expect(expireResult).toBe(1); // 1 means the key existed and TTL was set

  const ttl1 = await client.ttl(streamKey);
  expect(ttl1).toBeLessThanOrEqual(1);
  expect(ttl1).toBeGreaterThan(0);

  const existsBeforeTimeout = await client.exists(streamKey);
  expect(existsBeforeTimeout).toBe(1); // Key should exist before timeout

  // Wait for 1.1 seconds
  await new Promise((resolve) => {
    setTimeout(resolve, 1100);
  });

  const existsAfterTimeout = await client.exists(streamKey);
  expect(existsAfterTimeout).toBe(0); // Key should have expired

  await client.quit();
});
