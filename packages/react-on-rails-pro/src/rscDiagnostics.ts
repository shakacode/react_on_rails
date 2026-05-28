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

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;

const stringValue = (value: unknown) => (typeof value === 'string' && value.length > 0 ? value : undefined);

export const extractModulePathFromStack = (stack?: string) => {
  if (!stack) return undefined;

  const stackLines = stack.split('\n').map((line) => line.trim());
  for (const line of stackLines) {
    const parenthesizedLocation = /\(([^()]+):\d+:\d+\)$/.exec(line);
    const directLocation = /\bat\s+(.+):\d+:\d+$/.exec(line);
    const location = parenthesizedLocation?.[1] ?? directLocation?.[1];
    if (location) {
      return location.replace(/\?.*$/, '');
    }
  }

  return undefined;
};

export const buildRSCStreamDiagnosticError = (
  metadata: Record<string, unknown>,
  context: RSCStreamDiagnosticContext = {},
) => {
  const renderingErrorMetadata = isRecord(metadata.renderingError)
    ? (metadata.renderingError as RenderingErrorMetadata)
    : {};
  const originalMessage = stringValue(renderingErrorMetadata.message);
  const originalStack = stringValue(renderingErrorMetadata.stack);
  const hasErrors = metadata.hasErrors === true;

  if (!hasErrors && !originalMessage && !originalStack) {
    return undefined;
  }

  const modulePath = extractModulePathFromStack(originalStack);
  const message = [
    '[ReactOnRails] RSC bundle rendering failed.',
    context.componentName ? `Component: ${context.componentName}` : undefined,
    context.source ? `Source: ${context.source}` : undefined,
    modulePath ? `Module: ${modulePath}` : undefined,
    `Original error: ${originalMessage ?? 'RSC stream metadata reported hasErrors=true'}`,
  ]
    .filter((line): line is string => Boolean(line))
    .join('\n');

  const diagnosticError = new Error(message);
  diagnosticError.name = 'ReactOnRailsRSCStreamError';
  if (originalStack) {
    diagnosticError.stack = `${diagnosticError.name}: ${message}\nOriginal stack:\n${originalStack}`;
  }

  return diagnosticError;
};

export const mergeRSCStreamDiagnosticError = (error: unknown, diagnosticError?: Error) => {
  const streamError = error instanceof Error ? error : new Error(extractErrorMessage(error));
  if (!diagnosticError) {
    return streamError;
  }

  const message = `${diagnosticError.message}\nReact stream error: ${streamError.message}`;
  const mergedError = new Error(message) as Error & { cause?: unknown };
  mergedError.name = 'ReactOnRailsRSCStreamError';
  mergedError.cause = streamError;
  mergedError.stack = [
    `${mergedError.name}: ${message}`,
    diagnosticError.stack ? `RSC diagnostic stack:\n${diagnosticError.stack}` : undefined,
    streamError.stack ? `React stream stack:\n${streamError.stack}` : undefined,
  ]
    .filter((line): line is string => Boolean(line))
    .join('\n\n');

  return mergedError;
};
