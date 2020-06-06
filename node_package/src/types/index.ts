import type { ReactElement, Component, FunctionComponent, ComponentClass } from 'react';
import type { Store } from 'redux';


type ReactComponent = FunctionComponent | ComponentClass | string;

interface Params {
  props?: {};
  railsContext?: RailsContext;
  domNodeId?: string;
  trace?: boolean;
}

export interface RenderParams extends Params {
  name: string;
}

export interface CreateParams extends Params {
  componentObj: RegisteredComponent;
  shouldHydrate?: boolean;
}

export interface RailsContext {
  railsEnv?: "development" | "test" | "staging" | "production";
  inMailer?: boolean;
  i18nLocale?: string;
  i18nDefaultLocale?: string;
  rorVersion?: string;
  rorPro?: boolean;
  serverSide?: boolean;
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

type AuthenticityHeaders = {[id: string]: string} & {'X-CSRF-Token': string | null; 'X-Requested-With': string};

type StoreGenerator = (props: {}, railsContext: RailsContext) => Store

interface ServerRenderResult {
  renderedHtml?: string;
  redirectLocation?: {pathname: string; search: string};
  routeError?: Error;
  error?: Error;
}

type CreateReactOutputResult = ServerRenderResult | ReactElement;

type RenderFunctionResult = ReactComponent | ServerRenderResult;

interface RenderFunction {
  (props?: {}, railsContext?: RailsContext, domNodeId?: string): RenderFunctionResult;
  // We allow specifying that the function is RenderFunction and not a React Function Component
  // by setting this property
  renderFunction?: boolean;
}

type ReactComponentOrRenderFunction = ReactComponent | RenderFunction;

export type { // eslint-disable-line import/prefer-default-export
  ReactComponentOrRenderFunction,
  ReactComponent,
  AuthenticityHeaders,
  RenderFunction,
  RenderFunctionResult,
  StoreGenerator,
  CreateReactOutputResult,
  ServerRenderResult,
}

export interface RegisteredComponent {
  name: string;
  component: ReactComponentOrRenderFunction;
  renderFunction: boolean;
  isRenderer: boolean;
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

export interface ReactOnRails {
  register(components: { [id: string]: ReactComponentOrRenderFunction }): void;
  registerStore(stores: { [id: string]: Store }): void;
  getStore(name: string, throwIfMissing: boolean): Store | undefined;
  setOptions(newOptions: {traceTurbolinks: boolean}): void;
  reactOnRailsPageLoaded(): void;
  authenticityToken(): string | null;
  authenticityHeaders(otherHeaders: { [id: string]: string }): AuthenticityHeaders;
  option(key: string): string | number | boolean | undefined;
  getStoreGenerator(name: string): Function;
  setStore(name: string, store: Store): void;
  clearHydratedStores(): void;
  render(
    name: string, props: Record<string, string>, domNodeId: string, hydrate: boolean
  ): void | Element | Component;
  getComponent(name: string): RegisteredComponent;
  serverRenderReactComponent(options: RenderParams): string;
  handleError(options: ErrorOptions): string | undefined;
  buildConsoleReplay(): string;
  registeredComponents(): Map<string, RegisteredComponent>;
  storeGenerators(): Map<string, Function>;
  stores(): Map<string, Store>;
  resetOptions(): void;
  options: Record<string, string | number | boolean>;
}
