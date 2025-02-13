import { PassThrough } from 'stream';

// Escape closing script tags and HTML comments in JS content.
// https://www.w3.org/TR/html52/semantics-scripting.html#restrictions-for-contents-of-script-elements
// Avoid replacing </script with <\/script as it would break the following valid JS: 0</script/ (i.e. regexp literal).
// Instead, escape the s character.
function escapeScript(script) {
  return script
    .replace(/<!--/g, '<\\!--')
    .replace(/<\/(script)/gi, '</\\$1');
}

function writeChunk(chunk, transform) {
  transform.push(`<script>${escapeScript(`(self.__FLIGHT_DATA||=[]).push(${chunk})`)}</script>`);
}

export default function injectRSCPayload(pipeableHtmlStream, rscStream) {
  const htmlStream = new PassThrough();
  pipeableHtmlStream.pipe(htmlStream);
  const decoder = new TextDecoder();
  let rscPromise = null;
  const htmlBuffer = [];
  let timeout = null;
  const resultStream = new PassThrough();

  // Start reading RSC stream immediately
  const startRSC = async () => {
    try {
      for await (const chunk of rscStream) {
        try {
          writeChunk(JSON.stringify(decoder.decode(chunk)), resultStream);
        } catch (err) {
          const base64 = JSON.stringify(btoa(String.fromCodePoint(...chunk)));
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
  }

  htmlStream.on('data', (chunk) => {
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
    rscPromise.then(() => resultStream.end()).catch(err => resultStream.emit('error', err));
  });

  return resultStream;
}
