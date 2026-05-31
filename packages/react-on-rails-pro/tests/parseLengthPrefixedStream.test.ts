import LengthPrefixedStreamParser from '../src/parseLengthPrefixedStream.ts';

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const toRecord = (content: string, metadata: Record<string, unknown> = {}) => {
  const contentBytes = encoder.encode(content);
  return `${JSON.stringify(metadata)}\t${contentBytes.length.toString(16)}\n${content}`;
};

const collectRecords = (...chunks: string[]) => {
  const parser = new LengthPrefixedStreamParser();
  const records: Array<{ content: string; metadata: Record<string, unknown> }> = [];

  chunks.forEach((chunk) => {
    parser.feed(encoder.encode(chunk), (content, metadata) => {
      records.push({ content: decoder.decode(content), metadata });
    });
  });

  return records;
};

describe('LengthPrefixedStreamParser', () => {
  it('parses records separated by blank lines', () => {
    const records = collectRecords(`${toRecord('first', { index: 1 })}\n${toRecord('second', { index: 2 })}`);

    expect(records).toEqual([
      { content: 'first', metadata: { index: 1 } },
      { content: 'second', metadata: { index: 2 } },
    ]);
  });

  it('parses records separated by CRLF blank lines', () => {
    const records = collectRecords(
      `${toRecord('first', { index: 1 })}\r\n${toRecord('second', { index: 2 })}`,
    );

    expect(records).toEqual([
      { content: 'first', metadata: { index: 1 } },
      { content: 'second', metadata: { index: 2 } },
    ]);
  });

  it('parses records separated by multiple blank lines', () => {
    const records = collectRecords(
      `${toRecord('first', { index: 1 })}\n\n${toRecord('second', { index: 2 })}`,
    );

    expect(records).toEqual([
      { content: 'first', metadata: { index: 1 } },
      { content: 'second', metadata: { index: 2 } },
    ]);
  });

  it('parses when a blank separator is split across feed calls', () => {
    const records = collectRecords(toRecord('first', { index: 1 }), '\n', toRecord('second', { index: 2 }));

    expect(records).toEqual([
      { content: 'first', metadata: { index: 1 } },
      { content: 'second', metadata: { index: 2 } },
    ]);
  });

  it('still rejects non-empty malformed headers', () => {
    const parser = new LengthPrefixedStreamParser();

    expect(() => {
      parser.feed(encoder.encode(`not-json-or-length\n${toRecord('content')}`), () => {});
    }).toThrow('Malformed length-prefixed header: missing tab separator');
  });
});
