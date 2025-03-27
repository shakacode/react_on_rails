import { RSCPayloadChunk } from './types';

export default function transformRSCStreamAndReplayConsoleLogs(
  stream: ReadableStream<Uint8Array | RenderResult>,
) {
  return new ReadableStream({
    async start(controller) {
      const reader = stream.getReader();
      const decoder = new TextDecoder();
      const encoder = new TextEncoder();

      let lastIncompleteChunk = '';
      let { value, done } = await reader.read();

      const handleJsonChunk = (chunk: RenderResult) => {
        const { html, consoleReplayScript = '' } = chunk;
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
        if (ArrayBuffer.isView(value)) {
          const decodedValue = lastIncompleteChunk + decoder.decode(value);
          const chunks = decodedValue.split('\n');
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
        } else if (value) {
          handleJsonChunk(value);
        }

        // eslint-disable-next-line no-await-in-loop
        ({ value, done } = await reader.read());
      }
      controller.close();
    },
  });
}
