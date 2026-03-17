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
 *
 * Environment-agnostic: works with both Node.js Buffer and browser Uint8Array.
 */

const decoder = new TextDecoder();

function concatBytes(a: Uint8Array, b: Uint8Array): Uint8Array {
  const result = new Uint8Array(a.length + b.length);
  result.set(a);
  result.set(b, a.length);
  return result;
}

export default class LengthPrefixedStreamParser {
  private buf: Uint8Array = new Uint8Array(0);

  private state: 'header' | 'content' = 'header';

  private contentLen = 0;

  private metadata: Record<string, unknown> = {};

  feed(chunk: Uint8Array, onChunk: (content: Uint8Array, metadata: Record<string, unknown>) => void): void {
    this.buf = concatBytes(this.buf, chunk);

    let progressed = true;
    while (progressed) {
      progressed = false;
      if (this.state === 'header') {
        const idx = this.buf.indexOf(0x0a); // \n
        if (idx >= 0) {
          const header = this.buf.subarray(0, idx);
          this.buf = this.buf.subarray(idx + 1);
          const tabIdx = header.indexOf(0x09); // \t
          this.metadata = JSON.parse(decoder.decode(header.subarray(0, tabIdx)));
          this.contentLen = parseInt(decoder.decode(header.subarray(tabIdx + 1)), 16);
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
