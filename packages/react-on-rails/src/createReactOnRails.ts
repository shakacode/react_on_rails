import { createBaseClientObject, type BaseClientObjectType } from './base/client.ts';
import { createBaseFullObject } from './base/full.ts';
import { clientStartup, reactOnRailsPageLoaded } from './clientStartup.ts';
import { reactOnRailsComponentLoaded } from './ClientRenderer.ts';
import ComponentRegistry from './ComponentRegistry.ts';
import StoreRegistry from './StoreRegistry.ts';
import type { ReactOnRailsInternal, RegisteredComponent, Store, StoreGenerator } from './types/index.ts';

type BaseObjectCreator = typeof createBaseClientObject | typeof createBaseFullObject;

/**
 * Core-specific functions that override base stubs and add Pro stubs.
 * Typed explicitly to ensure type safety when mutating the base object.
 */
type ReactOnRailsCoreSpecificFunctions = Pick<
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

export default function createReactOnRails(
  baseObjectCreator: BaseObjectCreator,
  currentGlobal: BaseClientObjectType | null = null,
): ReactOnRailsInternal {
  // Create base object with core registries, passing currentGlobal for caching/validation
  const baseObject = baseObjectCreator(
    {
      ComponentRegistry,
      StoreRegistry,
    },
    currentGlobal,
  );

  // Define core-specific functions with proper types
  // This object acts as a type-safe specification of what we're adding/overriding on the base object
  const reactOnRailsCoreSpecificFunctions: ReactOnRailsCoreSpecificFunctions = {
    // Override base stubs with core implementations
    reactOnRailsPageLoaded(): Promise<void> {
      reactOnRailsPageLoaded();
      return Promise.resolve();
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      return reactOnRailsComponentLoaded(domId);
    },

    // Pro-only stubs (throw errors in core package)
    getOrWaitForComponent(): Promise<RegisteredComponent> {
      throw new Error('getOrWaitForComponent requires react-on-rails-pro package');
    },

    getOrWaitForStore(): Promise<Store> {
      throw new Error('getOrWaitForStore requires react-on-rails-pro package');
    },

    getOrWaitForStoreGenerator(): Promise<StoreGenerator> {
      throw new Error('getOrWaitForStoreGenerator requires react-on-rails-pro package');
    },

    reactOnRailsStoreLoaded(): Promise<void> {
      throw new Error('reactOnRailsStoreLoaded requires react-on-rails-pro package');
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    streamServerRenderedReactComponent(): any {
      throw new Error('streamServerRenderedReactComponent requires react-on-rails-pro package');
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    serverRenderRSCReactComponent(): any {
      throw new Error('serverRenderRSCReactComponent requires react-on-rails-pro package');
    },
  };

  // Type assertion is safe here because:
  // 1. We start with BaseClientObjectType or BaseFullObjectType (from baseObjectCreator)
  // 2. We add exactly the methods defined in ReactOnRailsCoreSpecificFunctions
  // 3. ReactOnRailsInternal = Base + ReactOnRailsCoreSpecificFunctions
  // TypeScript can't track the mutation, but we ensure type safety by explicitly typing
  // the functions object above
  const reactOnRails = baseObject as unknown as ReactOnRailsInternal;

  // Assign core-specific functions to the ReactOnRails object using Object.assign
  // This pattern ensures we add exactly what's defined in the type, nothing more, nothing less
  Object.assign(reactOnRails, reactOnRailsCoreSpecificFunctions);

  // Assign to global if not already assigned
  if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = reactOnRails;

    // Reset options to defaults (only on first initialization)
    reactOnRails.resetOptions();

    // Run client startup (only on first initialization)
    if (typeof window !== 'undefined') {
      setTimeout(() => {
        clientStartup();
      }, 0);
    }
  }

  return reactOnRails;
}
