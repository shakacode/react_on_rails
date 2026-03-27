import LengthPrefixedStreamParser from '../src/parseLengthPrefixedStream.ts';

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const toFrame = (content: string, metadata: Record<string, unknown> = {}) => {
  const contentBytes = encoder.encode(content);
  const header = `${JSON.stringify(metadata)}\t${contentBytes.length.toString(16).padStart(8, '0')}\n`;
  return encoder.encode(header + content);
};

describe('LengthPrefixedStreamParser', () => {
  it('parses consecutive frames separated by a blank line', () => {
    const parser = new LengthPrefixedStreamParser();
    const results: Array<{ content: string; metadata: Record<string, unknown> }> = [];
    const frame1 = toFrame('first\n', { index: 1 });
    const frame2 = toFrame('second\n', { index: 2 });
    const combined = new Uint8Array(frame1.length + 1 + frame2.length);

    combined.set(frame1);
    combined.set([0x0a], frame1.length);
    combined.set(frame2, frame1.length + 1);

    parser.feed(combined, (content, metadata) => {
      results.push({ content: decoder.decode(content), metadata });
    });

    expect(results).toEqual([
      { content: 'first\n', metadata: { index: 1 } },
      { content: 'second\n', metadata: { index: 2 } },
    ]);
  });

  it('parses blank-line-separated frames across feed boundaries', () => {
    const parser = new LengthPrefixedStreamParser();
    const results: Array<{ content: string; metadata: Record<string, unknown> }> = [];
    const frame1 = toFrame('first\n', { index: 1 });
    const frame2 = toFrame('second\n', { index: 2 });
    const combined = new Uint8Array(frame1.length + 1 + frame2.length);

    combined.set(frame1);
    combined.set([0x0a], frame1.length);
    combined.set(frame2, frame1.length + 1);

    parser.feed(combined.subarray(0, frame1.length + 1), (content, metadata) => {
      results.push({ content: decoder.decode(content), metadata });
    });
    parser.feed(combined.subarray(frame1.length + 1), (content, metadata) => {
      results.push({ content: decoder.decode(content), metadata });
    });

    expect(results).toEqual([
      { content: 'first\n', metadata: { index: 1 } },
      { content: 'second\n', metadata: { index: 2 } },
    ]);
  });
});
