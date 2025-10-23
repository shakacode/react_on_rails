declare const customFetch: (...args: Parameters<typeof fetch>) => Promise<Response>;
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
export declare const createRSCPayloadKey: (
  componentName: string,
  componentProps: unknown,
  domNodeId?: string,
) => string;
/**
 * Wraps a promise from react-server-dom-webpack in a standard JavaScript Promise.
 *
 * This is necessary because promises returned by react-server-dom-webpack's methods
 * (like `createFromReadableStream` and `createFromNodeStream`) have non-standard behavior:
 * their `then()` method returns `null` instead of the promise itself, which breaks
 * promise chaining. This wrapper creates a new standard Promise that properly
 * forwards the resolution/rejection of the original promise.
 */
export declare const wrapInNewPromise: <T>(promise: Promise<T>) => Promise<T>;
export declare const extractErrorMessage: (error: unknown) => string;
