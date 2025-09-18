/*
 * Copyright (c) 2025 Shakacode
 *
 * This file, and all other files in this directory, are NOT licensed under the MIT license.
 *
 * This file is part of React on Rails Pro.
 *
 * Unauthorized copying, modification, distribution, or use of this file, via any medium,
 * is strictly prohibited. It is proprietary and confidential.
 *
 * For the full license agreement, see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

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
