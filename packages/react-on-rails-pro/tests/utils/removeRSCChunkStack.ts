import LengthPrefixedStreamParser from '../../src/parseLengthPrefixedStream.ts';

const parseChunk = (chunk: string | Uint8Array) => {
  const parser = new LengthPrefixedStreamParser();
  const results: Array<{ html: string; [key: string]: unknown }> = [];
  const bytes = typeof chunk === 'string' ? new TextEncoder().encode(chunk) : chunk;
  parser.feed(bytes, (content, metadata) => {
    results.push({ html: new TextDecoder().decode(content), ...metadata });
  });
  return results[0]!;
};

const removeRSCChunkStack = (chunk: string | Uint8Array) => {
  const parsed = parseChunk(chunk);
  const { html } = parsed;
  const santizedHtml = html.split('\n').map((chunkLine) => {
    if (!chunkLine.includes('"stack":')) {
      return chunkLine;
    }

    const regexMatch = /(^\d+):\{/.exec(chunkLine);
    if (!regexMatch) {
      return chunkLine;
    }

    const chunkJsonString = chunkLine.slice(chunkLine.indexOf('{'));
    const chunkJson = JSON.parse(chunkJsonString) as { stack?: string };
    delete chunkJson.stack;
    return `${regexMatch[1]}:${JSON.stringify(chunkJson)}`;
  });

  return JSON.stringify({
    ...parsed,
    html: santizedHtml,
  });
};

export default removeRSCChunkStack;
