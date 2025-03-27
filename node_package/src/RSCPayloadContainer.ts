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

const RSCPayloadContainer = ({
  chunkIndex,
  getChunkPromise,
}: RSCPayloadContainerInnerProps): React.ReactNode => {
  const chunkPromise = getChunkPromise(chunkIndex);
  const chunk = React.use(chunkPromise);

  const scriptElement = React.createElement('script', {
    dangerouslySetInnerHTML: {
      __html: escapeScript(`(self.__FLIGHT_DATA||=[]).push(${chunk.chunk})`),
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
    let rejectCurrentPromise: (error: Error) => void = () => {};
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
      resolveCurrentPromise({ chunk: decoder.decode(streamChunk), isLastChunk: false });
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
