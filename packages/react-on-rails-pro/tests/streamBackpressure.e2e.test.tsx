/**
 * @jest-environment node
 */

/**
 * E2E tests for RSC stream backpressure when payloads exceed the default highWaterMark.
 *
 * These tests exercise the FULL rendering pipeline:
 *   streamServerRenderedReactComponent
 *     → createReactOutput (render function)
 *     → RSCRequestTracker.getRSCPayloadStream (event-based tee)
 *     → renderToPipeableStream (React SSR)
 *     → injectRSCPayload (RSC script embedding)
 *     → result stream (JSON chunks with HTML + RSC payloads)
 *
 * When the RSC payload exceeds the default highWaterMark (~32KB across readable + writable
 * buffers), pipe() pauses the source stream. If the render function must read ALL data from
 * stream1 before producing a React element, and stream2 is not yet consumed, the source
 * pause stalls stream1, preventing the render function from completing.
 */
import * as React from 'react';
import { PassThrough } from 'stream';
import streamServerRenderedReactComponent from '../src/streamServerRenderedReactComponent.ts';
import * as ComponentRegistry from '../src/ComponentRegistry.ts';
import ReactOnRails from '../src/ReactOnRails.node.ts';

const HIGHWATER_MARK = 16 * 1024; // Node.js default PassThrough highWaterMark: 16KB

const testingRailsContext = {
  serverSideRSCPayloadParameters: {},
  reactClientManifestFileName: 'clientManifest.json',
  reactServerClientManifestFileName: 'serverClientManifest.json',
  componentSpecificMetadata: {
    renderRequestId: '123',
  },
} as any;

// Collect all JSON chunks from the result stream into parsed objects.
// streamServerRenderedReactComponent emits JSON objects: {html, consoleReplayScript, hasErrors, isShellReady}
const collectChunks = (
  stream: NodeJS.ReadableStream,
): Promise<{ html: string; hasErrors: boolean; isShellReady: boolean }[]> =>
  new Promise((resolve, reject) => {
    const chunks: { html: string; hasErrors: boolean; isShellReady: boolean }[] = [];
    stream.on('data', (chunk: Buffer) => {
      const text = new TextDecoder().decode(chunk);
      // A single data event may contain multiple JSON objects separated by newlines
      for (const line of text.split('\n').filter(Boolean)) {
        chunks.push(JSON.parse(line));
      }
    });
    stream.on('end', () => resolve(chunks));
    stream.on('error', reject);
  });

describe('streamServerRenderedReactComponent - RSC payload exceeding default highWaterMark (e2e)', () => {
  let source: PassThrough;

  beforeEach(() => {
    ComponentRegistry.components().clear();
    source = new PassThrough();
    (globalThis as any).generateRSCPayload = jest.fn().mockResolvedValue(source);
  });

  afterEach(() => {
    delete (globalThis as any).generateRSCPayload;
  });

  const renderComponent = (name: string) =>
    streamServerRenderedReactComponent({
      name,
      domNodeId: `${name}-node`,
      trace: false,
      props: {},
      throwJsErrors: true,
      railsContext: testingRailsContext,
    } as any);

  // Helper: register a render function whose returned Promise reads ALL data from the RSC
  // payload stream before resolving to a React element. This simulates what
  // getReactServerComponent does: read the entire RSC Flight stream via createFromNodeStream,
  // then return the decoded React element tree for SSR.
  //
  // Because the render function's Promise must resolve before renderToPipeableStream is called,
  // the shell rendering is BLOCKED until all RSC data is consumed. This is the scenario
  // that triggers backpressure issues when the payload exceeds stream2's buffer capacity.
  const registerRSCRenderFunction = (name: string) => {
    ReactOnRails.register({
      [name]: (_props: Record<string, unknown>, railsContext: any) =>
        railsContext
          .getRSCPayloadStream('ServerComponent', _props)
          .then(async (rscStream: AsyncIterable<Buffer>) => {
            // Read all data from stream1 — mirrors createFromNodeStream reading the Flight stream
            const chunks: Buffer[] = [];
            for await (const chunk of rscStream) {
              chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
            }
            const totalBytes = Buffer.concat(chunks).length;
            return React.createElement(
              'div',
              { 'data-testid': 'rsc-content' },
              `RSC payload: ${totalBytes} bytes`,
            );
          }),
    });
  };

  it('completes with RSC payload scripts for payloads under the default highWaterMark', async () => {
    registerRSCRenderFunction('SmallRSCComponent');

    // Push a small payload — fits within stream2's buffer, no backpressure risk
    const payload = 'x'.repeat(1024);
    source.push(payload);
    source.push(null);

    const renderResult = renderComponent('SmallRSCComponent');

    const chunks = await collectChunks(renderResult);
    const allHtml = chunks.map((c) => c.html).join('');

    // Verify the component rendered with the RSC data
    expect(allHtml).toContain('rsc-content');
    expect(allHtml).toContain('RSC payload: 1024 bytes');

    // Verify RSC payload initialization and data scripts are embedded
    expect(allHtml).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
    expect(allHtml).toContain('.push(');
  });

  // Tests the edge case where the RSC Flight payload significantly exceeds the default
  // highWaterMark (16KB). A PassThrough has ~32KB of combined buffer capacity (readable +
  // writable). When the payload exceeds this, pipe() pauses the source. If the render
  // function must consume the full stream before producing a React element, and stream2
  // is not yet being read by injectRSCPayload, source stalling blocks stream1.
  it('does not deadlock when multi-chunk RSC payload exceeds stream2 buffer capacity (128KB)', async () => {
    registerRSCRenderFunction('LargeRSCComponent');

    // Push 128KB as 1KB chunks — simulates a large server component (e.g., a blog post
    // with syntax-highlighted code blocks). This exceeds stream2's ~32KB combined buffer
    // (16KB readable + 16KB writable).
    const chunkSize = 1024;
    const chunkCount = 128;
    const totalBytes = chunkSize * chunkCount;
    const chunk = Buffer.alloc(chunkSize, 0x61); // fill with 'a'
    for (let i = 0; i < chunkCount; i++) {
      source.push(chunk);
    }
    source.push(null);

    const renderResult = renderComponent('LargeRSCComponent');

    const chunks = await collectChunks(renderResult);
    const allHtml = chunks.map((c) => c.html).join('');

    expect(allHtml).toContain('rsc-content');
    expect(allHtml).toContain(`RSC payload: ${totalBytes} bytes`);
    expect(allHtml).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
    expect(allHtml).toContain('.push(');
  }, 5000);

  // Same as above but with data pushed asynchronously — more closely simulates a real
  // generateRSCPayload function that produces chunks over time as the RSC renderer works.
  it('does not deadlock when large RSC payload chunks arrive asynchronously', async () => {
    registerRSCRenderFunction('AsyncRSCComponent');

    const renderResult = renderComponent('AsyncRSCComponent');

    // Drip-feed 128KB over ~128ms — chunks arrive asynchronously after rendering starts.
    // This exercises the timing-sensitive path where pipe() distribution interleaves
    // with React rendering and event loop ticks.
    const chunkSize = 1024;
    const chunkCount = 128;
    const totalBytes = chunkSize * chunkCount;
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

    const chunks = await collectChunks(renderResult);
    const allHtml = chunks.map((c) => c.html).join('');

    expect(allHtml).toContain('rsc-content');
    expect(allHtml).toContain(`RSC payload: ${totalBytes} bytes`);
    expect(allHtml).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
  }, 10000);

  // Tests the boundary condition: payload just above ~32KB combined buffer capacity.
  // This is the minimal payload size that triggers backpressure in stream2.
  it('does not deadlock when RSC payload is just above stream2 buffer capacity (48KB)', async () => {
    registerRSCRenderFunction('BorderlineRSCComponent');

    // Push exactly 48KB — just above the ~32KB combined buffer capacity.
    const chunkSize = 1024;
    const chunkCount = 48;
    const totalBytes = chunkSize * chunkCount;
    const chunk = Buffer.alloc(chunkSize, 0x63); // fill with 'c'
    for (let i = 0; i < chunkCount; i++) {
      source.push(chunk);
    }
    source.push(null);

    const renderResult = renderComponent('BorderlineRSCComponent');

    const chunks = await collectChunks(renderResult);
    const allHtml = chunks.map((c) => c.html).join('');

    expect(allHtml).toContain('rsc-content');
    expect(allHtml).toContain(`RSC payload: ${totalBytes} bytes`);
    expect(allHtml).toContain('REACT_ON_RAILS_RSC_PAYLOADS');
  }, 5000);
});
