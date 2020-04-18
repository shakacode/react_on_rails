/* eslint-disable react/no-multi-comp */
/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable react/jsx-filename-extension */

import React from 'react';
import createReactClass from 'create-react-class';

import isRenderFunction from '../src/isRenderFunction';

describe('isRenderFunction', () => {
  expect.assertions(6);
  it('returns false for a ES5 React Component', () => {
    expect.assertions(1);

    const es5Component = createReactClass({
      render() {
        return <div>ES5 React Component</div>;
      },
    });

    expect(isRenderFunction(es5Component)).toBe(false);
  });

  it('returns false for a ES6 React class', () => {
    expect.assertions(1);

    class ES6Component extends React.Component {
      render() {
        return <div>ES6 Component</div>;
      }
    }

    expect(isRenderFunction(ES6Component)).toBe(false);
  });

  it('returns false for a ES6 React subclass', () => {
    expect.assertions(1);

    class ES6Component extends React.Component {
      render() {
        return <div>ES6 Component</div>;
      }
    }

    class ES6ComponentChild extends ES6Component {
      render() {
        return <div>ES6 Component Child</div>;
      }
    }

    expect(isRenderFunction(ES6ComponentChild)).toBe(false);
  });

  it('returns false for a stateless functional component with zero params', () => {
    expect.assertions(1);

    const pureComponent = () => <h1>Hello</h1>;

    expect(isRenderFunction(pureComponent)).toBe(false);
  });

  it('returns false for a stateless functional component with one param', () => {
    expect.assertions(1);

    /* eslint-disable react/prop-types */
    const pureComponent = (props) => <h1>{props.title}</h1>;
    /* eslint-enable react/prop-types */

    expect(isRenderFunction(pureComponent)).toBe(false);
  });

  it('returns true for a render function (containing two params)', () => {
    expect.assertions(1);

    const foobarComponent = () => <div>Component for render function</div>;
    const foobarrenderFunction = (_props, _railsContext) => foobarComponent;

    expect(isRenderFunction(foobarrenderFunction)).toBe(true);
  });

  it('returns false for simple object', () => {
    expect.assertions(1);

    const foobarComponent = {
      hello() {
        return 'world';
      },
    };
    expect(isRenderFunction(foobarComponent)).toBe(false);
  });
});
