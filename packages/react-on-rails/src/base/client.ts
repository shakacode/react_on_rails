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
import buildConsoleReplay from '../buildConsoleReplay.ts';
import reactHydrateOrRender from '../reactHydrateOrRender.ts';
import createReactOutput from '../createReactOutput.ts';

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
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

export function createBaseClientObject(registries: Registries) {
  const { ComponentRegistry, StoreRegistry } = registries;

  return {
    options: {} as Partial<ReactOnRailsOptions>,

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
      ComponentRegistry.register(components);
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

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    reactOnRailsComponentLoaded(_domId: string): Promise<void> {
      throw new Error(
        'ReactOnRails.reactOnRailsComponentLoaded is not initialized. This is a bug in react-on-rails.',
      );
    },

    // ===================================================================
    // SSR STUBS - Will throw errors in client bundle, overridden in full
    // ===================================================================

    serverRenderReactComponent(): never {
      throw new Error(
        'serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
      );
    },

    handleError(): never {
      throw new Error(
        'handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
      );
    },

    // ===================================================================
    // FLAGS
    // ===================================================================

    isRSCBundle: false,
  };
}

export type BaseClientObjectType = ReturnType<typeof createBaseClientObject>;
