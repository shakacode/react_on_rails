import React from 'react';

type ReactClassPrototype = {
  isReactComponent?: boolean;
};

type ComponentMetadata = {
  displayName?: string;
  name?: string;
  prototype?: ReactClassPrototype;
};

type CallableComponent = React.ComponentType<Record<string, unknown>> & ComponentMetadata;
type ObjectComponent = ComponentMetadata & {
  $$typeof?: symbol | number;
};
type ComponentWithMetadata = CallableComponent | ObjectComponent;
type RenderFunction = ((props?: unknown, railsContext?: unknown) => unknown) &
  ComponentMetadata & {
    renderFunction?: boolean;
  };

type ComponentRegistry = Record<string, unknown>;
type ReactOnRailsWithRegister = {
  register: (components: ComponentRegistry) => void;
  [key: string]: unknown;
};

const STRICT_MODE_PATCHED = '__reactOnRailsProDummyStrictModePatched';
const REACT_OBJECT_COMPONENT_TYPES = new Set<symbol | number>([
  Symbol.for('react.forward_ref'),
  Symbol.for('react.lazy'),
  Symbol.for('react.memo'),
]);

const wrappedFunctionComponents = new WeakMap<CallableComponent | RenderFunction, ComponentWithMetadata>();
const wrappedRenderFunctions = new WeakMap<RenderFunction, RenderFunction>();
const wrappedObjectComponents = new WeakMap<ObjectComponent, ComponentWithMetadata>();

const isPromiseLike = (value: unknown): value is Promise<unknown> =>
  typeof value === 'object' &&
  value !== null &&
  'then' in value &&
  typeof (value as { then?: unknown }).then === 'function';

const isFunctionWithMetadata = (component: unknown): component is CallableComponent | RenderFunction =>
  typeof component === 'function';

const isObjectComponent = (component: unknown): component is ObjectComponent =>
  typeof component === 'object' &&
  component !== null &&
  REACT_OBJECT_COMPONENT_TYPES.has((component as ObjectComponent).$$typeof ?? 0);

const isReactComponent = (component: unknown): component is ComponentWithMetadata =>
  isFunctionWithMetadata(component) || isObjectComponent(component);

// Mirrors React on Rails' render-function convention while extending it with an explicit
// `renderFunction = false` opt-out (the public helper only checks for truthiness; this dummy
// honors `false` so legacy 2-arg `(props, context)` components can be wrapped via the component
// path rather than the render-function path). Class components are detected via the prototype
// check.
const isRenderFunction = (component: unknown): component is RenderFunction => {
  if (typeof component !== 'function') {
    return false;
  }

  const reactPrototype = (component as { prototype?: ReactClassPrototype }).prototype;
  if (reactPrototype?.isReactComponent) {
    return false;
  }

  const renderFunctionFlag = (component as { renderFunction?: unknown }).renderFunction;
  if (typeof renderFunctionFlag === 'boolean') {
    return renderFunctionFlag;
  }

  return component.length >= 2;
};

// A 3-arg renderer controls its own root, so direct renderer files wrap their root elements explicitly.
const isRendererFunction = (component: unknown): component is RenderFunction =>
  isRenderFunction(component) && component.length === 3;

const createStrictModeWrapper = (Component: ComponentWithMetadata): React.FC<Record<string, unknown>> => {
  function StrictModeWrapper(props: Record<string, unknown>) {
    const childElement = React.createElement(Component as React.ElementType<Record<string, unknown>>, props);

    return <React.StrictMode>{childElement}</React.StrictMode>;
  }

  StrictModeWrapper.displayName = `StrictMode(${Component.displayName || Component.name || 'AnonymousComponent'})`;

  return StrictModeWrapper;
};

const wrapComponentInStrictMode = (component: ComponentWithMetadata): ComponentWithMetadata => {
  if (typeof component === 'function') {
    const cachedComponent = wrappedFunctionComponents.get(component);
    if (cachedComponent) {
      return cachedComponent;
    }

    const wrappedComponent = createStrictModeWrapper(component);
    wrappedFunctionComponents.set(component, wrappedComponent);
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

export const wrapElementInStrictMode = (reactElement: React.ReactElement): React.ReactElement => (
  <React.StrictMode>{reactElement}</React.StrictMode>
);

const wrapRenderFunctionResult = (result: unknown): unknown => {
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
// STRICT_MODE_PATCHED guard on `enableStrictModeForReactOnRails` ensures the patched `register`
// runs only once per singleton, which keeps that re-entry path unreachable. Note: when called
// directly (outside the registry path) with a 3-arg renderer, the wrapper's hardcoded
// `length === 2` would not reflect the original arity. `wrapRegisteredComponentsWithStrictMode`
// orders the renderer check before the render-function check so a 3-arg renderer never reaches
// this helper through the registry, but direct callers should treat this as a precondition.
const wrapRenderFunctionInStrictMode = (renderFunction: RenderFunction): RenderFunction => {
  const cachedRenderFunction = wrappedRenderFunctions.get(renderFunction);
  if (cachedRenderFunction) {
    return cachedRenderFunction;
  }

  const wrappedRenderFunction: RenderFunction = function StrictModeRenderFunction(props, railsContext) {
    return wrapRenderFunctionResult(renderFunction(props, railsContext));
  };
  wrappedRenderFunction.displayName = `StrictMode(${
    renderFunction.displayName || renderFunction.name || 'AnonymousRenderFunction'
  })`;

  if (renderFunction.renderFunction) {
    wrappedRenderFunction.renderFunction = true;
  }

  wrappedRenderFunctions.set(renderFunction, wrappedRenderFunction);
  return wrappedRenderFunction;
};

export const wrapRegisteredComponentsWithStrictMode = (components: ComponentRegistry): ComponentRegistry =>
  Object.fromEntries(
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

export const enableStrictModeForReactOnRails = <T extends ReactOnRailsWithRegister>(reactOnRails: T): T => {
  if (reactOnRails[STRICT_MODE_PATCHED]) {
    return reactOnRails;
  }

  // Mutate the singleton in place so every default-import consumer observes the patch.
  const reactOnRailsSingleton = reactOnRails;
  const originalRegister = reactOnRailsSingleton.register.bind(reactOnRailsSingleton);
  reactOnRailsSingleton.register = (components: ComponentRegistry) => {
    originalRegister(wrapRegisteredComponentsWithStrictMode(components));
  };

  Object.defineProperty(reactOnRailsSingleton, STRICT_MODE_PATCHED, { value: true });

  return reactOnRailsSingleton;
};
