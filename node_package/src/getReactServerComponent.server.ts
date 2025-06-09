import { BundleManifest } from 'react-on-rails-rsc';
import { buildClientRenderer } from 'react-on-rails-rsc/client.node';
import transformRSCStream from './transformRSCNodeStream.ts';
import loadJsonFile from './loadJsonFile.ts';
import { assertRailsContextWithServerComponentCapabilities, RailsContext } from './types/index.ts';

type GetReactServerComponentOnServerProps = {
  componentName: string;
  componentProps: unknown;
  railsContext: RailsContext;
};

let clientRenderer: ReturnType<typeof buildClientRenderer> | undefined;

const createFromReactOnRailsNodeStream = async (
  stream: NodeJS.ReadableStream,
  reactServerManifestFileName: string,
  reactClientManifestFileName: string,
) => {
  if (!clientRenderer) {
    const [reactServerManifest, reactClientManifest] = await Promise.all([
      loadJsonFile<BundleManifest>(reactServerManifestFileName),
      loadJsonFile<BundleManifest>(reactClientManifestFileName),
    ]);
    clientRenderer = buildClientRenderer(reactClientManifest, reactServerManifest);
  }

  const { createFromNodeStream } = clientRenderer;
  const transformedStream = transformRSCStream(stream);
  return createFromNodeStream<React.ReactNode>(transformedStream);
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
 * @param enforceRefetch - Whether to enforce a refetch of the component
 * @returns A Promise resolving to the rendered React element
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
const getReactServerComponent = async ({
  componentName,
  componentProps,
  railsContext,
}: GetReactServerComponentOnServerProps) => {
  assertRailsContextWithServerComponentCapabilities(railsContext);

  if (typeof ReactOnRails.getRSCPayloadStream !== 'function') {
    throw new Error(
      'ReactOnRails.getRSCPayloadStream is not defined. This likely means that you are not building the server bundle correctly. Please ensure that your server bundle is targeting Node.js',
    );
  }

  const rscPayloadStream = await ReactOnRails.getRSCPayloadStream(
    componentName,
    componentProps,
    railsContext,
  );

  return createFromReactOnRailsNodeStream(
    rscPayloadStream,
    railsContext.reactServerClientManifestFileName,
    railsContext.reactClientManifestFileName,
  );
};

export default getReactServerComponent;
