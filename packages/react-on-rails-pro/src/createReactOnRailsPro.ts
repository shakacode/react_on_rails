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

import { createBaseClientObject } from 'react-on-rails/@internal/base/client';
import { createBaseFullObject } from 'react-on-rails/@internal/base/full';
import { onPageLoaded, onPageUnloaded } from 'react-on-rails/pageLifecycle';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import type { Store, StoreGenerator, RegisteredComponent } from 'react-on-rails/types';
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

type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;

// Pro client startup with immediate hydration support
async function reactOnRailsPageLoaded() {
  debugTurbolinks('reactOnRailsPageLoaded [PRO]');
  await Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]);
}

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

  void renderOrHydrateImmediateHydratedComponents();
  void hydrateImmediateHydratedStores();

  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}

// eslint-disable-next-line import/prefer-default-export
export function createReactOnRailsPro(baseObjectCreator: BaseObjectCreator) {
  // Create base object with Pro registries
  const baseObject = baseObjectCreator({
    ComponentRegistry: ProComponentRegistry,
    StoreRegistry: ProStoreRegistry,
  });

  // Add Pro-specific implementations
  const ReactOnRails = {
    ...baseObject,

    // Override client-side rendering stubs with Pro implementations
    reactOnRailsPageLoaded(): Promise<void> {
      return reactOnRailsPageLoaded();
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return renderOrHydrateComponent(domId);
    },

    // ===================================================================
    // PRO-ONLY METHOD IMPLEMENTATIONS
    // These methods don't exist in base, add them here
    // ===================================================================

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
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars
    streamServerRenderedReactComponent(..._args: any[]): any {
      throw new Error(
        'streamServerRenderedReactComponent requires importing from react-on-rails-pro in Node.js environment',
      );
    },

    // serverRenderRSCReactComponent is added in ReactOnRailsRSC.ts
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars
    serverRenderRSCReactComponent(..._args: any[]): any {
      throw new Error('serverRenderRSCReactComponent is supported in RSC bundle only');
    },
  };

  // Assign to global
  globalThis.ReactOnRails = ReactOnRails;

  // Reset options to defaults
  ReactOnRails.resetOptions();

  // Run Pro client startup with immediate hydration support
  clientStartup();

  return ReactOnRails;
}
