import { jsx as _jsx } from 'react/jsx-runtime';
import ReactOnRails from '../../ReactOnRails.client.js';
import RSCRoute from '../RSCRoute.js';
import wrapServerComponentRenderer from '../wrapServerComponentRenderer/client.js';
/**
 * Registers React Server Components (RSC) with React on Rails.
 * This function wraps server components with RSCClientRoot to handle client-side rendering
 * and hydration of RSC payloads.
 *
 * Important: Components registered with this function are not included in the client bundle.
 * Instead, when the component needs to be rendered:
 * 1. A request is made to `${rscPayloadGenerationUrlPath}/${componentName}`
 * 2. The server returns an RSC payload containing:
 *    - Server component rendered output
 *    - References to client components that need hydration
 *    - Data props passed to client components
 * 3. The RSC payload is processed and rendered as HTML on the client
 *
 * This approach enables:
 * - Smaller client bundles (server components code stays on server)
 * - Progressive loading of components
 * - Automatic handling of data requirements
 *
 * @param options - Configuration options for RSC rendering
 * @param options.rscPayloadGenerationUrlPath - The base URL path where RSC payloads will be fetched from
 * @param componentNames - Names of server components to register
 *
 * @example
 * ```js
 * registerServerComponent('ServerComponent1', 'ServerComponent2');
 *
 * // When ServerComponent1 renders, it will fetch from: /rsc_payload/ServerComponent1
 * ```
 */
const registerServerComponent = (...componentNames) => {
  const componentsWrappedInRSCRoute = {};
  for (const name of componentNames) {
    componentsWrappedInRSCRoute[name] = wrapServerComponentRenderer((props) =>
      _jsx(RSCRoute, { componentName: name, componentProps: props }),
    );
  }
  ReactOnRails.register(componentsWrappedInRSCRoute);
};
export default registerServerComponent;
