import * as React from 'react';

type StreamChunk = {
  chunk: string;
  isLastChunk: boolean;
};

type RSCPayloadContainerProps = {
  RSCPayloadStream: NodeJS.ReadableStream;
};

type RSCPayloadContainerInnerProps = {
  chunkIndex: number;
  getChunkPromise: (chunkIndex: number) => Promise<StreamChunk>;
};

function escapeScript(script: string) {
  return script.replace(/<!--/g, '<\\!--').replace(/<\/(script)/gi, '</\\$1');
}

/**
 * RSCPayloadContainer is a React component that handles the server-to-client transfer
 * of React Server Component (RSC) payloads. It works in conjunction with RSCClientRoot
 * to ensure reliable delivery of RSC chunks.
 *
 * How it works:
 * 1. Receives a NodeJS.ReadableStream containing RSC payload chunks from the server
 * 2. Creates a series of promises to handle each chunk asynchronously
 * 3. For each chunk:
 *    - Creates a script tag that pushes the chunk to window.REACT_ON_RAILS_RSC_PAYLOAD
 *    - Uses React.use() to handle the async chunk loading
 *    - Recursively renders the next chunk using Suspense
 *
 * The component ensures that:
 * - Chunks are processed in order
 * - Server-side console logs are preserved
 * - The transfer is resilient to network conditions
 * - The client receives all chunks reliably
 */
const RSCPayloadContainer = ({
  chunkIndex,
  getChunkPromise,
}: RSCPayloadContainerInnerProps): React.ReactNode => {
  const chunkPromise = getChunkPromise(chunkIndex);
  const chunk = React.use(chunkPromise);

  const scriptElement = React.createElement('script', {
    dangerouslySetInnerHTML: {
      // Ensure the array is never reassigned.
      // Even at the RSCClientRoot component, the array is assigned
      // only if it's not already assigned by this script.
      __html: escapeScript(`(self.REACT_ON_RAILS_RSC_PAYLOAD||=[]).push(${chunk.chunk})`),
    },
    key: `script-${chunkIndex}`,
  });

  if (chunk.isLastChunk) {
    return scriptElement;
  }

  return React.createElement(React.Fragment, null, [
    scriptElement,
    React.createElement(
      React.Suspense,
      { fallback: null, key: `suspense-${chunkIndex}` },
      React.createElement(RSCPayloadContainer, { chunkIndex: chunkIndex + 1, getChunkPromise }),
    ),
  ]);
};

export default function RSCPayloadContainerWrapper({ RSCPayloadStream }: RSCPayloadContainerProps) {
  const [chunkPromises] = React.useState<Promise<StreamChunk>[]>(() => {
    const promises: Promise<StreamChunk>[] = [];
    let resolveCurrentPromise: (streamChunk: StreamChunk) => void = () => {};
    let rejectCurrentPromise: (error: unknown) => void = () => {};
    const decoder = new TextDecoder();

    const createNewPromise = () => {
      const promise = new Promise<StreamChunk>((resolve, reject) => {
        resolveCurrentPromise = resolve;
        rejectCurrentPromise = reject;
      });

      promises.push(promise);
    };

    createNewPromise();
    RSCPayloadStream.on('data', (streamChunk) => {
      resolveCurrentPromise({ chunk: decoder.decode(streamChunk as Uint8Array), isLastChunk: false });
      createNewPromise();
    });

    RSCPayloadStream.on('error', (error) => {
      rejectCurrentPromise(error);
      createNewPromise();
    });

    RSCPayloadStream.on('end', () => {
      resolveCurrentPromise({ chunk: '', isLastChunk: true });
    });

    return promises;
  });

  const getChunkPromise = React.useCallback(
    (chunkIndex: number) => {
      if (chunkIndex > chunkPromises.length) {
        throw new Error('React on Rails Error: RSC Chunk index out of bounds');
      }

      return chunkPromises[chunkIndex];
    },
    [chunkPromises],
  );

  return React.createElement(
    React.Suspense,
    { fallback: null },
    React.createElement(RSCPayloadContainer, { chunkIndex: 0, getChunkPromise }),
  );
}
