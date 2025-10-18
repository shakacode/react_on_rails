/**
 * Custom error type for when there's an issue fetching or rendering a server component.
 * This error includes information about the server component and the original error that occurred.
 */
export declare class ServerComponentFetchError extends Error {
  serverComponentName: string;

  serverComponentProps: unknown;

  originalError: Error;

  constructor(message: string, componentName: string, componentProps: unknown, originalError: Error);
}
/**
 * Type guard to check if an error is a ServerComponentFetchError
 */
export declare function isServerComponentFetchError(error: unknown): error is ServerComponentFetchError;
