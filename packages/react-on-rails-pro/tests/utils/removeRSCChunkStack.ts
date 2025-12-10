import { RSCPayloadChunk } from 'react-on-rails';

const removeRSCChunkStackInternal = (chunk: string) => {
  if (chunk.trim().length === 0) {
    return chunk;
  }

  let parsedJson: RSCPayloadChunk;
  try {
    parsedJson = JSON.parse(chunk) as RSCPayloadChunk;
  } catch (err) {
    throw new Error(`Error while parsing the json: "${chunk}", ${err}`);
  }
  const { html } = parsedJson;
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
    ...parsedJson,
    html: santizedHtml,
  });
};

const removeRSCChunkStack = (chunk: string) => {
  chunk.split('\n').map(removeRSCChunkStackInternal).join('\n');
}

export default removeRSCChunkStack;
