import test from 'tape';
import serverRenderReactComponent from '../src/serverRenderReactComponent';
import ComponentStore from '../src/ComponentStore';
import React from 'react';

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
