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

export const RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST = 'REACT_ON_RAILS_RSC_ROUTE_SSR_FALSE_BAILOUT';

/**
 * Intentional server-only bailout used by `RSCRoute ssr={false}`.
 *
 * React streaming SSR catches errors under Suspense boundaries and emits the nearest fallback.
 * The stream renderer uses this classified error to avoid reporting that intentional fallback
 * path as a real server-rendering failure.
 */
export class RSCRouteSSRFalseBailoutError extends Error {
  digest = RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST;

  constructor(componentName: string) {
    super(`RSCRoute "${componentName}" skipped server rendering because it was rendered with ssr={false}.`);
    this.name = 'RSCRouteSSRFalseBailoutError';
  }
}

export function isRSCRouteSSRFalseBailoutError(error: unknown): error is RSCRouteSSRFalseBailoutError {
  return (
    error instanceof RSCRouteSSRFalseBailoutError ||
    (typeof error === 'object' &&
      error !== null &&
      'digest' in error &&
      (error as { digest?: unknown }).digest === RSC_ROUTE_SSR_FALSE_BAILOUT_DIGEST)
  );
}
