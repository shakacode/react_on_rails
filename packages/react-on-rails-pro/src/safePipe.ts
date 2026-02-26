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

import { Readable, Writable } from 'stream';
import { PipeableOrReadableStream } from 'react-on-rails/types';

/**
 * Pipes source to destination with proper 'close' event handling.
 *
 * Node.js `pipe()` does NOT end the destination when the source is destroyed —
 * it silently unpipes, leaving the destination open forever. This function fills
 * that gap by listening for the 'close' event (which fires after both normal
 * 'end' and `destroy()`) and ending the destination if the source didn't end
 * normally.
 *
 * An optional `onError` callback provides observability for source stream errors
 * without forwarding them to the destination (which would break the pipe).
 *
 * NOTE: `PipeableOrReadableStream` can be either a React `PipeableStream`
 * (which only has `.pipe()` and `.abort()`, no `.on()`) or a Node.js
 * `ReadableStream`. The 'close' and 'error' listeners are only attached when
 * the source supports `.on()`.
 *
 * @param source - The source stream to pipe from
 * @param destination - The destination stream to pipe into
 * @param onError - Optional callback for source stream errors (for reporting, not forwarding)
 * @returns The destination stream (for chaining)
 */
export default function safePipe<T extends Writable>(
  source: PipeableOrReadableStream,
  destination: T,
  onError?: (err: Error) => void,
): T {
  // Attach listeners BEFORE pipe() to avoid a theoretical race with synchronous
  // event emission during pipe setup. This matches the ordering in utils.ts's safePipe.
  if (typeof (source as Readable).on === 'function') {
    const readableSource = source as Readable;

    if (onError) {
      readableSource.on('error', onError);
    }

    // 'close' fires after both normal 'end' and destroy().
    // On normal end, pipe() already forwards 'end' to the destination — this is a no-op.
    // On destroy, pipe() unpipes but does NOT end the destination — we do it here.
    readableSource.on('close', () => {
      if (!destination.writableEnded) {
        destination.end();
      }
    });
  }

  source.pipe(destination);

  return destination;
}
