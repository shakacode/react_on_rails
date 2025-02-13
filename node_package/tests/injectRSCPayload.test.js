import { Readable, PassThrough } from 'stream';
import injectRSCPayload from '../src/injectRSCPayload';

describe('injectRSCPayload', () => {
  const createMockStream = (chunks) => {
    if (Array.isArray(chunks)) {
      return Readable.from(chunks.map(chunk => 
        typeof chunk === 'string' ? new TextEncoder().encode(chunk) : chunk
      ));
    } 
    const passThrough = new PassThrough();
    const entries = Object.entries(chunks);
    const keysLength = entries.length;
    entries.forEach(([delay, value], index) => {
      setTimeout(() => {
        const chunksArray = Array.isArray(value) ? value : [value];
        chunksArray.forEach(chunk => {
          passThrough.push(new TextEncoder().encode(chunk));
        });
        if (index === keysLength - 1) {
          passThrough.push(null);
        }
      }, +delay);
    });
    return passThrough;
  }

  const collectStreamData = async (stream) => {
    const chunks = [];
    for await (const chunk of stream) {
      chunks.push(new TextDecoder().decode(chunk));
    }
    return chunks.join('');
  };

  it('should inject RSC payload as script tags', async () => {
    const mockRSC = createMockStream(['{"test": "data"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const result = injectRSCPayload(mockHTML, mockRSC);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data\\"}")</script>'
    );
  });

  it('should handle multiple RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream(['<html><body><div>Hello, world!</div></body></html>']);
    const result = injectRSCPayload(mockHTML, mockRSC);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toContain(
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data\\"}")</script>'
    );
    expect(resultStr).toContain(
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data2\\"}")</script>'
    );
  });

  it('should add all ready html chunks before adding RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream([
      '<html><body><div>Hello, world!</div></body></html>',
      '<div>Next chunk</div>',
    ]);
    const result = injectRSCPayload(mockHTML, mockRSC);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
      '<div>Next chunk</div>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data2\\"}")</script>'
    );
  });

  it('adds delayed html chunks after RSC payloads', async () => {
    const mockRSC = createMockStream(['{"test": "data"}', '{"test": "data2"}']);
    const mockHTML = createMockStream({
      0: '<html><body><div>Hello, world!</div></body></html>',
      100: '<div>Next chunk</div>'
    });
    const result = injectRSCPayload(mockHTML, mockRSC);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
      '<div>Next chunk</div>'
    );
  });

  it('handles the case when html is delayed', async () => {
    const mockRSC = createMockStream({
      0: '{"test": "data"}',
      150: '{"test": "data2"}',
    });
    const mockHTML = createMockStream({
      100: [
        '<html><body><div>Hello, world!</div></body></html>',
        '<div>Next chunk</div>'
      ],
      200: '<div>Third chunk</div>'
    });
    const result = injectRSCPayload(mockHTML, mockRSC);
    const resultStr = await collectStreamData(result);

    expect(resultStr).toEqual(
      '<html><body><div>Hello, world!</div></body></html>' +
      '<div>Next chunk</div>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data\\"}")</script>' +
      '<script>(self.__FLIGHT_DATA||=[]).push("{\\"test\\": \\"data2\\"}")</script>' +
      '<div>Third chunk</div>'
    );
  });
});
