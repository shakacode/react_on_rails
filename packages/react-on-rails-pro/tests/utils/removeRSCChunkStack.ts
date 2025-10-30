const removeRSCChunkStack = (chunk: string) => {
  const parsedJson = JSON.parse(chunk);
  const html = parsedJson.html as string;
  const santizedHtml = html.split('\n').map(chunkLine => {
    if (!chunkLine.includes('"stack":')) {
      return chunkLine;
    }

    const regexMatch = /(^\d+):\{/.exec(chunkLine)
    if (!regexMatch) {
      return;
    }

    const chunkJsonString = chunkLine.slice(chunkLine.indexOf('{'));
    const chunkJson = JSON.parse(chunkJsonString);
    delete chunkJson.stack;
    return `${regexMatch[1]}:${JSON.stringify(chunkJson)}`
  });

  return JSON.stringify({
    ...parsedJson,
    html: santizedHtml,
  });
}

export default removeRSCChunkStack;
