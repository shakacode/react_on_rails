import { PassThrough, Readable } from 'stream';
import {
  RSCPayloadStreamInfo,
  RSCPayloadCallback,
  RailsContextWithServerComponentMetadata,
} from './types/index.ts';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: unknown,
    railsContext: RailsContextWithServerComponentMetadata,
  ): Promise<NodeJS.ReadableStream>;
}

/**
 * RSC Request Tracker - manages RSC payload generation and tracking for a single request.
 *
 * This class provides a local alternative to the global RSC payload management,
 * allowing each request to have its own isolated tracker without sharing state.
 * It includes both tracking functionality for the server renderer and fetching
 * functionality for components.
 */
class RSCRequestTracker {
  private streams: RSCPayloadStreamInfo[] = [];

  private callbacks: RSCPayloadCallback[] = [];

  private railsContext: RailsContextWithServerComponentMetadata;

  constructor(railsContext: RailsContextWithServerComponentMetadata) {
    this.railsContext = railsContext;
  }

  /**
   * Clears all streams and callbacks for this request.
   * Should be called when the request is complete to ensure proper cleanup,
   * though garbage collection will handle cleanup automatically when the tracker goes out of scope.
   */
  clear(): void {
    // Close any active streams before clearing
    this.streams.forEach(({ stream }) => {
      if (typeof (stream as Readable).destroy === 'function') {
        (stream as Readable).destroy();
      }
    });

    this.streams = [];
    this.callbacks = [];
  }

  /**
   * Registers a callback to be executed when RSC payloads are generated.
   *
   * This function:
   * 1. Stores the callback function for this tracker
   * 2. Immediately executes the callback for any existing streams
   *
   * This synchronous execution is critical for preventing hydration race conditions.
   * It ensures payload array initialization happens before component HTML appears
   * in the response stream.
   *
   * @param callback - Function to call when an RSC payload is generated
   */
  onRSCPayloadGenerated(callback: RSCPayloadCallback): void {
    this.callbacks.push(callback);

    // Call callback for any existing streams
    this.streams.forEach(callback);
  }

  /**
   * Generates and tracks RSC payloads for server components.
   *
   * getRSCPayloadStream:
   * 1. Calls the provided generateRSCPayload function
   * 2. Tracks streams in this tracker for later access
   * 3. Notifies callbacks immediately to enable early payload embedding
   *
   * The immediate callback notification is critical for preventing hydration race conditions,
   * as it ensures the payload array is initialized in the HTML stream before component rendering.
   *
   * @param componentName - Name of the server component
   * @param props - Props for the server component
   * @returns A stream of the RSC payload
   */
  async getRSCPayloadStream(componentName: string, props: unknown): Promise<NodeJS.ReadableStream> {
    const stream = await generateRSCPayload(componentName, props, this.railsContext);

    // Tee stream to allow for multiple consumers:
    //   1. stream1 - Used by React's runtime to perform server-side rendering
    //   2. stream2 - Used by react-on-rails to embed the RSC payloads
    //      into the HTML stream for client-side hydration
    const stream1 = new PassThrough();
    stream.pipe(stream1);
    const stream2 = new PassThrough();
    stream.pipe(stream2);

    const streamInfo: RSCPayloadStreamInfo = {
      componentName,
      props,
      stream: stream2,
    };

    this.streams.push(streamInfo);

    // Notify callbacks about the new stream in a sync manner to maintain proper hydration timing
    this.callbacks.forEach((callback) => callback(streamInfo));

    return stream1;
  }

  /**
   * Returns all RSC payload streams tracked by this request tracker.
   * Used by the server renderer to access all fetched RSCs for this request.
   *
   * @returns Array of RSC payload stream information
   */
  getRSCPayloadStreams(): RSCPayloadStreamInfo[] {
    return [...this.streams]; // Return a copy to prevent external mutation
  }
}

export default RSCRequestTracker;
