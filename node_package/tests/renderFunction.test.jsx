/* eslint-disable react/prefer-es6-class */
/* eslint-disable react/prefer-stateless-function */
/* eslint-disable max-classes-per-file */

import * as React from 'react';
import * as createReactClass from 'create-react-class';

import isRenderFunction from '../src/isRenderFunction.ts';

describe('isRenderFunction', () => {
  it('returns false for a ES5 React Component', () => {
    const es5Component = createReactClass({
      render() {
        return <div>ES5 React Component</div>;
      },
    });

    expect(isRenderFunction(es5Component)).toBe(false);
  });

  it('returns false for a ES6 React class', () => {
    class ES6Component extends React.Component {
      render() {
        return <div>ES6 Component</div>;
      }
    }

    expect(isRenderFunction(ES6Component)).toBe(false);
  });

  it('returns false for a ES6 React subclass', () => {
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
    const pureComponent = () => <h1>Hello</h1>;

    expect(isRenderFunction(pureComponent)).toBe(false);
  });

  it('returns false for a stateless functional component with one param', () => {
    const pureComponent = (props) => <h1>{props.title}</h1>;

    expect(isRenderFunction(pureComponent)).toBe(false);
  });

  it('returns true for a Render-Function (containing two params)', () => {
    const foobarComponent = () => <div>Component for Render-Function</div>;
    const foobarrenderFunction = (_props, _railsContext) => foobarComponent;

    expect(isRenderFunction(foobarrenderFunction)).toBe(true);
  });

  it('returns false for simple object', () => {
    const foobarComponent = {
      hello() {
        return 'world';
      },
    };
    expect(isRenderFunction(foobarComponent)).toBe(false);
  });
});
