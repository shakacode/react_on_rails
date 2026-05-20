/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { BundleManifest } from 'react-on-rails-rsc';
import { buildClientRenderer } from 'react-on-rails-rsc/client.node';
import type { RailsContextWithServerStreamingCapabilities } from 'react-on-rails/types';
import transformRSCStream from './transformRSCNodeStream.ts';
import loadJsonFile from './loadJsonFile.ts';

type GetReactServerComponentOnServerProps = {
  componentName: string;
  componentProps: unknown;
};

let clientRendererPromise: Promise<ReturnType<typeof buildClientRenderer>> | undefined;

const createFromReactOnRailsNodeStream = async (
  stream: NodeJS.ReadableStream,
  reactServerManifestFileName: string,
  reactClientManifestFileName: string,
) => {
  if (!clientRendererPromise) {
    clientRendererPromise = Promise.all([
      loadJsonFile<BundleManifest>(reactServerManifestFileName),
      loadJsonFile<BundleManifest>(reactClientManifestFileName),
    ])
      .then(([reactServerManifest, reactClientManifest]) =>
        buildClientRenderer(reactClientManifest, reactServerManifest),
      )
      .catch((err: unknown) => {
        clientRendererPromise = undefined;
        throw err;
      });
  }

  const { createFromNodeStream } = await clientRendererPromise;
  const transformedStream = transformRSCStream(stream);
  return createFromNodeStream<React.ReactNode>(transformedStream);
};

/**
 * Creates a function that fetches and renders a server component on the server side.
 *
 * This style of higher-order function is necessary as the function that gets server components
 * on server has different parameters than the function that gets them on client. The environment
 * dependent parameters (railsContext) are passed from the `wrapServerComponentRenderer`
 * function, while the environment agnostic parameters (componentName, componentProps) are
 * passed from the RSCProvider which is environment agnostic.
 *
 * The returned function:
 * 1. Validates the railsContext for required properties
 * 2. Creates an SSR manifest mapping server and client modules
 * 3. Gets the RSC payload stream via getRSCPayloadStream
 * 4. Processes the stream with React's SSR runtime
 *
 * During SSR, this function ensures that the RSC payload is both:
 * - Used to render the server component
 * - Tracked so it can be embedded in the HTML response
 *
 * @param railsContext - Context for the current request with server streaming capabilities
 * @returns A function that accepts RSC parameters and returns a Promise resolving to the rendered React element
 *
 * The returned function accepts:
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
const getReactServerComponent =
  (railsContext: RailsContextWithServerStreamingCapabilities) =>
  async ({ componentName, componentProps }: GetReactServerComponentOnServerProps) => {
    const rscPayloadStream = await railsContext.getRSCPayloadStream(componentName, componentProps);

    return createFromReactOnRailsNodeStream(
      rscPayloadStream,
      railsContext.reactServerClientManifestFileName,
      railsContext.reactClientManifestFileName,
    );
  };

export default getReactServerComponent;
