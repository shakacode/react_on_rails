/* eslint-disable react/jsx-filename-extension */
/* eslint-disable no-unused-vars */

import React from 'react';

import serverRenderReactComponent from '../src/serverRenderReactComponent';
import ComponentStore from '../src/ComponentRegistry';

describe('serverRenderReactComponent', () => {
  expect.assertions(7);
  it('serverRenderReactComponent renders a registered component', () => {
    expect.assertions(2);
    const X1 = () => <div>HELLO</div>;
    ComponentStore.register({ X1 });

    const { html, hasErrors } =
      JSON.parse(serverRenderReactComponent({ name: 'X1', domNodeId: 'myDomId', trace: false }));

    const result = html.indexOf('>HELLO</div>') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders errors', () => {
    expect.assertions(2);
    const X2 = () => { throw new Error('XYZ'); };

    ComponentStore.register({ X2 });

    // Not testing the consoleReplayScript, as handleError is putting the console to the test
    // runner log.
    const { html, hasErrors } =
      JSON.parse(serverRenderReactComponent({ name: 'X2', domNodeId: 'myDomId', trace: false }));

    const result = html.indexOf('XYZ') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders html', () => {
    expect.assertions(2);
    const expectedHtml = '<div>Hello</div>';
    const X3 = () => ({ renderedHtml: expectedHtml });

    ComponentStore.register({ X3 });

    const { html, hasErrors, renderedHtml } =
      JSON.parse(serverRenderReactComponent({ name: 'X3', domNodeId: 'myDomId', trace: false }));

    expect(html).toEqual(expectedHtml);
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders an error if attempting to render a renderer', () => {
    expect.assertions(1);
    const X3 = (a1, a2, a3) => null;
    ComponentStore.register({ X3 });

    const { html } =
      JSON.parse(serverRenderReactComponent({ name: 'X3', domNodeId: 'myDomId', trace: false }));

    const result = html.indexOf('renderer') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
  })
})
