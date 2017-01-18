/* eslint-disable react/jsx-filename-extension */
/* eslint-disable no-unused-vars */

import React from 'react';
import test from 'tape';

import serverRenderReactComponent from '../src/serverRenderReactComponent';
import ComponentStore from '../src/ComponentRegistry';

test('serverRenderReactComponent renders a registered component', (assert) => {
  assert.plan(2);
  const X1 = () => <div>HELLO</div>;
  ComponentStore.register({ X1 });

  const { html, hasErrors } =
    JSON.parse(serverRenderReactComponent({ name: 'X1', domNodeId: 'myDomId', trace: false }));

  const actual = html.indexOf('>HELLO</div>') > 0;
  assert.ok(actual, 'serverRenderReactComponent should render HELLO');
  assert.ok(!hasErrors, 'serverRenderReactComponent should not have errors');
});

test('serverRenderReactComponent renders errors', (assert) => {
  assert.plan(2);
  const X2 = () => { throw new Error('XYZ'); };

  ComponentStore.register({ X2 });

  assert.comment('Expect to see a stack trace');

  // Not testing the consoleReplayScript, as handleError is putting the console to the test
  // runner log.
  const { html, hasErrors } =
    JSON.parse(serverRenderReactComponent({ name: 'X2', domNodeId: 'myDomId', trace: false }));

  const okHtml = html.indexOf('XYZ') > 0 && html.indexOf('Exception in rendering!') > 0;
  assert.ok(okHtml, 'serverRenderReactComponent HTML should render error message XYZ');
  assert.ok(hasErrors, 'serverRenderReactComponent should have errors if exception thrown');
});

test('serverRenderReactComponent renders html', (assert) => {
  assert.plan(3);
  const expectedHtml = '<div>Hello</div>';
  const X3 = () => ({ renderedHtml: expectedHtml });

  ComponentStore.register({ X3 });

  assert.comment('Expect to see renderedHtml');

  const { html, hasErrors, renderedHtml } =
    JSON.parse(serverRenderReactComponent({ name: 'X3', domNodeId: 'myDomId', trace: false }));

  assert.ok(html === expectedHtml, 'serverRenderReactComponent HTML should render renderedHtml value');
  assert.ok(!hasErrors, 'serverRenderReactComponent should not have errors if no exception thrown');
  assert.ok(!hasErrors, 'serverRenderReactComponent should have errors if exception thrown');
});

test('serverRenderReactComponent renders an error if attempting to render a renderer', (assert) => {
  assert.plan(1);
  const X3 = (a1, a2, a3) => null;
  ComponentStore.register({ X3 });

  const { html } =
    JSON.parse(serverRenderReactComponent({ name: 'X3', domNodeId: 'myDomId', trace: false }));

  const ok = html.indexOf('renderer') > 0 && html.indexOf('Exception in rendering!') > 0;
  assert.ok(
    ok,
    'serverRenderReactComponent renders an error if attempting to render a renderer',
  );
});
