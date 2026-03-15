import { PassThrough } from 'stream';
import type { Readable } from 'stream';

/**
 * Converts an NDJSON stream to the length-prefixed streaming protocol.
 *
 * NDJSON input format (per line):
 *   {"html":"...","consoleReplayScript":"...","hasErrors":false,"isShellReady":true}\n
 *
 * Length-prefixed output format (per chunk):
 *   <metadata JSON>\t<content byte length hex>\n<raw content bytes>
 *
 * The metadata JSON contains all fields EXCEPT "html". The HTML content is sent
 * as raw bytes with a length prefix, avoiding JSON.stringify escaping overhead.
 *
 * This conversion happens at the HTTP response boundary so that internal Node.js
 * consumers (RSC tee, injectRSCPayload, transformRSCNodeStream) continue to
 * receive the original NDJSON format.
 */
export default function ndjsonToLengthPrefixed(ndjsonStream: Readable): Readable {
  let lastIncompleteChunk = '';

  const output = new PassThrough({
    transform(chunk: Buffer, _, callback) {
      try {
        const decoded = lastIncompleteChunk + chunk.toString('utf8');
        const lines = decoded.split('\n');
        lastIncompleteChunk = lines.pop() ?? '';

        const nonEmptyLines = lines.filter((line) => line.trim() !== '');
        for (const line of nonEmptyLines) {
          const parsed = JSON.parse(line);
          const { html, ...metadata } = parsed;
          const htmlContent = html ?? '';
          const contentBuf = Buffer.from(htmlContent, 'utf8');
          const metaJson = JSON.stringify(metadata);
          const header = `${metaJson}\t${contentBuf.length.toString(16).padStart(8, '0')}\n`;

          this.push(Buffer.concat([Buffer.from(header, 'utf8'), contentBuf]));
        }
        callback();
      } catch (error) {
        callback(error as Error);
      }
    },

    flush(callback) {
      try {
        if (lastIncompleteChunk.trim() !== '') {
          const parsed = JSON.parse(lastIncompleteChunk);
          const { html, ...metadata } = parsed;
          const htmlContent = html ?? '';
          const contentBuf = Buffer.from(htmlContent, 'utf8');
          const metaJson = JSON.stringify(metadata);
          const header = `${metaJson}\t${contentBuf.length.toString(16).padStart(8, '0')}\n`;

          this.push(Buffer.concat([Buffer.from(header, 'utf8'), contentBuf]));
        }
        callback();
      } catch (error) {
        callback(error as Error);
      }
    },
  });

  ndjsonStream.pipe(output);
  ndjsonStream.on('error', (err) => output.destroy(err));

  return output;
}
