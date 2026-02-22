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
import {
  RSCPayloadStreamInfo,
  RSCPayloadCallback,
  RailsContextWithServerComponentMetadata,
} from 'react-on-rails/types';
import { extractErrorMessage } from './utils.ts';

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
class RSCRequestTracker {
  private streams: RSCPayloadStreamInfo[] = [];

  private callbacks: RSCPayloadCallback[] = [];

  private railsContext: RailsContextWithServerComponentMetadata;

  private keyPropsOverride?: unknown;

  constructor(railsContext: RailsContextWithServerComponentMetadata) {
    this.railsContext = railsContext;
  }

  /**
   * Sets a key props override for RSC payload cache key generation.
   *
   * When a PropsTransformer is configured, the server renders with full (transformed) props,
   * but the RSC payload cache key should use the original compact (key) props.
   * This override is consumed on the first getRSCPayloadStream call (the top-level RSC component)
   * and then reset, so nested RSC components use their own props for keys.
   *
   * @param keyProps - Compact props to use for the RSC payload cache key
   */
  setKeyPropsOverride(keyProps: unknown): void {
    this.keyPropsOverride = keyProps;
  }

  /**
   * Clears all streams and callbacks for this request.
   * Should be called when the request is complete to ensure proper cleanup,
   * though garbage collection will handle cleanup automatically when the tracker goes out of scope.
   *
   * This method is safe to call multiple times and will handle any errors during cleanup gracefully.
   */
  clear(): void {
    // Close any active streams before clearing
    this.streams.forEach(({ stream, componentName }, index) => {
      try {
        if (stream && typeof (stream as Readable).destroy === 'function') {
          (stream as Readable).destroy();
        }
      } catch (error) {
        // Log the error but don't throw to avoid disrupting cleanup of other streams
        console.warn(
          `Warning: Error while destroying RSC stream for component "${componentName}" at index ${index}:`,
          error,
        );
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
   * @throws Error if generateRSCPayload is not available or fails
   */
  async getRSCPayloadStream(componentName: string, props: unknown): Promise<NodeJS.ReadableStream> {
    // Validate that the global generateRSCPayload function is available
    if (typeof generateRSCPayload !== 'function') {
      throw new Error(
        'generateRSCPayload is not defined. Please ensure that you are using at least version 4.0.0 of ' +
          'React on Rails Pro and the Node renderer, and that ReactOnRailsPro.configuration.enable_rsc_support ' +
          'is set to true.',
      );
    }

    try {
      const stream = await generateRSCPayload(componentName, props, this.railsContext);

      // Tee stream to allow for multiple consumers:
      //   1. stream1 - Used by React's runtime to perform server-side rendering
      //   2. stream2 - Used by react-on-rails to embed the RSC payloads
      //      into the HTML stream for client-side hydration
      //
      // Manual forwarding via on('data') + push() is used instead of pipe() to
      // avoid backpressure coupling between the two destinations. With pipe(),
      // if either destination's buffer fills (e.g., stream2 is not consumed yet
      // because injectRSCPayload waits for the first HTML chunk), pipe() pauses
      // the source, which stalls BOTH destinations. With push(), each destination
      // buffers independently — stream1 keeps receiving data even if stream2's
      // buffer is full.
      const stream1 = new PassThrough();
      const stream2 = new PassThrough();
      stream.on('data', (chunk: Buffer) => {
        stream1.push(chunk);
        stream2.push(chunk);
      });
      stream.on('end', () => {
        stream1.push(null);
        stream2.push(null);
      });
      stream.on('error', (err: Error) => {
        stream1.destroy(err);
        stream2.destroy(err);
      });

      // Use keyPropsOverride for the first RSC component (top-level), then reset.
      // This ensures the RSC payload cache key uses compact (key) props when a
      // PropsTransformer is configured, while nested RSC components use their own props.
      const keyProps = this.keyPropsOverride;
      this.keyPropsOverride = undefined;

      const streamInfo: RSCPayloadStreamInfo = {
        componentName,
        props,
        keyProps,
        stream: stream2,
      };

      this.streams.push(streamInfo);

      // Notify callbacks about the new stream in a sync manner to maintain proper hydration timing
      this.callbacks.forEach((callback) => callback(streamInfo));

      return stream1;
    } catch (error) {
      // Provide a more helpful error message that includes context
      throw new Error(
        `Failed to generate RSC payload for component "${componentName}": ${extractErrorMessage(error)}`,
      );
    }
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
