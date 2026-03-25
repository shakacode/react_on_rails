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

import { RSCPayloadChunk } from 'react-on-rails/types';
import { sanitizeNonce, replayConsoleLog } from './utils.ts';

/**
 * Transforms an RSC stream and replays console logs on the client.
 *
 * This utility:
 * 1. Takes a ReadableStream of RSC payload chunks
 * 2. Processes each chunk to extract and replay embedded console logs
 * 3. Passes through the actual RSC payload data
 *
 * This improves debugging by making server-side console logs appear in
 * the client console, maintaining a seamless development experience.
 *
 * @param stream - The RSC payload stream to transform
 * @returns A transformed stream with console logs extracted and replayed
 */

export default function transformRSCStreamAndReplayConsoleLogs(
  stream: ReadableStream<Uint8Array | string>,
  cspNonce?: string,
) {
  const sanitizedNonce = sanitizeNonce(cspNonce);
  return new ReadableStream({
    async start(controller) {
      const reader = stream.getReader();
      const decoder = new TextDecoder();
      const encoder = new TextEncoder();

      let lastIncompleteChunk = '';
      let { value, done } = await reader.read();

      const handleJsonChunk = (chunk: RSCPayloadChunk) => {
        const { html, consoleReplayScript } = chunk;
        controller.enqueue(encoder.encode(html ?? ''));
        replayConsoleLog(consoleReplayScript, sanitizedNonce);
      };

      const parseAndHandleLines = (lines: string[]) => {
        const jsonChunks = lines
          .filter((line) => line.trim() !== '')
          .map((line) => {
            try {
              return JSON.parse(line) as RSCPayloadChunk;
            } catch (error) {
              console.error('Error parsing JSON:', line, error);
              throw error;
            }
          });

        for (const jsonChunk of jsonChunks) {
          handleJsonChunk(jsonChunk);
        }
      };

      try {
        while (!done) {
          const decodedValue = typeof value === 'string' ? value : decoder.decode(value, { stream: true });
          const decodedChunks = lastIncompleteChunk + decodedValue;
          const chunks = decodedChunks.split('\n');
          lastIncompleteChunk = chunks.pop() ?? '';

          parseAndHandleLines(chunks);

          // eslint-disable-next-line no-await-in-loop
          ({ value, done } = await reader.read());
        }

        const finalDecodedValue = lastIncompleteChunk + decoder.decode();
        if (finalDecodedValue.trim() !== '') {
          parseAndHandleLines(finalDecodedValue.split('\n'));
        }

        controller.close();
      } catch (error) {
        console.error('Error transforming RSC stream:', error);
        controller.error(error);
      }
    },
  });
}
