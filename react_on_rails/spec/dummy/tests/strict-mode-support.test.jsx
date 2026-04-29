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

  it('does not wrap render functions or renderer functions', () => {
    const renderFunction = (props, railsContext) => ({ props, railsContext });
    const rendererFunction = (props, railsContext, domNodeId) => ({ props, railsContext, domNodeId });
    const flaggedRenderFunction = () => () => <div>Hello</div>;
    flaggedRenderFunction.renderFunction = true;

    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({
      flaggedRenderFunction,
      renderFunction,
      rendererFunction,
    });

    expect(wrappedComponents.flaggedRenderFunction).toBe(flaggedRenderFunction);
    expect(wrappedComponents.renderFunction).toBe(renderFunction);
    expect(wrappedComponents.rendererFunction).toBe(rendererFunction);
  });

  it('treats a 2-arg functional component as a render function (arity heuristic)', () => {
    // A 2-arg component looks like a render function to isRenderFunction; this test pins down
    // the heuristic so a future change has to update the test alongside the behavior.
    const TwoArgComponent = ({ greeting }, _legacyContext) => <div>{greeting}</div>;
    TwoArgComponent.propTypes = {
      greeting: PropTypes.string.isRequired,
    };

    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({ TwoArgComponent });

    expect(wrappedComponents.TwoArgComponent).toBe(TwoArgComponent);
  });

  it('wraps manual render trees in StrictMode', () => {
    const innerElement = <div>hello</div>;
    const wrappedElement = wrapElementInStrictMode(innerElement);

    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children).toBe(innerElement);
  });
});
