import { Component, Ref } from 'react';
import { Store } from 'redux';

export interface RegisteredComponent {
  name: string;
  component: Component;
  generatorFunction: boolean;
  isRenderer: boolean;
}

export interface RailsContext {
  railsEnv: "development" | "test" | "staging" | "production";
  inMailer: boolean;
  i18nLocale: string;
  i18nDefaultLocale: string;
  rorVersion: string;
  rorPro: boolean;
  serverSide: boolean;
  originalUrl?: string;
  href?: string;
  location?: string;
  scheme?: string;
  host?: string;
  port?: string;
  pathname?: string;
  search?: string;
  httpAcceptLanguage?: string;
}

interface FileError extends Error {
  fileName: string;
  lineNumber: string;
}

export interface ErrorOptions {
  e: FileError;
  name?: string;
  jsCode?: string;
  serverSide: boolean;
}

export interface RenderParams {
  name?: string;
  componentObj: Component;
  props: Record<string, string>;
  railsContext?: RailsContext;
  domNodeId?: string;
  trace?: string;
  shouldHydrate?: boolean;
}

export interface ReactOnRails {
  register(components: { [id: string]: Component }): void;
  registerStore(stores: { [id: string]: Function }): void;
  getStore(name: string, throwIfMissing: boolean): Store;
  setOptions(newOptions: {traceTurbolinks: boolean}): void;
  reactOnRailsPageLoaded(): void;
  authenticityToken(): string;
  authenticityHeaders(otherHeaders: { [id: string]: string }): {[id: string]: string} & {'X-CSRF-Token': string; 'X-Requested-With': string};
  option(key: string): string | number | boolean | undefined;
  getStoreGenerator(name: string): Function;
  setStore(name: string, store: Store): void;
  clearHydratedStores(): void;
  render(name: string, props: Record<string, string>, domNodeId: string, hydrate: boolean): Ref;
  getComponent(name: string): RegisteredComponent;
  serverRenderReactComponent(options: RenderParams): string;
  handleError(options: ErrorOptions): string | undefined;
  buildConsoleReplay(): string;
  registeredComponents(): Map<string, Component>;
  storeGenerators(): Map<string, Function>;
  stores(): Map<string, Store>;
  resetOptions(): void;
}
