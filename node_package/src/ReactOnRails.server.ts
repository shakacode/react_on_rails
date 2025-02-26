import handleError from './handleError';
import serverRenderReactComponent from './serverRenderReactComponent';

import ReactOnRails from './ReactOnRails.client';

if (typeof window !== 'undefined') {
  console.log("This file shouldn't be loaded in the client. If your Webpack target is 'web' (default), add 'server' to 'resolve.conditionNames'.");
}

ReactOnRails.handleError = handleError;
ReactOnRails.serverRenderReactComponent = serverRenderReactComponent;

export * from "./types";
export default ReactOnRails;
