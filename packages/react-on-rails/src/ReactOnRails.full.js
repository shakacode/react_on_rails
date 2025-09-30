import handleError from './handleError.js';
import serverRenderReactComponent from './serverRenderReactComponent.js';
import Client from './ReactOnRails.client.js';
if (typeof window !== 'undefined') {
  // warn to include a collapsed stack trace
  console.warn(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account). Click this for the stack trace.',
  );
}
Client.handleError = (options) => handleError(options);
Client.serverRenderReactComponent = (options) => serverRenderReactComponent(options);
export * from './types/index.js';
export default Client;
//# sourceMappingURL=ReactOnRails.full.js.map
