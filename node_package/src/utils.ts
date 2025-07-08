// Override the fetch function to make it easier to test
// The default fetch implementation in jest returns Node's Readable stream
// In jest.setup.js, we configure this fetch to return a web-standard ReadableStream instead,
// which matches browser behavior where fetch responses have ReadableStream bodies
// See jest.setup.js for the implementation details
const customFetch = (...args: Parameters<typeof fetch>) => {
  const res = fetch(...args);
  return res;
};

export { customFetch as fetch };

/**
 * Creates a unique cache key for RSC payloads to prevent collisions between component instances.
 *
 * This function generates cache keys that ensure:
 * 1. Different components have different keys
 * 2. Same components with different props have different keys
 * 3. Multiple instances of the same component on the same rails view have different keys
 *
 * @param componentName - Name of the React Server Component
 * @param componentProps - Props passed to the component (serialized to JSON)
 * @param domNodeId - DOM node ID of the parent react component rendered at the rails view (prevents instance collisions)
 * @returns A unique cache key string
 * @throws Error if domNodeId is missing, which could lead to cache collisions
 */
export const createRSCPayloadKey = (
  componentName: string,
  componentProps: unknown,
  domNodeId: string | undefined,
) => {
  if (!domNodeId) {
    const errorMessage =
      'domNodeId is required when using React Server Components to ensure unique RSC payload caching ' +
      'and prevent conflicts between multiple instances of the same component at the same rails view. ' +
      'This could lead to incorrect hydration and component state issues.';

    if (process.env.NODE_ENV === 'development') {
      throw new Error(`RSC Cache Key Error: ${errorMessage}`);
    } else {
      console.warn(`Warning: ${errorMessage}`);
    }
  }

  return `${componentName}-${JSON.stringify(componentProps)}-${domNodeId}`;
};

/**
 * Wraps a promise from react-server-dom-webpack in a standard JavaScript Promise.
 *
 * This is necessary because promises returned by react-server-dom-webpack's methods
 * (like `createFromReadableStream` and `createFromNodeStream`) have non-standard behavior:
 * their `then()` method returns `null` instead of the promise itself, which breaks
 * promise chaining. This wrapper creates a new standard Promise that properly
 * forwards the resolution/rejection of the original promise.
 */
export const wrapInNewPromise = <T>(promise: Promise<T>) => {
  return new Promise<T>((resolve, reject) => {
    void promise.then(resolve);
    void promise.catch(reject);
  });
};
