import { Readable, PassThrough } from 'stream';
import { RailsContextWithServerStreamingCapabilities, StreamRenderState } from 'react-on-rails/types';
import injectRSCPayload from '../src/injectRSCPayload.ts';
import RSCRequestTracker from '../src/RSCRequestTracker.ts';

// Shared utilities
const createMockStream = (chunks: (string | Buffer)[] | { [key: number]: string | string[] }) => {
  if (Array.isArray(chunks)) {
    return Readable.from(
      chunks.map((chunk) => (typeof chunk === 'string' ? new TextEncoder().encode(chunk) : chunk)),
    );
  }
  const passThrough = new PassThrough();
  const entries = Object.entries(chunks);
  const keysLength = entries.length;
  entries.forEach(([delay, value], index) => {
    setTimeout(() => {
      const chunksArray = Array.isArray(value) ? value : [value];
      chunksArray.forEach((chunk) => {
        passThrough.push(new TextEncoder().encode(chunk));
      });
      if (index === keysLength - 1) {
        passThrough.push(null);
      }
    }, +delay);
  });
  return passThrough;
};

const collectStreamData = async (stream: Readable) => {
  const chunks: string[] = [];
  for await (const chunk of stream) {
    chunks.push(new TextDecoder().decode(chunk as Buffer));
  }
  return chunks.join('');
};

// Test setup helper
const setupTest = (mockRSC: Readable) => {
  const railsContext = {} as RailsContextWithServerStreamingCapabilities;
  const rscRequestTracker = new RSCRequestTracker(railsContext);
  jest.spyOn(rscRequestTracker, 'onRSCPayloadGenerated').mockImplementation((callback) => {
    callback({ stream: mockRSC, componentName: 'test', props: {} });
  });

  return { railsContext, rscRequestTracker, domNodeId: 'test-node' };
};

describe('injectRSCPayload', () => {
  it('should inject RSC payload as script tags', async () => {
    const mockRSC = createMockStream(['{"test": "data"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data\\"}")</script>`,
    );
  });

  it('should handle multiple RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data\\"}")</script>`,
    );
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data2\\"}")</script>`,
    );
  });

  it('should add all ready html chunks before adding RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream([
      '<html><body><div>Hello, world!</div></body></html>',
      '<div>Next chunk</div>',
    ]);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]</script>' +
        '<html><body><div>Hello, world!</div></body></html>' +
        '<div>Next chunk</div>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data2\\"}")</script>',
    );
  });

  it('adds delayed html chunks after RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream({
      0: '<html><body><div>Hello, world!</div></body></html>',
      100: '<div>Next chunk</div>',
    });
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]</script>' +
        '<html><body><div>Hello, world!</div></body></html>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
        '<div>Next chunk</div>',
    );
  });

  it('handles the case when html is delayed', async () => {
    const mockRSC = createMockStream({
      0: '{"test": "data"}',
      150: '{"test": "data2"}',
    });
    const mockHTML = createMockStream({
      100: ['<html><body><div>Hello, world!</div></body></html>', '<div>Next chunk</div>'],
      200: '<div>Third chunk</div>',
    });
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]</script>' +
        '<html><body><div>Hello, world!</div></body></html>' +
        '<div>Next chunk</div>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
        '<div>Third chunk</div>',
    );
  });
});

describe('injectRSCPayload renderState management', () => {
  const createRenderState = (overrides: Partial<StreamRenderState> = {}): StreamRenderState => ({
    result: null,
    hasErrors: false,
    isShellReady: true,
    ...overrides,
  });

  // Setup that simulates the real RSC flow: onRSCPayloadGenerated fires
  // asynchronously when generateRSCPayload resolves (after the first HTML chunk).
  const setupDelayedRSCTest = (mockRSC: Readable, rscDelay: number = 50) => {
    const railsContext = {} as RailsContextWithServerStreamingCapabilities;
    const rscRequestTracker = new RSCRequestTracker(railsContext);
    jest.spyOn(rscRequestTracker, 'onRSCPayloadGenerated').mockImplementation((callback) => {
      // Simulate async RSC payload generation — fires after rscDelay ms
      setTimeout(() => {
        callback({ stream: mockRSC, componentName: 'test', props: {} });
      }, rscDelay);
    });
    return { rscRequestTracker, domNodeId: 'test-node' };
  };

  it('sets isShellReady to false when RSC payload is detected', async () => {
    const mockRSC = createMockStream(['{"data": "ok"}']);
    const renderState = createRenderState({ isShellReady: true });
    const { rscRequestTracker, domNodeId } = setupDelayedRSCTest(mockRSC, 10);

    // Shell chunk at t=0, post-shell chunk at t=100 (after RSC resolves at t=10)
    const mockHTML = createMockStream({
      0: '<div>shell</div>',
      100: '<div>content</div>',
    });

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId, renderState);

    // After shell chunk but before RSC fires, isShellReady should still be true
    await new Promise((resolve) => {
      setTimeout(resolve, 5);
    });
    expect(renderState.isShellReady).toBe(true);

    // After RSC payload is detected (~10ms), isShellReady should be false
    await new Promise((resolve) => {
      setTimeout(resolve, 20);
    });
    expect(renderState.isShellReady).toBe(false);

    await collectStreamData(result);
  });

  it('restores isShellReady to true on successful post-shell chunk', async () => {
    const mockRSC = createMockStream(['{"data": "ok"}']);
    const renderState = createRenderState({ isShellReady: true });
    const { rscRequestTracker, domNodeId } = setupDelayedRSCTest(mockRSC, 10);

    const mockHTML = createMockStream({
      0: '<div>shell</div>',
      100: '<div>content</div>',
    });

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId, renderState);
    await collectStreamData(result);

    // After stream completes, isShellReady should be true (RSC resolved successfully)
    expect(renderState.isShellReady).toBe(true);
    expect(renderState.hasErrors).toBe(false);
  });

  it('keeps isShellReady false when post-shell chunk has errors', async () => {
    const mockRSC = createMockStream(['{"data": "ok"}']);
    const renderState = createRenderState({ isShellReady: true });
    const { rscRequestTracker, domNodeId } = setupDelayedRSCTest(mockRSC, 10);

    const mockHTML = createMockStream({
      0: '<div>shell</div>',
      100: '<div>error content</div>',
    });

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId, renderState);

    // Simulate onError firing before the second chunk (as React does synchronously)
    setTimeout(() => {
      renderState.hasErrors = true;
    }, 90);

    await collectStreamData(result);

    // isShellReady should remain false because hasErrors was true when post-shell chunk arrived
    expect(renderState.isShellReady).toBe(false);
  });

  it('does not modify renderState when no RSC payload is generated (non-RSC component)', async () => {
    const railsContext = {} as RailsContextWithServerStreamingCapabilities;
    const rscRequestTracker = new RSCRequestTracker(railsContext);
    // Don't mock onRSCPayloadGenerated — no RSC payloads will be generated
    const renderState = createRenderState({ isShellReady: true });

    const mockHTML = createMockStream({
      0: '<div>shell</div>',
      100: '<div>content</div>',
    });

    const result = injectRSCPayload(mockHTML, rscRequestTracker, 'test-node', renderState);
    await collectStreamData(result);

    // isShellReady should stay true — no RSC activity, no modification
    expect(renderState.isShellReady).toBe(true);
  });

  it('does not modify renderState when renderState is not provided', async () => {
    const mockRSC = createMockStream(['{"data": "ok"}']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const mockHTML = createMockStream({
      0: '<div>shell</div>',
      100: '<div>content</div>',
    });

    // No renderState passed — should work without errors (backward compatible)
    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain('<div>shell</div>');
    expect(resultStr).toContain('<div>content</div>');
  });
});
