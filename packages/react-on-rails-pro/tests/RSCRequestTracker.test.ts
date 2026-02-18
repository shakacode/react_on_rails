/**
 * @jest-environment node
 */
import { PassThrough, Transform } from 'stream';
import { RailsContextWithServerComponentMetadata } from 'react-on-rails/types';
import RSCRequestTracker from '../src/RSCRequestTracker.ts';
import injectRSCPayload from '../src/injectRSCPayload.ts';

const HIGHWATER_MARK = 16 * 1024; // Node.js default PassThrough highWaterMark: 16KB

const createTracker = () => {
  const railsContext = {} as RailsContextWithServerComponentMetadata;
  return new RSCRequestTracker(railsContext);
};

// Helper: create a PassThrough that we control manually as the "source" RSC stream.
// generateRSCPayload resolves with this stream, then we push chunks into it.
const setupSourceStream = () => {
  const source = new PassThrough();
  (globalThis as any).generateRSCPayload = jest.fn().mockResolvedValue(source);
  return source;
};

// Push `totalBytes` of data into a stream as individual `chunkSize`-byte chunks, then end it.
const pushChunks = (stream: PassThrough, totalBytes: number, chunkSize = 1024) => {
  const chunk = Buffer.alloc(chunkSize, 0x61); // fill with 'a'
  const count = Math.ceil(totalBytes / chunkSize);
  for (let i = 0; i < count; i++) {
    stream.push(chunk);
  }
  stream.push(null);
  return count * chunkSize;
};

const collectStreamData = async (stream: NodeJS.ReadableStream): Promise<Buffer> => {
  const chunks: Buffer[] = [];
  for await (const chunk of stream as AsyncIterable<Buffer>) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
};

// Simulates what React's renderToPipeableStream does: reads the RSC Flight stream (stream1)
// and produces HTML output. In a real app, React uses stream1 to resolve server component
// references and renders them to HTML. Here we just wrap the raw bytes in an HTML shell,
// since the important thing is that stream1 is consumed and HTML is produced.
const createSimulatedSSR = (rscStream: NodeJS.ReadableStream) => {
  let firstChunk = true;
  const htmlTransform = new Transform({
    transform(chunk, _encoding, callback) {
      if (firstChunk) {
        this.push(Buffer.from('<html><body>'));
        firstChunk = false;
      }
      // Each RSC chunk becomes a piece of "rendered HTML"
      this.push(Buffer.from(`<div data-rsc-chunk="${chunk.length}"></div>`));
      callback();
    },
    flush(callback) {
      this.push(Buffer.from('</body></html>'));
      callback();
    },
  });
  (rscStream as NodeJS.ReadableStream).pipe(htmlTransform);
  return htmlTransform;
};

// Simulates React SSR that requires accumulating a minimum amount of Flight data before
// it can render the shell and start producing HTML. This models the real behavior:
// React's renderToPipeableStream reads the RSC Flight stream and must parse enough of
// the component tree before onShellReady fires and HTML starts flowing.
//
// For large server components (e.g., blog posts with syntax-highlighted code), the Flight
// payload for the shell can exceed the default highWaterMark. When stream2 fills up and
// pauses the source, this Transform never receives enough data to start producing HTML.
const createDelayedSSR = (rscStream: NodeJS.ReadableStream, shellThreshold: number) => {
  let receivedBytes = 0;
  let shellReady = false;
  const htmlTransform = new Transform({
    transform(chunk, _encoding, callback) {
      receivedBytes += chunk.length;
      if (!shellReady && receivedBytes >= shellThreshold) {
        shellReady = true;
        this.push(Buffer.from('<html><body>'));
      }
      if (shellReady) {
        this.push(Buffer.from(`<div data-rsc-chunk="${chunk.length}"></div>`));
      }
      // Data is accepted (callback called) whether or not HTML is produced yet.
      // This mirrors React's behavior: it reads Flight data eagerly but only
      // produces HTML after the shell is built.
      callback();
    },
    flush(callback) {
      if (!shellReady) {
        this.push(Buffer.from('<html><body>'));
      }
      this.push(Buffer.from('</body></html>'));
      callback();
    },
  });
  (rscStream as NodeJS.ReadableStream).pipe(htmlTransform);
  return htmlTransform;
};

afterEach(() => {
  delete (globalThis as any).generateRSCPayload;
});

describe('RSCRequestTracker', () => {
  describe('getRSCPayloadStream tee behavior', () => {
    it('delivers data to both stream1 and stream2 for payloads under the default highWaterMark', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('TestComponent', {});
      const stream2 = tracker.getRSCPayloadStreams()[0].stream;

      const totalBytes = pushChunks(source, 100);

      const [data1, data2] = await Promise.all([
        collectStreamData(stream1),
        collectStreamData(stream2),
      ]);

      expect(data1.length).toBe(totalBytes);
      expect(data2.length).toBe(totalBytes);
    });

    // Tests that the tee handles payloads larger than the default highWaterMark (16KB)
    // without deadlocking when stream2 is not consumed immediately.
    //
    // In the real RSC rendering pipeline:
    //   1. Source RSC Flight stream is teed to stream1 (SSR) and stream2 (HTML embedding)
    //   2. stream1 is consumed immediately (SSR reads it to produce HTML)
    //   3. stream2 is NOT consumed yet (injectRSCPayload waits for first HTML chunk)
    //   4. When multi-chunk payload exceeds stream2's highWaterMark,
    //      pipe() pauses the source, which also starves stream1
    //
    // The tee must ensure stream1 receives all data regardless of stream2's consumption state.
    it('does not deadlock when multi-chunk payload exceeds the default highWaterMark and stream2 is not consumed', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('TestComponent', {});
      const stream2 = tracker.getRSCPayloadStreams()[0].stream;

      // Push 64KB as 1KB chunks — enough to overflow the 16KB default highWaterMark.
      // Multiple chunks are critical: pipe() can only pause between individual reads.
      const totalBytes = pushChunks(source, HIGHWATER_MARK * 4);

      // Only consume stream1 (SSR consumer). stream2 is deliberately not consumed,
      // simulating injectRSCPayload waiting for the first HTML chunk.
      const data1 = await collectStreamData(stream1);

      // Now consume stream2 — all buffered data should be available.
      const data2 = await collectStreamData(stream2);

      expect(data1.length).toBe(totalBytes);
      expect(data2.length).toBe(totalBytes);
    }, 5000);

    // Same scenario but with data pushed asynchronously (drip-fed via setTimeout),
    // which more closely simulates a real RSC Flight stream producing chunks over time.
    it('does not deadlock when chunks exceeding the default highWaterMark are pushed asynchronously', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('TestComponent', {});
      const stream2 = tracker.getRSCPayloadStreams()[0].stream;

      // Drip-feed 32 × 1KB chunks with 1ms intervals
      const chunkSize = 1024;
      const chunkCount = 32; // 32KB total > 16KB highWaterMark
      const chunk = Buffer.alloc(chunkSize, 0x62); // fill with 'b'
      let pushed = 0;
      const pushInterval = setInterval(() => {
        if (pushed >= chunkCount) {
          clearInterval(pushInterval);
          source.push(null);
          return;
        }
        source.push(chunk);
        pushed++;
      }, 1);

      const data1 = await collectStreamData(stream1);
      const data2 = await collectStreamData(stream2);

      expect(data1.length).toBe(chunkSize * chunkCount);
      expect(data2.length).toBe(chunkSize * chunkCount);
    }, 5000);
  });

  // Integration tests: RSCRequestTracker + injectRSCPayload wired together.
  //
  // These test the rendering pipeline when the RSC payload exceeds the default
  // highWaterMark:
  //   source RSC stream → tee → stream1 → simulated SSR → HTML
  //                           → stream2 ← injectRSCPayload reads (after first HTML chunk)
  //   result stream = HTML interleaved with RSC payload <script> tags
  //
  // When stream2 fills, the source is paused, which starves stream1. If SSR cannot
  // produce HTML, injectRSCPayload never starts reading stream2, causing a stall.
  describe('integration with injectRSCPayload', () => {
    it('produces output with RSC payload scripts for payloads under the default highWaterMark', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('TestComponent', { id: 1 });
      const htmlStream = createSimulatedSSR(stream1);

      // Wire up injectRSCPayload — this is the real function, not a mock.
      // It waits for the first HTML chunk, then starts consuming stream2 (from tracker).
      const resultStream = injectRSCPayload(htmlStream, tracker, 'app-node');

      // Push a small RSC payload (under 16KB) — no backpressure risk
      const payload = '{"type":"div","props":{"children":"hello"}}';
      source.push(payload);
      source.push(null);

      const result = (await collectStreamData(resultStream)).toString();

      // Output must contain the HTML from simulated SSR
      expect(result).toContain('<html><body>');
      expect(result).toContain('</body></html>');

      // Output must contain the RSC payload initialization and data scripts
      expect(result).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
      expect(result).toContain('.push(');
      expect(result).toContain(JSON.stringify(payload));
    });

    it('does not deadlock with large multi-chunk payloads exceeding the default highWaterMark', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('BlogPost', { id: 42 });
      const htmlStream = createSimulatedSSR(stream1);
      const resultStream = injectRSCPayload(htmlStream, tracker, 'blog-node');

      // Push 64KB as 1KB chunks — simulates a large RSC Flight payload (e.g., a blog post
      // with syntax-highlighted code blocks rendered via marked + highlight.js).
      // This exceeds the default 16KB highWaterMark.
      const chunkCount = 64;
      const chunkSize = 1024;
      const chunk = 'z'.repeat(chunkSize);
      for (let i = 0; i < chunkCount; i++) {
        source.push(chunk);
      }
      source.push(null);

      const result = (await collectStreamData(resultStream)).toString();

      expect(result).toContain('<html><body>');
      expect(result).toContain('</body></html>');
      expect(result).toContain('REACT_ON_RAILS_RSC_PAYLOADS');

      // Every chunk should be embedded as a .push() script
      // (the exact count may vary due to flush batching, but all data must be present)
      const pushCount = (result.match(/\.push\(/g) || []).length;
      expect(pushCount).toBeGreaterThanOrEqual(1);
    }, 5000);

    it('does not deadlock when chunks exceeding the default highWaterMark are drip-fed asynchronously', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('Dashboard', {});
      const htmlStream = createSimulatedSSR(stream1);
      const resultStream = injectRSCPayload(htmlStream, tracker, 'dash-node');

      // Drip-feed 32KB over 32ms — simulates a real RSC stream producing chunks over time
      const chunkSize = 1024;
      const chunkCount = 32;
      const chunk = 'q'.repeat(chunkSize);
      let pushed = 0;
      const pushInterval = setInterval(() => {
        if (pushed >= chunkCount) {
          clearInterval(pushInterval);
          source.push(null);
          return;
        }
        source.push(chunk);
        pushed++;
      }, 1);

      const result = (await collectStreamData(resultStream)).toString();

      expect(result).toContain('<html><body>');
      expect(result).toContain('REACT_ON_RAILS_RSC_PAYLOADS');

      const pushCount = (result.match(/\.push\(/g) || []).length;
      expect(pushCount).toBeGreaterThanOrEqual(1);
    }, 5000);

    // Tests the edge case where SSR requires more Flight data than stream2's buffer
    // can hold before producing any HTML output.
    //
    // In a real React SSR pipeline, renderToPipeableStream reads the RSC Flight stream
    // and must parse enough data to build the component tree before producing HTML
    // (onShellReady). For a complex server component (e.g., a blog post with
    // syntax-highlighted code), the shell may require a large amount of Flight data.
    //
    // A PassThrough stream has TWO internal buffers that can absorb data before pipe()
    // returns false: the readable buffer (highWaterMark = 16KB) fills first, then
    // subsequent writes stall in the writable buffer (also 16KB). pipe() only pauses
    // the source when write() returns false, which requires BOTH buffers to fill.
    // This means ~32KB of data flows to each destination before the source is paused.
    //
    // When SSR needs more Flight data than ~32KB to render the shell:
    //   1. Source pushes multi-chunk Flight data into pipe()
    //   2. pipe() writes to stream1 (SSR) and stream2 (payload embedding)
    //   3. stream2's readable buffer fills at 16KB, then writable buffer fills at 16KB
    //   4. After ~32KB, stream2.write() returns false → pipe() pauses the source
    //   5. SSR received ~32KB but needs more to render the shell → no HTML produced
    //   6. injectRSCPayload doesn't start → stream2 never consumed → stall
    it('does not deadlock when SSR needs more Flight data than stream2 can buffer', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('BlogPost', { id: 1 });

      // SSR requires 48KB of Flight data before producing HTML (shell threshold).
      // stream2 can absorb ~32KB (16KB readable + 16KB writable) before pipe() pauses.
      // With 48KB threshold > 32KB buffer, SSR never gets enough data.
      const shellThreshold = HIGHWATER_MARK * 3; // 48KB, well above the ~32KB pause point
      const htmlStream = createDelayedSSR(stream1, shellThreshold);
      const resultStream = injectRSCPayload(htmlStream, tracker, 'blog-node');

      // Push 128KB as 1KB chunks
      const totalBytes = pushChunks(source, HIGHWATER_MARK * 8);

      const result = (await collectStreamData(resultStream)).toString();

      expect(result).toContain('<html><body>');
      expect(result).toContain('</body></html>');
      expect(result).toContain('REACT_ON_RAILS_RSC_PAYLOADS');

      const pushCount = (result.match(/\.push\(/g) || []).length;
      expect(pushCount).toBeGreaterThanOrEqual(1);
    }, 5000);

    it('does not deadlock when SSR needs >32KB and chunks arrive asynchronously', async () => {
      const source = setupSourceStream();
      const tracker = createTracker();

      const stream1 = await tracker.getRSCPayloadStream('Dashboard', {});
      const shellThreshold = HIGHWATER_MARK * 3; // 48KB
      const htmlStream = createDelayedSSR(stream1, shellThreshold);
      const resultStream = injectRSCPayload(htmlStream, tracker, 'dash-node');

      // Drip-feed 128KB over ~128ms
      const chunkSize = 1024;
      const chunkCount = 128;
      const chunk = 'r'.repeat(chunkSize);
      let pushed = 0;
      const pushInterval = setInterval(() => {
        if (pushed >= chunkCount) {
          clearInterval(pushInterval);
          source.push(null);
          return;
        }
        source.push(chunk);
        pushed++;
      }, 1);

      const result = (await collectStreamData(resultStream)).toString();

      expect(result).toContain('<html><body>');
      expect(result).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
    }, 5000);
  });
});
