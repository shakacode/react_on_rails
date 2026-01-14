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
import { getOrCreateAsyncPropsManager } from './AsyncPropsManager.ts';

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

  const { pipeToTransform, readableStream, emitError } = transformRenderStreamChunksToResultObject(
    renderState,
    'RSC',
  );

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

/**
 * Adds async props capability to component props.
 *
 * DESIGN DECISION: Function in props vs. Hook
 *
 * We use `getReactOnRailsAsyncProp` function in props instead of a `useAsyncProps` hook because:
 *
 * 1. REACT SERVER COMPONENTS: RSCs cannot use hooks - they're async functions, not components
 *    with a render lifecycle. Hooks require the React hooks runtime which isn't available in RSC.
 *
 * 2. SIMPLER ARCHITECTURE: No need for React Context or Provider wrappers.
 *    The function is just a closure over the AsyncPropsManager.
 *
 * 3. TYPE SAFETY: TypeScript can infer the prop types from the generic parameters,
 *    giving autocomplete for available async props.
 *
 * USAGE:
 * ```tsx
 * // Types define what async props are available
 * type AsyncProps = { users: User[]; posts: Post[] };
 * type SyncProps = { title: string };
 *
 * // Component receives getReactOnRailsAsyncProp with proper types
 * function Dashboard({ title, getReactOnRailsAsyncProp }: WithAsyncProps<AsyncProps, SyncProps>) {
 *   const users = await getReactOnRailsAsyncProp('users');  // Promise<User[]>
 *   const posts = await getReactOnRailsAsyncProp('posts');  // Promise<Post[]>
 *   // ...
 * }
 * ```
 *
 * @param props - The component props to enhance
 * @param sharedExecutionContext - Map scoped to the current HTTP request for sharing state
 * @returns props - Original props plus getReactOnRailsAsyncProp function
 */
function addAsyncPropsCapabilityToComponentProps<
  AsyncPropsType extends Record<string, unknown>,
  PropsType extends Record<string, unknown>,
>(props: PropsType, sharedExecutionContext: Map<string, unknown>) {
  const asyncPropManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
  const propsAfterAddingAsyncProps = {
    ...props,
    // This function is a closure over asyncPropManager, allowing the component
    // to retrieve async props without needing access to the manager directly.
    getReactOnRailsAsyncProp: <PropName extends keyof AsyncPropsType>(propName: PropName) => {
      return asyncPropManager.getProp(propName as string) as Promise<AsyncPropsType[PropName]>;
    },
  };

  return {
    props: propsAfterAddingAsyncProps,
  };
}

ReactOnRails.addAsyncPropsCapabilityToComponentProps = addAsyncPropsCapabilityToComponentProps;
ReactOnRails.getOrCreateAsyncPropsManager = getOrCreateAsyncPropsManager;

ReactOnRails.isRSCBundle = true;

export * from 'react-on-rails/types';
export default ReactOnRails;
