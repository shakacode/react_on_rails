/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */

import test from 'tape';
import { createStore } from 'redux';
import React from 'react';

import ReactOnRails from '../src/ReactOnRails';

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

  // eslint-disable-next-line no-underscore-dangle
  const actual = ReactOnRails.render('R1', {}, 'root')._reactInternalInstance._currentElement.type;
  assert.deepEqual(actual, R1,
    'ReactOnRails render should return a virtual DOM element for component');
});

test('ReactOnRails accepts traceTurbolinks as an option true', (assert) => {
  ReactOnRails.resetOptions();
  assert.plan(1);
  ReactOnRails.setOptions({ traceTurbolinks: true });
  const actual = ReactOnRails.option('traceTurbolinks');
  assert.equal(actual, true);
});

test('ReactOnRails accepts traceTurbolinks as an option false', (assert) => {
  ReactOnRails.resetOptions();
  assert.plan(1);
  ReactOnRails.setOptions({ traceTurbolinks: false });
  const actual = ReactOnRails.option('traceTurbolinks');
  assert.equal(actual, false);
});

test('ReactOnRails not specified has traceTurbolinks as false', (assert) => {
  ReactOnRails.resetOptions();
  assert.plan(1);
  ReactOnRails.setOptions({ });
  const actual = ReactOnRails.option('traceTurbolinks');
  assert.equal(actual, false);
});

test('serverRenderReactComponent throws error for invalid options', (assert) => {
  ReactOnRails.resetOptions();
  assert.plan(1);
  assert.throws(
    () => ReactOnRails.setOptions({ foobar: true }),
    /Invalid option/,
    'setOptions should throw an error for invalid options',
  );
});

test('registerStore throws if passed a falsey object (null, undefined, etc)', (assert) => {
  assert.plan(3);

  assert.throws(
    () => ReactOnRails.registerStore(null),
    /null or undefined/,
    'registerStore should throw an error if a falsey value is passed (null)',
  );

  assert.throws(
    () => ReactOnRails.registerStore(undefined),
    /null or undefined/,
    'registerStore should throw an error if a falsey value is passed (undefined)',
  );

  assert.throws(
    () => ReactOnRails.registerStore(false),
    /null or undefined/,
    'registerStore should throw an error if a falsey value is passed (false)',
  );
});

test('register store and getStoreGenerator allow registration', (assert) => {
  assert.plan(2);
  function reducer() {
    return {};
  }

  function storeGenerator(props) {
    return createStore(reducer, props);
  }

  ReactOnRails.registerStore({ storeGenerator });

  const actual = ReactOnRails.getStoreGenerator('storeGenerator');
  assert.equal(actual, storeGenerator,
    `Could not find 'storeGenerator' amongst store generators \
${JSON.stringify(ReactOnRails.storeGenerators())}.`);

  assert.deepEqual(ReactOnRails.storeGenerators(), new Map([['storeGenerator', storeGenerator]]));
});

test('setStore and getStore', (assert) => {
  assert.plan(2);
  function reducer() {
    return {};
  }

  function storeGenerator(props) {
    return createStore(reducer, props);
  }

  const store = storeGenerator({});

  ReactOnRails.setStore('storeGenerator', store);

  const actual = ReactOnRails.getStore('storeGenerator');
  assert.equal(actual, store,
    `Could not find 'store' amongst store generators ${JSON.stringify(ReactOnRails.stores())}.`);
  const expected = new Map();
  expected.set('storeGenerator', store);

  assert.deepEqual(ReactOnRails.stores(), expected);
});

test('clearHydratedStores', (assert) => {
  assert.plan(2);
  function reducer() {
    return {};
  }

  function storeGenerator(props) {
    return createStore(reducer, props);
  }

  ReactOnRails.setStore('storeGenerator', storeGenerator);
  const actual = new Map();
  actual.set(storeGenerator);
  assert.deepEqual(actual, ReactOnRails.stores());

  ReactOnRails.clearHydratedStores();
  const expected = new Map();
  assert.deepEqual(ReactOnRails.stores(), expected,
    'clearHydratedStores should clear hydratedStores map');
});
