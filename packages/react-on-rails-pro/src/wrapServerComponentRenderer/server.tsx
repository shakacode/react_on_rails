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

import * as React from 'react';
import type { RenderFunction, ReactComponentOrRenderFunction } from 'react-on-rails/types';
import isRenderFunction from 'react-on-rails/isRenderFunction';
import { assertRailsContextWithServerStreamingCapabilities } from 'react-on-rails/types';
import getReactServerComponent from '../getReactServerComponent.server.ts';
import { createRSCProvider } from '../RSCProvider.tsx';

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
const wrapServerComponentRenderer = (
  componentOrRenderFunction: ReactComponentOrRenderFunction,
  componentName?: string,
) => {
  if (typeof componentOrRenderFunction !== 'function') {
    throw new Error('wrapServerComponentRenderer: component is not a function');
  }

  const displayName = componentName ?? 'Unknown';

  const wrapper: RenderFunction = async (props, railsContext) => {
    try {
      assertRailsContextWithServerStreamingCapabilities(railsContext);
    } catch (e) {
      const originalMessage = e instanceof Error ? `\n\nOriginal error: ${e.message}` : '';
      throw new Error(
        `Server component '${displayName}' cannot be rendered in this context.\n\n` +
          `This usually means one of:\n` +
          `1. '${displayName}' uses client-side features (hooks, event handlers, class components)\n` +
          `   but is missing the "use client" directive at the top of its file.\n` +
          `   Add '"use client";' as the first line to register it as a client component.\n` +
          `2. '${displayName}' is rendered with react_component() instead of stream_react_component().\n` +
          `   Server components require the streaming render helper.${originalMessage}`,
      );
    }

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
