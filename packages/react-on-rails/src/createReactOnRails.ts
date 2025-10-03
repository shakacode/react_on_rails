import { createBaseClientObject } from './base/client.ts';
import { createBaseFullObject } from './base/full.ts';
import { clientStartup, reactOnRailsPageLoaded } from './clientStartup.ts';
import { reactOnRailsComponentLoaded } from './ClientRenderer.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import type { RegisteredComponent, Store, StoreGenerator } from './types/index.ts';

type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;

// eslint-disable-next-line import/prefer-default-export
export function createReactOnRails(baseObjectCreator: BaseObjectCreator) {
  // Check if ReactOnRails already exists
  if (globalThis.ReactOnRails !== undefined) {
    throw new Error(`\
The ReactOnRails value exists in the ${globalThis} scope, it may not be safe to overwrite it.
This could be caused by setting Webpack's optimization.runtimeChunk to "true" or "multiple," rather than "single."
Check your Webpack configuration. Read more at https://github.com/shakacode/react_on_rails/issues/1558.`);
  }

  // Create base object with core registries
  const baseObject = baseObjectCreator({
    ComponentRegistry,
    StoreRegistry,
  });

  // Add core-specific implementations and pro-only stubs
  const ReactOnRails = {
    ...baseObject,

    // Override client-side rendering stubs with core implementations
    reactOnRailsPageLoaded(): Promise<void> {
      reactOnRailsPageLoaded();
      return Promise.resolve();
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return reactOnRailsComponentLoaded(domId);
    },

    // ===================================================================
    // PRO-ONLY STUBS - These methods don't exist in base, add them here
    // ===================================================================

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    getOrWaitForComponent(_name: string): Promise<RegisteredComponent> {
      throw new Error('getOrWaitForComponent requires react-on-rails-pro package');
    },

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    getOrWaitForStore(_name: string): Promise<Store> {
      throw new Error('getOrWaitForStore requires react-on-rails-pro package');
    },

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    getOrWaitForStoreGenerator(_name: string): Promise<StoreGenerator> {
      throw new Error('getOrWaitForStoreGenerator requires react-on-rails-pro package');
    },

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    reactOnRailsStoreLoaded(_storeName: string): Promise<void> {
      throw new Error('reactOnRailsStoreLoaded requires react-on-rails-pro package');
    },

    streamServerRenderedReactComponent(): never {
      throw new Error('streamServerRenderedReactComponent requires react-on-rails-pro package');
    },

    serverRenderRSCReactComponent(): never {
      throw new Error('serverRenderRSCReactComponent requires react-on-rails-pro package');
    },
  };

  // Assign to global
  globalThis.ReactOnRails = ReactOnRails;

  // Reset options to defaults
  ReactOnRails.resetOptions();

  // Run client startup
  if (typeof window !== 'undefined') {
    setTimeout(() => {
      clientStartup();
    }, 0);
  }

  return ReactOnRails;
}
