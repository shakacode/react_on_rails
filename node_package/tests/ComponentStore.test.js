/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */

import test from 'tape';
import ComponentStore from '../src/ComponentStore';
import React from 'react';

test('ComponentStore registers and retrieves generator function components', (assert) => {
  assert.plan(1);
  const C1 = () => <div>HELLO</div>;
  ComponentStore.register({ C1 });
  const actual = ComponentStore.get('C1');
  const expected = { name: 'C1', component: C1, generatorFunction: true };
  assert.deepEqual(actual, expected,
    'ComponentStore should store and retrieve a generator function');
});

test('ComponentStore registers and retrieves ES5 class components', (assert) => {
  assert.plan(1);
  const C2 = React.createClass({
    render() {
      return (
        <div> WORLD </div>
      );
    },
  });
  ComponentStore.register({ C2 });
  const actual = ComponentStore.get('C2');
  const expected = { name: 'C2', component: C2, generatorFunction: false };
  assert.deepEqual(actual, expected,
    'ComponentStore should store and retrieve a ES5 class');
});

test('ComponentStore registers and retrieves ES6 class components', (assert) => {
  assert.plan(1);
  class C3 extends React.Component {
    render() {
      return (
        <div>Wow!</div>
      );
    }
  }
  ComponentStore.register({ C3 });
  const actual = ComponentStore.get('C3');
  const expected = { name: 'C3', component: C3, generatorFunction: false };
  assert.deepEqual(actual, expected,
    'ComponentStore should store and retrieve a ES6 class');
});

/*
 * NOTE: Since ComponentStore is a singleton, it preserves value as the tests run.
 * Thus, tests are cummulative.
 */
test('ComponentStore registers and retrieves multiple components', (assert) => {
  assert.plan(3);
  const C4 = () => <div>WHY</div>;
  const C5 = () => <div>NOW</div>;
  ComponentStore.register({ C4 });
  ComponentStore.register({ C5 });
  const components = ComponentStore.components();
  assert.equal(components.size, 5, 'size should be 5');
  assert.deepEqual(components.get('C4'),
    { name: 'C4', component: C4, generatorFunction: true });
  assert.deepEqual(components.get('C5'),
    { name: 'C5', component: C5, generatorFunction: true });
});
