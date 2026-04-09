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

import { createCoreCapability } from 'react-on-rails/@internal/capabilities/core';
import createReactOnRails from 'react-on-rails/@internal/createReactOnRails';
import type { ReactOnRailsInternal } from 'react-on-rails/types';
import * as ProComponentRegistry from './ComponentRegistry.ts';
import * as ProStoreRegistry from './StoreRegistry.ts';
import { createProLifecycleCapability } from './capabilities/proLifecycle.ts';
import { createProMethodCapability } from './capabilities/proMethods.ts';
import { proClientStartup } from './proClientStartup.ts';

/**
 * Creates a ReactOnRails instance with Pro capabilities.
 *
 * @param additionalCapabilities - Extra capabilities to include (e.g., SSR, streaming, RSC).
 * @param currentGlobal - Current globalThis.ReactOnRails value (for misconfiguration detection).
 */
export default function createReactOnRailsPro(
  additionalCapabilities: Partial<ReactOnRailsInternal>[] = [],
  currentGlobal: ReactOnRailsInternal | null = null,
): ReactOnRailsInternal {
  const registries = {
    ComponentRegistry: ProComponentRegistry,
    StoreRegistry: ProStoreRegistry,
  };

  return createReactOnRails(
    [
      createCoreCapability(registries),
      createProLifecycleCapability(),
      createProMethodCapability(),
      ...additionalCapabilities,
    ],
    {
      currentGlobal,
      startup: proClientStartup,
      registries,
    },
  );
}
