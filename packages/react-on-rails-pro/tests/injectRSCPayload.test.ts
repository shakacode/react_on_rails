import { Readable, PassThrough } from 'stream';
import { RailsContextWithServerStreamingCapabilities } from 'react-on-rails/types';
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

// Test setup helper for keyProps scenarios
const setupTestWithKeyProps = (mockRSC: Readable, keyProps: unknown) => {
  const railsContext = {} as RailsContextWithServerStreamingCapabilities;
  const rscRequestTracker = new RSCRequestTracker(railsContext);
  jest.spyOn(rscRequestTracker, 'onRSCPayloadGenerated').mockImplementation((callback) => {
    callback({ stream: mockRSC, componentName: 'test', props: { id: 1, huge_data: 'x'.repeat(1000) }, keyProps });
  });

  return { railsContext, rscRequestTracker, domNodeId: 'test-node' };
};

describe('injectRSCPayload', () => {
  it('should use keyProps for cache key when provided in streamInfo', async () => {
    const mockRSC = createMockStream(['{"test": "data"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTestWithKeyProps(mockRSC, { id: 1 });

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    // Key should use keyProps {id: 1}, not full props {id: 1, huge_data: "xxx..."}
    // The key is JSON.stringify'd inside the script, so inner quotes are escaped
    expect(resultStr).toContain('test-{\\"id\\":1}-test-node');
    // Should NOT contain the huge_data in the key
    expect(resultStr).not.toContain('huge_data');
  });

  it('should fall back to props when keyProps is undefined', async () => {
    const mockRSC = createMockStream(['{"test": "data"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTestWithKeyProps(mockRSC, undefined);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    // Key should use full props since keyProps is undefined
    expect(resultStr).toContain('huge_data');
  });

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
