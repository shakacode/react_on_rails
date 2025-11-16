import { createClient, RedisClientType } from 'redis';

const REDIS_LISTENER_TIMEOUT = 15000; // 15 seconds

/**
 * Redis xRead result message structure
 */
interface RedisStreamMessage {
  id: string;
  message: Record<string, string>;
}

/**
 * Redis xRead result structure
 */
interface RedisStreamResult {
  name: string;
  messages: RedisStreamMessage[];
}

/**
 * Listener interface
 */
interface RequestListener {
  getValue: (key: string) => Promise<unknown>;
  destroy: () => void;
}

/**
 * Listens to a Redis stream for data based on a requestId
 * @param requestId - The stream key to listen on
 * @returns An object with a getValue function to get values by key and a close function
 */
export function listenToRequestData(requestId: string): RequestListener {
  // State - all local to this listener instance
  const valuesMap = new Map<string, unknown>();
  const valuePromises = new Map<string, Promise<unknown>>();
  const streamKey = `stream:${requestId}`;
  let listenToStreamPromise: Promise<void> | null = null;
  let lastId = '0'; // Start from beginning of stream
  // True when streams ends and the connection is closed
  let isClosed = false;
  // True when user explictly calls destroy, it makes any call to getValue throw immediately
  let isDestroyed = false;

  // Redis client
  const url = process.env.REDIS_URL || 'redis://localhost:6379';
  const redisClient: RedisClientType = createClient({ url });
  let isConnected = false;

  /**
   * Closes the Redis connection and rejects all pending promises
   */
  function close() {
    if (isClosed) return;
    isClosed = true;

    // Close client - this will cause xRead to throw, which rejects pending promises
    try {
      redisClient.destroy();
    } finally {
      isConnected = false;
    }
  }

  /**
   * Listens to the stream for the next batch of messages
   * Blocks until at least one message arrives
   * Multiple concurrent calls return the same promise
   */
  function listenToStream(): Promise<void> {
    // Return existing promise if already listening
    if (listenToStreamPromise) {
      return listenToStreamPromise;
    }

    // Create new listening promise
    const promise = (async (): Promise<void> => {
      if (isClosed) {
        throw new Error('Redis Connection is closed');
      }

      // redisClient.connect(); is called only here
      // And `listenToStream` runs only one promise at a time, so no fear of race condition
      if (!isConnected) {
        await redisClient.connect();
        await redisClient.expire(streamKey, REDIS_LISTENER_TIMEOUT / 1000); // Set TTL to avoid stale streams
        isConnected = true;
      }

      // xRead blocks indefinitely until message arrives
      const result = (await redisClient.xRead(
        { key: streamKey, id: lastId },
        { BLOCK: 0 }, // Block indefinitely
      )) as RedisStreamResult[] | null;

      if (!result || result.length === 0) {
        return;
      }

      const [{ messages }] = result;

      let receivedEndMessage = false;
      for (const { id, message } of messages) {
        lastId = id;

        // Check for end message
        if ('end' in message) {
          receivedEndMessage = true;
        }

        // Process key-value pairs
        Object.entries(message).forEach(([key, value]) => {
          const normalizedKey = key.startsWith(':') ? key.substring(1) : key;
          const parsedValue = JSON.parse(value) as unknown;
          valuesMap.set(normalizedKey, parsedValue);
        });
      }

      // If end message received, close the connection
      if (receivedEndMessage) {
        close();
      }
    })();

    listenToStreamPromise = promise.finally(() => {
      // Reset so next call creates new promise
      listenToStreamPromise = null;
    });

    return listenToStreamPromise;
  }

  /**
   * Gets a value for a specific key from the Redis stream
   * Returns the same promise for multiple calls with the same key
   * @param key - The key to look for in the stream
   * @returns A promise that resolves when the key is found
   */
  async function getValue(key: string): Promise<unknown> {
    if (isDestroyed) {
      throw new Error(`Can't get value for key "${key}" - Redis Connection is destroyed`);
    }

    // Return existing promise if already requested
    const valuePromise = valuePromises.get(key);
    if (valuePromise) {
      return valuePromise;
    }

    // Create new promise that loops until value is found
    const promise = (async () => {
      try {
        // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
        while (true) {
          // Check if value already available
          if (valuesMap.has(key)) {
            return valuesMap.get(key);
          }

          // Wait for next batch of messages
          // eslint-disable-next-line no-await-in-loop
          await listenToStream();
        }
      } catch (error) {
        throw new Error(
          `Error getting value for key "${key}": ${(error as Error).message}, stack: ${(error as Error).stack}`,
        );
      }
    })();

    valuePromises.set(key, promise);
    return promise;
  }

  let globalTimeout: NodeJS.Timeout;
  /**
   * Destroys the listener, closing the connection and preventing further getValue calls
   */
  function destroy() {
    if (isDestroyed) return;
    isDestroyed = true;

    // Clear global timeout
    clearTimeout(globalTimeout);

    close();
  }

  // Global timeout - destroys listener after 15 seconds
  globalTimeout = setTimeout(() => {
    destroy();
  }, REDIS_LISTENER_TIMEOUT);

  return { getValue, destroy };
}
