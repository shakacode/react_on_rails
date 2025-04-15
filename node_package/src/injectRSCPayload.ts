import { PipeableStream } from 'react-dom/server';
import { PassThrough, Transform } from 'stream';
import { RailsContext } from './types';

// In JavaScript, when an escape sequence with a backslash (\) is followed by a character
// that isn't a recognized escape character, the backslash is ignored, and the character
// is treated as-is.
// This behavior allows us to use the backslash to escape characters that might be
// interpreted as HTML tags, preventing them from being processed by the HTML parser.
// For example, we can escape the comment tag <!-- as <\!-- and the script tag </script>
// as <\/script>.
// This ensures that these tags are not prematurely closed or misinterpreted by the browser.
function escapeScript(script: string) {
  return script.replace(/<!--/g, '<\\!--').replace(/<\/(script)/gi, '</\\$1');
}

function writeChunk(chunk: string, transform: Transform) {
  transform.push(`<script>${escapeScript(`(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push(${chunk})`)}</script>`);
}

export default function injectRSCPayload(
  pipeableHtmlStream: NodeJS.ReadableStream | PipeableStream,
  railsContext: RailsContext,
) {
  const htmlStream = new PassThrough();
  pipeableHtmlStream.pipe(htmlStream);
  const decoder = new TextDecoder();
  let rscPromise: Promise<void> | null = null;
  const htmlBuffer: string[] = [];
  let timeout: NodeJS.Timeout | null = null;
  const resultStream = new PassThrough();

  // Start reading RSC stream immediately
  const startRSC = async () => {
    try {
      for await (const chunk of ReactOnRails.getRSCPayloadStreams?.(railsContext)?.[0]?.stream ?? []) {
        try {
          const decodedChunk = typeof chunk === 'string' ? chunk : decoder.decode(chunk);
          writeChunk(JSON.stringify(decodedChunk), resultStream);
        } catch (_) {
          const decodedChunk = typeof chunk === 'string' ? chunk : String.fromCodePoint(...chunk);
          const base64 = JSON.stringify(btoa(decodedChunk));
          writeChunk(`Uint8Array.from(atob(${base64}), m => m.codePointAt(0))`, resultStream);
        }
      }
    } catch (err) {
      resultStream.emit('error', err);
    }
  };

  const writeHTMLChunks = () => {
    for (const htmlChunk of htmlBuffer) {
      resultStream.push(htmlChunk);
    }
    htmlBuffer.length = 0;
  };

  htmlStream.on('data', (chunk: Buffer) => {
    const buf = decoder.decode(chunk);
    htmlBuffer.push(buf);
    if (timeout) {
      return;
    }

    timeout = setTimeout(() => {
      writeHTMLChunks();
      if (!rscPromise) {
        rscPromise = startRSC();
      }
      timeout = null;
    }, 0);
  });

  htmlStream.on('end', () => {
    if (timeout) {
      clearTimeout(timeout);
    }
    writeHTMLChunks();
    if (!rscPromise) {
      rscPromise = startRSC();
    }
    rscPromise.then(() => resultStream.end()).catch((err: unknown) => resultStream.emit('error', err));
  });

  return resultStream;
}
