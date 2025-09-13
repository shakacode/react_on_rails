/* Copyright (c) 2015–2025 ShakaCode, LLC
   SPDX-License-Identifier: MIT */
import * as React from 'react';
import type { RenderFunction, ReactComponentOrRenderFunction } from '../types/index.ts';
import getReactServerComponent from '../getReactServerComponent.server.ts';
import { createRSCProvider } from '../RSCProvider.tsx';
import isRenderFunction from '../isRenderFunction.ts';
import { assertRailsContextWithServerStreamingCapabilities } from '../types/index.ts';

/**
 * Wraps a client component with the necessary RSC context and handling for server-side operations.
 *
 * This higher-order function:
 * 1. Creates an RSCProvider with server-specific implementation of getReactServerComponent
 * 2. Provides a render function that returns React elements for SSR
 * 3. Ensures Suspense boundaries are properly set up for async rendering
 *
 * Use this version specifically for server bundle registration.
 *
 * @param componentOrRenderFunction - Client component or render function to wrap
 * @returns A render function that produces React elements for server-side rendering that should be registered with ReactOnRails.register
 *
 * @example
 * ```tsx
 * const WrappedComponent = WrapServerComponentRenderer(ClientComponent);
 * ReactOnRails.register({ ClientComponent: WrappedComponent });
 * ```
 */
const wrapServerComponentRenderer = (componentOrRenderFunction: ReactComponentOrRenderFunction) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error('wrapServerComponentRenderer: component is not a function');
  }

  const wrapper: RenderFunction = async (props, railsContext) => {
    assertRailsContextWithServerStreamingCapabilities(railsContext);

    const Component = isRenderFunction(componentOrRenderFunction)
      ? await componentOrRenderFunction(props, railsContext)
      : componentOrRenderFunction;

    if (typeof Component !== 'function') {
      throw new Error('wrapServerComponentRenderer: component is not a function');
    }

    const RSCProvider = createRSCProvider({
      getServerComponent: getReactServerComponent(railsContext),
    });

    return () => (
      <RSCProvider>
        <React.Suspense fallback={null}>
          <Component {...props} />
        </React.Suspense>
      </RSCProvider>
    );
  };

  return wrapper;
};

export default wrapServerComponentRenderer;
