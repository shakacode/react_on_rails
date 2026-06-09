/*
 * Copyright (c) 2026 Shakacode LLC
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

import type { ReactNode } from 'react';
import { fetchRSC } from './getReactServerComponent.client.ts';
import type { CreateRscPayloadNodeOptions } from './createRscPayloadNode.types.ts';

export type { CreateRscPayloadNodeOptions, RscPayloadNodeCredentials } from './createRscPayloadNode.types.ts';

const INVALID_COMPONENT_NAME_PATH_CHARS = /[/\\?#%]/;
const INVALID_PAYLOAD_PATH_CHARS = /[\\?#%]|^[a-z][a-z0-9+\-.]*:\/\//i;

const isErrorLike = (payload: unknown): payload is Error =>
  payload instanceof Error ||
  (Object.prototype.toString.call(payload) === '[object Error]' &&
    typeof (payload as { message?: unknown }).message === 'string' &&
    typeof (payload as { name?: unknown }).name === 'string' &&
    typeof (payload as { stack?: unknown }).stack === 'string');

const normalizeThrownValue = (error: unknown): Error => {
  if (error instanceof Error) return error;

  const wrappedError: Error & { cause?: unknown } = new Error(String(error));
  wrappedError.cause = error;
  return wrappedError;
};

const normalizePayloadPath = (payloadPath: string): string => {
  const trimmedPayloadPath = payloadPath.trim();
  if (!trimmedPayloadPath) {
    throw new Error('createRscPayloadNode requires a payloadPath.');
  }
  const pathSegments = trimmedPayloadPath.split('/').filter(Boolean);
  if (
    pathSegments.length === 0 ||
    INVALID_PAYLOAD_PATH_CHARS.test(trimmedPayloadPath) ||
    pathSegments.some((segment) => segment === '.' || segment === '..')
  ) {
    throw new Error(
      'createRscPayloadNode payloadPath must be a Rails path without traversal, URL, query, hash, or encoded path characters.',
    );
  }

  return `/${pathSegments.join('/')}`;
};

const rejectErrorPayload = (promise: Promise<ReactNode>): Promise<ReactNode> =>
  promise.then((payload) => {
    // React's RSC parser can resolve serialized server failures as Error instances.
    // Treat those as route-loader failures while preserving all other ReactNode values.
    if (isErrorLike(payload)) {
      throw payload;
    }
    return payload;
  });

/**
 * Fetches a React on Rails Pro RSC payload endpoint and resolves it into a
 * React node that can be returned from a client router loader and read with
 * React `use()` inside Suspense.
 */
export const createRscPayloadNode = (options: CreateRscPayloadNodeOptions): Promise<ReactNode> => {
  try {
    const { componentName, credentials = 'same-origin', headers, payloadPath, props = {}, signal } = options;
    if (typeof componentName !== 'string' || !componentName.trim()) {
      throw new Error('createRscPayloadNode requires a componentName.');
    }
    const normalizedComponentName = componentName.trim();
    if (INVALID_COMPONENT_NAME_PATH_CHARS.test(normalizedComponentName)) {
      throw new Error('createRscPayloadNode componentName cannot include path or query-string characters.');
    }
    if (typeof payloadPath !== 'string') {
      throw new Error('createRscPayloadNode requires a payloadPath.');
    }
    const normalizedPayloadPath = normalizePayloadPath(payloadPath);

    const fetchOptions: Pick<RequestInit, 'credentials' | 'headers' | 'signal'> = { credentials };
    if (headers) fetchOptions.headers = headers;
    if (signal) fetchOptions.signal = signal;

    return rejectErrorPayload(
      fetchRSC({
        componentName: normalizedComponentName,
        componentProps: props,
        fetchOptions,
        rscPayloadGenerationUrlPath: normalizedPayloadPath,
        // Route-data payloads must be safe under strict CSP; renderer console replay
        // metadata is intentionally ignored instead of materialized as inline script.
        replayConsoleScripts: false,
      }),
    );
  } catch (error) {
    return Promise.reject(normalizeThrownValue(error));
  }
};
