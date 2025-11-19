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
import { buildServerRenderer } from 'react-on-rails-rsc/server.node';
import { Readable } from 'stream';

import {
  RSCRenderParams,
  assertRailsContextWithServerStreamingCapabilities,
  StreamRenderState,
  StreamableComponentResult,
} from 'react-on-rails/types';
import { convertToError } from 'react-on-rails/serverRenderUtils';
import handleError from './handleErrorRSC.ts';
import ReactOnRails from './ReactOnRails.full.ts';
import AsyncPropsManager from './AsyncPropsManager.ts';

import {
  streamServerRenderedComponent,
  StreamingTrackers,
  transformRenderStreamChunksToResultObject,
} from './streamingUtils.ts';
import loadJsonFile from './loadJsonFile.ts';

let serverRendererPromise: Promise<ReturnType<typeof buildServerRenderer>> | undefined;

const streamRenderRSCComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RSCRenderParams,
  streamingTrackers: StreamingTrackers,
): Readable => {
  const { throwJsErrors } = options;
  const { railsContext } = options;
  assertRailsContextWithServerStreamingCapabilities(railsContext);

  const { reactClientManifestFileName } = railsContext;
  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { pipeToTransform, readableStream, emitError } =
    transformRenderStreamChunksToResultObject(renderState);

  const reportError = (error: Error) => {
    console.error('Error in RSC stream', error);
    if (throwJsErrors) {
      emitError(error);
    }
    renderState.hasErrors = true;
    renderState.error = error;
  };

  const initializeAndRender = async () => {
    if (!serverRendererPromise) {
      serverRendererPromise = loadJsonFile<BundleManifest>(reactClientManifestFileName)
        .then((reactClientManifest) => buildServerRenderer(reactClientManifest))
        .catch((err: unknown) => {
          serverRendererPromise = undefined;
          throw err;
        });
    }

    const { renderToPipeableStream } = await serverRendererPromise;
    const rscStream = renderToPipeableStream(await reactRenderingResult, {
      onError: (err) => {
        const error = convertToError(err);
        reportError(error);
      },
    });
    pipeToTransform(rscStream);
  };

  initializeAndRender().catch((e: unknown) => {
    const error = convertToError(e);
    reportError(error);
    const errorHtml = handleError({ e: error, name: options.name, serverSide: true });
    pipeToTransform(errorHtml);
  });

  readableStream.on('end', () => {
    streamingTrackers.postSSRHookTracker.notifySSREnd();
  });
  return readableStream;
};

ReactOnRails.serverRenderRSCReactComponent = (options: RSCRenderParams) => {
  try {
    return streamServerRenderedComponent(options, streamRenderRSCComponent, handleError);
  } finally {
    console.history = [];
  }
};

function addAsyncPropsCapabilityToComponentProps<
  AsyncPropsType extends Record<string, unknown>,
  PropsType extends Record<string, unknown>,
>(props: PropsType) {
  const asyncPropManager = new AsyncPropsManager();
  const propsAfterAddingAsyncProps = {
    ...props,
    getReactOnRailsAsyncProp: <PropName extends keyof AsyncPropsType>(propName: PropName) => {
      return asyncPropManager.getProp(propName as string) as Promise<AsyncPropsType[PropName]>;
    },
  };

  return {
    asyncPropManager,
    props: propsAfterAddingAsyncProps,
  };
}

ReactOnRails.addAsyncPropsCapabilityToComponentProps = addAsyncPropsCapabilityToComponentProps;

ReactOnRails.isRSCBundle = true;

export * from 'react-on-rails/types';
export default ReactOnRails;
