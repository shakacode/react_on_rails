/**
 * Parses a length-prefixed streaming response into content chunks and metadata.
 *
 * Supports two formats:
 * 1. Length-prefixed: <metadata JSON>\t<hex length>\n<raw content bytes>
 * 2. Legacy NDJSON: <JSON line>\n (backward compatible)
 *
 * Format is auto-detected per line: if a header line contains \t, it's length-prefixed.
 */

export interface ParsedChunk {
  html: string;
  consoleReplayScript?: string;
  hasErrors?: boolean;
  isShellReady?: boolean;
  renderingError?: { message: string; stack: string };
  [key: string]: unknown;
}

export class LengthPrefixedStreamParser {
  private buf: Buffer = Buffer.alloc(0);

  private state: 'header' | 'content' = 'header';

  private contentLen = 0;

  private metadata: Record<string, unknown> | null = null;

  readonly htmlChunks: string[] = [];

  readonly parsedChunks: ParsedChunk[] = [];

  feed(data: string | Buffer): void {
    const buf = typeof data === 'string' ? Buffer.from(data, 'utf8') : data;
    this.buf = Buffer.concat([this.buf, buf]);
    this.drain();
  }

  private drain(): void {
    // eslint-disable-next-line no-constant-condition
    while (true) {
      if (this.state === 'header') {
        const idx = this.buf.indexOf(0x0a); // \n
        if (idx < 0) break;

        const header = this.buf.subarray(0, idx);
        this.buf = this.buf.subarray(idx + 1);
        const tabIdx = header.indexOf(0x09); // \t

        if (tabIdx >= 0) {
          const metaJson = header.subarray(0, tabIdx).toString('utf8');
          const lenHex = header.subarray(tabIdx + 1).toString('utf8');
          this.metadata = JSON.parse(metaJson);
          this.contentLen = parseInt(lenHex, 16);
          this.state = 'content';
        } else {
          // Legacy NDJSON
          const line = header.toString('utf8').trim();
          if (line.length > 0) {
            try {
              const parsed = JSON.parse(line) as ParsedChunk;
              this.htmlChunks.push(parsed.html || '');
              this.parsedChunks.push(parsed);
            } catch {
              this.htmlChunks.push(line);
            }
          }
        }
      } else {
        if (this.buf.length < this.contentLen) break;

        const content = this.buf.subarray(0, this.contentLen).toString('utf8');
        this.buf = this.buf.subarray(this.contentLen);
        const parsed = { html: content, ...this.metadata } as ParsedChunk;
        this.htmlChunks.push(content);
        this.parsedChunks.push(parsed);
        this.metadata = null;
        this.state = 'header';
      }
    }
  }
}
