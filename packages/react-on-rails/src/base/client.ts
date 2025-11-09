import type { ReactElement } from 'react';
import type {
  RegisteredComponent,
  RenderReturnType,
  ReactComponentOrRenderFunction,
  AuthenticityHeaders,
  Store,
  StoreGenerator,
  ReactOnRailsOptions,
  ReactOnRailsInternal,
} from '../types/index.ts';
import * as Authenticity from '../Authenticity.ts';
import buildConsoleReplay from '../buildConsoleReplay.ts';
import reactHydrateOrRender from '../reactHydrateOrRender.ts';
import createReactOutput from '../createReactOutput.ts';

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
  debugMode: false,
  logComponentRegistration: false,
};

interface Registries {
  ComponentRegistry: {
    register: (components: Record<string, ReactComponentOrRenderFunction>) => void;
    get: (name: string) => RegisteredComponent;
    components: () => Map<string, RegisteredComponent>;
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
      return reactHydrateOrRender(domNode, reactElement, hydrate);
    },

    setOptions(newOptions: Partial<ReactOnRailsOptions>): void {
      if (typeof newOptions.traceTurbolinks !== 'undefined') {
        this.options.traceTurbolinks = newOptions.traceTurbolinks;
        // eslint-disable-next-line no-param-reassign
        delete newOptions.traceTurbolinks;
      }

      if (typeof newOptions.turbo !== 'undefined') {
        this.options.turbo = newOptions.turbo;
        // eslint-disable-next-line no-param-reassign
        delete newOptions.turbo;
      }

      if (typeof newOptions.debugMode !== 'undefined') {
        this.options.debugMode = newOptions.debugMode;
        if (newOptions.debugMode) {
          console.log('[ReactOnRails] Debug mode enabled');
        }
        // eslint-disable-next-line no-param-reassign
        delete newOptions.debugMode;
      }

      if (typeof newOptions.logComponentRegistration !== 'undefined') {
        this.options.logComponentRegistration = newOptions.logComponentRegistration;
        if (newOptions.logComponentRegistration) {
          console.log('[ReactOnRails] Component registration logging enabled');
        }
        // eslint-disable-next-line no-param-reassign
        delete newOptions.logComponentRegistration;
      }

      if (Object.keys(newOptions).length > 0) {
        throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`);
      }
    },

    option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K] | undefined {
      return this.options[key];
    },

    buildConsoleReplay(): string {
      return buildConsoleReplay();
    },

    resetOptions(): void {
      this.options = { ...DEFAULT_OPTIONS };
    },

    // ===================================================================
    // REGISTRY METHOD IMPLEMENTATIONS - Using provided registries
    // ===================================================================

    register(components: Record<string, ReactComponentOrRenderFunction>): void {
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
            const size = component.toString().length;
            console.log(`[ReactOnRails] ✅ Registered: ${name} (${size} chars)`);
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

    getComponent(name: string): RegisteredComponent {
      return ComponentRegistry.get(name);
    },

    registeredComponents(): Map<string, RegisteredComponent> {
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
      props: Record<string, string>,
      domNodeId: string,
      hydrate: boolean,
    ): RenderReturnType {
      const componentObj = ComponentRegistry.get(name);
      const reactElement = createReactOutput({ componentObj, props, domNodeId });

      return this.reactHydrateOrRender(
        document.getElementById(domNodeId) as Element,
        reactElement as ReactElement,
        hydrate,
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
  };

  // Cache the object and registries
  cachedObject = obj;
  cachedRegistries = registries;

  return obj;
}
