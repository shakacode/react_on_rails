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
 * Creates a unique cache key for RSC payloads.
 *
 * This function generates cache keys that ensure:
 * 1. Different components have different keys
 * 2. Same components with different props have different keys
 *
 * @param componentName - Name of the React Server Component
 * @param componentProps - Props passed to the component (serialized to JSON)
 * @returns A unique cache key string
 */
export const createRSCPayloadKey = (componentName: string, componentProps: unknown, domNodeId?: string) => {
  return `${componentName}-${JSON.stringify(componentProps)}${domNodeId ? `-${domNodeId}` : ''}`;
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

export const extractErrorMessage = (error: unknown): string => {
  return error instanceof Error ? error.message : String(error);
};
