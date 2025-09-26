/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
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
