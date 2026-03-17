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
import { RailsContext } from 'react-on-rails/types';
import { createRSCPayloadKey, fetch, wrapInNewPromise, extractErrorMessage, sanitizeNonce } from './utils.ts';
import LengthPrefixedStreamParser from './parseLengthPrefixedStream.ts';

declare global {
  interface Window {
    REACT_ON_RAILS_RSC_PAYLOADS?: Record<string, string[]>;
  }
}

export type ClientGetReactServerComponentProps = {
  componentName: string;
  componentProps: unknown;
  enforceRefetch?: boolean;
};

/**
 * Replays a consoleReplayScript by injecting it as a <script> element.
 */
const replayConsole = (consoleReplayScript: string, nonce?: string) => {
  const code = consoleReplayScript
    .trim()
    .replace(/^<script[^>]*>/i, '')
    .replace(/<\/script>$/i, '');
  if (code.trim() !== '') {
    const el = document.createElement('script');
    if (nonce) {
      el.nonce = nonce;
    }
    el.textContent = code;
    document.body.appendChild(el);
  }
};

/**
 * Parses a length-prefixed RSC fetch response stream.
 *
 * Wire format per chunk: <metadata JSON>\t<hex content length>\n<raw Flight data>
 *
 * Extracts raw Flight data for React, replays console from metadata.
 */
const createFromFetch = async (fetchPromise: Promise<Response>, cspNonce?: string) => {
  const response = await fetchPromise;
  const { body } = response;
  if (!body) {
    throw new Error('No stream found in response');
  }

  const nonce = sanitizeNonce(cspNonce);
  const parser = new LengthPrefixedStreamParser();

  const transformedStream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const reader = body.getReader();
      try {
        let done = false;
        while (!done) {
          // eslint-disable-next-line no-await-in-loop
          const readResult = await reader.read();
          done = readResult.done;
          if (readResult.value) {
            parser.feed(readResult.value, (content, metadata) => {
              controller.enqueue(content);
              const consoleScript = (metadata.consoleReplayScript as string) ?? '';
              if (consoleScript) {
                replayConsole(consoleScript, nonce);
              }
            });
          }
        }
        controller.close();
      } catch (error) {
        controller.error(error);
      }
    },
  });

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

const createRSCStreamFromArray = (payloads: string[]) => {
  const encoder = new TextEncoder();
  let streamController: ReadableStreamController<Uint8Array> | undefined;
  const stream = new ReadableStream<Uint8Array>({
    start(controller) {
      if (typeof window === 'undefined') {
        return;
      }
      const handleChunk = (chunk: string) => {
        controller.enqueue(encoder.encode(chunk));
      };

      payloads.forEach(handleChunk);
      // eslint-disable-next-line no-param-reassign
      payloads.push = (...chunks) => {
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
 * Creates React elements from preloaded RSC payloads in the page.
 *
 * This function:
 * 1. Creates a ReadableStream from the array of raw Flight data strings
 * 2. Feeds the stream directly to React's createFromReadableStream
 *
 * Console replay is handled separately via standalone <script> tags
 * emitted by injectRSCPayload, not through the payload array.
 *
 * This is used during hydration to avoid making HTTP requests when
 * the payload is already embedded in the page.
 *
 * @param payloads - Array of raw Flight data strings from the global array
 * @returns A Promise resolving to the rendered React element
 */
const createFromPreloadedPayloads = (payloads: string[]) => {
  const stream = createRSCStreamFromArray(payloads);
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
        return createFromPreloadedPayloads(payloads);
      }
    }
    return fetchRSC({ componentName, componentProps, railsContext });
  };

export default getReactServerComponent;
