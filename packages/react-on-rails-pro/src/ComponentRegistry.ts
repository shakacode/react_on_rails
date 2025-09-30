/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { type RegisteredComponent, type ReactComponentOrRenderFunction } from '../types/index.ts';
import isRenderFunction from '../isRenderFunction.ts';
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

    const renderFunction = isRenderFunction(component);
    const isRenderer = renderFunction && component.length === 3;

    componentRegistry.set(name, {
      name,
      component,
      renderFunction,
      isRenderer,
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
