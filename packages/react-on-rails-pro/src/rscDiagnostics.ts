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
// Exported so tests reference the marker by constant rather than a duplicated string literal.
export const MERGED_DIAGNOSTIC_FLAG = '__rorRSCDiagMerged';

type RSCStreamDiagnosticError = Error & {
  [MERGED_DIAGNOSTIC_FLAG]?: true;
  cause?: unknown;
};

const nonEmptyString = (value: unknown) => {
  if (typeof value !== 'string') return undefined;
  // Trim so a whitespace-only `renderingError.message`/`stack` (e.g. `"  "` or `"\n"`) is
  // treated as absent rather than surfacing as `Original error:` with blank text.
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
};

// Bundler/framework frames point at library code rather than the failing component, so they
// are a poor value for `Module:`. Skip them when a later user-code frame is available.
// Note: this is matched against the extracted file *path*, not the raw frame, so a webpack
// runtime frame is caught by its `webpack/` or `webpack-internal:` path, not its function name.
const INTERNAL_FRAME_RE = /(?:^|[\\/])node_modules[\\/]|(?:^|[\\/])webpack[\\/]|\bwebpack-internal:/;

export const extractModulePathFromStack = (stack?: string) => {
  if (!stack) return undefined;
  let firstLocation: string | undefined;
  for (const rawLine of stack.split('\n')) {
    const line = rawLine.trim();
    // Two V8 frame shapes:
    //   `at fn (/path/to/file.js:10:5)`  -> parenthesized
    //   `at /path:10:5` / `at async /path:10:5` -> anonymous/top-level
    // The anonymous form is anchored to an absolute path (POSIX `/` or a Windows drive) and
    // tolerates the optional `async ` keyword, so a bare function name in an unusual
    // `at fn /path:10:5` frame isn't mistaken for the module path.
    const match = /\(([^()]+):\d+:\d+\)$|\bat\s+(?:async\s+)?((?:\/|[A-Za-z]:[\\/]).*?):\d+:\d+$/.exec(line);
    const location = (match?.[1] ?? match?.[2])?.replace(/\?.*$/, '');
    if (location) {
      firstLocation ??= location;
      if (!INTERNAL_FRAME_RE.test(location)) return location;
    }
  }
  // Every frame was framework-internal — fall back to the first so `Module:` is still populated.
  return firstLocation;
};

export const buildRSCStreamDiagnosticError = (
  metadata: Record<string, unknown>,
  context: RSCStreamDiagnosticContext = {},
) => {
  const raw = metadata.renderingError;
  // `RenderingErrorMetadata` has only optional `unknown` fields, so a plain annotation
  // accepts any object without a type assertion; `nonEmptyString()` validates each field at runtime.
  const re: RenderingErrorMetadata = typeof raw === 'object' && raw !== null ? raw : {};
  const originalMessage = nonEmptyString(re.message);
  const originalStack = nonEmptyString(re.stack);
  // Wire contract: the React on Rails server bundle only emits `renderingError` on actual
  // failure, so presence of a message or stack is treated as a failure signal even when
  // `hasErrors` isn't explicitly set. Belt-and-suspenders intentional — if a future producer
  // wants to use `renderingError` for non-fatal info, this guard needs to change with it.
  if (metadata.hasErrors !== true && !originalMessage && !originalStack) return undefined;

  const modulePath = extractModulePathFromStack(originalStack);
  // Without a message, name the actual signal that triggered the diagnostic: `hasErrors=true`
  // when that flag is set, otherwise a stack-only `renderingError` (claiming `hasErrors=true`
  // in the latter case would be inaccurate).
  const fallbackOriginalError =
    metadata.hasErrors === true
      ? 'RSC stream metadata reported hasErrors=true'
      : 'RSC stream metadata reported a rendering error';
  const message = [
    '[ReactOnRails] RSC bundle rendering failed.',
    context.componentName && `Component: ${context.componentName}`,
    context.source && `Source: ${context.source}`,
    modulePath && `Module: ${modulePath}`,
    `Original error: ${originalMessage ?? fallbackOriginalError}`,
  ]
    .filter((line): line is string => Boolean(line))
    .join('\n');

  const diagnosticError = new Error(message);
  diagnosticError.name = RSC_STREAM_DIAGNOSTIC_ERROR_NAME;
  // Always overwrite the auto-generated stack. With an original stack we surface it; without one
  // we reduce the stack to just the header line, because the V8-generated stack would otherwise
  // point at this diagnostics module and error monitors (Sentry, Honeybadger) would misattribute
  // the error origin to react-on-rails internals.
  diagnosticError.stack = originalStack
    ? `${diagnosticError.name}: ${message}\nOriginal stack:\n${originalStack}`
    : `${diagnosticError.name}: ${message}`;
  return diagnosticError;
};

/**
 * Merges a generic React stream error with the original RSC bundle diagnostic.
 *
 * Idempotent on `error`: if `error` is already a merged result (carries `MERGED_DIAGNOSTIC_FLAG`)
 * it is returned untouched, so re-entering this in a chain of catch handlers won't double-wrap.
 *
 * Precondition: `diagnosticError` must be a fresh (non-merged) diagnostic — in practice it always
 * comes from `buildRSCStreamDiagnosticError`, which never sets the flag. The idempotency guard
 * intentionally only inspects `error`; passing an already-merged error as `diagnosticError` would
 * duplicate context.
 */
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
