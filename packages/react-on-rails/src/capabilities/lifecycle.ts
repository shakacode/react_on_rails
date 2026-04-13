/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

import { reactOnRailsPageLoaded } from '../clientStartup.ts';
import { reactOnRailsComponentLoaded } from '../ClientRenderer.ts';

/**
 * Core lifecycle capability.
 * Provides the core (non-Pro) implementations for page/component loaded callbacks.
 */
export function createLifecycleCapability() {
  return {
    reactOnRailsPageLoaded(): Promise<void> {
      reactOnRailsPageLoaded();
      return Promise.resolve();
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return reactOnRailsComponentLoaded(domId);
    },
  };
}
