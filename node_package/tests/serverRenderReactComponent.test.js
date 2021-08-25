/* eslint-disable react/jsx-filename-extension */
/* eslint-disable no-unused-vars */

import React from 'react';

import serverRenderReactComponent from '../src/serverRenderReactComponent';
import ComponentRegistry from '../src/ComponentRegistry';

describe('serverRenderReactComponent', () => {
  beforeEach(() => {
    ComponentRegistry.components().clear();
  });

  it('serverRenderReactComponent renders a registered component', () => {
    expect.assertions(2);
    const X1 = () => <div>HELLO</div>;
    ComponentRegistry.register({ X1 });

    const renderResult = serverRenderReactComponent({ name: 'X1', domNodeId: 'myDomId', trace: false });
    const { html, hasErrors } = JSON.parse(renderResult);

    const result = html.indexOf('>HELLO</div>') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders errors', () => {
    expect.assertions(2);
    const X2 = () => {
      throw new Error('XYZ');
    };

    ComponentRegistry.register({ X2 });

    // Not testing the consoleReplayScript, as handleError is putting the console to the test
    // runner log.
    const renderResult = serverRenderReactComponent({ name: 'X2', domNodeId: 'myDomId', trace: false });
    const { html, hasErrors } = JSON.parse(renderResult);

    const result = html.indexOf('XYZ') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
    expect(hasErrors).toBeTruthy();
  });

  it('serverRenderReactComponent renders html', () => {
    expect.assertions(2);
    const expectedHtml = '<div>Hello</div>';
    const X3 = (props, _railsContext) => ({ renderedHtml: expectedHtml });

    ComponentRegistry.register({ X3 });

    const renderResult = serverRenderReactComponent({ name: 'X3', domNodeId: 'myDomId', trace: false });
    const { html, hasErrors, renderedHtml } = JSON.parse(renderResult);

    expect(html).toEqual(expectedHtml);
    expect(hasErrors).toBeFalsy();
  });

  it('serverRenderReactComponent renders an error if attempting to render a renderer', () => {
    expect.assertions(1);
    const X4 = (a1, a2, a3) => null;
    ComponentRegistry.register({ X4 });

    const renderResult = serverRenderReactComponent({ name: 'X4', domNodeId: 'myDomId', trace: false });
    const { html } = JSON.parse(renderResult);

    const result = html.indexOf('renderer') > 0 && html.indexOf('Exception in rendering!') > 0;
    expect(result).toBeTruthy();
  });

  it('serverRenderReactComponent renders promises', async () => {
    expect.assertions(2);
    const expectedHtml = '<div>Hello</div>';
    const X5 = (props, _railsContext) => Promise.resolve(expectedHtml);

    ComponentRegistry.register({ X5 });

    const renderResult = await serverRenderReactComponent({
      name: 'X5',
      domNodeId: 'myDomId',
      trace: false,
      renderingReturnsPromises: true,
    });
    const html = await renderResult.html;

    expect(html).toEqual(expectedHtml);
    expect(renderResult.hasErrors).toBeFalsy();
  });
});
