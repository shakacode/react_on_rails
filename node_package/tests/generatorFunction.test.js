/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */

import React from 'react';
import createReactClass from 'create-react-class';

import generatorFunction from '../src/generatorFunction';

describe('generatorFunction', () => {
  expect.assertions(6);
  it('returns false for a ES5 React Component', () => {
    expect.assertions(1);

    const es5Component = createReactClass({
      render() {
        return (<div>ES5 React Component</div>);
      },
    });

    expect(generatorFunction(es5Component)).toBe(false);
  });

  it('returns false for a ES6 React class', () => {
    expect.assertions(1);

    class ES6Component extends React.Component {
      render() {
        return (<div>ES6 Component</div>);
      }
    }

    expect(generatorFunction(ES6Component)).toBe(false);
  });

  it('returns false for a ES6 React subclass', () => {
    expect.assertions(1);

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

    expect(generatorFunction(ES6ComponentChild)).toBe(false);
  });

  it('returns true for a stateless functional component', () => {
    expect.assertions(1);

    /* eslint-disable react/prop-types */
    const pureComponent = (props) => <h1>{ props.title }</h1>;
    /* eslint-enable react/prop-types */

    expect(generatorFunction(pureComponent)).toBe(true);
  });

  it('returns true for a generator function', () => {
    expect.assertions(1);

    const foobarComponent = createReactClass({
      render() {
        return (<div>Component for Generator Function</div>);
      },
    });

    const foobarGeneratorFunction = () => foobarComponent;

    expect(generatorFunction(foobarGeneratorFunction)).toBe(true);
  });

  it('returns false for simple object', () => {
    expect.assertions(1);

    const foobarComponent = {
      hello() {
        return 'world';
      },
    };
    expect(generatorFunction(foobarComponent)).toBe(false);
  })
})
