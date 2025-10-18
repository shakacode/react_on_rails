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
): ReadableStream;
