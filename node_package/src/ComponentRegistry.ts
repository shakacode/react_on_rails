import { type RegisteredComponent, type ReactComponentOrRenderFunction } from './types/index.ts';
import isRenderFunction from './isRenderFunction.ts';
import CallbackRegistry from './CallbackRegistry.ts';

const componentRegistry = new CallbackRegistry<RegisteredComponent>('component');

/**
 * @param components { component1: component1, component2: component2, etc. }
 */
export function register(components: Record<string, ReactComponentOrRenderFunction>): void {
  Object.keys(components).forEach((name) => {
    if (componentRegistry.has(name)) {
      console.warn('Called register for component that is already registered', name);
    }

    const component = components[name];
    if (!component) {
      throw new Error(`Called register with null component named ${name}`);
    }

      if (isRenderFunction(component)) {
        return componentRegistry.set(name, {
          name,
          component,
          type: component.length === 3 ? 'renderer-function' : 'render-function',
        });
      }

      componentRegistry.set(name, {
        name,
        component,
        type: 'react-component',
      });
  });
}

export function registerServerComponentReferences(...references: string[]): void {
  references.forEach((reference) => {
      componentRegistry.set(reference, {
      name: reference,
      component: undefined,
      type: 'server-component-reference',
    });
  });
}

/**
 * @param name
 * @returns { name, component, isRenderFunction, isRenderer }
 */
export const get = (name: string): RegisteredComponent => componentRegistry.get(name);

export const getOrWaitForComponent = (name: string): Promise<RegisteredComponent> =>
  componentRegistry.getOrWaitForItem(name);

/**
 * Get a Map containing all registered components. Useful for debugging.
 * @returns Map where key is the component name and values are the
 * { name, component, renderFunction, isRenderer}
 */
export const components = (): Map<string, RegisteredComponent> => componentRegistry.getAll();

/** @internal Exported only for tests */
export function clear(): void {
  componentRegistry.clear();
}
