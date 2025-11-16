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
import { ReactComponent, RenderFunction } from 'react-on-rails/types';
import ReactOnRails from '../ReactOnRails.client.ts';
import RSCRoute from '../RSCRoute.tsx';
import wrapServerComponentRenderer from '../wrapServerComponentRenderer/server.tsx';

/**
 * Registers React Server Components for use in server bundles.
 *
 * This function:
 * 1. Takes server component implementations
 * 2. Wraps each component with RSCRoute using WrapServerComponentRenderer
 * 3. Registers the wrapped components with ReactOnRails
 *
 * @param components - Object mapping component names to their implementations
 *
 * @example
 * ```js
 * registerServerComponent({
 *   ServerComponent1: ServerComponent1Component,
 *   ServerComponent2: ServerComponent2Component
 * });
 * ```
 */
const registerServerComponent = (components: Record<string, ReactComponent>) => {
  const componentsWrappedInRSCRoute: Record<string, RenderFunction> = {};
  for (const [componentName] of Object.entries(components)) {
    componentsWrappedInRSCRoute[componentName] = wrapServerComponentRenderer((props: unknown) => (
      <RSCRoute componentName={componentName} componentProps={props} />
    ));
  }

  ReactOnRails.register(componentsWrappedInRSCRoute);
};

export default registerServerComponent;
