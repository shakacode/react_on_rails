import PropTypes from 'prop-types';
import React from 'react';

import {
  wrapElementInStrictMode,
  wrapRegisteredComponentsWithStrictMode,
} from '../client/app/strictModeSupport';

describe('strictModeSupport', () => {
  it('wraps registered React components in StrictMode', () => {
    const HelloWorld = ({ greeting }) => <div>{greeting}</div>;
    HelloWorld.propTypes = {
      greeting: PropTypes.string.isRequired,
    };
    const wrappedComponent = wrapRegisteredComponentsWithStrictMode({ HelloWorld }).HelloWorld;

    expect(wrappedComponent).not.toBe(HelloWorld);

    const wrappedElement = wrappedComponent({ greeting: 'hello' });
    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children.type).toBe(HelloWorld);
    expect(wrappedElement.props.children.props.greeting).toBe('hello');
  });

  it('reuses the same wrapper for repeated registrations of the same component', () => {
    const HelloWorld = () => <div>Hello</div>;

    const firstWrappedComponent = wrapRegisteredComponentsWithStrictMode({ HelloWorld }).HelloWorld;
    const secondWrappedComponent = wrapRegisteredComponentsWithStrictMode({ HelloWorld }).HelloWorld;

    expect(firstWrappedComponent).toBe(secondWrappedComponent);
  });

  it('wraps class components and preserves useful display names', () => {
    // eslint-disable-next-line react/prefer-stateless-function
    class HelloWorld extends React.Component {
      render() {
        return <div>Hello</div>;
      }
    }

    const wrappedComponent = wrapRegisteredComponentsWithStrictMode({ HelloWorld }).HelloWorld;
    const wrappedElement = wrappedComponent({});

    expect(wrappedComponent.displayName).toBe('StrictMode(HelloWorld)');
    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children.type).toBe(HelloWorld);
  });

  it('skips 3-arg renderer functions (they manage their own DOM root)', () => {
    const rendererFunction = (props, railsContext, domNodeId) => ({ props, railsContext, domNodeId });
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ rendererFunction });

    expect(wrappedComponents.rendererFunction).toBe(rendererFunction);
  });

  it('wraps 2-arg render functions and intercepts React element results in StrictMode', () => {
    const renderFunction = (props, _railsContext) => <div>{props.greeting}</div>;
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ renderFunction });

    expect(wrappedComponents.renderFunction).not.toBe(renderFunction);
    const result = wrappedComponents.renderFunction({ greeting: 'hello' }, {});
    expect(result.type).toBe(React.StrictMode);
    expect(result.props.children.type).toBe('div');
    expect(result.props.children.props.children).toBe('hello');
  });

  it('wraps render functions flagged with renderFunction = true', () => {
    const flaggedRenderFunction = (props) => <div>{props.greeting}</div>;
    flaggedRenderFunction.renderFunction = true;
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ flaggedRenderFunction });

    expect(wrappedComponents.flaggedRenderFunction).not.toBe(flaggedRenderFunction);
    const result = wrappedComponents.flaggedRenderFunction({ greeting: 'hello' });
    expect(result.type).toBe(React.StrictMode);
    expect(result.props.children.type).toBe('div');
  });

  it('passes through non-element results from render functions unchanged', () => {
    const renderFunction = (props, railsContext) => ({ props, railsContext });
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ renderFunction });

    const result = wrappedComponents.renderFunction({ a: 1 }, { b: 2 });
    expect(result).toEqual({ props: { a: 1 }, railsContext: { b: 2 } });
  });

  it('wraps a component result returned from a render function via the component path', () => {
    const ResultComponent = ({ greeting }) => <span>{greeting}</span>;
    ResultComponent.propTypes = {
      greeting: PropTypes.string.isRequired,
    };
    const renderFunction = (_props, _railsContext) => ResultComponent;
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ renderFunction });

    const wrappedResult = wrappedComponents.renderFunction({}, {});
    expect(wrappedResult).not.toBe(ResultComponent);
    const wrappedElement = wrappedResult({ greeting: 'hello' });
    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children.type).toBe(ResultComponent);
  });

  it('respects explicit renderFunction = false on 2-arg components (component path)', () => {
    const TwoArgComponent = ({ greeting }, _legacyContext) => <div>{greeting}</div>;
    TwoArgComponent.propTypes = {
      greeting: PropTypes.string.isRequired,
    };
    TwoArgComponent.renderFunction = false;

    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ TwoArgComponent });

    expect(wrappedComponents.TwoArgComponent).not.toBe(TwoArgComponent);
    const wrappedElement = wrappedComponents.TwoArgComponent({ greeting: 'hello' });
    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children.type).toBe(TwoArgComponent);
  });

  it('treats a 2-arg functional component as a render function by default (arity heuristic)', () => {
    // Without the explicit `renderFunction = false` opt-out, a 2-arg signature is classified as
    // a render function and its return value is intercepted (wrapped in StrictMode) rather than
    // the component itself wrapped via the component path.
    const TwoArgComponent = ({ greeting }, _legacyContext) => <div>{greeting}</div>;
    TwoArgComponent.propTypes = {
      greeting: PropTypes.string.isRequired,
    };
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ TwoArgComponent });

    expect(wrappedComponents.TwoArgComponent).not.toBe(TwoArgComponent);
    const result = wrappedComponents.TwoArgComponent({ greeting: 'hello' }, {});
    expect(result.type).toBe(React.StrictMode);
    expect(result.props.children.type).toBe('div');
  });

  it('passes plain objects (non-React components) through unchanged', () => {
    const plainObject = { world: () => 'hello' };
    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ plainObject });

    expect(wrappedComponents.plainObject).toBe(plainObject);
  });

  it('wraps manual render trees in StrictMode', () => {
    const innerElement = <div>hello</div>;
    const wrappedElement = wrapElementInStrictMode(innerElement);

    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children).toBe(innerElement);
  });
});
