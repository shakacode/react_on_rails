import React from 'react';

const wrappedFunctionComponents = new WeakMap();
const wrappedOtherComponents = new Map(); // Map, not WeakMap: string component names are valid keys.

// Mirrors the public react-on-rails/isRenderFunction convention for this dummy-only wrapper.
const isRenderFunction = (component) => {
  if (typeof component !== 'function') {
    return false;
  }

  if (component.prototype?.isReactComponent) {
    return false;
  }

  if (component.renderFunction) {
    return true;
  }

  return component.length >= 2;
};

const createStrictModeWrapper = (Component) => {
  function StrictModeWrapper(props) {
    return <React.StrictMode>{React.createElement(Component, props)}</React.StrictMode>;
  }

  const componentName =
    typeof Component === 'string'
      ? Component
      : Component.displayName || Component.name || 'AnonymousComponent';
  StrictModeWrapper.displayName = `StrictMode(${componentName})`;

  return StrictModeWrapper;
};

const wrapComponentInStrictMode = (component) => {
  if (typeof component === 'function') {
    const cachedComponent = wrappedFunctionComponents.get(component);
    if (cachedComponent) {
      return cachedComponent;
    }

    const wrappedComponent = createStrictModeWrapper(component);
    wrappedFunctionComponents.set(component, wrappedComponent);
    return wrappedComponent;
  }

  const cachedComponent = wrappedOtherComponents.get(component);
  if (cachedComponent) {
    return cachedComponent;
  }

  const wrappedComponent = createStrictModeWrapper(component);
  wrappedOtherComponents.set(component, wrappedComponent);
  return wrappedComponent;
};

export const wrapElementInStrictMode = (reactElement) => <React.StrictMode>{reactElement}</React.StrictMode>;

export const wrapRegisteredComponentsWithStrictMode = (components) =>
  Object.fromEntries(
    Object.entries(components).map(([name, component]) => [
      name,
      // OSS dummy registered render functions own their root; manual renderer entries wrap explicitly.
      isRenderFunction(component) ? component : wrapComponentInStrictMode(component),
    ]),
  );
