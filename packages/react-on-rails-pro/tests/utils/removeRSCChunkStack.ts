import { RSCPayloadChunk } from 'react-on-rails';

// Parses a stream chunk in the length-prefixed format:
// <metadata JSON>\t<content byte length hex>\n<raw content>
const parseLengthPrefixedChunk = (chunk: string): RSCPayloadChunk => {
  const newlineIdx = chunk.indexOf('\n');
  if (newlineIdx < 0) {
    // Fallback: try legacy NDJSON format
    return JSON.parse(chunk) as RSCPayloadChunk;
  }

  const header = chunk.slice(0, newlineIdx);
  const tabIdx = header.indexOf('\t');

  if (tabIdx < 0) {
    // No tab → legacy NDJSON format
    return JSON.parse(chunk) as RSCPayloadChunk;
  }

  const metaJson = header.slice(0, tabIdx);
  const contentLenHex = header.slice(tabIdx + 1);
  const contentLen = parseInt(contentLenHex, 16);
  const content = chunk.slice(newlineIdx + 1, newlineIdx + 1 + contentLen);
  const metadata = JSON.parse(metaJson) as Omit<RSCPayloadChunk, 'html'>;

  return { html: content, ...metadata } as RSCPayloadChunk;
};

const removeRSCChunkStack = (chunk: string) => {
  const parsedChunk = parseLengthPrefixedChunk(chunk);
  const { html } = parsedChunk;
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
    ...parsedChunk,
    html: santizedHtml,
  });
};

export default removeRSCChunkStack;
