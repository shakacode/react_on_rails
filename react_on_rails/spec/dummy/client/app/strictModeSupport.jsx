import React from 'react';

const wrappedFunctionComponents = new WeakMap();
// Object-typed React components (memo, forwardRef, lazy) are GC-safe in a WeakMap.
const wrappedObjectComponents = new WeakMap();
// Strings are primitives and cannot key a WeakMap, so registered string component names live here.
const wrappedStringComponents = new Map();

// Mirrors the public react-on-rails/isRenderFunction convention for this dummy-only wrapper.
// Note: the `length >= 2` heuristic intentionally classifies any 2-arg function as a render
// function. Legacy 2-arg components that use the (props, context) signature must opt back in by
// setting `fn.renderFunction = false` (or, for class components, are detected via the prototype
// check). Set `fn.renderFunction = true` to flag a 1-arg render function explicitly.
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

  if (typeof component === 'string') {
    const cachedComponent = wrappedStringComponents.get(component);
    if (cachedComponent) {
      return cachedComponent;
    }

    const wrappedComponent = createStrictModeWrapper(component);
    wrappedStringComponents.set(component, wrappedComponent);
    return wrappedComponent;
  }

  const cachedComponent = wrappedObjectComponents.get(component);
  if (cachedComponent) {
    return cachedComponent;
  }

  const wrappedComponent = createStrictModeWrapper(component);
  wrappedObjectComponents.set(component, wrappedComponent);
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
