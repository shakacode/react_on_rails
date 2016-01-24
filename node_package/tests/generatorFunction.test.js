/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */

import test from 'tape';
import React from 'react';
import generatorFunction from '../src/generatorFunction';

test('generatorFunction: ES5 Component recognized as React.Component', (assert) => {
  assert.plan(1);

  const es5Component = React.createClass({
    render() {
      return (<div>ES5 React Component</div>);
    },
  });

  assert.equal(generatorFunction(es5Component), false,
    'ES5 Component should not be a generatorFunction');
});

test('generatorFunction: ES6 class recognized as React.Component', (assert) => {
  assert.plan(1);

  class ES6Component extends React.Component {
    render() {
      return (<div>ES6 Component</div>);
    }
  }

  assert.equal(generatorFunction(ES6Component), false,
    'es6Component should not be a generatorFunction');
});

test('generatorFunction: ES6 class subclass recognized as React.Component', (assert) => {
  assert.plan(1);

  class ES6Component extends React.Component {
    render() {
      return (<div>ES6 Component</div>);
    }
  }

  class ES6ComponentChild extends ES6Component {
    render() {
      return (<div>ES6 Component Child</div>);
    }
  }

  assert.equal(generatorFunction(ES6ComponentChild), false,
    'es6ComponentChild should not be a generatorFunction');
});

test('generatorFunction: pure component recognized as React.Component', (assert) => {
  assert.plan(1);

  /* eslint-disable react/prop-types */
  const pureComponent = (props) => <h1>{ props.title }</h1>;
  /* eslint-enable react/prop-types */

  assert.equal(generatorFunction(pureComponent), true,
    'pure component should not be a generatorFunction');
});

test('generatorFunction: Generator function recognized as such', (assert) => {
  assert.plan(1);

  const foobarComponent = React.createClass({
    render() {
      return (<div>Component for Generator Function</div>);
    },
  });

  const foobarGeneratorFunction = () => {
    return foobarComponent;
  };

  assert.equal(generatorFunction(foobarGeneratorFunction), true,
    'generatorFunction should be recognized as a generatorFunction');
});

test('generatorFunction: simple object returns false', (assert) => {
  assert.plan(1);

  const foobarComponent = {
    hello() {
      return 'world';
    },
  };
  assert.equal(generatorFunction(foobarComponent), false,
    'Plain object is not a generator function.');
});
