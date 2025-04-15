import { Readable, PassThrough } from 'stream';
import ReactOnRails, { RailsContext } from '../src/ReactOnRails.node';
import injectRSCPayload from '../src/injectRSCPayload';

describe('injectRSCPayload', () => {
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

  it('should inject RSC payload as script tags', async () => {
    const mockRSC = createMockStream(['{"test": "data"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);

    jest
      .spyOn(ReactOnRails, 'getRSCPayloadStreams')
      .mockReturnValue([{ stream: mockRSC, componentName: 'test' }]);

    const result = injectRSCPayload(mockHTML, {} as RailsContext);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data\\"}")</script>',
    );
  });

  it('should handle multiple RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);

    jest
      .spyOn(ReactOnRails, 'getRSCPayloadStreams')
      .mockReturnValue([{ stream: mockRSC, componentName: 'test' }]);

    const result = injectRSCPayload(mockHTML, {} as RailsContext);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data\\"}")</script>',
    );
    expect(resultStr).toContain(
      '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data2\\"}")</script>',
    );
  });

  it('should add all ready html chunks before adding RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream([
      '<html><body><div>Hello, world!</div></body></html>',
      '<div>Next chunk</div>',
    ]);
    jest
      .spyOn(ReactOnRails, 'getRSCPayloadStreams')
      .mockReturnValue([{ stream: mockRSC, componentName: 'test' }]);

    const result = injectRSCPayload(mockHTML, {} as RailsContext);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
        '<div>Next chunk</div>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data2\\"}")</script>',
    );
  });

  it('adds delayed html chunks after RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream({
      0: '<html><body><div>Hello, world!</div></body></html>',
      100: '<div>Next chunk</div>',
    });
    jest
      .spyOn(ReactOnRails, 'getRSCPayloadStreams')
      .mockReturnValue([{ stream: mockRSC, componentName: 'test' }]);

    const result = injectRSCPayload(mockHTML, {} as RailsContext);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
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
    jest
      .spyOn(ReactOnRails, 'getRSCPayloadStreams')
      .mockReturnValue([{ stream: mockRSC, componentName: 'test' }]);

    const result = injectRSCPayload(mockHTML, {} as RailsContext);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
        '<div>Next chunk</div>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
        '<script>(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
        '<div>Third chunk</div>',
    );
  });
});
