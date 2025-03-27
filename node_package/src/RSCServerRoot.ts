import * as React from 'react';
import { createFromNodeStream } from 'react-on-rails-rsc/client.node';
import type { RenderFunction, RailsContext } from './types';
import transformRSCStream from './transformRSCNodeStreamAndReplayConsoleLogs';
import loadJsonFile from './loadJsonFile';
import RSCPayloadContainer from './RSCPayloadContainer';
import { PassThrough } from 'stream';

declare global {
  function generateRSCPayload(
    componentName: string,
    props: Record<string, unknown>,
    serverSideRSCPayloadParameters: unknown,
  ): Promise<NodeJS.ReadableStream>;
}

type RSCServerRootProps = {
  componentName: string;
  componentProps: Record<string, unknown>;
};

if (!('use' in React && typeof React.use === 'function')) {
  throw new Error(
    'React.use is not defined. Please ensure you are using React 18 with experimental features enabled or React 19+ to use server components.',
  );
}

const { use } = React;

const createFromReactOnRailsNodeStream = (
  stream: NodeJS.ReadableStream,
  ssrManifest: Record<string, unknown>,
) => {
  const transformedStream = transformRSCStream(stream);
  return createFromNodeStream(transformedStream, ssrManifest);
};

const createSSRManifest = async (
  reactServerManifestFileName: string,
  reactClientManifestFileName: string,
) => {
  const [reactServerManifest, reactClientManifest] = await Promise.all([
    loadJsonFile(reactServerManifestFileName),
    loadJsonFile(reactClientManifestFileName),
  ]);

  const ssrManifest = {
    moduleLoading: {
      prefix: '/webpack/development/',
      crossOrigin: null,
    },
    moduleMap: {} as Record<string, unknown>,
  };

  Object.entries(reactClientManifest).forEach(([aboluteFileUrl, clientFileBundlingInfo]) => {
    const serverFileBundlingInfo = reactServerManifest[aboluteFileUrl];
    ssrManifest.moduleMap[(clientFileBundlingInfo as { id: string }).id] = {
      '*': {
        id: (serverFileBundlingInfo as { id: string }).id,
        chunks: (serverFileBundlingInfo as { chunks: string[] }).chunks,
        name: '*',
      },
    };
  });

  return ssrManifest;
};

const RSCServerRoot: RenderFunction = async (
  { componentName, componentProps }: RSCServerRootProps,
  railsContext?: RailsContext,
) => {
  if (
    !railsContext?.serverSide ||
    !railsContext?.reactClientManifestFileName ||
    !railsContext?.reactServerClientManifestFileName
  ) {
    throw new Error(
      `${
        'serverClientManifestFileName and reactServerClientManifestFileName are required. ' +
        'Please ensure that React Server Component webpack configurations are properly set ' +
        'as stated in the React Server Component tutorial. The received rails context is: '
      }${JSON.stringify(railsContext)}`,
    );
  }

  if (typeof generateRSCPayload !== 'function') {
    throw new Error(
      'generateRSCPayload is not defined. Please ensure that you are using at least version 4.0.0 of ' +
        'React on Rails Pro and the node renderer, and that ReactOnRailsPro.configuration.enable_rsc_support ' +
        'is set to true.',
    );
  }

  const ssrManifest = await createSSRManifest(
    railsContext.reactServerClientManifestFileName,
    railsContext.reactClientManifestFileName,
  );
  const rscPayloadStream = await generateRSCPayload(
    componentName,
    componentProps,
    railsContext.serverSideRSCPayloadParameters,
  );

  // Tee the stream to pass it to the server component and the payload container
  const rscPayloadStream1 = new PassThrough();
  rscPayloadStream.pipe(rscPayloadStream1);
  const rscPayloadStream2 = new PassThrough();
  rscPayloadStream.pipe(rscPayloadStream2);
  const serverComponentElement = createFromReactOnRailsNodeStream(rscPayloadStream1, ssrManifest);

  return () =>
    React.createElement(React.Fragment, null, [
      React.createElement(React.Fragment, { key: 'serverComponentElement' }, use(serverComponentElement)),
      React.createElement(RSCPayloadContainer, {
        RSCPayloadStream: rscPayloadStream2,
        key: 'rscPayloadContainer',
      }),
    ]);
};

export default RSCServerRoot;
