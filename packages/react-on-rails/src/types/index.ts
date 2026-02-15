/// <reference types="react/experimental" />

import type { ReactElement, ReactNode, Component, ComponentType } from 'react';
import type { PipeableStream } from 'react-dom/server';
import type { Readable } from 'stream';

/* eslint-disable @typescript-eslint/no-explicit-any */
/**
 * Don't import Redux just for the type definitions
 * See https://github.com/shakacode/react_on_rails/issues/1321
 * and https://redux.js.org/api/store for the actual API.
 * @see {import('redux').Store}
 */
type Store = {
  getState(): unknown;
};

type ReactComponent = ComponentType<any> | string;

// Keep these in sync with method lib/react_on_rails/helper.rb#rails_context
export type RailsContext = {
  componentRegistryTimeout: number;
  railsEnv: string;
  inMailer: boolean;
  i18nLocale: string;
  i18nDefaultLocale: string;
  rorVersion: string;
  rorPro: boolean;
  rorProVersion?: string;
  href: string;
  location: string;
  scheme: string;
  host: string;
  port: number | null;
  pathname: string;
  search: string | null;
  httpAcceptLanguage: string;
  rscPayloadGenerationUrlPath?: string;
} & (
  | {
      serverSide: false;
    }
  | {
      serverSide: true;
      // These parameters are passed from React on Rails Pro to the node renderer.
      // They contain the necessary information to generate the RSC (React Server Components) payload.
      // Typically, this includes the bundle hash of the RSC bundle.
      // The react-on-rails package uses 'unknown' for these parameters to avoid direct dependency.
      // This ensures that if the communication protocol between the node renderer and the Rails server changes,
      // we don't need to update this type or introduce a breaking change.
      serverSideRSCPayloadParameters?: unknown;
      reactClientManifestFileName?: string;
      reactServerClientManifestFileName?: string;
      getRSCPayloadStream: (componentName: string, props: unknown) => Promise<NodeJS.ReadableStream>;
    }
);

export type RailsContextWithServerComponentMetadata = RailsContext & {
  serverSide: true;
  serverSideRSCPayloadParameters?: unknown;
  reactClientManifestFileName: string;
  reactServerClientManifestFileName: string;
};

export type RailsContextWithServerStreamingCapabilities = RailsContextWithServerComponentMetadata & {
  getRSCPayloadStream: (componentName: string, props: unknown) => Promise<NodeJS.ReadableStream>;
  addPostSSRHook: (hook: () => void) => void;
};

const throwRailsContextMissingEntries = (missingEntries: string) => {
  throw new Error(
    `Rails context does not have server side ${missingEntries}.\n\n` +
      'Possible causes:\n' +
      '1. Your version of react_on_rails_pro does not support server components.\n' +
      '2. Server components support is not enabled. Set:\n' +
      '   ReactOnRailsPro.configuration.enable_rsc_support = true',
  );
};

export const assertRailsContextWithServerComponentMetadata: (
  context: RailsContext | undefined,
) => asserts context is RailsContextWithServerComponentMetadata = (
  context: RailsContext | undefined,
): asserts context is RailsContextWithServerComponentMetadata => {
  if (
    !context ||
    !('reactClientManifestFileName' in context) ||
    !('reactServerClientManifestFileName' in context)
  ) {
    throwRailsContextMissingEntries(
      'server side RSC payload parameters, reactClientManifestFileName, and reactServerClientManifestFileName',
    );
  }
};

export const assertRailsContextWithServerStreamingCapabilities: (
  context: RailsContext | undefined,
) => asserts context is RailsContextWithServerStreamingCapabilities = (
  context: RailsContext | undefined,
): asserts context is RailsContextWithServerStreamingCapabilities => {
  assertRailsContextWithServerComponentMetadata(context);

  if (!('getRSCPayloadStream' in context) || !('addPostSSRHook' in context)) {
    throwRailsContextMissingEntries('getRSCPayloadStream and addPostSSRHook functions');
  }
};

// not strictly what we want, see https://github.com/microsoft/TypeScript/issues/17867#issuecomment-323164375
type AuthenticityHeaders = Record<string, string> & {
  'X-CSRF-Token': string | null;
  'X-Requested-With': string;
};

type StoreGenerator = (props: Record<string, unknown>, railsContext: RailsContext) => Store;

type ServerRenderHashRenderedHtml = {
  componentHtml: string;
  [key: string]: string;
};

interface ServerRenderResult {
  renderedHtml?: string | ServerRenderHashRenderedHtml;
  redirectLocation?: { pathname: string; search: string };
  routeError?: Error;
  error?: Error;
}

type CreateReactOutputSyncResult = ServerRenderResult | ReactElement;

type CreateReactOutputAsyncResult = Promise<string | ServerRenderHashRenderedHtml | ReactElement>;

type CreateReactOutputResult = CreateReactOutputSyncResult | CreateReactOutputAsyncResult;

type RenderFunctionSyncResult = ReactComponent | ServerRenderResult;

type RenderFunctionAsyncResult = Promise<string | ServerRenderHashRenderedHtml | ReactComponent>;

type RenderFunctionResult = RenderFunctionSyncResult | RenderFunctionAsyncResult;

type StreamableComponentResult = ReactElement | Promise<ReactElement | string>;

/**
 * Render-functions are used to create dynamic React components or server-rendered HTML with side effects.
 * They receive two arguments: props and railsContext.
 *
 * @param props - The component props passed to the render function
 * @param railsContext - The Rails context object containing environment information
 * @returns A string, React component, React element, or a Promise resolving to a string
 *
 * @remarks
 * To distinguish a render function from a React Function Component:
 * 1. Ensure it accepts two parameters (props and railsContext), even if railsContext is unused, or
 * 2. Set the `renderFunction` property to `true` on the function object.
 *
 * If neither condition is met, it will be treated as a React Function Component,
 * and ReactDOMServer will attempt to render it.
 *
 * @example
 * // Option 1: Two-parameter function
 * const renderFunction = (props, railsContext) => { ... };
 *
 * // Option 2: Using renderFunction property
 * const anotherRenderFunction = (props) => { ... };
 * anotherRenderFunction.renderFunction = true;
 */
interface RenderFunction {
  (props?: any, railsContext?: RailsContext, domNodeId?: string): RenderFunctionResult;
  // We allow specifying that the function is RenderFunction and not a React Function Component
  // by setting this property
  renderFunction?: true;
}

type ReactComponentOrRenderFunction = ReactComponent | RenderFunction;

type PipeableOrReadableStream = PipeableStream | NodeJS.ReadableStream;

export type {
  ReactComponentOrRenderFunction,
  ReactComponent,
  AuthenticityHeaders,
  RenderFunction,
  RenderFunctionResult,
  Store,
  StoreGenerator,
  CreateReactOutputResult,
  ServerRenderResult,
  ServerRenderHashRenderedHtml,
  CreateReactOutputSyncResult,
  CreateReactOutputAsyncResult,
  RenderFunctionSyncResult,
  RenderFunctionAsyncResult,
  StreamableComponentResult,
  PipeableOrReadableStream,
};

export interface RegisteredComponent {
  name: string;
  component: ReactComponentOrRenderFunction;
  /**
   * Indicates if the registered component is a RenderFunction
   * @see RenderFunction for more details on its behavior and usage.
   */
  renderFunction: boolean;
  // Indicates if the registered component is a Renderer function.
  // Renderer function handles DOM rendering or hydration with 3 args: (props, railsContext, domNodeId)
  // Supported on the client side only.
  // All renderer functions are render-functions, but not all render-functions are renderer functions.
  isRenderer: boolean;
}

export type ItemRegistrationCallback<T> = (component: T) => void;

interface Params {
  props?: Record<string, unknown>;
  railsContext?: RailsContext;
  domNodeId?: string;
  trace?: boolean;
}

export interface RenderParams extends Params {
  name: string;
  throwJsErrors: boolean;
  renderingReturnsPromises: boolean;
}

export interface RSCRenderParams extends Omit<RenderParams, 'railsContext'> {
  railsContext: RailsContextWithServerStreamingCapabilities;
}

export interface CreateParams extends Params {
  componentObj: RegisteredComponent;
  shouldHydrate?: boolean;
}

export interface ErrorOptions {
  // fileName and lineNumber are non-standard, but useful if present
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/fileName
  e: Error & { fileName?: string; lineNumber?: string };
  name?: string;
  jsCode?: string;
  serverSide: boolean;
}

export type RenderingError = Pick<Error, 'message' | 'stack'>;

export type FinalHtmlResult = string | ServerRenderHashRenderedHtml;

export interface RenderResult {
  html: FinalHtmlResult | null;
  consoleReplayScript: string;
  hasErrors: boolean;
  renderingError?: RenderingError;
  isShellReady?: boolean;
}

export interface RSCPayloadChunk extends RenderResult {
  html: string;
}

// from react-dom 18
export interface Root {
  render(children: ReactNode): void;
  unmount(): void;
}

// eslint-disable-next-line @typescript-eslint/no-invalid-void-type -- inherited from React 16/17, can't avoid here
export type RenderReturnType = void | Element | Component | Root;

export interface ReactOnRailsOptions {
  /** Gives you debugging messages on Turbolinks events. */
  traceTurbolinks?: boolean;
  /** Turbo (the successor of Turbolinks) events will be registered, if set to true. */
  turbo?: boolean;
  /** Enable debug mode for detailed logging of React on Rails operations. */
  debugMode?: boolean;
  /** Log component registration details including timing and size information. */
  logComponentRegistration?: boolean;
}

export interface ReactOnRails {
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components keys are component names, values are components
   */
  register(components: Record<string, ReactComponentOrRenderFunction>): void;
  /** @deprecated Use registerStoreGenerators instead */
  registerStore(stores: Record<string, StoreGenerator>): void;
  /**
   * Allows registration of store generators to be used by multiple React components on one Rails
   * view. Store generators are functions that take one arg, props, and return a store. Note that
   * the `setStore` API is different in that it's the actual store hydrated with props.
   * @param storeGenerators keys are store names, values are the store generators
   */
  registerStoreGenerators(storeGenerators: Record<string, StoreGenerator>): void;
  /**
   * Allows retrieval of the store by name. This store will be hydrated by any Rails form props.
   * @param name
   * @param [throwIfMissing=true] When false, this function will return undefined if
   *        there is no store with the given name.
   * @returns Redux Store, possibly hydrated
   */
  getStore(name: string, throwIfMissing?: boolean): Store | undefined;
  /**
   * Get a store by name, or wait for it to be registered.
   */
  getOrWaitForStore(name: string): Promise<Store>;
  /**
   * Get a store generator by name, or wait for it to be registered.
   */
  getOrWaitForStoreGenerator(name: string): Promise<StoreGenerator>;
  /**
   * Set options for ReactOnRails, typically before you call `ReactOnRails.register`.
   * @see {ReactOnRailsOptions}
   */
  setOptions(newOptions: Partial<ReactOnRailsOptions>): void;
  /**
   * Renders or hydrates the React element passed. In case React version is >=18 will use the root API.
   * @param domNode
   * @param reactElement
   * @param hydrate if true will perform hydration, if false will render
   * @returns {Root|ReactComponent|ReactElement|null}
   */
  reactHydrateOrRender(domNode: Element, reactElement: ReactElement, hydrate: boolean): RenderReturnType;
  /**
   * Allow directly calling the page loaded script in case the default events that trigger React
   * rendering are not sufficient, such as when loading JavaScript asynchronously with TurboLinks.
   * More details can be found here:
   * https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/turbolinks.md
   */
  reactOnRailsPageLoaded(): Promise<void>;
  reactOnRailsComponentLoaded(domId: string): Promise<void>;
  reactOnRailsStoreLoaded(storeName: string): Promise<void>;
  /**
   * Returns CSRF authenticity token inserted by Rails csrf_meta_tags
   * @returns String or null
   */
  authenticityToken(): string | null;
  /**
   * Returns headers with CSRF authenticity token and XMLHttpRequest
   * @param otherHeaders Other headers
   */
  authenticityHeaders(otherHeaders: Record<string, string>): AuthenticityHeaders;
  /**
   * Adds a post SSR hook to be called after the SSR has completed.
   * @param hook - The hook to be called after the SSR has completed.
   */
}

export type RSCPayloadStreamInfo = {
  stream: NodeJS.ReadableStream;
  props: unknown;
  componentName: string;
};

export type RSCPayloadCallback = (streamInfo: RSCPayloadStreamInfo) => void;

/** Contains the parts of the `ReactOnRails` API intended for internal use only. */
export interface ReactOnRailsInternal extends ReactOnRails {
  /**
   * Retrieve an option by key.
   * @param key
   * @returns option value
   */
  option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K];
  /**
   * Allows retrieval of the store generator by name. This is used internally by ReactOnRails after
   * a Rails form loads to prepare stores.
   * @param name
   * @returns Redux Store generator function
   */
  getStoreGenerator(name: string): StoreGenerator;
  /**
   * Allows saving the store populated by Rails form props. Used internally by ReactOnRails.
   */
  setStore(name: string, store: Store): void;
  /**
   * Clears `hydratedStores` to avoid accidental usage of wrong store hydrated in a previous/parallel
   * request.
   */
  clearHydratedStores(): void;
  /**
   * @example
   * ```js
   * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, "app");
   * ```
   *
   * Does this:
   * ```js
   * ReactDOM.render(
   *   React.createElement(HelloWorldApp, {name: "Stranger"}),
   *   document.getElementById("app")
   * );
   * ```
   * under React 16/17 and
   * ```js
   * const root = ReactDOMClient.createRoot(document.getElementById("app"));
   * root.render(React.createElement(HelloWorldApp, {name: "Stranger"}));
   * return root;
   * ```
   * under React 18+.
   *
   * @param name Name of your registered component
   * @param props Props to pass to your component
   * @param domNodeId HTML ID of the node the component will be rendered at
   * @param [hydrate=false] Pass truthy to update server rendered HTML. Default is falsy
   * @returns {Root|ReactComponent|ReactElement} Under React 18+: the created React root
   *   (see "What is a root?" in https://github.com/reactwg/react-18/discussions/5).
   *   Under React 16/17: Reference to your component's backing instance or `null` for stateless components.
   */
  render(name: string, props: Record<string, string>, domNodeId: string, hydrate?: boolean): RenderReturnType;
  /**
   * Get the component that you registered
   * @returns {name, component, renderFunction, isRenderer}
   */
  getComponent(name: string): RegisteredComponent;
  /**
   * Get the component that you registered, or wait for it to be registered
   * @returns {name, component, renderFunction, isRenderer}
   */
  getOrWaitForComponent(name: string): Promise<RegisteredComponent>;
  /**
   * Used by server rendering by Rails
   */
  serverRenderReactComponent(options: RenderParams): null | string | Promise<RenderResult>;
  /**
   * Used by server rendering by Rails
   */
  streamServerRenderedReactComponent(options: RenderParams): Readable;
  /**
   * Generates RSC payload, used by Rails
   */
  serverRenderRSCReactComponent(options: RSCRenderParams): Readable;
  /**
   * Used by Rails to catch errors in rendering
   */
  handleError(options: ErrorOptions): string | undefined;
  /**
   * Used by Rails server rendering to replay console messages.
   * Returns the console replay script wrapped in script tags.
   */
  buildConsoleReplay(): string;
  /**
   * Returns the console replay JavaScript code without wrapping it in script tags.
   * Useful when you need to add CSP nonce or other attributes to the script tag.
   */
  getConsoleReplayScript(): string;
  /**
   * Get a Map containing all registered components. Useful for debugging.
   */
  registeredComponents(): Map<string, RegisteredComponent>;
  /**
   * Get a Map containing all registered store generators. Useful for debugging.
   */
  storeGenerators(): Map<string, StoreGenerator>;
  /**
   * Get a Map containing all hydrated stores. Useful for debugging.
   */
  stores(): Map<string, Store>;
  /**
   * Reset options to default.
   */
  resetOptions(): void;
  /**
   * Current options.
   */
  options: ReactOnRailsOptions;
  /**
   * Indicates if the RSC bundle is being used.
   */
  isRSCBundle: boolean;
}

export type RenderStateHtml = FinalHtmlResult | Promise<FinalHtmlResult>;

export type RenderState = {
  result: null | RenderStateHtml;
  hasErrors: boolean;
  error?: RenderingError;
};

export type StreamRenderState = Omit<RenderState, 'result'> & {
  result: null | Readable;
  isShellReady: boolean;
};

export type RenderOptions = {
  componentName: string;
  domNodeId?: string;
  trace?: boolean;
  renderingReturnsPromises: boolean;
};

// Note: Global type declaration for ReactOnRails is in context.ts
// to avoid circular dependencies with ReactOnRailsInternal
