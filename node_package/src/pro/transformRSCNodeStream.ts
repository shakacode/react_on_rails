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
