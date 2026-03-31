/**
 * Test utility that wraps the production LengthPrefixedStreamParser with a
 * convenience API for collecting parsed chunks. Uses the same parser as
 * production code — no duplicated parsing logic.
 */

// eslint-disable-next-line import/no-relative-packages
import ProductionParser from '../../react-on-rails-pro/src/parseLengthPrefixedStream';

export interface ParsedChunk {
  html: string;
  consoleReplayScript?: string;
  hasErrors?: boolean;
  isShellReady?: boolean;
  renderingError?: { message: string; stack: string };
  [key: string]: unknown;
}

export class LengthPrefixedStreamParser {
  private parser = new ProductionParser();

  readonly htmlChunks: string[] = [];

  readonly parsedChunks: ParsedChunk[] = [];

  feed(data: string | Buffer): void {
    const buf = typeof data === 'string' ? Buffer.from(data, 'utf8') : data;
    this.parser.feed(buf, (content, metadata) => {
      const html = new TextDecoder().decode(content);
      this.htmlChunks.push(html);
      this.parsedChunks.push({ html, ...metadata } as ParsedChunk);
    });
  }
}
