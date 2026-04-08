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

const collectStreamDataAndError = (stream: Readable) =>
  new Promise<{ data: string; error?: Error }>((resolve) => {
    const chunks: string[] = [];
    let capturedError: Error | undefined;
    let settled = false;
    const finish = () => {
      if (settled) {
        return;
      }
      settled = true;
      resolve({ data: chunks.join(''), error: capturedError });
    };

    stream.on('data', (chunk) => {
      chunks.push(new TextDecoder().decode(chunk as Buffer));
    });
    stream.once('error', (error) => {
      capturedError = error as Error;
    });
    stream.once('end', finish);
    stream.once('close', finish);
  });

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
    const mockRSC = createMockStream(['{"test": "data"}\n']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>`,
    );
  });

  it('should handle multiple RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n', '{"test": "data2"}\n']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>`,
    );
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data2"})</script>`,
    );
  });

  it('should add all ready html chunks before adding RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n', '{"test": "data2"}\n']);
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
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data2"})</script>',
    );
  });

  it('adds delayed html chunks after RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n', '{"test": "data2"}\n']);
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
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data2"})</script>' +
        '<div>Next chunk</div>',
    );
  });

  it('handles the case when html is delayed', async () => {
    const mockRSC = createMockStream({
      0: '{"test": "data"}\n',
      150: '{"test": "data2"}\n',
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
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>' +
        '<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data2"})</script>' +
        '<div>Third chunk</div>',
    );
  });

  it('should include RSC payload that arrives after HTML stream finishes', async () => {
    const mockRSC = createMockStream({
      300: '{"late": "rsc_data"}\n',
    });
    const mockHTML = createMockStream({
      0: '<html><body>Hello</body></html>',
    });
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain('<html><body>Hello</body></html>');
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"late": "rsc_data"})</script>`,
    );
  });

  it('should include all RSC payloads arriving at different times after HTML stream finishes', async () => {
    const mockRSC = createMockStream({
      200: '{"first": "chunk"}\n',
      400: '{"second": "chunk"}\n',
    });
    const mockHTML = createMockStream({
      0: '<div>content</div>',
    });
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain('<div>content</div>');
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"first": "chunk"})</script>`,
    );
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"second": "chunk"})</script>`,
    );
  });

  it('handles chunks that split across JSON object boundaries', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n{"test": "dat', 'a2"}\n']);
    const mockHTML = createMockStream(['<html><body>Hello</body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data"})</script>`,
    );
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test": "data2"})</script>`,
    );
  });

  it('handles chunks that split a multibyte UTF-8 character', async () => {
    const mockRSC = createMockStream([
      Buffer.from('{"test":"'),
      Buffer.from([0xf0, 0x9f]),
      Buffer.from([0x98, 0x80]),
      Buffer.from('"}\n'),
    ]);
    const mockHTML = createMockStream(['<html><body>Hello</body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test":"😀"})</script>`,
    );
  });

  it('normalizes CRLF on the final buffered payload chunk', async () => {
    const mockRSC = createMockStream(['{"test":"data"}\r\n', '{"final":"chunk"}\r']);
    const mockHTML = createMockStream(['<html><body>Hello</body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test":"data"})</script>`,
    );
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"final":"chunk"})</script>`,
    );
    expect(resultStr).not.toContain('\r');
  });

  it('emits an error instead of embedding malformed NDJSON as invalid JavaScript', async () => {
    const mockRSC = createMockStream(['{"test":"data"}\n', '{"broken": }\n']);
    const mockHTML = createMockStream(['<html><body>Hello</body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId);
    const { data: resultStr, error } = await collectStreamDataAndError(result);

    expect(resultStr).toContain('<html><body>Hello</body></html>');
    expect(resultStr).toContain(
      `<script>((self.REACT_ON_RAILS_RSC_PAYLOADS||={})["test-{}-test-node"]||=[]).push({"test":"data"})</script>`,
    );
    expect(resultStr).not.toContain('{"broken": }');
    expect(error?.message).toContain('Malformed NDJSON line in RSC stream');
  });

  it('adds sanitized nonce attribute to injected RSC script tags', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId, 'abc123" onload=alert(1)');
    const resultStr = await collectStreamData(result);

    expect(resultStr).not.toContain('nonce=');
    expect(resultStr).not.toContain('onload=');
  });

  it('adds valid nonce attribute to injected RSC script tags', async () => {
    const mockRSC = createMockStream(['{"test": "data"}\n']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const { rscRequestTracker, domNodeId } = setupTest(mockRSC);

    const result = injectRSCPayload(mockHTML, rscRequestTracker, domNodeId, 'abc123');
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain('nonce="abc123"');
  });
});
