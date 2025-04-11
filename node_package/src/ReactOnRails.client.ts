import type { ReactElement } from 'react';
import * as ClientStartup from './clientStartup.ts';
import { renderOrHydrateComponent, hydrateStore } from './ClientSideRenderer.ts';
import * as ComponentRegistry from './ComponentRegistry.ts';
import * as StoreRegistry from './StoreRegistry.ts';
import createReactOutput from './createReactOutput.ts';
import * as Authenticity from './Authenticity.ts';
import type {
  RegisteredComponent,
  RenderResult,
  RenderReturnType,
  ReactComponentOrRenderFunction,
  AuthenticityHeaders,
  Store,
  StoreGenerator,
  ReactOnRailsOptions,
} from './types/index.ts';
import reactHydrateOrRenderInternal from './reactHydrateOrRender.ts';

export { default as buildConsoleReplay } from './buildConsoleReplay.ts';

declare global {
  /* eslint-disable no-var,vars-on-top,no-underscore-dangle */
  var __REACT_ON_RAILS_LOADED__: boolean;
  /* eslint-enable no-var,vars-on-top,no-underscore-dangle */
}

if (globalThis.__REACT_ON_RAILS_LOADED__) {
  throw new Error(`\
The ReactOnRails value exists in the ${globalThis} scope, it may not be safe to overwrite it.
This could be caused by setting Webpack's optimization.runtimeChunk to "true" or "multiple," rather than "single."
Check your Webpack configuration. Read more at https://github.com/shakacode/react_on_rails/issues/1558.`);
}

globalThis.__REACT_ON_RAILS_LOADED__ = true;

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
};

let options: ReactOnRailsOptions = {};

// TODO: convert to re-exports if everything works fine
export function register(components: Record<string, ReactComponentOrRenderFunction>): void {
  ComponentRegistry.register(components);
}

// eslint-disable-next-line @typescript-eslint/no-shadow
export function registerStoreGenerators(storeGenerators: Record<string, StoreGenerator>): void {
  if (!storeGenerators) {
    throw new Error(
      'Called ReactOnRails.registerStoreGenerators with a null or undefined, rather than ' +
        'an Object with keys being the store names and the values are the store generators.',
    );
  }

  StoreRegistry.register(storeGenerators);
}

// eslint-disable-next-line @typescript-eslint/no-shadow
export function registerStore(stores: Record<string, StoreGenerator>): void {
  registerStoreGenerators(stores);
}

export function getStore(name: string, throwIfMissing = true): Store | undefined {
  return StoreRegistry.getStore(name, throwIfMissing);
}

export function getOrWaitForStore(name: string): Promise<Store> {
  return StoreRegistry.getOrWaitForStore(name);
}

export function getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator> {
  return StoreRegistry.getOrWaitForStoreGenerator(name);
}

export function reactHydrateOrRender(
  domNode: Element,
  reactElement: ReactElement,
  hydrate: boolean,
): RenderReturnType {
  return reactHydrateOrRenderInternal(domNode, reactElement, hydrate);
}

export function setOptions(newOptions: Partial<ReactOnRailsOptions>): void {
  if (typeof newOptions.traceTurbolinks !== 'undefined') {
    options.traceTurbolinks = newOptions.traceTurbolinks;

    // eslint-disable-next-line no-param-reassign
    delete newOptions.traceTurbolinks;
  }

  if (typeof newOptions.turbo !== 'undefined') {
    options.turbo = newOptions.turbo;

    // eslint-disable-next-line no-param-reassign
    delete newOptions.turbo;
  }

  if (Object.keys(newOptions).length > 0) {
    throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`);
  }
}

export function reactOnRailsPageLoaded() {
  return ClientStartup.reactOnRailsPageLoaded();
}

export function reactOnRailsComponentLoaded(domId: string): Promise<void> {
  return renderOrHydrateComponent(domId);
}

export function reactOnRailsStoreLoaded(storeName: string): Promise<void> {
  return hydrateStore(storeName);
}

export function authenticityToken(): string | null {
  return Authenticity.authenticityToken();
}

export function authenticityHeaders(otherHeaders: Record<string, string> = {}): AuthenticityHeaders {
  return Authenticity.authenticityHeaders(otherHeaders);
}

// /////////////////////////////////////////////////////////////////////////////
// INTERNALLY USED APIs
// /////////////////////////////////////////////////////////////////////////////

export function option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K] | undefined {
  return options[key];
}

export function getStoreGenerator(name: string): StoreGenerator {
  return StoreRegistry.getStoreGenerator(name);
}

export function setStore(name: string, store: Store): void {
  StoreRegistry.setStore(name, store);
}

export function clearHydratedStores(): void {
  StoreRegistry.clearHydratedStores();
}

export function render(
  name: string,
  props: Record<string, string>,
  domNodeId: string,
  hydrate: boolean,
): RenderReturnType {
  const componentObj = ComponentRegistry.get(name);
  const reactElement = createReactOutput({ componentObj, props, domNodeId });

  return reactHydrateOrRenderInternal(
    document.getElementById(domNodeId) as Element,
    reactElement as ReactElement,
    hydrate,
  );
}

export function getComponent(name: string): RegisteredComponent {
  return ComponentRegistry.get(name);
}

export function getOrWaitForComponent(name: string): Promise<RegisteredComponent> {
  return ComponentRegistry.getOrWaitForComponent(name);
}

export function serverRenderReactComponent(): null | string | Promise<RenderResult> {
  throw new Error(
    'serverRenderReactComponent is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
  );
}

export function streamServerRenderedReactComponent() {
  throw new Error(
    'streamServerRenderedReactComponent is only supported when using a bundle built for Node.js environments',
  );
}

export function serverRenderRSCReactComponent() {
  throw new Error('serverRenderRSCReactComponent is supported in RSC bundle only.');
}

export function handleError(): string | undefined {
  throw new Error(
    'handleError is not available in "react-on-rails/client". Import "react-on-rails" server-side.',
  );
}

export function registeredComponents(): Map<string, RegisteredComponent> {
  return ComponentRegistry.components();
}

export function storeGenerators(): Map<string, StoreGenerator> {
  return StoreRegistry.storeGenerators();
}

export function stores(): Map<string, Store> {
  return StoreRegistry.stores();
}

export function resetOptions(): void {
  options = { ...DEFAULT_OPTIONS };
}

export const isRSCBundle = false;

resetOptions();

ClientStartup.clientStartup();

export * from './types/index.ts';
