import { PassThrough, Transform } from 'stream';
import { finished } from 'stream/promises';
import { createRSCPayloadKey } from './utils.ts';
import { RailsContextWithServerComponentCapabilities, PipeableOrReadableStream } from './types/index.ts';

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

function cacheKeyJSArray(cacheKey: string) {
  return `(self.REACT_ON_RAILS_RSC_PAYLOADS||={})[${JSON.stringify(cacheKey)}]||=[]`;
}

function writeScript(script: string, transform: Transform) {
  transform.push(`<script>${escapeScript(script)}</script>`);
}

function initializeCacheKeyJSArray(cacheKey: string, transform: Transform) {
  writeScript(cacheKeyJSArray(cacheKey), transform);
}

function writeChunk(chunk: string, transform: Transform, cacheKey: string) {
  writeScript(`(${cacheKeyJSArray(cacheKey)}).push(${chunk})`, transform);
}

/**
 * Embeds RSC payloads into the HTML stream for optimal hydration.
 *
 * This function:
 * 1. Creates a result stream for the combined HTML + RSC payloads
 * 2. Listens for RSC payload generation via onRSCPayloadGenerated
 * 3. Initializes global arrays for each payload BEFORE component HTML
 * 4. Writes each payload chunk as a script tag that pushes to the array
 * 5. Passes HTML through to the result stream
 *
 * The timing of array initialization is critical - it must occur before the
 * component's HTML to ensure the array exists when client hydration begins.
 * This prevents unnecessary HTTP requests during hydration.
 *
 * @param pipeableHtmlStream - HTML stream from React's renderToPipeableStream
 * @param railsContext - Context for the current request
 * @returns A combined stream with embedded RSC payloads
 */
export default function injectRSCPayload(
  pipeableHtmlStream: PipeableOrReadableStream,
  railsContext: RailsContextWithServerComponentCapabilities,
) {
  const htmlStream = new PassThrough();
  pipeableHtmlStream.pipe(htmlStream);
  const decoder = new TextDecoder();
  let rscPromise: Promise<void> | null = null;
  const htmlBuffer: Buffer[] = [];
  let timeout: NodeJS.Timeout | null = null;
  const resultStream = new PassThrough();

  const startRSC = async () => {
    try {
      const rscPromises: Promise<void>[] = [];

      if (!ReactOnRails.onRSCPayloadGenerated) {
        // This should never occur in normal operation and indicates a bug in react_on_rails that needs to be fixed.
        // While not fatal, missing RSC payload injection will degrade performance by forcing
        console.error(
          'ReactOnRails Error: ReactOnRails.onRSCPayloadGenerated is not defined. RSC payloads cannot be injected.',
        );
      }

      ReactOnRails.onRSCPayloadGenerated?.(railsContext, (streamInfo) => {
        const { stream, props, componentName } = streamInfo;
        const cacheKey = createRSCPayloadKey(componentName, props, railsContext);

        // When a component requests an RSC payload, we initialize a global array to store it.
        // This array is injected into the HTML before the component's HTML markup.
        // From our tests in SuspenseHydration.test.tsx, we know that client-side components
        // only hydrate after their HTML is present in the page. This timing ensures that
        // the RSC payload array is available before hydration begins.
        // As a result, the component can access its RSC payload directly from the page
        // instead of making a separate network request.
        // The client-side RSCProvider actively monitors the array for new chunks, processing them as they arrive and forwarding them to the RSC payload stream, regardless of whether the array is initially empty.
        initializeCacheKeyJSArray(cacheKey, resultStream);
        rscPromises.push(
          (async () => {
            for await (const chunk of stream ?? []) {
              const decodedChunk = typeof chunk === 'string' ? chunk : decoder.decode(chunk);
              writeChunk(JSON.stringify(decodedChunk), resultStream, cacheKey);
            }
          })(),
        );
      });

      await finished(htmlStream).then(() => Promise.all(rscPromises));
    } catch (err) {
      resultStream.emit('error', err);
    }
  };

  const writeHTMLChunks = () => {
    resultStream.push(Buffer.concat(htmlBuffer));
    htmlBuffer.length = 0;
  };

  htmlStream.on('data', (chunk: Buffer) => {
    htmlBuffer.push(chunk);
    if (timeout) {
      return;
    }

    timeout = setTimeout(() => {
      if (!rscPromise) {
        rscPromise = startRSC();
      }
      writeHTMLChunks();
      timeout = null;
    }, 0);
  });

  htmlStream.on('error', (err) => {
    resultStream.emit('error', err);
  });

  htmlStream.on('end', () => {
    if (timeout) {
      clearTimeout(timeout);
    }
    if (!rscPromise) {
      rscPromise = startRSC();
    }
    writeHTMLChunks();
    rscPromise
      .then(() => {
        resultStream.end();
      })
      .finally(() => {
        if (!ReactOnRails.clearRSCPayloadStreams) {
          console.error('ReactOnRails Error: clearRSCPayloadStreams is not a function');
          return;
        }

        ReactOnRails.clearRSCPayloadStreams(railsContext);
      })
      .catch((err: unknown) => resultStream.emit('error', err));
  });

  return resultStream;
}
