import { RSCPayloadChunk } from './types/index.ts';

export default function transformRSCStreamAndReplayConsoleLogs(stream: ReadableStream<Uint8Array | string>) {
  return new ReadableStream({
    async start(controller) {
      const reader = stream.getReader();
      const decoder = new TextDecoder();
      const encoder = new TextEncoder();

      let lastIncompleteChunk = '';
      let { value, done } = await reader.read();

      const handleJsonChunk = (chunk: RSCPayloadChunk) => {
        const { html, consoleReplayScript = '' } = chunk;
        if (html.includes('client7.chunk.js')) {
          console.log('received client7.chunk.js at chunk [DEBUG RSC]', chunk);
        }
        if (html.includes('client6.chunk.js')) {
          console.log('received client6.chunk.js at chunk [DEBUG RSC]', chunk);
        }
        controller.enqueue(encoder.encode(html ?? ''));

        const replayConsoleCode = consoleReplayScript
          .trim()
          .replace(/^<script.*>/, '')
          .replace(/<\/script>$/, '');
        if (replayConsoleCode?.trim() !== '') {
          const scriptElement = document.createElement('script');
          scriptElement.textContent = replayConsoleCode;
          document.body.appendChild(scriptElement);
        }
      };

      while (!done) {
        const decodedValue = typeof value === 'string' ? value : decoder.decode(value);
        const decodedChunks = lastIncompleteChunk + decodedValue;
        const chunks = decodedChunks.split('\n');
        lastIncompleteChunk = chunks.pop() ?? '';

        const jsonChunks = chunks
          .filter((line) => line.trim() !== '')
          .map((line) => {
            try {
              return JSON.parse(line) as RSCPayloadChunk;
            } catch (error) {
              console.error('Error parsing JSON:', line, error);
              throw error;
            }
          });

        for (const jsonChunk of jsonChunks) {
          handleJsonChunk(jsonChunk);
        }

        // eslint-disable-next-line no-await-in-loop
        ({ value, done } = await reader.read());
      }
      controller.close();
    },
  });
}
