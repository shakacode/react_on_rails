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

test('StoreRegistry throws error for registering null or undefined store', (assert) => {
  assert.plan(2);
  StoreRegistry.stores().clear();
  assert.throws(() => StoreRegistry.register({ storeGenerator: null }),
    /Called ReactOnRails.registerStores with a null or undefined as a value/,
    'Expected an exception for calling StoreRegistry.register with an invalid store generator.'
  );
  assert.throws(() => StoreRegistry.register({ storeGenerator: undefined }),
    /Called ReactOnRails.registerStores with a null or undefined as a value/,
    'Expected an exception for calling StoreRegistry.register with an invalid store generator.'
  );
});

test('StoreRegistry throws error for retrieving unregistered store', (assert) => {
  assert.plan(1);
  StoreRegistry.stores().clear();
  assert.throws(() => StoreRegistry.getStore('foobar'),
    /There are no stores hydrated and you are requesting the store/,
    'Expected an exception for calling StoreRegistry.getStore with no registered stores.'
  );
});

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
    /Could not find store registered with name 'foobar'\. Registered store names include/,
    'Expected an exception for calling StoreRegistry.getStoreGenerator with an invalid name.'
  );
});

test('StoreRegistry returns undefined for retrieving unregistered store, ' +
  'passing throwIfMissing = false',
  (assert) => {
    assert.plan(1);
    StoreRegistry.setStore('foobarX', {});
    const actual = StoreRegistry.getStore('foobar', false);
    const expected = undefined;
    assert.equals(actual, expected, 'StoreRegistry.get should return undefined for missing ' +
      'store if throwIfMissing is passed as false'
    );
  }
);

test('StoreRegistry getStore, setStore', (assert) => {
  assert.plan(1);
  const store = storeGenerator({});
  StoreRegistry.setStore('storeGenerator', store);
  const actual = StoreRegistry.getStore('storeGenerator');
  const expected = store;
  assert.deepEqual(actual, expected, 'StoreRegistry should store and retrieve the store');
});

test('StoreRegistry throws error for retrieving unregistered hydrated store', (assert) => {
  assert.plan(1);
  assert.throws(() => StoreRegistry.getStore('foobar'),
    /Could not find hydrated store with name 'foobar'\. Hydrated store names include/,
    'Expected an exception for calling StoreRegistry.getStore with an invalid name.'
  );
});
