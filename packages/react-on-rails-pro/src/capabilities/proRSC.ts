/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

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

import { Readable } from 'stream';

import * as React from 'react';

import {
  RSCRenderParams,
  assertRailsContextWithServerStreamingCapabilities,
  StreamRenderState,
  StreamableComponentResult,
} from 'react-on-rails/types';
import { convertToError } from 'react-on-rails/serverRenderUtils';
import handleError from '../handleErrorRSC.ts';
import { getOrCreateAsyncPropsManager } from '../AsyncPropsManager.ts';

import {
  streamServerRenderedComponent,
  StreamingTrackers,
  transformRenderStreamChunksToResultObject,
} from '../streamingUtils.ts';
import { setManifestFileNames, getRscCssHrefs } from '../cache/manifestLoader.ts';
import { getServerRenderer } from '../cache/manifestLoaderServer.ts';
import { setBuildId } from '../cache/buildIdProvider.ts';

// Precedence group for RSC-emitted stylesheet <link>s. React 19 hoists links
// that share a precedence into <head> together and blocks tree commit until they
// load, which is what prevents CSS FOUC on 'use client' boundaries (#3211).
const RSC_CSS_PRECEDENCE = 'ror-rsc';

/**
 * Wrap the rendered RSC tree with `<link rel="stylesheet" precedence>` for every
 * stylesheet imported behind a `'use client'` boundary. Emitting the links
 * inside the RSC payload means React hoists/dedupes them into `<head>` on both
 * the initial SSR stream and on client-side navigation (the same payload decodes
 * identically), so no CSR-specific handling is needed.
 */
const wrapWithRscCssLinks = (renderedTree: React.ReactNode, cssHrefs: readonly string[]): React.ReactNode => {
  if (cssHrefs.length === 0) {
    return renderedTree;
  }

  const stylesheetLinks = cssHrefs.map((href) =>
    React.createElement('link', { key: href, rel: 'stylesheet', href, precedence: RSC_CSS_PRECEDENCE }),
  );
  return React.createElement(React.Fragment, null, stylesheetLinks, renderedTree);
};

const CLIENT_HOOK_NAMES = [
  'useState',
  'useEffect',
  'useReducer',
  'useCallback',
  'useMemo',
  'useRef',
  'useLayoutEffect',
  'useImperativeHandle',
  'useContext',
  'useSyncExternalStore',
  'useTransition',
  'useDeferredValue',
  'useId',
  'useDebugValue',
  'useInsertionEffect',
  'useOptimistic',
  'useActionState',
].join('|');
const CLIENT_HOOK_RUNTIME_ERROR_REGEX = new RegExp(
  `(?:(?:React\\.)|\\(0\\s*,\\s*[\\w$]+\\.)?(${CLIENT_HOOK_NAMES})\\)? is not a function\\b`,
);

const addRSCClientHookDiagnostic = (error: Error, componentName: string): Error => {
  const match = error.message.match(CLIENT_HOOK_RUNTIME_ERROR_REGEX);
  if (!match) return error;

  const hookName = match[1];
  const enhancedError = new Error(
    `[React on Rails Pro] Component "${componentName}" called client hook "${hookName}" while rendering in ` +
      `the React Server Components runtime.\n\n` +
      `Most likely cause: "${componentName}", or a component it imports, uses client-only APIs but is missing ` +
      `the '"use client";' directive.\n\n` +
      `Add '"use client";' as the first statement of the client component file, or move hooks, event handlers, ` +
      `and class components into a separate client component.\n\n` +
      `Note: .client/.server file suffixes only control bundle placement. The '"use client";' directive controls ` +
      `RSC client/server classification.\n\n` +
      `Original error: ${error.message}`,
  ) as Error & { cause?: unknown };

  enhancedError.name = error.name;
  enhancedError.cause = error;
  const enhancedStackFrames = enhancedError.stack?.split('\n').slice(1).join('\n');
  enhancedError.stack = `${enhancedError.name}: ${enhancedError.message}${
    enhancedStackFrames ? `\n${enhancedStackFrames}` : ''
  }\nCaused by: ${error.stack || error.message}`;

  return enhancedError;
};

const streamRenderRSCComponent = (
  reactRenderingResult: StreamableComponentResult,
  options: RSCRenderParams,
  streamingTrackers: StreamingTrackers,
): Readable => {
  const { name: componentName, throwJsErrors } = options;
  const { railsContext } = options;
  assertRailsContextWithServerStreamingCapabilities(railsContext);

  const { reactClientManifestFileName, reactServerClientManifestFileName } = railsContext;
  const rscPayloadParams = railsContext.serverSideRSCPayloadParameters as
    | { rscBundleHash?: string }
    | undefined;

  // Initialize manifest loader and BUILD_ID on first render request.
  // These are per-process constants that don't change between requests.
  setManifestFileNames(reactClientManifestFileName, reactServerClientManifestFileName);
  if (rscPayloadParams?.rscBundleHash) {
    setBuildId(rscPayloadParams.rscBundleHash);
  }

  const renderState: StreamRenderState = {
    result: null,
    hasErrors: false,
    isShellReady: true,
  };

  const { pipeToTransform, readableStream, emitError } =
    transformRenderStreamChunksToResultObject(renderState);

  const reportError = (error: Error): Error => {
    const diagnosticError = addRSCClientHookDiagnostic(error, componentName);
    console.error('Error in RSC stream', diagnosticError);
    if (throwJsErrors) {
      emitError(diagnosticError);
    }
    renderState.hasErrors = true;
    renderState.error = diagnosticError;

    return diagnosticError;
  };

  const initializeAndRender = async () => {
    const { renderToPipeableStream } = await getServerRenderer();
    const cssHrefsPromise = getRscCssHrefs().catch((err: unknown) => {
      console.error('Error loading RSC CSS hrefs', convertToError(err));
      return [] as string[];
    });
    const [renderedTree, cssHrefs] = await Promise.all([reactRenderingResult, cssHrefsPromise]);
    const rscStream = renderToPipeableStream(wrapWithRscCssLinks(renderedTree, cssHrefs), {
      onError: (err) => {
        const error = convertToError(err);
        reportError(error);
      },
    });
    pipeToTransform(rscStream);
  };

  initializeAndRender().catch((e: unknown) => {
    const error = reportError(convertToError(e));
    const errorHtml = handleError({ e: error, name: options.name, serverSide: true });
    pipeToTransform(errorHtml);
  });

  readableStream.on('end', () => {
    streamingTrackers.postSSRHookTracker.notifySSREnd();
  });
  return readableStream;
};

/**
 * Pro RSC capability.
 * Provides React Server Components rendering support.
 */
export function createProRSCCapability() {
  return {
    isRSCBundle: true as const,

    serverRenderRSCReactComponent(options: RSCRenderParams): Readable {
      try {
        return streamServerRenderedComponent(options, streamRenderRSCComponent, handleError);
      } finally {
        console.history = [];
      }
    },

    addAsyncPropsCapabilityToComponentProps<
      AsyncPropsType extends Record<string, unknown>,
      PropsType extends Record<string, unknown>,
    >(props: PropsType, sharedExecutionContext: Map<string, unknown>) {
      const asyncPropManager = getOrCreateAsyncPropsManager(sharedExecutionContext);
      const propsAfterAddingAsyncProps = {
        ...props,
        getReactOnRailsAsyncProp: <PropName extends keyof AsyncPropsType>(propName: PropName) => {
          return asyncPropManager.getProp(propName as string) as Promise<AsyncPropsType[PropName]>;
        },
      };

      return { props: propsAfterAddingAsyncProps };
    },

    getOrCreateAsyncPropsManager(sharedExecutionContext: Map<string, unknown>) {
      return getOrCreateAsyncPropsManager(sharedExecutionContext);
    },
  };
}
