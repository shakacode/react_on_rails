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

  it('does not wrap render functions or renderer functions', () => {
    const renderFunction = (props, railsContext) => ({ props, railsContext });
    const rendererFunction = (props, railsContext, domNodeId) => ({ props, railsContext, domNodeId });

    const wrappedComponents = wrapRegisteredComponentsWithStrictMode({
      renderFunction,
      rendererFunction,
    });

    expect(wrappedComponents.renderFunction).toBe(renderFunction);
    expect(wrappedComponents.rendererFunction).toBe(rendererFunction);
  });

  it('wraps manual render trees in StrictMode', () => {
    const innerElement = <div>hello</div>;
    const wrappedElement = wrapElementInStrictMode(innerElement);

    expect(wrappedElement.type).toBe(React.StrictMode);
    expect(wrappedElement.props.children).toBe(innerElement);
  });
});
