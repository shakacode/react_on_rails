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
export default function transformRSCStream(stream: NodeJS.ReadableStream): NodeJS.ReadableStream;
