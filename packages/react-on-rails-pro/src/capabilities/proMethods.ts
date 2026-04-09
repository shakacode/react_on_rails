/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

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

import type { RegisteredComponent, Store, StoreGenerator } from 'react-on-rails/types';
import * as ProComponentRegistry from '../ComponentRegistry.ts';
import * as ProStoreRegistry from '../StoreRegistry.ts';
import { hydrateStore } from '../ClientSideRenderer.ts';

/**
 * Pro methods capability.
 * Provides Pro-only features: async component/store access and store hydration.
 */
export function createProMethodCapability() {
  return {
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
  };
}
