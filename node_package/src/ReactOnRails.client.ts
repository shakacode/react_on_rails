import type { ReactElement } from 'react';
import * as ClientStartup from './clientStartup';
import { renderOrHydrateComponent, hydrateStore } from './ClientSideRenderer';
import ComponentRegistry from './ComponentRegistry';
import StoreRegistry from './StoreRegistry';
import buildConsoleReplay from './buildConsoleReplay';
import createReactOutput from './createReactOutput';
import Authenticity from './Authenticity';
import context from './context';
import type {
  RegisteredComponent,
  RenderResult,
  RenderReturnType,
  ReactComponentOrRenderFunction,
  AuthenticityHeaders,
  Store,
  StoreGenerator,
  ReactOnRailsOptions,
} from './types';
import reactHydrateOrRender from './reactHydrateOrRender';

const ctx = context();

if (ctx === undefined) {
  throw new Error("The context (usually Window or NodeJS's Global) is undefined.");
}

if (ctx.ReactOnRails !== undefined) {
  /* eslint-disable @typescript-eslint/no-base-to-string -- Window and Global both have useful toString() */
  throw new Error(`\
The ReactOnRails value exists in the ${ctx} scope, it may not be safe to overwrite it.
This could be caused by setting Webpack's optimization.runtimeChunk to "true" or "multiple," rather than "single."
Check your Webpack configuration. Read more at https://github.com/shakacode/react_on_rails/issues/1558.`);
  /* eslint-enable @typescript-eslint/no-base-to-string */
}

const DEFAULT_OPTIONS: ReactOnRailsOptions = {
  traceTurbolinks: false,
  turbo: false,
  rscPayloadGenerationUrlPath: '/rsc_payload',
};

ctx.ReactOnRails = {
  options: {},

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

  getOrWaitForStore(name: string): Promise<Store> {
    return StoreRegistry.getOrWaitForStore(name);
  },

  getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator> {
    return StoreRegistry.getOrWaitForStoreGenerator(name);
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

    const validOptionKeys = Object.keys(DEFAULT_OPTIONS);
    const providedOptionKeys = Object.keys(newOptions);
    
    const invalidOptions = providedOptionKeys.filter(key => !validOptionKeys.includes(key));
    if (invalidOptions.length > 0) {
      throw new Error(
        `Invalid options passed to ReactOnRails.options: ${JSON.stringify(invalidOptions)}`,
      );
    }

    // Filter out undefined values before merging
    const definedOptions = Object.fromEntries(
      Object.entries(newOptions).filter(([_, value]) => value !== undefined)
    );

    this.options = { ...this.options, ...definedOptions };
  },

  reactOnRailsPageLoaded() {
    return ClientStartup.reactOnRailsPageLoaded();
  },

  reactOnRailsComponentLoaded(domId: string): Promise<void> {
    return renderOrHydrateComponent(domId);
  },

  reactOnRailsStoreLoaded(storeName: string): Promise<void> {
    return hydrateStore(storeName);
  },

  authenticityToken(): string | null {
    return Authenticity.authenticityToken();
  },

  authenticityHeaders(otherHeaders: Record<string, string> = {}): AuthenticityHeaders {
    return Authenticity.authenticityHeaders(otherHeaders);
  },

  // /////////////////////////////////////////////////////////////////////////////
  // INTERNALLY USED APIs
  // /////////////////////////////////////////////////////////////////////////////

  option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K] | undefined {
    return this.options[key];
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

  render(name: string, props: Record<string, string>, domNodeId: string, hydrate: boolean): RenderReturnType {
    const componentObj = ComponentRegistry.get(name);
    const reactElement = createReactOutput({ componentObj, props, domNodeId });

    return reactHydrateOrRender(
      document.getElementById(domNodeId) as Element,
      reactElement as ReactElement,
      hydrate,
    );
  },

  getComponent(name: string): RegisteredComponent {
    return ComponentRegistry.get(name);
  },

  getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
    return ComponentRegistry.getOrWaitForComponent(name);
  },

  serverRenderReactComponent(): null | string | Promise<RenderResult> {
    throw new Error(
      'serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
    );
  },

  streamServerRenderedReactComponent() {
    throw new Error(
      'streamServerRenderedReactComponent is only supported when using a bundle built for Node.js environments',
    );
  },

  serverRenderRSCReactComponent() {
    throw new Error('serverRenderRSCReactComponent is supported in RSC bundle only.');
  },

  handleError(): string | undefined {
    throw new Error(
      'handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
    );
  },

  buildConsoleReplay(): string {
    return buildConsoleReplay();
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

  resetOptions(): void {
    this.options = { ...DEFAULT_OPTIONS };
  },

  isRSCBundle: false,
};

ctx.ReactOnRails.resetOptions();

ClientStartup.clientStartup(ctx);

export * from './types';
export default ctx.ReactOnRails;
