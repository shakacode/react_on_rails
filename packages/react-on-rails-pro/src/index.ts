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

// Re-export everything from core
export * from 'react-on-rails';

// Import core ReactOnRails to enhance it
import ReactOnRailsCore from 'react-on-rails/ReactOnRails.client';

// Import pro registries and features
import * as ProComponentRegistry from './ComponentRegistry.ts';
import * as ProStoreRegistry from './StoreRegistry.ts';
import {
  renderOrHydrateComponent,
  hydrateStore,
  renderOrHydrateAllComponents,
  hydrateAllStores,
  renderOrHydrateImmediateHydratedComponents,
  hydrateImmediateHydratedStores,
  unmountAll,
} from './ClientSideRenderer.ts';

import type {
  Store,
  StoreGenerator,
  RegisteredComponent,
  ReactComponentOrRenderFunction,
} from 'react-on-rails/types';

// Enhance ReactOnRails with Pro features
const ReactOnRailsPro = {
  ...ReactOnRailsCore,

  // Override register methods to use pro registries
  register(components: Record<string, ReactComponentOrRenderFunction>): void {
    ProComponentRegistry.register(components);
  },

  registerStoreGenerators(storeGenerators: Record<string, StoreGenerator>): void {
    if (!storeGenerators) {
      throw new Error(
        'Called ReactOnRails.registerStoreGenerators with a null or undefined, rather than ' +
          'an Object with keys being the store names and the values are the store generators.',
      );
    }

    ProStoreRegistry.register(storeGenerators);
  },

  registerStore(stores: Record<string, StoreGenerator>): void {
    this.registerStoreGenerators(stores);
  },

  // Pro registry methods with async support
  getStore(name: string, throwIfMissing = true): Store | undefined {
    return ProStoreRegistry.getStore(name, throwIfMissing);
  },

  getOrWaitForStore(name: string): Promise<Store> {
    return ProStoreRegistry.getOrWaitForStore(name);
  },

  getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator> {
    return ProStoreRegistry.getOrWaitForStoreGenerator(name);
  },

  getStoreGenerator(name: string): StoreGenerator {
    return ProStoreRegistry.getStoreGenerator(name);
  },

  setStore(name: string, store: Store): void {
    ProStoreRegistry.setStore(name, store);
  },

  clearHydratedStores(): void {
    ProStoreRegistry.clearHydratedStores();
  },

  getComponent(name: string): RegisteredComponent {
    return ProComponentRegistry.get(name);
  },

  getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
    return ProComponentRegistry.getOrWaitForComponent(name);
  },

  registeredComponents() {
    return ProComponentRegistry.components();
  },

  storeGenerators() {
    return ProStoreRegistry.storeGenerators();
  },

  stores() {
    return ProStoreRegistry.stores();
  },

  // Pro rendering methods
  reactOnRailsComponentLoaded(domId: string): Promise<void> {
    return renderOrHydrateComponent(domId);
  },

  reactOnRailsStoreLoaded(storeName: string): Promise<void> {
    return hydrateStore(storeName);
  },
};

// Replace global ReactOnRails with Pro version
globalThis.ReactOnRails = ReactOnRailsPro;

// Pro client startup with immediate hydration support
import { onPageLoaded, onPageUnloaded } from 'react-on-rails/pageLifecycle';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';

export async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded [PRO]');
  // Pro: Render all components that don't have immediate_hydration
  await Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]);
}

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded [PRO]');
  unmountAll();
}

export function clientStartup() {
  // Check if server rendering
  if (globalThis.document === undefined) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  if (globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  // Pro: Hydrate immediate_hydration components before page load
  void renderOrHydrateImmediateHydratedComponents();
  void hydrateImmediateHydratedStores();

  // Other components are rendered when page is fully loaded
  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}

// Run pro startup
clientStartup();

export default ReactOnRailsPro;
