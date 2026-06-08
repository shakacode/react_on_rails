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

export type RscPayloadNodeCredentials = Extract<RequestCredentials, 'same-origin' | 'include'>;

export type CreateRscPayloadNodeOptions = {
  /**
   * Registered React Server Component name served by the Pro RSC payload route.
   */
  componentName: string;

  /**
   * Rails path configured with `rsc_payload_route`, for example `/rsc_payload`.
   */
  payloadPath: string;

  /**
   * Props serialized into the payload request's `props` query parameter.
   */
  props?: unknown;

  /**
   * Additional request headers, such as application-specific tracing headers.
   */
  headers?: HeadersInit;

  /**
   * Fetch credentials mode. Defaults to `same-origin` so Rails session cookies
   * continue to accompany same-origin payload requests.
   */
  credentials?: RscPayloadNodeCredentials;

  /**
   * Optional cancellation signal for route loaders.
   */
  signal?: AbortSignal;
};

const INVALID_COMPONENT_NAME_PATH_CHARS = /[/\\?#%]/;

const rejectErrorPayload = (promise: Promise<ReactNode>): Promise<ReactNode> =>
  promise.then((payload) => {
    // React's RSC parser can resolve serialized server failures as Error instances.
    // Treat those as route-loader failures while preserving all other ReactNode values.
    if (payload instanceof Error) {
      throw payload;
    }
    return payload;
  });

/**
 * Fetches a React on Rails Pro RSC payload endpoint and resolves it into a
 * React node that can be returned from a client router loader and read with
 * React `use()` inside Suspense.
 */
export const createRscPayloadNode = ({
  componentName,
  credentials = 'same-origin',
  headers,
  payloadPath,
  props = {},
  signal,
}: CreateRscPayloadNodeOptions): Promise<ReactNode> => {
  if (typeof componentName !== 'string' || !componentName.trim()) {
    throw new Error('createRscPayloadNode requires a componentName.');
  }
  const normalizedComponentName = componentName.trim();
  if (INVALID_COMPONENT_NAME_PATH_CHARS.test(normalizedComponentName)) {
    throw new Error('createRscPayloadNode componentName cannot include path or query-string characters.');
  }
  if (typeof payloadPath !== 'string' || !payloadPath.trim()) {
    throw new Error('createRscPayloadNode requires a payloadPath.');
  }

  const fetchOptions: Pick<RequestInit, 'credentials' | 'headers' | 'signal'> = { credentials };
  if (headers) fetchOptions.headers = headers;
  if (signal) fetchOptions.signal = signal;

  let fetchPromise: Promise<ReactNode>;
  try {
    fetchPromise = fetchRSC({
      componentName: normalizedComponentName,
      componentProps: props,
      fetchOptions,
      rscPayloadGenerationUrlPath: payloadPath,
      // Route-data payloads must be safe under strict CSP; renderer console replay
      // metadata is intentionally ignored instead of materialized as inline script.
      replayConsoleScripts: false,
    });
  } catch (error) {
    fetchPromise = Promise.reject(error instanceof Error ? error : new Error(String(error)));
  }

  return rejectErrorPayload(fetchPromise);
};
