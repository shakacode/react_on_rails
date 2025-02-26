import handleError from './handleError';
import serverRenderReactComponent from './serverRenderReactComponent';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent';

import Client from './ReactOnRails.client';

if (typeof window !== 'undefined') {
  console.log("This file shouldn't be loaded in the browser, your configuration may be wrong");
}

Client.handleError = handleError;

Client.serverRenderReactComponent = serverRenderReactComponent;

Client.streamServerRenderedReactComponent = streamServerRenderedReactComponent;

export * from "./types";
export default Client;
