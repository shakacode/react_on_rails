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

import { extractErrorMessage } from './utils.ts';

type RSCStreamDiagnosticContext = {
  componentName?: string;
  source?: string;
};

export type RSCStreamDiagnosticsOptions = RSCStreamDiagnosticContext & {
  onDiagnosticError?: (error: Error) => void;
};

type RenderingErrorMetadata = {
  message?: unknown;
  stack?: unknown;
};

export const RSC_STREAM_DIAGNOSTIC_ERROR_NAME = 'ReactOnRailsRSCStreamError';
const MERGED_DIAGNOSTIC_FLAG = '__rorRSCDiagMerged';

type RSCStreamDiagnosticError = Error & {
  [MERGED_DIAGNOSTIC_FLAG]?: true;
  cause?: unknown;
};

const str = (value: unknown) => (typeof value === 'string' && value.length > 0 ? value : undefined);

export const extractModulePathFromStack = (stack?: string) => {
  if (!stack) return undefined;
  for (const line of stack.split('\n')) {
    const match = /\(([^()]+):\d+:\d+\)$|\bat\s+(.+):\d+:\d+$/.exec(line.trim());
    // V8 emits anonymous async frames as `at async /path:l:c`; strip the `async ` keyword
    // so the diagnostic reports `Module: /path` instead of `Module: async /path`.
    const location = match?.[1] ?? match?.[2]?.replace(/^async\s+/, '');
    if (location) return location.replace(/\?.*$/, '');
  }
  return undefined;
};

export const buildRSCStreamDiagnosticError = (
  metadata: Record<string, unknown>,
  context: RSCStreamDiagnosticContext = {},
) => {
  const raw = metadata.renderingError;
  const re = (typeof raw === 'object' && raw !== null ? raw : {}) as RenderingErrorMetadata;
  const originalMessage = str(re.message);
  const originalStack = str(re.stack);
  // Wire contract: the React on Rails server bundle only emits `renderingError` on actual
  // failure, so presence of a message or stack is treated as a failure signal even when
  // `hasErrors` isn't explicitly set. Belt-and-suspenders intentional — if a future producer
  // wants to use `renderingError` for non-fatal info, this guard needs to change with it.
  if (metadata.hasErrors !== true && !originalMessage && !originalStack) return undefined;

  const modulePath = extractModulePathFromStack(originalStack);
  const message = [
    '[ReactOnRails] RSC bundle rendering failed.',
    context.componentName && `Component: ${context.componentName}`,
    context.source && `Source: ${context.source}`,
    modulePath && `Module: ${modulePath}`,
    `Original error: ${originalMessage ?? 'RSC stream metadata reported hasErrors=true'}`,
  ]
    .filter((line): line is string => Boolean(line))
    .join('\n');

  const diagnosticError = new Error(message);
  diagnosticError.name = RSC_STREAM_DIAGNOSTIC_ERROR_NAME;
  if (originalStack) {
    diagnosticError.stack = `${diagnosticError.name}: ${message}\nOriginal stack:\n${originalStack}`;
  }
  return diagnosticError;
};

export const mergeRSCStreamDiagnosticError = (error: unknown, diagnosticError?: Error) => {
  const streamError: RSCStreamDiagnosticError =
    error instanceof Error ? error : new Error(extractErrorMessage(error));
  if (!diagnosticError || streamError[MERGED_DIAGNOSTIC_FLAG]) return streamError;

  const message = `${diagnosticError.message}\nReact stream error: ${streamError.message}`;
  const mergedError: RSCStreamDiagnosticError = new Error(message);
  mergedError.name = RSC_STREAM_DIAGNOSTIC_ERROR_NAME;
  mergedError.cause = streamError;
  // Non-enumerable so error reporters that iterate own keys (Sentry "extra data",
  // structured cloning, etc.) don't pick up this internal marker.
  Object.defineProperty(mergedError, MERGED_DIAGNOSTIC_FLAG, {
    value: true,
    writable: false,
    enumerable: false,
    configurable: false,
  });
  mergedError.stack = [
    `${mergedError.name}: ${message}`,
    diagnosticError.stack && `RSC diagnostic stack:\n${diagnosticError.stack}`,
    streamError.stack && `React stream stack:\n${streamError.stack}`,
  ]
    .filter((line): line is string => Boolean(line))
    .join('\n\n');
  return mergedError;
};
