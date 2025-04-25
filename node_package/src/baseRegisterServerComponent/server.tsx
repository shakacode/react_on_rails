import * as React from 'react';
import ReactOnRails from '../ReactOnRails.client';
import RSCServerRoot from '../RSCServerRoot';
import { ReactComponent, RenderFunction, RailsContext } from '../types';

/**
 * Registers React Server Components (RSC) with React on Rails for the server bundle.
 *
 * This function wraps each component with RSCServerRoot, which handles the server-side
 * rendering of React Server Components using pre-generated RSC payloads.
 *
 * The RSCServerRoot component:
 * - Uses pre-generated RSC payloads from the RSC bundle
 * - Builds the rendering tree of the server component
 * - Handles the integration with React's streaming SSR
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
const registerServerComponent = (
  WrapperComponent: ReactComponent,
  components: Record<string, ReactComponent>,
) => {
  const componentsWrappedInRSCServerRoot: Record<string, RenderFunction> = {};
  for (const [componentName] of Object.entries(components)) {
    componentsWrappedInRSCServerRoot[componentName] = (
      componentProps?: unknown,
      railsContext?: RailsContext,
    ) =>
      RSCServerRoot(
        {
          ServerComponentContainer: () => (
            <WrapperComponent
              railsContext={railsContext}
              componentName={componentName}
              componentProps={componentProps}
            />
          ),
        },
        railsContext,
      );
  }
  ReactOnRails.register(componentsWrappedInRSCServerRoot);
};

export default registerServerComponent;
