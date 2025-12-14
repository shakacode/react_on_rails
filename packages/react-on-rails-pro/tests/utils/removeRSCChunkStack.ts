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
    if (/^[0-9a-fA-F]+\:D/.exec(chunkLine) || chunkLine.startsWith(':N')) {
      return '';
    }
    if (!(chunkLine.includes('"stack":') || chunkLine.includes('"start":') || chunkLine.includes('"end":'))) {
      return chunkLine;
    }

    const regexMatch = /([^\{]+)\{/.exec(chunkLine)
    if (!regexMatch) {
      return chunkLine;
    }

    const chunkJsonString = chunkLine.slice(chunkLine.indexOf('{'));
    try {
      const chunkJson = JSON.parse(chunkJsonString);
      delete chunkJson.stack;
      delete chunkJson.start;
      delete chunkJson.end;
      return `${regexMatch[1]}${JSON.stringify(chunkJson)}`
    } catch {
      return chunkLine
    }
  });

  return JSON.stringify({
    ...parsedJson,
    html: santizedHtml,
  });
};

const removeRSCChunkStack = (chunk: string) => {
  chunk.split('\n').map(removeRSCChunkStackInternal).join('\n');
};

export default removeRSCChunkStack;
