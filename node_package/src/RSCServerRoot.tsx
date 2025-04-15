import * as React from 'react';
import { createFromNodeStream } from 'react-on-rails-rsc/client.node';
import type { RenderFunction, RailsContext } from './types';
import transformRSCStream from './transformRSCNodeStream';
import loadJsonFile from './loadJsonFile';
import { ensureReactUseAvailable } from './reactApis';

ensureReactUseAvailable();

type RSCServerRootProps = {
  componentName: string;
  componentProps: Record<string, unknown>;
};

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
    loadJsonFile(reactServerManifestFileName) as Promise<Record<string, { id: string; chunks: string[] }>>,
    loadJsonFile(reactClientManifestFileName) as Promise<Record<string, { id: string }>>,
  ]);

  const moduleMap: Record<string, unknown> = {};
  Object.entries(reactClientManifest).forEach(([aboluteFileUrl, clientFileBundlingInfo]) => {
    const { id, chunks } = reactServerManifest[aboluteFileUrl];
    moduleMap[clientFileBundlingInfo.id] = {
      '*': {
        id,
        chunks,
        name: '*',
      },
    };
  });

  const ssrManifest = {
    // The `moduleLoading` property is utilized by the React runtime to load JavaScript modules.
    // It can accept options such as `prefix` and `crossOrigin` to specify the path and crossorigin attribute for the modules.
    // In our case, since the server code is bundled into a single bundle, there is no need to load additional JavaScript modules.
    // As a result, we set this property to an empty object because it will not be used.
    moduleLoading: {},
    moduleMap,
  };

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
      'serverClientManifestFileName and reactServerClientManifestFileName are required. ' +
        'Please ensure that React Server Component webpack configurations are properly set ' +
        'as stated in the React Server Component tutorial. ' +
        'Make sure to use "stream_react_component" instead of "react_component" to SSR a server component.',
    );
  }

  if (typeof ReactOnRails.getRSCPayloadStream !== 'function') {
    throw new Error(
      'ReactOnRails.getRSCPayloadStream is not defined. This likely means that you are not building the server bundle correctly. Please ensure that your server bundle is targeting Node.js',
    );
  }

  const ssrManifest = await createSSRManifest(
    railsContext.reactServerClientManifestFileName,
    railsContext.reactClientManifestFileName,
  );
  const rscPayloadStream = await ReactOnRails.getRSCPayloadStream(
    componentName,
    componentProps,
    railsContext,
  );

  const serverComponentElement = createFromReactOnRailsNodeStream(rscPayloadStream, ssrManifest);
  return () => use(serverComponentElement);
};

export default RSCServerRoot;
