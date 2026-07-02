/**
 * @deprecated Use `capabilities/core.ts` instead. This file is kept for backward compatibility
 * with older versions of react-on-rails-pro that import from `react-on-rails/@internal/base/client`.
 */

// This is a thin compatibility shim: the implementation lives in `capabilities/core.ts`
// (`createCoreCapability`). This file adds only the shim-specific concerns that old Pro
// consumers rely on — singleton caching/validation and the client-side lifecycle stubs
// that `createReactOnRails` overrides — and re-shapes the object to the historical
// `BaseClientObjectType` surface (no Pro methods).

import type {
  RegisteredComponent,
  RegisteredComponentValue,
  Store,
  StoreGenerator,
  ReactOnRailsInternal,
} from '../types/index.ts';
import { createCoreCapability } from '../capabilities/core.ts';

type RegisteredComponentEntry = RegisteredComponent<RegisteredComponentValue>;

interface Registries {
  ComponentRegistry: {
    register: (components: Record<string, RegisteredComponentValue>) => void;
    get: (name: string) => RegisteredComponentEntry;
    components: () => Map<string, RegisteredComponentEntry>;
  };
  StoreRegistry: {
    register: (storeGenerators: Record<string, StoreGenerator>) => void;
    getStore: (name: string, throwIfMissing?: boolean) => Store | undefined;
    getStoreGenerator: (name: string) => StoreGenerator;
    setStore: (name: string, store: Store) => void;
    clearHydratedStores: () => void;
    clearStoreGenerators: () => void;
    storeGenerators: () => Map<string, StoreGenerator>;
    stores: () => Map<string, Store>;
  };
}

/**
 * Base client object type that includes all core ReactOnRails methods except Pro-specific ones.
 * Derived from ReactOnRailsInternal by omitting Pro-only methods.
 */
export type BaseClientObjectType = Omit<
  ReactOnRailsInternal,
  // Pro-only methods (not in base)
  | 'getOrWaitForComponent'
  | 'getOrWaitForStore'
  | 'getOrWaitForStoreGenerator'
  | 'reactOnRailsStoreLoaded'
  | 'streamServerRenderedReactComponent'
  | 'serverRenderRSCReactComponent'
  | 'addAsyncPropsCapabilityToComponentProps'
  | 'getOrCreateAsyncPropsManager'
>;

// Cache to track created objects and their registries
let cachedObject: BaseClientObjectType | null = null;
let cachedRegistries: Registries | null = null;

export function createBaseClientObject(
  registries: Registries,
  currentObject: BaseClientObjectType | null = null,
): BaseClientObjectType {
  // Error detection: currentObject is null but we have a cached object
  // This indicates webpack misconfiguration (multiple runtime chunks)
  if (currentObject === null && cachedObject !== null) {
    throw new Error(`\
ReactOnRails was already initialized, but a new initialization was attempted without passing the existing global.
This usually means Webpack's optimization.runtimeChunk is set to "true" or "multiple" instead of "single".

Fix: Set optimization.runtimeChunk to "single" in your webpack configuration.
See: https://github.com/shakacode/react_on_rails/issues/1558`);
  }

  // Error detection: currentObject exists but doesn't match cached object
  // This could indicate:
  // 1. Global was contaminated by external code
  // 2. Mixing core and pro packages
  if (currentObject !== null && cachedObject !== null && currentObject !== cachedObject) {
    throw new Error(`\
ReactOnRails global object mismatch detected.
The current global ReactOnRails object is different from the one created by this package.

This usually means:
1. You're mixing react-on-rails (core) with react-on-rails-pro
2. Another library is interfering with the global ReactOnRails object

Fix: Use only one package (core OR pro) consistently throughout your application.`);
  }

  // Error detection: Different registries with existing cache
  // This indicates mixing core and pro packages
  if (cachedRegistries !== null) {
    if (
      registries.ComponentRegistry !== cachedRegistries.ComponentRegistry ||
      registries.StoreRegistry !== cachedRegistries.StoreRegistry
    ) {
      throw new Error(`\
Cannot mix react-on-rails (core) with react-on-rails-pro.
Different registries detected - the packages use incompatible registries.

Fix: Use only react-on-rails OR react-on-rails-pro, not both.`);
    }
  }

  // If we have a cached object, return it (all checks passed above)
  if (cachedObject !== null) {
    return cachedObject;
  }

  // Delegate the core method implementations to `createCoreCapability` (the canonical source),
  // then re-shape to the historical base surface: strip the Pro-only stubs and add the
  // client-side lifecycle stubs that `createReactOnRails` overrides at initialization. The
  // stripped names are kept in sync with the `Omit<...>` in BaseClientObjectType so the shim
  // object's enumerable keys match what old Pro consumers received.
  const proOnlyMethods = new Set<string>([
    'getOrWaitForComponent',
    'getOrWaitForStore',
    'getOrWaitForStoreGenerator',
    'reactOnRailsStoreLoaded',
    'streamServerRenderedReactComponent',
    'serverRenderRSCReactComponent',
    'addAsyncPropsCapabilityToComponentProps',
    'getOrCreateAsyncPropsManager',
  ]);
  const core = createCoreCapability(registries);
  const obj = Object.fromEntries(
    Object.entries(core).filter(([key]) => !proOnlyMethods.has(key)),
  ) as unknown as BaseClientObjectType;

  // ===================================================================
  // CLIENT-SIDE RENDERING STUBS - To be overridden by createReactOnRails
  // ===================================================================

  obj.reactOnRailsPageLoaded = (): Promise<void> => {
    throw new Error(
      'ReactOnRails.reactOnRailsPageLoaded is not initialized. This is a bug in react-on-rails.',
    );
  };

  obj.reactOnRailsComponentLoaded = (domId: string): Promise<void> => {
    void domId; // Mark as used
    throw new Error(
      'ReactOnRails.reactOnRailsComponentLoaded is not initialized. This is a bug in react-on-rails.',
    );
  };

  // Cache the object and registries
  cachedObject = obj;
  cachedRegistries = registries;

  return obj;
}
