
import test from 'tape';
import StoreRegistry from '../src/StoreRegistry';
import React from 'react';
import { createStore } from 'redux';

function reducer(state = {}, action) {
  return {};
}

function storeGenerator(props) {
  return createStore(reducer, props);
};

function storeGenerator2(props) {
  return createStore(reducer, props);
};

test('StoreRegistry registers and retrieves generator function stores', (assert) => {
  assert.plan(2);
  StoreRegistry.register({ storeGenerator, storeGenerator2 });
  const actual = StoreRegistry.getStoreGenerator('storeGenerator');
  const expected = storeGenerator;
  assert.deepEqual(actual, expected,
    'StoreRegistry should store and retrieve the storeGenerator');
  const actual2 = StoreRegistry.getStoreGenerator('storeGenerator2');
  const expected2 = storeGenerator2;
  assert.deepEqual(actual2, expected2,
    'StoreRegistry should store and retrieve the storeGenerator2');
});

test('StoreRegistry throws error for retrieving unregistered store', (assert) => {
  assert.plan(1);
  assert.throws(() => StoreRegistry.getStoreGenerator('foobar'),
    /Could not find store registered with name foobar/,
    'Expected an exception for calling StoreRegistry.get with an invalid name.'
  );
});

test('StoreRegistry getStore, setStore', (assert) => {
  assert.plan(1);
  const store = storeGenerator({});
  StoreRegistry.setStore('storeGenerator', store);
  const actual = StoreRegistry.getStore('storeGenerator');
  const expected = store;
  assert.deepEqual(actual, expected, 'StoreRegistry should store and retrieve the store');
});

