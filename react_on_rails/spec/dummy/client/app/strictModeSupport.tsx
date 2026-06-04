import React, { type ReactNode } from 'react';

const useStrictMode = process.env.NODE_ENV !== 'production';

type ComponentMetadata = {
  $$typeof?: symbol;
  displayName?: string;
  name?: string;
};

type FunctionWithMetadata = ((...args: unknown[]) => unknown) &
  ComponentMetadata & {
    length: number;
    prototype?: {
      isReactComponent?: unknown;
    };
    renderFunction?: boolean;
  };

type ObjectComponent = ComponentMetadata & object;
type ReactComponentCandidate =
  | React.ComponentType<Record<string, unknown>>
  | React.ExoticComponent<Record<string, unknown>>;
type RenderFunction = FunctionWithMetadata &
  ((props: Record<string, unknown>, railsContext: unknown) => unknown);
type ComponentRegistry = Record<string, unknown>;

let reactObjectComponentTypes: Set<symbol> | undefined;
let wrappedFunctionComponents: WeakMap<FunctionWithMetadata, ReactComponentCandidate> | undefined;
let wrappedRenderFunctions: WeakMap<RenderFunction, RenderFunction> | undefined;
let wrappedObjectComponents: WeakMap<ObjectComponent, ReactComponentCandidate> | undefined;

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

const isPromiseLike = (value: unknown): value is PromiseLike<unknown> => {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  return typeof (value as { then?: unknown }).then === 'function';
};

const isFunctionWithMetadata = (component: unknown): component is FunctionWithMetadata =>
  typeof component === 'function';

const isObjectComponent = (component: unknown): component is ObjectComponent => {
  if (typeof component !== 'object' || component === null) {
    return false;
  }

  const componentType = (component as ObjectComponent).$$typeof;

  return componentType !== undefined && getReactObjectComponentTypes().has(componentType);
};

const isReactComponent = (component: unknown): component is ReactComponentCandidate =>
  isFunctionWithMetadata(component) || isObjectComponent(component);

// Mirrors the public react-on-rails/isRenderFunction convention while extending it with an
// explicit `renderFunction = false` opt-out (the public helper only checks for truthiness; this
// dummy honors `false` so legacy 2-arg `(props, context)` components can be wrapped via the
// component path rather than the render-function path). Set `fn.renderFunction = true` to flag a
// 1-arg render function explicitly. Class components are detected via the prototype check.
const isRenderFunction = (component: unknown): component is RenderFunction => {
  if (!isFunctionWithMetadata(component)) {
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
const isRendererFunction = (component: unknown) => isRenderFunction(component) && component.length === 3;

const getComponentDisplayName = (Component: ComponentMetadata) =>
  Component.displayName || Component.name || 'AnonymousComponent';

const createStrictModeWrapper = (Component: ReactComponentCandidate) => {
  const StrictModeWrapper = (props: Record<string, unknown>) => (
    <React.StrictMode>{React.createElement(Component, props)}</React.StrictMode>
  );

  StrictModeWrapper.displayName = `StrictMode(${getComponentDisplayName(Component)})`;

  return StrictModeWrapper;
};

const wrapComponentInStrictMode = (component: ReactComponentCandidate): ReactComponentCandidate => {
  if (!useStrictMode) {
    return component;
  }

  if (isFunctionWithMetadata(component)) {
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

const wrapElementInStrictMode = (reactElement: ReactNode): ReactNode =>
  useStrictMode ? <React.StrictMode>{reactElement}</React.StrictMode> : reactElement;

const wrapRenderFunctionResult = (result: unknown): unknown => {
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
// `STRICT_MODE_PATCHED` guard on the patched `register` call (in `client-bundle.ts`) keeps that
// re-entry path unreachable. Note: when called directly (outside the registry path), the wrapper's
// hardcoded `length === 2` does not reflect the original function's arity.
const wrapRenderFunctionInStrictMode = (renderFunction: RenderFunction): RenderFunction => {
  if (!useStrictMode) {
    return renderFunction;
  }

  const renderFunctionCache = getWrappedRenderFunctions();
  const cachedRenderFunction = renderFunctionCache.get(renderFunction);
  if (cachedRenderFunction) {
    return cachedRenderFunction;
  }

  const wrappedRenderFunction = function StrictModeRenderFunction(
    props: Record<string, unknown>,
    railsContext: unknown,
  ) {
    return wrapRenderFunctionResult(renderFunction(props, railsContext));
  } as RenderFunction;
  wrappedRenderFunction.displayName = `StrictMode(${getComponentDisplayName(renderFunction)})`;

  if (renderFunction.renderFunction) {
    wrappedRenderFunction.renderFunction = true;
  }

  renderFunctionCache.set(renderFunction, wrappedRenderFunction);
  return wrappedRenderFunction;
};

const wrapRegisteredComponentsWithStrictMode = <Components extends ComponentRegistry>(
  components: Components,
): Components => {
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
  ) as Components;
};

export { wrapElementInStrictMode, wrapRegisteredComponentsWithStrictMode };
