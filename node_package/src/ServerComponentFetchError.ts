/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

/**
 * Custom error type for when there's an issue fetching or rendering a server component.
 * This error includes information about the server component and the original error that occurred.
 */
export class ServerComponentFetchError extends Error {
  serverComponentName: string;

  serverComponentProps: unknown;

  originalError: Error;

  constructor(message: string, componentName: string, componentProps: unknown, originalError: Error) {
    super(message);
    this.name = 'ServerComponentFetchError';
    this.serverComponentName = componentName;
    this.serverComponentProps = componentProps;
    this.originalError = originalError;
  }
}

/**
 * Type guard to check if an error is a ServerComponentFetchError
 */
export function isServerComponentFetchError(error: unknown): error is ServerComponentFetchError {
  return error instanceof ServerComponentFetchError;
}
