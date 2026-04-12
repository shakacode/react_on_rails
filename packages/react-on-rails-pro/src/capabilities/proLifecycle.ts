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

import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import {
  renderOrHydrateComponent,
  renderOrHydrateAllComponents,
  hydrateAllStores,
} from '../ClientSideRenderer.ts';

/** Shared implementation used by both the capability object and proClientStartup. */
export async function reactOnRailsPageLoaded(): Promise<void> {
  debugTurbolinks('reactOnRailsPageLoaded [PRO]');
  await Promise.all([hydrateAllStores(), renderOrHydrateAllComponents()]);
}

/**
 * Pro lifecycle capability.
 * Overrides core lifecycle with Pro implementations that support hydration
 * and on-demand rendering.
 */
export function createProLifecycleCapability() {
  return {
    reactOnRailsPageLoaded,

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return renderOrHydrateComponent(domId);
    },
  };
}
