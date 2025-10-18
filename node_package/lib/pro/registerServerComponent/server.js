import { jsx as _jsx } from 'react/jsx-runtime';
import ReactOnRails from '../../ReactOnRails.client.js';
import RSCRoute from '../RSCRoute.js';
import wrapServerComponentRenderer from '../wrapServerComponentRenderer/server.js';
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
const registerServerComponent = (components) => {
  const componentsWrappedInRSCRoute = {};
  for (const [componentName] of Object.entries(components)) {
    componentsWrappedInRSCRoute[componentName] = wrapServerComponentRenderer((props) =>
      _jsx(RSCRoute, { componentName, componentProps: props }),
    );
  }
  ReactOnRails.register(componentsWrappedInRSCRoute);
};
export default registerServerComponent;
