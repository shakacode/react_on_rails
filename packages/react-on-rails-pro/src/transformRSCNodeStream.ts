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
  let buf = Buffer.alloc(0);
  let state: 'header' | 'content' = 'header';
  let contentLen = 0;

  const htmlExtractor = new Transform({
    transform(chunk: Buffer, _, callback) {
      try {
        buf = Buffer.concat([buf, chunk]);

        // eslint-disable-next-line no-constant-condition
        while (true) {
          if (state === 'header') {
            const newlineIdx = buf.indexOf(0x0a); // \n
            if (newlineIdx < 0) break; // incomplete header

            const header = buf.subarray(0, newlineIdx);
            buf = buf.subarray(newlineIdx + 1);

            const tabIdx = header.indexOf(0x09); // \t
            if (tabIdx >= 0) {
              // Length-prefixed format: metadata\tcontent_length\n<raw content>
              const lenHex = header.subarray(tabIdx + 1).toString('utf8');
              contentLen = parseInt(lenHex, 16);
              state = 'content';
            } else {
              // Legacy NDJSON format: JSON line
              const line = header.toString('utf8');
              if (line.trim() !== '') {
                const parsedData = JSON.parse(line) as { html: string };
                this.push(parsedData.html);
              }
            }
          } else {
            // state === 'content'
            if (buf.length < contentLen) break; // incomplete content

            this.push(buf.subarray(0, contentLen).toString('utf8'));
            buf = buf.subarray(contentLen);
            state = 'header';
          }
        }
        callback();
      } catch (error) {
        callback(error as Error);
      }
    },
  });

  return safePipe(stream as Readable, htmlExtractor);
}
