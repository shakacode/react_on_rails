/**
 * @deprecated Use `capabilities/core.ts` instead. This file is kept for backward compatibility
 * with older versions of react-on-rails-pro that import from `react-on-rails/@internal/base/client`.
 */

import type { ReactElement } from 'react';
import type {
  RegisteredComponent,
  RenderReturnType,
  RegisteredComponentValue,
  AuthenticityHeaders,
  Store,
  StoreGenerator,
  ReactOnRailsOptions,
  ReactOnRailsInternal,
} from '../types/index.ts';
import * as Authenticity from '../Authenticity.ts';
import buildConsoleReplay, { consoleReplay } from '../buildConsoleReplay.ts';
import reactHydrateOrRender from '../reactHydrateOrRender.ts';
import createReactOutput from '../createReactOutput.ts';
import componentRegistrationMetric from '../componentRegistrationMetric.ts';
import {
  buildRootErrorCallbackOptions,
  getRootErrorHandlers,
  resetRootErrorHandlers,
  setRootErrorHandlers,
} from '../rootErrorHandlers.ts';

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
  debugMode: false,
  logComponentRegistration: false,
};

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
  const { ComponentRegistry, StoreRegistry } = registries;

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

  // Create and return new object
  const obj = {
    options: {} as Partial<ReactOnRailsOptions>,
    isRSCBundle: false,

    // ===================================================================
    // STABLE METHOD IMPLEMENTATIONS - Core package implementations
    // ===================================================================

    authenticityToken(): string | null {
      return Authenticity.authenticityToken();
    },

    authenticityHeaders(otherHeaders: Record<string, string> = {}): AuthenticityHeaders {
      return Authenticity.authenticityHeaders(otherHeaders);
    },

    reactHydrateOrRender(domNode: Element, reactElement: ReactElement, hydrate: boolean): RenderReturnType {
      // The component name is unknown on this low-level path; the dom id still ties errors to a mount.
      const rootErrorCallbackOptions = buildRootErrorCallbackOptions(
        { domNodeId: domNode.id || undefined },
        hydrate,
      );
      return reactHydrateOrRender(domNode, reactElement, hydrate, rootErrorCallbackOptions);
    },

    setOptions(newOptions: Partial<ReactOnRailsOptions>): void {
      const { traceTurbolinks, turbo, debugMode, logComponentRegistration, rootErrorHandlers, ...rest } =
        newOptions;

      if (typeof traceTurbolinks !== 'undefined') {
        this.options.traceTurbolinks = traceTurbolinks;
      }

      if (typeof turbo !== 'undefined') {
        this.options.turbo = turbo;
      }

      if (typeof debugMode !== 'undefined') {
        this.options.debugMode = debugMode;
        if (debugMode) {
          console.log('[ReactOnRails] Debug mode enabled');
        }
      }

      if (typeof logComponentRegistration !== 'undefined') {
        this.options.logComponentRegistration = logComponentRegistration;
        if (logComponentRegistration) {
          console.log('[ReactOnRails] Component registration logging enabled');
        }
      }

      if (Object.prototype.hasOwnProperty.call(newOptions, 'rootErrorHandlers')) {
        // MIRROR OF: packages/react-on-rails/src/capabilities/core.ts
        // Validates and merges the handlers per key (partial updates keep previously registered
        // callbacks); warns when the React runtime cannot support them. Store the merged result so
        // `option('rootErrorHandlers')` reflects the effective registration.
        if (typeof rootErrorHandlers === 'undefined') {
          resetRootErrorHandlers();
          this.options.rootErrorHandlers = undefined;
        } else {
          setRootErrorHandlers(rootErrorHandlers);
          this.options.rootErrorHandlers = getRootErrorHandlers();
        }
      }

      if (Object.keys(rest).length > 0) {
        throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(rest)}`);
      }
    },

    option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K] {
      return this.options[key];
    },

    buildConsoleReplay(): string {
      return buildConsoleReplay();
    },

    getConsoleReplayScript(): string {
      return consoleReplay();
    },

    resetOptions(): void {
      this.options = { ...DEFAULT_OPTIONS };
      resetRootErrorHandlers();
    },

    // ===================================================================
    // REGISTRY METHOD IMPLEMENTATIONS - Using provided registries
    // ===================================================================

    register(components: Record<string, RegisteredComponentValue>): void {
      if (this.options.debugMode || this.options.logComponentRegistration) {
        // Use performance.now() if available, otherwise fallback to Date.now()
        const perf = typeof performance !== 'undefined' ? performance : { now: () => Date.now() };
        const startTime = perf.now();
        const componentNames = Object.keys(components);
        console.log(
          `[ReactOnRails] Registering ${componentNames.length} component(s): ${componentNames.join(', ')}`,
        );

        ComponentRegistry.register(components);

        const endTime = perf.now();
        console.log(
          `[ReactOnRails] Component registration completed in ${(endTime - startTime).toFixed(2)}ms`,
        );

        // Log individual component details if in full debug mode
        if (this.options.debugMode) {
          componentNames.forEach((name) => {
            const component = components[name];
            const registrationMetric = componentRegistrationMetric(component);
            console.log(
              `[ReactOnRails] ✅ Registered: ${name} (${registrationMetric.value} ${registrationMetric.label})`,
            );
          });
        }
      } else {
        ComponentRegistry.register(components);
      }
    },

    registerStore(stores: Record<string, StoreGenerator>): void {
      this.registerStoreGenerators(stores);
    },

    registerStoreGenerators(storeGenerators: Record<string, StoreGenerator>): void {
      if (!storeGenerators) {
        throw new Error(
          'Called ReactOnRails.registerStoreGenerators with a null or undefined, rather than ' +
            'an Object with keys being the store names and the values are the store generators.',
        );
      }
      StoreRegistry.register(storeGenerators);
    },

    getStore(name: string, throwIfMissing = true): Store | undefined {
      return StoreRegistry.getStore(name, throwIfMissing);
    },

    getStoreGenerator(name: string): StoreGenerator {
      return StoreRegistry.getStoreGenerator(name);
    },

    setStore(name: string, store: Store): void {
      StoreRegistry.setStore(name, store);
    },

    clearHydratedStores(): void {
      StoreRegistry.clearHydratedStores();
    },

    getComponent(name: string): RegisteredComponentEntry {
      return ComponentRegistry.get(name);
    },

    registeredComponents(): Map<string, RegisteredComponentEntry> {
      return ComponentRegistry.components();
    },

    storeGenerators(): Map<string, StoreGenerator> {
      return StoreRegistry.storeGenerators();
    },

    stores(): Map<string, Store> {
      return StoreRegistry.stores();
    },

    render(
      name: string,
      props: Record<string, unknown>,
      domNodeId: string,
      hydrate: boolean,
    ): RenderReturnType {
      const componentObj = ComponentRegistry.get(name);
      const reactElement = createReactOutput({ componentObj, props, domNodeId });

      return reactHydrateOrRender(
        document.getElementById(domNodeId) as Element,
        reactElement as ReactElement,
        hydrate,
        buildRootErrorCallbackOptions(
          { componentName: name || undefined, domNodeId: domNodeId || undefined },
          hydrate,
        ),
      );
    },

    // ===================================================================
    // CLIENT-SIDE RENDERING STUBS - To be overridden by createReactOnRails
    // ===================================================================

    reactOnRailsPageLoaded(): Promise<void> {
      throw new Error(
        'ReactOnRails.reactOnRailsPageLoaded is not initialized. This is a bug in react-on-rails.',
      );
    },

    reactOnRailsComponentLoaded(domId: string): Promise<void> {
      void domId; // Mark as used
      throw new Error(
        'ReactOnRails.reactOnRailsComponentLoaded is not initialized. This is a bug in react-on-rails.',
      );
    },

    // ===================================================================
    // SSR STUBS - Will throw errors in client bundle, overridden in full
    // ===================================================================

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    serverRenderReactComponent(...args: any[]): any {
      void args; // Mark as used
      throw new Error(
        'serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
      );
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleError(...args: any[]): any {
      void args; // Mark as used
      throw new Error(
        'handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
      );
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    prepareRenderResult(...args: any[]): any {
      void args; // Mark as used
      throw new Error(
        'prepareRenderResult is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
      );
    },
  };

  // Cache the object and registries
  cachedObject = obj;
  cachedRegistries = registries;

  return obj;
}
