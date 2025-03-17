import { Transform } from 'stream';

export default function transformRSCStream(stream: NodeJS.ReadableStream): NodeJS.ReadableStream {
  const decoder = new TextDecoder();
  let lastIncompleteChunk = '';

  const htmlExtractor = new Transform({
    transform(oneOrMoreChunks, _, callback) {
      try {
        const decodedChunk = lastIncompleteChunk + decoder.decode(oneOrMoreChunks);
        const separateChunks = decodedChunk.split('\n').filter(chunk => chunk.trim() !== '');

        if (!decodedChunk.endsWith('\n')) {
          lastIncompleteChunk = separateChunks.pop() ?? '';
        } else {
          lastIncompleteChunk = '';
        }

        for (const chunk of separateChunks) {
          const parsedData = JSON.parse(chunk) as { html: string };
          this.push(parsedData.html);
        }
        callback();
      } catch (error) {
        callback(error as Error);
      }
    }
  });

  return stream.pipe(htmlExtractor);
}
