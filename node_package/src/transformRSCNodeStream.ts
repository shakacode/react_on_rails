/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */

import { Transform } from 'stream';

/**
 * Transforms an RSC Node.js stream for server-side processing.
 *
 * This utility:
 * 1. Takes a Node.js ReadableStream of RSC payload chunks
 * 2. Applies necessary transformations for server-side consumption
 * 3. Returns a modified stream that works with React's SSR runtime
 *
 * This is essential for proper handling of RSC payloads in Node.js
 * environment during server-side rendering.
 *
 * @param stream - The Node.js RSC payload stream
 * @returns A transformed stream compatible with React's SSR runtime
 */
export default function transformRSCStream(stream: NodeJS.ReadableStream): NodeJS.ReadableStream {
  const decoder = new TextDecoder();
  let lastIncompleteChunk = '';

  const htmlExtractor = new Transform({
    transform(oneOrMoreChunks, _, callback) {
      try {
        const decodedChunk = lastIncompleteChunk + decoder.decode(oneOrMoreChunks as Uint8Array);
        const separateChunks = decodedChunk.split('\n').filter((chunk) => chunk.trim() !== '');

        if (!decodedChunk.endsWith('\n')) {
          lastIncompleteChunk = separateChunks.pop() ?? '';
        } else {
          lastIncompleteChunk = '';
        }

        for (const chunk of separateChunks) {
          const parsedData = JSON.parse(chunk) as { html: string };
          this.push(parsedData.html);
        }
        callback();
      } catch (error) {
        callback(error as Error);
      }
    },
  });

  return stream.pipe(htmlExtractor);
}
