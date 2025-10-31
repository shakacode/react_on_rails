import { createClient, RedisClientType } from 'redis';

const REDIS_READ_TIMEOUT = 10000;

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

/**
 * Listens to a Redis stream for data based on a requestId
 * @param requestId - The stream key to listen on
 * @returns An object with a getValue function to get values by key
 */
export function listenToRequestData(requestId: string): RequestListener {
  // Private state for THIS listener only - no global state
  const pendingPromises: Record<string, PendingPromise | undefined> = {};
  const receivedKeys: string[] = [];
  const streamKey = `stream:${requestId}`;
  const messagesToDelete: string[] = [];
  let isActive = true;
  let isEnded = false;
  let initializationError: Error | null = null;

  // Create dedicated Redis client for THIS listener
  const url = process.env.REDIS_URL || 'redis://localhost:6379';
  const redisClient: RedisClientType = createClient({ url });
  let isClientConnected = false;
  let connectionPromise: Promise<void> | null = null;

  /**
   * Ensures the Redis client is connected
   * Prevents race condition where multiple concurrent calls try to connect
   */
  async function ensureConnected(): Promise<RedisClientType> {
    // Fast path: already connected
    if (isClientConnected) {
      return redisClient;
    }

    // Start connection if not already in progress
    if (!connectionPromise) {
      connectionPromise = redisClient
        .connect()
        .then(() => {
          isClientConnected = true;
          connectionPromise = null; // Clear after successful connection
        })
        .catch((error: unknown) => {
          connectionPromise = null; // Clear on error to allow retry
          throw error; // Re-throw to propagate error
        });
    }

    // Wait for connection to complete (handles concurrent calls)
    await connectionPromise;
    return redisClient;
  }

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
      const client = await ensureConnected();
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
      const client = await ensureConnected();

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
      const client = await ensureConnected();

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

  // Create the listener object
  const listener: RequestListener = {
    /**
     * Gets a value for a specific key from the Redis stream
     * @param key - The key to look for in the stream
     * @returns A promise that resolves when the key is found
     */
    getValue: async (key: string) => {
      // If initialization failed, reject immediately with the initialization error
      if (initializationError) {
        return Promise.reject(
          new Error(`Redis listener initialization failed: ${initializationError.message}`),
        );
      }

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
      }, REDIS_READ_TIMEOUT);

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
      if (!isActive) {
        return;
      }
      isActive = false;

      // Reject and cleanup all pending promises
      Object.entries(pendingPromises).forEach(([_, pendingPromise]) => {
        if (pendingPromise && !pendingPromise.resolved) {
          clearTimeout(pendingPromise.timer);
          pendingPromise.reject(new Error('Redis connection closed'));
        }
      });

      // Clear the pendingPromises map completely
      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      Object.keys(pendingPromises).forEach((key) => delete pendingPromises[key]);

      // Wait for any pending connection attempt to complete
      if (connectionPromise) {
        try {
          await connectionPromise;
        } catch {
          // Connection failed, but we still need to clean up state
          connectionPromise = null;
        }
      }

      // Always close THIS listener's Redis client
      try {
        if (isClientConnected) {
          await redisClient.quit();
        }
      } catch (error) {
        console.error('Error closing Redis client:', error);
      } finally {
        isClientConnected = false;
        connectionPromise = null;
      }
    },
  };

  // Start listening to existing and new messages immediately
  (async () => {
    try {
      await checkExistingMessages();
      await setupStreamListener();
    } catch (error) {
      console.error('Error initializing Redis listener:', error);
      initializationError = error instanceof Error ? error : new Error(String(error));
      await listener.close();
    }
  })().catch((error: unknown) => {
    console.error('Fatal error in Redis listener initialization:', error);
  });

  return listener;
}
