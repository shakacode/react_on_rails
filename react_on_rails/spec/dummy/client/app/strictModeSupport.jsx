import React from 'react';

const useStrictMode = process.env.NODE_ENV !== 'production';
let reactObjectComponentTypes;
let wrappedFunctionComponents;
let wrappedRenderFunctions;
let wrappedObjectComponents;

const getReactObjectComponentTypes = () => {
  if (!reactObjectComponentTypes) {
    reactObjectComponentTypes = new Set([
      Symbol.for('react.forward_ref'),
      Symbol.for('react.lazy'),
      Symbol.for('react.memo'),
    ]);
  }

  return reactObjectComponentTypes;
};

const getWrappedFunctionComponents = () => {
  if (!wrappedFunctionComponents) {
    wrappedFunctionComponents = new WeakMap();
  }

  return wrappedFunctionComponents;
};

const getWrappedRenderFunctions = () => {
  if (!wrappedRenderFunctions) {
    wrappedRenderFunctions = new WeakMap();
  }

  return wrappedRenderFunctions;
};

const getWrappedObjectComponents = () => {
  if (!wrappedObjectComponents) {
    // Object-typed React components (memo, forwardRef, lazy) are GC-safe in a WeakMap.
    wrappedObjectComponents = new WeakMap();
  }

  return wrappedObjectComponents;
};

const isPromiseLike = (value) =>
  typeof value === 'object' && value !== null && typeof value.then === 'function';

const isFunctionWithMetadata = (component) => typeof component === 'function';

const isObjectComponent = (component) =>
  typeof component === 'object' &&
  component !== null &&
  getReactObjectComponentTypes().has(component.$$typeof ?? 0);

const isReactComponent = (component) => isFunctionWithMetadata(component) || isObjectComponent(component);

// Mirrors the public react-on-rails/isRenderFunction convention while extending it with an
// explicit `renderFunction = false` opt-out (the public helper only checks for truthiness; this
// dummy honors `false` so legacy 2-arg `(props, context)` components can be wrapped via the
// component path rather than the render-function path). Set `fn.renderFunction = true` to flag a
// 1-arg render function explicitly. Class components are detected via the prototype check.
const isRenderFunction = (component) => {
  if (typeof component !== 'function') {
    return false;
  }

  if (component.prototype?.isReactComponent) {
    return false;
  }

  if (typeof component.renderFunction === 'boolean') {
    return component.renderFunction;
  }

  return component.length >= 2;
};

// A 3-arg renderer controls its own root, so direct renderer files wrap their root elements explicitly.
const isRendererFunction = (component) => isRenderFunction(component) && component.length === 3;

const createStrictModeWrapper = (Component) => {
  function StrictModeWrapper(props) {
    return <React.StrictMode>{React.createElement(Component, props)}</React.StrictMode>;
  }

  StrictModeWrapper.displayName = `StrictMode(${Component.displayName || Component.name || 'AnonymousComponent'})`;

  return StrictModeWrapper;
};

const wrapComponentInStrictMode = (component) => {
  if (!useStrictMode) {
    return component;
  }

  if (typeof component === 'function') {
    const componentCache = getWrappedFunctionComponents();
    const cachedComponent = componentCache.get(component);
    if (cachedComponent) {
      return cachedComponent;
    }

    const wrappedComponent = createStrictModeWrapper(component);
    componentCache.set(component, wrappedComponent);
    return wrappedComponent;
  }

  const objectComponentCache = getWrappedObjectComponents();
  const cachedComponent = objectComponentCache.get(component);
  if (cachedComponent) {
    return cachedComponent;
  }

  const wrappedComponent = createStrictModeWrapper(component);
  objectComponentCache.set(component, wrappedComponent);
  return wrappedComponent;
};

export const wrapElementInStrictMode = (reactElement) =>
  useStrictMode ? <React.StrictMode>{reactElement}</React.StrictMode> : reactElement;

const wrapRenderFunctionResult = (result) => {
  if (!useStrictMode) {
    return result;
  }

  if (isPromiseLike(result)) {
    return result.then(wrapRenderFunctionResult);
  }

  if (React.isValidElement(result)) {
    return wrapElementInStrictMode(result);
  }

  if (isReactComponent(result)) {
    return wrapComponentInStrictMode(result);
  }

  return result;
};

// The wrapped function below has `length === 2`, so `isRenderFunction` would re-classify it as a
// render function if it ever flowed back through `wrapRegisteredComponentsWithStrictMode`. The
// `STRICT_MODE_PATCHED` guard on the patched `register` call (in `client-bundle.js`) keeps that
// re-entry path unreachable. Note: when called directly (outside the registry path), the wrapper's
// hardcoded `length === 2` does not reflect the original function's arity.
const wrapRenderFunctionInStrictMode = (renderFunction) => {
  if (!useStrictMode) {
    return renderFunction;
  }

  const renderFunctionCache = getWrappedRenderFunctions();
  const cachedRenderFunction = renderFunctionCache.get(renderFunction);
  if (cachedRenderFunction) {
    return cachedRenderFunction;
  }

  const wrappedRenderFunction = function StrictModeRenderFunction(props, railsContext) {
    return wrapRenderFunctionResult(renderFunction(props, railsContext));
  };
  wrappedRenderFunction.displayName = `StrictMode(${
    renderFunction.displayName || renderFunction.name || 'AnonymousRenderFunction'
  })`;

  if (renderFunction.renderFunction) {
    wrappedRenderFunction.renderFunction = true;
  }

  renderFunctionCache.set(renderFunction, wrappedRenderFunction);
  return wrappedRenderFunction;
};

export const wrapRegisteredComponentsWithStrictMode = (components) => {
  if (!useStrictMode) {
    return components;
  }

  return Object.fromEntries(
    Object.entries(components).map(([name, component]) => {
      if (isRendererFunction(component)) {
        return [name, component];
      }

      if (isRenderFunction(component)) {
        return [name, wrapRenderFunctionInStrictMode(component)];
      }

      if (!isReactComponent(component)) {
        return [name, component];
      }

      return [name, wrapComponentInStrictMode(component)];
    }),
  );
};
