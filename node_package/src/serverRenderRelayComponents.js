import ReactDOMServer from 'react-dom/server';
import buildConsoleReplay from './buildConsoleReplay';
import ReactOnRails from './ReactOnRails';
import Relay from 'react-relay';
import React from 'react';

export default function serverRenderRelayComponents(options) {
  const { componentName, domNodeId, routeName } = options;

  let htmlResult = '';
  const hasErrors = false;
  const componentObj = ReactOnRails.getComponent(componentName);
  const routeObj = ReactOnRails.getRoute(routeName);

  // CONSIDER NOT RELEASING THE OPTION version
  const { component } = componentObj;
  const { route } = routeObj;

  htmlResult = ReactDOMServer.render(
  <Relay.RootContainer
    Component={component}
    route={route}
    renderLoading={function() {
    return  <div className="loader">
              <span className="fa fa-spin fa-spinner"></span>
            </div>;
    }}
  />,
    document.getElementById(domNodeId)
  );

  const consoleReplayScript = buildConsoleReplay();

  return JSON.stringify({
    html: htmlResult,
    consoleReplayScript,
    hasErrors,
  });
}
