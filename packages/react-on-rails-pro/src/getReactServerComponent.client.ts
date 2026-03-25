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

import * as React from 'react';
import { createFromReadableStream } from 'react-on-rails-rsc/client.browser';
import { RailsContext, RSCPayloadChunk } from 'react-on-rails/types';
import {
  createRSCPayloadKey,
  fetch,
  wrapInNewPromise,
  extractErrorMessage,
  sanitizeNonce,
  replayConsoleLog,
} from './utils.ts';
import transformRSCStreamAndReplayConsoleLogs from './transformRSCStreamAndReplayConsoleLogs.ts';

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOADS?: Record<string, RSCPayloadChunk[]>;
  }
}

export type ClientGetReactServerComponentProps = {
  componentName: string;
  componentProps: unknown;
  enforceRefetch?: boolean;
};

const createFromFetch = async (fetchPromise: Promise<Response>, cspNonce?: string) => {
  const response = await fetchPromise;
  const stream = response.body;
  if (!stream) {
    throw new Error('No stream found in response');
  }
  const transformedStream = transformRSCStreamAndReplayConsoleLogs(stream, cspNonce);
  const renderPromise = createFromReadableStream<React.ReactNode>(transformedStream);
  return wrapInNewPromise(renderPromise);
};

/**
 * Fetches an RSC payload via HTTP request.
 *
 * This function:
 * 1. Serializes the component props
 * 2. Makes an HTTP request to the RSC payload generation endpoint
 * 3. Processes the response stream into React elements
 *
 * This is used for client-side navigation or when rendering components
 * that weren't part of the initial server render.
 *
 * @param componentName - Name of the server component
 * @param componentProps - Props for the server component
 * @param railsContext - The Rails context containing configuration
 * @returns A Promise resolving to the rendered React element
 * @throws Error if RSC payload generation URL path is not configured or network request fails
 */
const fetchRSC = ({
  componentName,
  componentProps,
  railsContext,
}: ClientGetReactServerComponentProps & { railsContext: RailsContext }) => {
  const { rscPayloadGenerationUrlPath } = railsContext;

  if (!rscPayloadGenerationUrlPath) {
    throw new Error(
      `Cannot fetch RSC payload for component "${componentName}": rscPayloadGenerationUrlPath is not configured. ` +
        'Please ensure React Server Components support is properly enabled and configured.',
    );
  }

  try {
    const propsString = JSON.stringify(componentProps);
    const strippedUrlPath = rscPayloadGenerationUrlPath.replace(/^\/|\/$/g, '');
    const encodedParams = new URLSearchParams({ props: propsString }).toString();
    const fetchUrl = `/${strippedUrlPath}/${componentName}?${encodedParams}`;

    return createFromFetch(fetch(fetchUrl), railsContext.cspNonce).catch((error: unknown) => {
      throw new Error(
        `Failed to fetch RSC payload for component "${componentName}" from "${fetchUrl}": ${extractErrorMessage(error)}`,
      );
    });
  } catch (error: unknown) {
    // Handle JSON.stringify errors or other synchronous errors
    throw new Error(
      `Failed to prepare RSC request for component "${componentName}": ${extractErrorMessage(error)}`,
    );
  }
};

/**
 * Creates a ReadableStream of raw Flight data from preloaded RSC payload objects.
 *
 * The payloads are objects (not strings) because injectRSCPayload embeds JSON
 * directly as JavaScript expressions, avoiding the double JSON.stringify overhead.
 * This function extracts the html field and replays console logs from each chunk.
 */
const createRSCStreamFromPreloadedPayloads = (payloads: RSCPayloadChunk[], cspNonce?: string) => {
  const encoder = new TextEncoder();
  const sanitizedNonceValue = sanitizeNonce(cspNonce);
  let streamController: ReadableStreamController<Uint8Array> | undefined;
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      // Browser-only by design (callers read from window.REACT_ON_RAILS_RSC_PAYLOADS).
      // If called outside the browser, close immediately to avoid hanging streams.
      if (typeof window === 'undefined') {
        controller.close();
        return;
      }
      const handleChunk = (chunk: RSCPayloadChunk) => {
        controller.enqueue(encoder.encode(chunk.html ?? ''));
        replayConsoleLog(chunk.consoleReplayScript, sanitizedNonceValue);
      };

      payloads.forEach(handleChunk);
      // eslint-disable-next-line no-param-reassign
      payloads.push = (...chunks: RSCPayloadChunk[]) => {
        chunks.forEach(handleChunk);
        return chunks.length;
      };
      streamController = controller;
    },
  });

  if (typeof document !== 'undefined' && document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      streamController?.close();
    });
  } else {
    streamController?.close();
  }

  return stream;
};

/**
 * Creates React elements from preloaded RSC payloads embedded in the page.
 *
 * The payloads are RSCPayloadChunk objects pushed to the global array by
 * injectRSCPayload's script tags. This processes them directly without
 * JSON.parse overhead (the objects are already parsed by the JS engine).
 *
 * @param payloads - Array of RSC payload chunk objects from the global array
 * @returns A Promise resolving to the rendered React element
 */
const createFromPreloadedPayloads = (payloads: RSCPayloadChunk[], cspNonce?: string) => {
  const stream = createRSCStreamFromPreloadedPayloads(payloads, cspNonce);
  const renderPromise = createFromReadableStream<React.ReactNode>(stream);
  return wrapInNewPromise(renderPromise);
};

/**
 * Creates a function that fetches and renders a server component on the client side.
 *
 * This style of higher-order function is necessary as the function that gets server components
 * on server has different parameters than the function that gets them on client. The environment
 * dependent parameters (domNodeId, railsContext) are passed from the `wrapServerComponentRenderer`
 * function, while the environment agnostic parameters (componentName, componentProps, enforceRefetch)
 * are passed from the RSCProvider which is environment agnostic.
 *
 * The returned function:
 * 1. Checks for embedded RSC payloads in window.REACT_ON_RAILS_RSC_PAYLOADS using the domNodeId
 * 2. If found, uses the embedded payload to avoid an HTTP request
 * 3. If not found (during client navigation or dynamic rendering), fetches via HTTP
 * 4. Processes the RSC payload into React elements
 *
 * The embedded payload approach ensures optimal performance during initial page load,
 * while the HTTP fallback enables dynamic rendering after navigation.
 *
 * @param domNodeId - The DOM node ID to create a unique key for the RSC payload store
 * @param railsContext - Context for the current request, shared across all components
 * @returns A function that accepts RSC parameters and returns a Promise resolving to the rendered React element
 *
 * The returned function accepts:
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 * @param enforceRefetch - Whether to enforce a refetch of the component
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
const getReactServerComponent =
  (domNodeId: string, railsContext: RailsContext) =>
  ({ componentName, componentProps, enforceRefetch = false }: ClientGetReactServerComponentProps) => {
    if (!enforceRefetch && window.REACT_ON_RAILS_RSC_PAYLOADS) {
      const rscPayloadKey = createRSCPayloadKey(componentName, componentProps, domNodeId);
      const payloads = window.REACT_ON_RAILS_RSC_PAYLOADS[rscPayloadKey];
      if (payloads) {
        return createFromPreloadedPayloads(payloads, railsContext.cspNonce);
      }
    }
    return fetchRSC({ componentName, componentProps, railsContext });
  };

export default getReactServerComponent;
