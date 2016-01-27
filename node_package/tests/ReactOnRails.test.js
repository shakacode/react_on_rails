/* eslint-disable react/no-multi-comp */
import test from 'tape';
import React from 'react';
import ReactOnRails from '../src/ReactOnRails';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import JsDom from 'jsdom';

if (!canUseDOM) {
  global.document = JsDom.jsdom('<div id="root"></div>');
  global.window = document.defaultView;
}

test('ReactOnRails render returns a virtual DOM element for component', (assert) => {
  assert.plan(1);
  const R1 = React.createClass({
    render() {
      return (
        <div> WORLD </div>
      );
    },
  });
  ReactOnRails.register({ R1 });
  const actual = ReactOnRails.render('R1', {}, 'root')._reactInternalInstance._currentElement.type;
  assert.deepEqual(actual, R1,
    'ReactOnRails render should return a virtual DOM element for component');
});
