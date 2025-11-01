import {
  RSCPayloadStreamInfo,
  RSCPayloadCallback,
  RailsContextWithServerComponentMetadata,
} from '../types/index.ts';
/**
 * Global function provided by React on Rails Pro for generating RSC payloads.
 *
 * This function is injected into the global scope during server-side rendering
 * by the RORP rendering request. It handles the actual generation of React Server
 * Component payloads on the server side.
 *
 * @see https://github.com/shakacode/react_on_rails_pro/blob/master/lib/react_on_rails_pro/server_rendering_js_code.rb
 */
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
declare class RSCRequestTracker {
  private streams;

  private callbacks;

  private railsContext;

  constructor(railsContext: RailsContextWithServerComponentMetadata);

  /**
   * Clears all streams and callbacks for this request.
   * Should be called when the request is complete to ensure proper cleanup,
   * though garbage collection will handle cleanup automatically when the tracker goes out of scope.
   *
   * This method is safe to call multiple times and will handle any errors during cleanup gracefully.
   */
  clear(): void;

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
  onRSCPayloadGenerated(callback: RSCPayloadCallback): void;

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
   * @throws Error if generateRSCPayload is not available or fails
   */
  getRSCPayloadStream(componentName: string, props: unknown): Promise<NodeJS.ReadableStream>;

  /**
   * Returns all RSC payload streams tracked by this request tracker.
   * Used by the server renderer to access all fetched RSCs for this request.
   *
   * @returns Array of RSC payload stream information
   */
  getRSCPayloadStreams(): RSCPayloadStreamInfo[];
}
export default RSCRequestTracker;
