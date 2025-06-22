import { createClient, RedisClientType } from 'redis';

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
  close: () => Promise<void>;
}

interface PendingPromise {
  promise: Promise<unknown>;
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
  timer: NodeJS.Timeout;
  resolved?: boolean;
}

// Shared Redis client
let sharedRedisClient: RedisClientType | null = null;
let isClientConnected = false;

// Store active listeners by requestId
const activeListeners: Record<string, RequestListener | undefined> = {};

// Store pending promises
const pendingPromises: Record<string, PendingPromise | undefined> = {};

/**
 * Gets or creates the shared Redis client
 */
async function getRedisClient() {
  if (!sharedRedisClient) {
    const url = process.env.REDIS_URL || 'redis://localhost:6379';
    sharedRedisClient = createClient({ url });
  }

  if (!isClientConnected) {
    await sharedRedisClient.connect();
    isClientConnected = true;
  }

  return sharedRedisClient;
}

/**
 * Closes the shared Redis client
 */
async function closeRedisClient() {
  if (sharedRedisClient && isClientConnected) {
    await sharedRedisClient.quit();
    isClientConnected = false;
  }
}

/**
 * Listens to a Redis stream for data based on a requestId
 * @param requestId - The stream key to listen on
 * @returns An object with a getValue function to get values by key
 */
export function listenToRequestData(requestId: string): RequestListener {
  // If a listener for this requestId already exists, return it
  const existingListener = activeListeners[requestId];
  if (existingListener) {
    return existingListener;
  }

  const receivedKeys: string[] = [];

  // Stream key for this request
  const streamKey = `stream:${requestId}`;

  // IDs of messages that need to be deleted
  const messagesToDelete: string[] = [];

  // Track if this listener is active
  let isActive = true;
  // Track if we've received the end message
  let isEnded = false;

  /**
   * Process a message from the Redis stream
   */
  function processMessage(message: Record<string, string>, messageId: string) {
    // Add message to delete queue
    messagesToDelete.push(messageId);

    // Check for end message
    if ('end' in message) {
      isEnded = true;

      // Reject any pending promises that haven't been resolved yet
      Object.entries(pendingPromises).forEach(([key, pendingPromise]) => {
        if (pendingPromise && !pendingPromise.resolved) {
          clearTimeout(pendingPromise.timer);
          pendingPromise.reject(new Error(`Key ${key} not found before stream ended`));
          pendingPromises[key] = undefined;
        }
      });

      return;
    }

    // Process each key-value pair in the message
    Object.entries(message).forEach(([key, value]) => {
      const parsedValue = JSON.parse(value) as unknown;

      // Remove colon prefix if it exists
      const normalizedKey = key.startsWith(':') ? key.substring(1) : key;
      receivedKeys.push(normalizedKey);

      // Resolve any pending promises for this key
      const pendingPromise = pendingPromises[normalizedKey];
      if (pendingPromise) {
        clearTimeout(pendingPromise.timer);
        pendingPromise.resolve(parsedValue);
        pendingPromise.resolved = true; // Mark as resolved
      } else {
        pendingPromises[normalizedKey] = {
          promise: Promise.resolve(parsedValue),
          resolve: () => {},
          reject: () => {},
          timer: setTimeout(() => {}, 0),
          resolved: true, // Mark as resolved immediately
        };
      }
    });
  }

  /**
   * Delete processed messages from the stream
   */
  async function deleteProcessedMessages() {
    if (messagesToDelete.length === 0 || !isActive) {
      return;
    }

    try {
      const client = await getRedisClient();
      await client.xDel(streamKey, messagesToDelete);
      messagesToDelete.length = 0; // Clear the array
    } catch (error) {
      console.error('Error deleting messages from stream:', error);
    }
  }

  /**
   * Check for existing messages in the stream
   */
  async function checkExistingMessages() {
    if (!isActive) {
      return;
    }

    try {
      const client = await getRedisClient();

      // Read all messages from the beginning of the stream
      const results = (await client.xRead({ key: streamKey, id: '0' }, { COUNT: 100 })) as
        | RedisStreamResult[]
        | null;

      if (results && Array.isArray(results) && results.length > 0) {
        const [{ messages }] = results;

        // Process each message
        for (const { id, message } of messages) {
          processMessage(message, id);
        }

        // Delete processed messages
        await deleteProcessedMessages();
      }
    } catch (error) {
      console.error('Error checking existing messages:', error);
    }
  }

  /**
   * Setup a listener for new messages in the stream
   */
  async function setupStreamListener() {
    if (!isActive) {
      return;
    }

    try {
      const client = await getRedisClient();

      // Use $ as the ID to read only new messages
      let lastId = '$';

      // Start reading from the stream
      const readStream = async () => {
        if (!isActive || isEnded) {
          return;
        }

        try {
          const results = (await client.xRead(
            { key: streamKey, id: lastId },
            { COUNT: 100, BLOCK: 1000 },
          )) as RedisStreamResult[] | null;

          if (results && Array.isArray(results) && results.length > 0) {
            const [{ messages }] = results;

            // Process each message from the stream
            for (const { id, message } of messages) {
              lastId = id; // Update the last ID for subsequent reads
              processMessage(message, id);
            }

            // Delete processed messages
            await deleteProcessedMessages();
          }
        } catch (error) {
          console.error('Error reading from stream:', error);
        } finally {
          void readStream();
        }
      };

      void readStream();
    } catch (error) {
      console.error('Error setting up stream listener:', error);
    }
  }

  // Start listening to existing and new messages immediately
  (async () => {
    try {
      await checkExistingMessages();
      await setupStreamListener();
    } catch (error) {
      console.error('Error initializing Redis listener:', error);
    }
  })().catch((error: unknown) => {
    console.error('Error initializing Redis listener:', error);
  });

  // Create the listener object
  const listener: RequestListener = {
    /**
     * Gets a value for a specific key from the Redis stream
     * @param key - The key to look for in the stream
     * @returns A promise that resolves when the key is found
     */
    getValue: async (key: string) => {
      // If we already have a promise for this key, return it
      const existingPromise = pendingPromises[key];
      if (existingPromise) {
        return existingPromise.promise;
      }

      // If we've received the end message and don't have this key, reject immediately
      if (isEnded) {
        return Promise.reject(new Error(`Key ${key} not available, stream has ended`));
      }

      // Create a new promise for this key
      let resolvePromise: ((value: unknown) => void) | undefined;
      let rejectPromise: ((reason: unknown) => void) | undefined;

      const promise = new Promise<unknown>((resolve, reject) => {
        resolvePromise = resolve;
        rejectPromise = reject;
      });

      // Create a timeout that will reject the promise after 8 seconds
      const timer = setTimeout(() => {
        const pendingPromise = pendingPromises[key];
        if (pendingPromise) {
          pendingPromise.reject(
            new Error(`Timeout waiting for key: ${key}, available keys: ${receivedKeys.join(', ')}`),
          );
          // Keep the pending promise in the dictionary with the error state
        }
      }, 8000);

      // Store the promise and its controllers
      if (resolvePromise && rejectPromise) {
        pendingPromises[key] = {
          promise,
          resolve: resolvePromise,
          reject: rejectPromise,
          timer,
          resolved: false, // Mark as not resolved initially
        };
      }

      return promise;
    },

    /**
     * Closes the Redis client connection
     */
    close: async () => {
      isActive = false;

      // Delete this listener from active listeners
      activeListeners[requestId] = undefined;

      // Reject any pending promises
      Object.entries(pendingPromises).forEach(([key, pendingPromise]) => {
        if (pendingPromise) {
          clearTimeout(pendingPromise.timer);
          pendingPromise.reject(new Error('Redis connection closed'));
          pendingPromises[key] = undefined;
        }
      });

      // Only close the Redis client if no other listeners are active
      const hasActiveListeners = Object.values(activeListeners).some(Boolean);
      if (!hasActiveListeners) {
        await closeRedisClient();
      }
    },
  };

  // Store the listener in active listeners
  activeListeners[requestId] = listener;

  return listener;
}
