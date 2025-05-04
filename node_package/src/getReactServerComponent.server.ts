import { createFromNodeStream } from 'react-on-rails-rsc/client.node';
import transformRSCStream from './transformRSCNodeStream.ts';
import loadJsonFile from './loadJsonFile.ts';
import { RailsContext } from './types/index.ts';

type RSCServerRootProps = {
  componentName: string;
  componentProps: unknown;
  railsContext: RailsContext;
};

const createFromReactOnRailsNodeStream = (
  stream: NodeJS.ReadableStream,
  ssrManifest: Record<string, unknown>,
) => {
  const transformedStream = transformRSCStream(stream);
  return createFromNodeStream(transformedStream, ssrManifest);
};

/**
 * Creates an SSR manifest for React's server components runtime.
 *
 * This function:
 * 1. Loads the server and client component manifests
 * 2. Creates a mapping between client and server module IDs
 * 3. Builds a moduleMap structure required by React's SSR runtime
 *
 * The manifest allows React to correctly associate server components
 * with their client counterparts during hydration.
 *
 * @param reactServerManifestFileName - Path to the server manifest file
 * @param reactClientManifestFileName - Path to the client manifest file
 * @returns A Promise resolving to the SSR manifest object
 */
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
    moduleLoading: {
      prefix: '/webpack/development/',
    },
    moduleMap,
  };

  return ssrManifest;
};

/**
 * Fetches and renders a server component on the server side.
 *
 * This function:
 * 1. Validates the railsContext for required properties
 * 2. Creates an SSR manifest mapping server and client modules
 * 3. Gets the RSC payload stream via getRSCPayloadStream
 * 4. Processes the stream with React's SSR runtime
 *
 * During SSR, this function ensures that the RSC payload is both:
 * - Used to render the server component
 * - Tracked so it can be embedded in the HTML response
 *
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 * @param railsContext - Context for the current request
 * @returns A Promise resolving to the rendered React element
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and getCachedComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
const getReactServerComponent = async ({
  componentName,
  componentProps,
  railsContext,
}: RSCServerRootProps) => {
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

  return createFromReactOnRailsNodeStream(rscPayloadStream, ssrManifest);
};

export default getReactServerComponent;
