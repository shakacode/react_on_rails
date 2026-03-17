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

import { Readable, Transform } from 'stream';
import safePipe from './safePipe.ts';
import LengthPrefixedStreamParser from './parseLengthPrefixedStream.ts';

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
  const parser = new LengthPrefixedStreamParser();

  const htmlExtractor = new Transform({
    transform(chunk: Buffer, _, callback) {
      try {
        parser.feed(chunk, (content) => {
          this.push(content);
        });
        callback();
      } catch (error) {
        callback(error as Error);
      }
    },
  });

  return safePipe(stream as Readable, htmlExtractor);
}
