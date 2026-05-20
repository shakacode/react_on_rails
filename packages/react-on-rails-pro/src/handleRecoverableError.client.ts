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

import { isRSCRouteSSRFalseBailoutError } from './RSCRouteSSRFalseBailoutError.ts';

const getRecoverableErrorCause = (error: unknown): unknown =>
  error instanceof Error && 'cause' in error ? (error as Error & { cause?: unknown }).cause : undefined;

const handleRecoverableError = (error: unknown) => {
  const cause = getRecoverableErrorCause(error);

  if (isRSCRouteSSRFalseBailoutError(error) || isRSCRouteSSRFalseBailoutError(cause)) {
    return;
  }

  if (typeof globalThis.reportError === 'function') {
    globalThis.reportError(error);
  } else {
    console.error(error);
  }
};

export default handleRecoverableError;
