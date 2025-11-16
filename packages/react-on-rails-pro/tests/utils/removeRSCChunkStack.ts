import { RSCPayloadChunk } from 'react-on-rails';

const removeRSCChunkStack = (chunk: string) => {
  const parsedJson = JSON.parse(chunk) as RSCPayloadChunk;
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

export default removeRSCChunkStack;
