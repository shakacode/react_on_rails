import React from 'react';

type ReactClassPrototype = {
  isReactComponent?: boolean;
};

type ComponentWithMetadata = React.ComponentType<Record<string, unknown>> & {
  displayName?: string;
  name?: string;
  prototype?: ReactClassPrototype;
};

type RenderFunction = ((props?: unknown, railsContext?: unknown) => unknown) & {
  renderFunction?: true;
  displayName?: string;
  name?: string;
  prototype?: ReactClassPrototype;
};

type RegisteredComponent = string | ComponentWithMetadata | RenderFunction;
type ComponentRegistry = Record<string, RegisteredComponent>;
type ReactOnRailsWithRegister = {
  register: (components: ComponentRegistry) => void;
  [key: string]: unknown;
};

const STRICT_MODE_PATCHED = '__reactOnRailsProDummyStrictModePatched';

const wrappedFunctionComponents = new WeakMap<ComponentWithMetadata | RenderFunction, RegisteredComponent>();
const wrappedRenderFunctions = new WeakMap<RenderFunction, RenderFunction>();
const wrappedOtherComponents = new Map<RegisteredComponent, RegisteredComponent>();

const isPromiseLike = (value: unknown): value is Promise<unknown> =>
  typeof value === 'object' &&
  value !== null &&
  'then' in value &&
  typeof (value as { then?: unknown }).then === 'function';

const isRenderFunction = (component: RegisteredComponent): component is RenderFunction => {
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

const isRendererFunction = (component: RegisteredComponent): component is RenderFunction =>
  isRenderFunction(component) && component.length === 3;

const createStrictModeWrapper = (Component: RegisteredComponent): React.FC<Record<string, unknown>> => {
  function StrictModeWrapper(props: Record<string, unknown>) {
    const childElement =
      typeof Component === 'string'
        ? React.createElement(Component, props)
        : React.createElement(Component as ComponentWithMetadata, props);

    return <React.StrictMode>{childElement}</React.StrictMode>;
  }

  const componentName =
    typeof Component === 'string'
      ? Component
      : Component.displayName || Component.name || 'AnonymousComponent';
  StrictModeWrapper.displayName = `StrictMode(${componentName})`;

  return StrictModeWrapper;
};

const wrapComponentInStrictMode = (component: RegisteredComponent): RegisteredComponent => {
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

  if (typeof result === 'function') {
    return wrapComponentInStrictMode(result as RegisteredComponent);
  }

  return result;
};

const wrapRenderFunctionInStrictMode = (renderFunction: RenderFunction): RenderFunction => {
  const cachedRenderFunction = wrappedRenderFunctions.get(renderFunction);
  if (cachedRenderFunction) {
    return cachedRenderFunction;
  }

  const wrappedRenderFunction: RenderFunction = function StrictModeRenderFunction(props, railsContext) {
    return wrapRenderFunctionResult(renderFunction(props, railsContext));
  };

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

      return [name, wrapComponentInStrictMode(component)];
    }),
  );

export const enableStrictModeForReactOnRails = <T extends ReactOnRailsWithRegister>(reactOnRails: T): T => {
  if (reactOnRails[STRICT_MODE_PATCHED]) {
    return reactOnRails;
  }

  const originalRegister = reactOnRails.register.bind(reactOnRails);
  const patchedReactOnRails = reactOnRails;

  patchedReactOnRails.register = (components: ComponentRegistry) => {
    originalRegister(wrapRegisteredComponentsWithStrictMode(components));
  };

  Object.defineProperty(patchedReactOnRails, STRICT_MODE_PATCHED, { value: true });

  return patchedReactOnRails;
};
