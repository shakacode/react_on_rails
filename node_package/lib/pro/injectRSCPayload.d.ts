import { PassThrough } from 'stream';
import { PipeableOrReadableStream } from '../types/index.ts';
import RSCRequestTracker from './RSCRequestTracker.ts';
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
): PassThrough;
