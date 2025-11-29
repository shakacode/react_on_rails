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

import { createBaseClientObject, type BaseClientObjectType } from 'react-on-rails/@internal/base/client';
import { createBaseFullObject } from 'react-on-rails/@internal/base/full';
import { onPageUnloaded } from 'react-on-rails/pageLifecycle';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import type { ReactOnRailsInternal, RegisteredComponent, Store, StoreGenerator } from 'react-on-rails/types';
import * as ProComponentRegistry from './ComponentRegistry.ts';
import * as ProStoreRegistry from './StoreRegistry.ts';
import {
  renderOrHydrateComponent,
  hydrateStore,
  renderOrHydratePageComponents,
  hydratePageStores,
  unmountAll,
} from './ClientSideRenderer.ts';

type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;

/**
 * Pro-specific functions that override base/core stubs with real implementations.
 * Typed explicitly to ensure type safety when mutating the base object.
 */
type ReactOnRailsProSpecificFunctions = Pick<
  ReactOnRailsInternal,
  | 'reactOnRailsPageLoaded'
  | 'reactOnRailsComponentLoaded'
  | 'getOrWaitForComponent'
  | 'getOrWaitForStore'
  | 'getOrWaitForStoreGenerator'
  | 'reactOnRailsStoreLoaded'
  | 'streamServerRenderedReactComponent'
  | 'serverRenderRSCReactComponent'
>;

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded [PRO]');
  unmountAll();
}

function clientStartup() {
  if (globalThis.document === undefined) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  if (globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  void renderOrHydratePageComponents();
  void hydratePageStores();

  onPageUnloaded(reactOnRailsPageUnloaded);
}

export default function createReactOnRailsPro(
  baseObjectCreator: BaseObjectCreator,
  currentGlobal: BaseClientObjectType | null = null,
): ReactOnRailsInternal {
  // Create base object with Pro registries, passing currentGlobal for caching/validation
  const baseObject = baseObjectCreator(
    {
      ComponentRegistry: ProComponentRegistry,
      StoreRegistry: ProStoreRegistry,
    },
    currentGlobal,
  );

  // Define Pro-specific functions with proper types
  // This object acts as a type-safe specification of what we're adding/overriding on the base object
  const reactOnRailsProSpecificFunctions: ReactOnRailsProSpecificFunctions = {
    // Override core implementations with Pro implementations
    reactOnRailsPageLoaded(): Promise<void> {
      // Do nothing, the pro package doesn't wait until page load to hydrate components and stores
      return Promise.resolve();
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return renderOrHydrateComponent(domId);
    },

    // Pro-only method implementations (override core stubs)
    getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
      return ProComponentRegistry.getOrWaitForComponent(name);
    },

    getOrWaitForStore(name: string): Promise<Store> {
      return ProStoreRegistry.getOrWaitForStore(name);
    },

    getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator> {
      return ProStoreRegistry.getOrWaitForStoreGenerator(name);
    },

    reactOnRailsStoreLoaded(storeName: string): Promise<void> {
      return hydrateStore(storeName);
    },

    // streamServerRenderedReactComponent is added in ReactOnRails.node.ts
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    streamServerRenderedReactComponent(): any {
      throw new Error(
        'streamServerRenderedReactComponent requires importing from react-on-rails-pro in Node.js environment',
      );
    },

    // serverRenderRSCReactComponent is added in ReactOnRailsRSC.ts
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    serverRenderRSCReactComponent(): any {
      throw new Error('serverRenderRSCReactComponent is supported in RSC bundle only');
    },
  };

  // Type assertion is safe here because:
  // 1. We start with BaseClientObjectType or BaseFullObjectType (from baseObjectCreator)
  // 2. We add exactly the methods defined in ReactOnRailsProSpecificFunctions
  // 3. ReactOnRailsInternal = Base + ReactOnRailsProSpecificFunctions
  // TypeScript can't track the mutation, but we ensure type safety by explicitly typing
  // the functions object above
  const reactOnRailsPro = baseObject as unknown as ReactOnRailsInternal;

  if (reactOnRailsPro.streamServerRenderedReactComponent) {
    reactOnRailsProSpecificFunctions.streamServerRenderedReactComponent =
      reactOnRailsPro.streamServerRenderedReactComponent;
  }

  if (reactOnRailsPro.serverRenderRSCReactComponent) {
    reactOnRailsProSpecificFunctions.serverRenderRSCReactComponent =
      reactOnRailsPro.serverRenderRSCReactComponent;
  }

  // Assign Pro-specific functions to the ReactOnRailsPro object using Object.assign
  // This pattern ensures we add exactly what's defined in the type, nothing more, nothing less
  Object.assign(reactOnRailsPro, reactOnRailsProSpecificFunctions);

  // Assign to global if not already assigned
  if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = reactOnRailsPro;

    // Reset options to defaults (only on first initialization)
    reactOnRailsPro.resetOptions();

    // Run Pro client startup that hydrates components and stores immediately without waiting for full page load
    clientStartup();
  }

  return reactOnRailsPro;
}
