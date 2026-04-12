import type { ReactElement } from 'react';
import type {
  RegisteredComponent,
  RenderReturnType,
  ReactComponentOrRenderFunction,
  AuthenticityHeaders,
  Store,
  StoreGenerator,
  ReactOnRailsOptions,
} from '../types/index.ts';
import * as Authenticity from '../Authenticity.ts';
import buildConsoleReplay, { consoleReplay } from '../buildConsoleReplay.ts';
import reactHydrateOrRender from '../reactHydrateOrRender.ts';
import createReactOutput from '../createReactOutput.ts';

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
  debugMode: false,
  logComponentRegistration: false,
};

export interface Registries {
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
 * Creates the core capability containing all base ReactOnRails methods.
 * These are the methods that exist in every bundle variant (client, full, node, RSC).
 */
export function createCoreCapability(registries: Registries) {
  const { ComponentRegistry, StoreRegistry } = registries;

  return {
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
    // SSR STUBS — overridden by createSSRCapability() in full/node bundles
    // ===================================================================

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    serverRenderReactComponent(...args: any[]): any {
      void args;
      throw new Error(
        'serverRenderReactComponent is not available in the client bundle. Import "react-on-rails" server-side.',
      );
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    handleError(...args: any[]): any {
      void args;
      throw new Error(
        'handleError is not available in the client bundle. Import "react-on-rails" server-side.',
      );
    },

    // ===================================================================
    // PRO STUBS — overridden by Pro capabilities in react-on-rails-pro
    // ===================================================================

    getOrWaitForComponent(): Promise<RegisteredComponent> {
      throw new Error('getOrWaitForComponent requires the react-on-rails-pro package.');
    },

    getOrWaitForStore(): Promise<Store> {
      throw new Error('getOrWaitForStore requires the react-on-rails-pro package.');
    },

    getOrWaitForStoreGenerator(): Promise<StoreGenerator> {
      throw new Error('getOrWaitForStoreGenerator requires the react-on-rails-pro package.');
    },

    reactOnRailsStoreLoaded(): Promise<void> {
      throw new Error('reactOnRailsStoreLoaded requires the react-on-rails-pro package.');
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    streamServerRenderedReactComponent(...args: any[]): any {
      void args;
      throw new Error('streamServerRenderedReactComponent requires the react-on-rails-pro package.');
    },

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    serverRenderRSCReactComponent(...args: any[]): any {
      void args;
      throw new Error('serverRenderRSCReactComponent requires the react-on-rails-pro package.');
    },
  };
}
