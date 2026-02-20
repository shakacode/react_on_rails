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

import { PassThrough, Readable } from 'stream';
import { finished } from 'stream/promises';
import { PipeableOrReadableStream } from 'react-on-rails/types';
import { createRSCPayloadKey } from './utils.ts';
import RSCRequestTracker from './RSCRequestTracker.ts';

// In JavaScript, when an escape sequence with a backslash (\) is followed by a character
// that isn't a recognized escape character, the backslash is ignored, and the character
// is treated as-is.
// This behavior allows us to use the backslash to escape characters that might be
// interpreted as HTML tags, preventing them from being processed by the HTML parser.
// For example, we can escape the comment tag <!-- as <\!-- and the script tag </script>
// as <\/script>.
// This ensures that these tags are not prematurely closed or misinterpreted by the browser.
function escapeScript(script: string) {
  return script.replace(/<!--/g, '<\\!--').replace(/<\/(script)/gi, '</\\$1');
}

function cacheKeyJSArray(cacheKey: string) {
  return `(self.REACT_ON_RAILS_RSC_PAYLOADS||={})[${JSON.stringify(cacheKey)}]||=[]`;
}

function createScriptTag(script: string) {
  return `<script>${escapeScript(script)}</script>`;
}

function createRSCPayloadInitializationScript(cacheKey: string) {
  return createScriptTag(cacheKeyJSArray(cacheKey));
}

function createRSCPayloadChunk(chunk: string, cacheKey: string) {
  return createScriptTag(`(${cacheKeyJSArray(cacheKey)}).push(${JSON.stringify(chunk)})`);
}

/**
 * Embeds RSC payloads into the HTML stream for optimal hydration.
 *
 * This function implements a sophisticated buffer management system that coordinates
 * three different data sources and streams them in a specific order.
 *
 * BUFFER MANAGEMENT STRATEGY:
 * - Three separate buffer arrays collect data from different sources
 * - A scheduled flush mechanism combines and sends data in coordinated chunks
 * - Streaming only begins after receiving the first HTML chunk
 * - Each output chunk maintains a specific data order for proper hydration
 *
 * TIMING CONSTRAINTS:
 * - RSC payload initialization must occur BEFORE component HTML
 * - First output chunk MUST contain HTML data
 * - Subsequent chunks can contain any combination of the three data types
 *
 * HYDRATION OPTIMIZATION:
 * - RSC payloads are embedded directly in the HTML stream
 * - Client components can access RSC data immediately without additional requests
 * - Global arrays are initialized before component HTML to ensure availability
 *
 * @param pipeableHtmlStream - HTML stream from React's renderToPipeableStream
 * @param railsContext - Context for the current request
 * @returns A combined stream with embedded RSC payloads
 */
export default function injectRSCPayload(
  pipeableHtmlStream: PipeableOrReadableStream,
  rscRequestTracker: RSCRequestTracker,
  domNodeId: string | undefined,
) {
  const htmlStream = new PassThrough();
  pipeableHtmlStream.pipe(htmlStream);
  // When the source is destroyed, pipe() unpipes but does NOT end htmlStream.
  // Listen for 'close' to ensure htmlStream ends, which triggers the cleanup chain.
  if (typeof (pipeableHtmlStream as Readable).on === 'function') {
    (pipeableHtmlStream as Readable).on('close', () => {
      if (!htmlStream.writableEnded) {
        htmlStream.end();
      }
    });
  }
  const decoder = new TextDecoder();
  let rscPromise: Promise<void> | null = null;

  // ========================================
  // BUFFER ARRAYS - Three data sources
  // ========================================

  /**
   * Buffer for RSC payload array initialization scripts.
   * These scripts create global JavaScript arrays that will store RSC payload chunks.
   * CRITICAL: Must be sent BEFORE the corresponding component HTML to ensure
   * the arrays exist when client-side hydration begins.
   */
  const rscInitializationBuffers: Buffer[] = [];

  /**
   * Buffer for HTML chunks from the React rendering stream.
   * Contains the actual component markup that will be displayed to users.
   * CONSTRAINT: The first output chunk must contain HTML data to begin streaming.
   */
  const htmlBuffers: Buffer[] = [];

  /**
   * Buffer for RSC payload chunk scripts.
   * These scripts push actual RSC data into the previously initialized global arrays.
   * Can be sent after the component HTML since the arrays already exist.
   */
  const rscPayloadBuffers: Buffer[] = [];

  // ========================================
  // FLUSH SCHEDULING SYSTEM
  // ========================================

  let flushTimeout: NodeJS.Timeout | null = null;
  const resultStream = new PassThrough();
  let hasReceivedFirstHtmlChunk = false;

  /**
   * Combines all buffered data into a single chunk and sends it to the result stream.
   *
   * FLUSH BEHAVIOR:
   * - Only starts streaming after receiving the first HTML chunk
   * - Combines data in a specific order: RSC initialization → HTML → RSC payloads
   * - Clears all buffers after flushing to prevent memory leaks
   * - Uses efficient buffer allocation based on total size calculation
   *
   * OUTPUT CHUNK STRUCTURE:
   * [RSC Array Initialization Scripts][HTML Content][RSC Payload Scripts]
   */
  const flush = () => {
    // STREAMING CONSTRAINT: Don't start until we have HTML content
    // This ensures the first chunk always contains HTML, which is required
    // for proper page rendering and prevents empty initial chunks
    if (!hasReceivedFirstHtmlChunk && htmlBuffers.length === 0) {
      flushTimeout = null;
      return;
    }

    // Calculate total buffer size for efficient memory allocation
    const rscInitializationSize = rscInitializationBuffers.reduce((sum, buf) => sum + buf.length, 0);
    const htmlSize = htmlBuffers.reduce((sum, buf) => sum + buf.length, 0);
    const rscPayloadSize = rscPayloadBuffers.reduce((sum, buf) => sum + buf.length, 0);
    const totalSize = rscInitializationSize + htmlSize + rscPayloadSize;

    // Skip flush if no data is buffered
    if (totalSize === 0) {
      flushTimeout = null;
      return;
    }

    // Create single buffer with exact size needed (no reallocation)
    const combinedBuffer = Buffer.allocUnsafe(totalSize);
    let offset = 0;

    // COPY ORDER IS CRITICAL - matches hydration requirements:

    // 1. RSC Payload array initialization scripts FIRST
    // These must execute before HTML to create the global arrays
    for (const buffer of rscInitializationBuffers) {
      buffer.copy(combinedBuffer, offset);
      offset += buffer.length;
    }

    // 2. HTML chunks SECOND
    // Component markup that references the initialized arrays
    for (const buffer of htmlBuffers) {
      buffer.copy(combinedBuffer, offset);
      offset += buffer.length;
    }

    // 3. RSC payload chunk scripts LAST
    // Data pushed into the already-existing arrays
    for (const buffer of rscPayloadBuffers) {
      buffer.copy(combinedBuffer, offset);
      offset += buffer.length;
    }

    // Send combined chunk to output stream
    resultStream.push(combinedBuffer);

    // Clear all buffers to free memory and prepare for next flush cycle
    rscInitializationBuffers.length = 0;
    htmlBuffers.length = 0;
    rscPayloadBuffers.length = 0;

    flushTimeout = null;
  };

  const endResultStream = () => {
    if (flushTimeout) clearTimeout(flushTimeout);
    flush();
    if (!resultStream.writableEnded) {
      resultStream.end();
    }
  };

  /**
   * Schedules a flush operation using setTimeout to batch multiple data arrivals.
   *
   * SCHEDULING STRATEGY:
   * - Uses setTimeout(flush, 0) to defer flush until the next event loop tick
   * - Batches multiple rapid data arrivals into single output chunks
   * - Provides optimal balance between latency and chunk efficiency
   */
  const scheduleFlush = () => {
    if (flushTimeout) {
      return;
    }

    flushTimeout = setTimeout(flush, 0);
  };

  /**
   * Initializes RSC payload streaming and handles component registration.
   *
   * RSC WORKFLOW:
   * 1. Components request RSC payloads via onRSCPayloadGenerated callback
   * 2. For each component, we immediately create a global array initialization script
   * 3. We then stream RSC payload chunks as they become available
   * 4. Each chunk is converted to a script that pushes data to the global array
   *
   * TIMING GUARANTEE:
   * - Array initialization scripts are buffered immediately when requested
   * - HTML rendering proceeds independently
   * - When HTML flushes, initialization scripts are sent first
   * - This ensures arrays exist before component hydration begins
   */
  const startRSC = async () => {
    try {
      const rscPromises: Promise<void>[] = [];

      rscRequestTracker.onRSCPayloadGenerated((streamInfo) => {
        const { stream, props, componentName } = streamInfo;
        const rscPayloadKey = createRSCPayloadKey(componentName, props, domNodeId);

        // CRITICAL TIMING: Initialize global array IMMEDIATELY when component requests RSC
        // This ensures the array exists before the component's HTML is rendered and sent.
        // Client-side hydration depends on this array being present in the page.
        //
        // The initialization script creates: (self.REACT_ON_RAILS_RSC_PAYLOADS||={})[cacheKey]||=[]
        // This creates a global array that the client-side RSCProvider monitors for new chunks.
        const initializationScript = createRSCPayloadInitializationScript(rscPayloadKey);
        rscInitializationBuffers.push(Buffer.from(initializationScript));

        // Process RSC payload stream asynchronously
        rscPromises.push(
          (async () => {
            for await (const chunk of stream ?? []) {
              const decodedChunk = typeof chunk === 'string' ? chunk : decoder.decode(chunk);
              const payloadScript = createRSCPayloadChunk(decodedChunk, rscPayloadKey);
              rscPayloadBuffers.push(Buffer.from(payloadScript));
              scheduleFlush();
            }
          })(),
        );
      });

      // Wait for HTML stream to complete, then wait for all RSC promises
      await finished(htmlStream).then(() => Promise.all(rscPromises));
    } catch {
      endResultStream();
    }
  };

  // ========================================
  // EVENT HANDLERS - Coordinate the three data sources
  // ========================================

  /**
   * HTML data handler - receives chunks from React's rendering stream.
   *
   * RESPONSIBILITIES:
   * - Buffer HTML chunks for coordinated flushing
   * - Track when first HTML chunk arrives (enables streaming)
   * - Initialize RSC processing on first HTML data
   * - Schedule flush to send combined data
   */
  htmlStream.on('data', (chunk: Buffer) => {
    htmlBuffers.push(chunk);
    hasReceivedFirstHtmlChunk = true;

    if (!rscPromise) {
      rscPromise = startRSC();
    }

    scheduleFlush();
  });

  /**
   * Prevent unhandled error crash. Error alone is not the end of the stream —
   * termination is handled by the 'close' event below.
   */
  htmlStream.on('error', () => {});

  /**
   * 'close' fires after both normal 'end' and destroy().
   * When htmlStream ends normally, readableEnded is true — the 'end' handler handles cleanup.
   * When htmlStream is destroyed (e.g., source stream failure), readableEnded stays false
   * and 'end' never fires — this handler ensures resultStream is still properly terminated.
   */
  htmlStream.on('close', () => {
    if (!htmlStream.readableEnded && !resultStream.writableEnded) {
      endResultStream();
    }
  });

  /**
   * HTML stream completion handler.
   *
   * CLEANUP RESPONSIBILITIES:
   * - Cancel any pending flush timeout
   * - Perform final flush to send remaining buffered data
   * - Wait for RSC processing to complete
   * - Clean up RSC payload streams
   * - Close result stream
   */
  htmlStream.on('end', () => {
    const cleanup = () => {
      endResultStream();
    };

    if (!rscPromise) {
      cleanup();
      return;
    }

    rscPromise
      .then(cleanup)
      .finally(() => {
        rscRequestTracker.clear();
      })
      .catch(() => endResultStream());
  });

  return resultStream;
}
