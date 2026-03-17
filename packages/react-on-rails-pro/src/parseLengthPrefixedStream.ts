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

/**
 * Parses a length-prefixed stream.
 *
 * Wire format per chunk:
 *   <metadata JSON>\t<content byte length hex>\n<raw content bytes>
 *
 * Handles buffer boundaries: a single feed() call may contain partial
 * headers, partial content, or multiple complete chunks merged together.
 */
export default class LengthPrefixedStreamParser {
  private buf = Buffer.alloc(0);

  private state: 'header' | 'content' = 'header';

  private contentLen = 0;

  private metadata: Record<string, unknown> = {};

  feed(
    chunk: Buffer | Uint8Array,
    onChunk: (content: Buffer, metadata: Record<string, unknown>) => void,
  ): void {
    this.buf = Buffer.concat([this.buf, chunk instanceof Buffer ? chunk : Buffer.from(chunk)]);

    let progressed = true;
    while (progressed) {
      progressed = false;
      if (this.state === 'header') {
        const idx = this.buf.indexOf(0x0a); // \n
        if (idx >= 0) {
          const header = this.buf.subarray(0, idx);
          this.buf = this.buf.subarray(idx + 1);
          const tabIdx = header.indexOf(0x09); // \t
          this.metadata = JSON.parse(header.subarray(0, tabIdx).toString('utf8'));
          this.contentLen = parseInt(header.subarray(tabIdx + 1).toString('utf8'), 16);
          this.state = 'content';
          progressed = true;
        }
      } else if (this.buf.length >= this.contentLen) {
        const content = this.buf.subarray(0, this.contentLen);
        this.buf = this.buf.subarray(this.contentLen);
        onChunk(content, this.metadata);
        this.state = 'header';
        progressed = true;
      }
    }
  }
}
