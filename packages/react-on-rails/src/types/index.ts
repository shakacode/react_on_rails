/// <reference types="react/experimental" />

import type { ReactElement, ReactNode, Component, ComponentType, ExoticComponent } from 'react';
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

type ReactComponent = ComponentType<any> | ExoticComponent<any> | string;

// Keep these in sync with method lib/react_on_rails/helper.rb#rails_context
export type RailsContext = {
  componentRegistryTimeout: number;
  railsEnv: string;
  inMailer: boolean;
  i18nLocale: string;
  i18nDefaultLocale: string;
  rorVersion: string;
  // True when React on Rails Pro is installed on the server.
  // This does not indicate whether the current license token is valid.
  rorPro: boolean;
  // Present when rorPro is true; contains the installed React on Rails Pro version string.
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
  cspNonce?: string;
  /** Omit or leave undefined to disable; only true is a valid opt-in value. */
  rscStreamObservability?: true;
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
  // Records an RSC bundle diagnostic captured while parsing a component's payload stream so the
  // render-scoped error-surfacing site can recover it even when the failure propagates through
  // React's deferred render phase rather than rejecting the stream parse synchronously (#3475).
  //
  // Optional for backward compatibility: this field was added in the deferred-render diagnostic work
  // (#3475) and is additive over the pre-existing streaming contract. An external consumer that
  // constructs this context against an older Pro version (or a custom integration) may not supply it.
  // Callers must treat a missing `recordRSCDiagnostic` as "diagnostic recording unavailable" and skip
  // recording rather than crashing — see `getReactServerComponent.server.ts`. The Pro renderer always
  // supplies it (`streamingUtils.ts`), so the common path is unaffected.
  recordRSCDiagnostic?: (componentName: string, diagnosticError: Error) => void;
};

const throwRailsContextMissingEntries = (missingEntries: string) => {
  throw new Error(
    `Rails context does not have server side ${missingEntries}.\n\n` +
      'This is either a configuration issue or a bug:\n' +
      '1. Ensure you are using a compatible version of react_on_rails_pro\n' +
      '2. Ensure server components support is enabled:\n' +
      '   ReactOnRailsPro.configuration.enable_rsc_support = true\n\n' +
      'If the above are correct, please report at https://github.com/shakacode/react_on_rails/issues',
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

  // Verify the capabilities are callable, not merely present, so a misconfigured context fails here
  // with the intended diagnostic instead of crashing later at a call site.
  //
  // `recordRSCDiagnostic` is intentionally NOT required here. It is an additive field (#3475); an
  // external consumer constructing this context against an older Pro version may not supply it.
  // Hard-throwing on its absence would be a compat regression for those consumers even though their
  // type-check passes (the field is optional). Callers degrade gracefully when it is missing, so the
  // assertion only guards the two pre-existing required capabilities.
  // Cast to a Partial of the target type (rather than Record<string, unknown>) so the known
  // capability keys stay typed while we runtime-check that each is actually a function.
  const capabilities = context as Partial<RailsContextWithServerStreamingCapabilities>;
  if (
    typeof capabilities.getRSCPayloadStream !== 'function' ||
    typeof capabilities.addPostSSRHook !== 'function'
  ) {
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
  renderedHtml?: string | ServerRenderHashRenderedHtml | ReactElement;
  clientProps?: Record<string, unknown>;
  redirectLocation?: { pathname: string; search: string };
  routeError?: Error;
  error?: Error;
}

type CreateReactOutputSyncResult = ServerRenderResult | ReactElement;

type CreateReactOutputAsyncResult = Promise<
  string | ServerRenderHashRenderedHtml | ReactElement | ServerRenderResult
>;

type CreateReactOutputResult = CreateReactOutputSyncResult | CreateReactOutputAsyncResult;

type RenderFunctionSyncResult = ReactComponent | ServerRenderResult;

type RenderFunctionAsyncResult = Promise<
  string | ServerRenderHashRenderedHtml | ReactComponent | ServerRenderResult
>;

type RenderFunctionResult = RenderFunctionSyncResult | RenderFunctionAsyncResult;

type ReactComponentRenderFunctionResult = ReactComponent | Promise<ReactComponent>;

/**
 * Optional cleanup callback that a renderer function (the 3-argument form
 * `(props, railsContext, domNodeId) => …`) may return inside a {@link RendererTeardownResult}.
 * React on Rails invokes it when the mount is torn down — on Turbo/Turbolinks navigation (the
 * framework's soft-navigation page swap, not a native browser unload) and when the same `domNodeId`
 * node is replaced — so renderer-managed React roots, event listeners, and subscriptions are released
 * instead of leaked. May be synchronous or asynchronous.
 *
 * @see RenderFunction
 */
type RendererTeardownReturn = void | Promise<void>;

type RendererTeardown = () => RendererTeardownReturn;

/**
 * Object wrapper returned by a 3-argument renderer to opt into cleanup. The wrapper keeps teardown
 * detection unambiguous: legacy renderers may have returned function components before this contract
 * existed, so a bare function return is treated as no teardown.
 */
type RendererTeardownResult = {
  teardown: RendererTeardown;
};

/**
 * What the 3-argument renderer form may return for cleanup: nothing, or a
 * {@link RendererTeardownResult}. Runtime cleanup only recognizes this explicit wrapper; legacy
 * component/server-result returns from 3-argument renderers are ignored.
 *
 * Consumers discriminate this union at runtime by an object with a `teardown` function vs. a thenable
 * (an async renderer, awaited/adopted before re-checking) vs. anything else (no teardown). The
 * `void` arm is therefore treated as "no teardown," same as `undefined`.
 */
// `void` (not `undefined`) is required for the opt-out case: a renderer that returns nothing has
// type `(...) => void`, and that stays assignable to `RendererFunction` only while `void` is part of
// this union. Switching to `undefined` breaks backward compatibility for every existing
// nothing-returning renderer. The no-invalid-void-type rule is disabled because this `void` is a
// deliberate "may return nothing" marker in a return-position union, exactly the case it over-flags.
// eslint-disable-next-line @typescript-eslint/no-invalid-void-type -- renderer functions may return nothing
type RendererResult = void | RendererTeardownResult | Promise<void | RendererTeardownResult>;

// Renderer functions historically ignored any non-teardown return value. Keeping the legacy
// RenderFunctionResult arm preserves existing 3-argument renderers that returned a component/server
// result only to satisfy the old RenderFunction type; runtime cleanup still only recognizes the
// explicit `{ teardown }` wrapper.
type RendererFunctionResult = RendererResult | RenderFunctionResult;

interface RenderFunctionMarker {
  // We allow specifying that the function is RenderFunction and not a React Function Component
  // by setting this property
  renderFunction?: true;
}

/**
 * The precise call signature of the 3-argument "renderer" form `(props, railsContext, domNodeId) =>
 * …`. A renderer owns its own mount and may return nothing or a {@link RendererTeardownResult}
 * (possibly async) to opt into cleanup. It also accepts the legacy {@link RenderFunctionResult}
 * return shapes because older 3-argument renderers sometimes returned a component only to satisfy
 * the old `RenderFunction` type; those non-teardown values are ignored at runtime. Shared by the
 * core and Pro client renderers so the two cannot drift.
 *
 * @returns New renderer code should return `void` or `{ teardown }`. The broader legacy return
 * shapes stay accepted only so existing 3-argument renderers remain type-compatible.
 */
interface RendererFunction extends RenderFunctionMarker {
  (props?: Record<string, unknown>, railsContext?: RailsContext, domNodeId?: string): RendererFunctionResult;
}

/**
 * A render function variant for APIs that require a React component result, such as
 * Pro server-component wrappers. Unlike {@link RenderFunction}, this does not allow
 * server-render hashes/HTML, and unlike {@link RendererFunction}, this does not allow
 * renderer teardown results.
 *
 * Runtime render-function detection still follows the regular React on Rails
 * convention: declare at least two parameters, or set `renderFunction = true`
 * on one-argument functions.
 */
interface ReactComponentRenderFunction<Props = any> extends RenderFunctionMarker {
  (props?: Props, railsContext?: RailsContext, domNodeId?: string): ReactComponentRenderFunctionResult;
}

type StreamableComponentResult = ReactElement | Promise<ReactElement | string>;

type AsyncPropsManager = {
  getProp: (propName: string) => Promise<unknown>;
  setProp: (propName: string, propValue: unknown) => void;
  endStream: () => void;
};

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
 *
 * @remarks
 * `RenderFunction` is exactly this 2-argument server/client render-function form. The 3-argument
 * "renderer" form `(props, railsContext, domNodeId)` owns its own DOM rendering/hydration and is a
 * distinct role: type those functions {@link RendererFunction} (they return nothing or an optional
 * `{ teardown }` wrapper for cleanup). For `RenderFunction`, this makes the illegal combination —
 * a server render-function "returning" a teardown — unrepresentable instead of merely discouraged.
 * (`RendererFunction` still accepts legacy {@link RenderFunctionResult} return shapes for backward
 * compatibility with old 3-argument renderers; those values are ignored at runtime.)
 *
 * The doc block above describes {@link RenderFunction}, the public alias for this interface. Prefer
 * `RenderFunction` in public-facing annotations; `ServerRenderFunction` is the concrete interface
 * behind it (exported mainly so call sites can narrow to the precise role after runtime guards).
 */
interface ServerRenderFunction extends RenderFunctionMarker {
  (props?: any, railsContext?: RailsContext): RenderFunctionResult;
}

/**
 * The public name for the 2-argument server/client render-function form
 * `(props, railsContext) => RenderFunctionResult`. Alias of {@link ServerRenderFunction}; prefer
 * `RenderFunction` in public-facing annotations. See {@link ServerRenderFunction} for the full
 * render-function vs. renderer role explanation.
 */
type RenderFunction = ServerRenderFunction;

type ReactComponentOrRenderFunction = ReactComponent | RenderFunction | RendererFunction;
// Plain-object modules registered via server_render_js: no render function and no React component.
type RegisteredComponentValue = ReactComponentOrRenderFunction | Record<string, unknown>;

type PipeableOrReadableStream = PipeableStream | NodeJS.ReadableStream;

export type {
  ReactComponentOrRenderFunction,
  RegisteredComponentValue,
  ReactComponent,
  ReactComponentRenderFunction,
  AuthenticityHeaders,
  RenderFunction,
  ServerRenderFunction,
  RendererTeardown,
  RendererTeardownResult,
  RendererFunction,
  RenderFunctionResult,
  RendererFunctionResult,
  Store,
  StoreGenerator,
  CreateReactOutputResult,
  ServerRenderResult,
  ServerRenderHashRenderedHtml,
  CreateReactOutputSyncResult,
  CreateReactOutputAsyncResult,
  RenderFunctionSyncResult,
  RenderFunctionAsyncResult,
  ReactComponentRenderFunctionResult,
  StreamableComponentResult,
  PipeableOrReadableStream,
};

/**
 * The generic defaults to the pre-object-registration component type so existing consumers that
 * read `registeredComponent.component` stay source-compatible. Use
 * `RegisteredComponent<RegisteredComponentValue>` when handling plain-object server_render_js
 * registrations.
 */
export interface RegisteredComponent<
  ComponentValue extends RegisteredComponentValue = ReactComponentOrRenderFunction,
> {
  name: string;
  component: ComponentValue;
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

export type GenerateRSCPayloadFunction = (
  componentName: string,
  props: unknown,
  railsContext: RailsContextWithServerComponentMetadata,
) => Promise<NodeJS.ReadableStream>;

interface Params {
  props?: Record<string, unknown>;
  railsContext?: RailsContext;
  domNodeId?: string;
  trace?: boolean;
  generateRSCPayload?: GenerateRSCPayloadFunction;
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
  componentObj: RegisteredComponent<RegisteredComponentValue>;
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
  clientProps?: Record<string, unknown>;
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

/** Extra context React on Rails adds when invoking registered root error callbacks. */
export interface RootErrorContext {
  /** Name of the registered component rendered into the affected React root, when known. */
  componentName?: string;
  /** DOM id of the element the affected React root was mounted in, when known. */
  domNodeId?: string;
}

/**
 * A root error callback registered through `ReactOnRails.setOptions({ rootErrorHandlers })`.
 * Receives React's original `(error, errorInfo)` arguments plus React on Rails context about the
 * affected root. `errorInfo` typically contains `componentStack` (see the `react-dom/client`
 * `createRoot`/`hydrateRoot` option docs for the exact per-callback shape).
 */
export type RootErrorHandler = (error: unknown, errorInfo: unknown, context: RootErrorContext) => void;

/**
 * User-registered React root error callbacks, applied to every React root that React on Rails
 * creates via `hydrateRoot`/`createRoot`. Register them before your components render (typically
 * in the same pack file where you call `ReactOnRails.register`); each root captures the callbacks
 * registered at the moment it is created. Partial updates merge per key: a later
 * `setOptions({ rootErrorHandlers })` call that sets only one callback keeps the others; pass an
 * explicit `undefined` for a key to clear just that callback. Passing `null` is invalid and
 * throws at runtime; use `undefined` to deregister.
 */
export interface RootErrorHandlers {
  /**
   * Called when React automatically recovers from an error, e.g. a hydration mismatch.
   * Requires React 18+.
   */
  onRecoverableError?: RootErrorHandler;
  /** Called for errors caught by an error boundary. Requires React 19+. */
  onCaughtError?: RootErrorHandler;
  /** Called for errors not caught by any error boundary. Requires React 19+. */
  onUncaughtError?: RootErrorHandler;
}

export interface ReactOnRailsOptions {
  /** Gives you debugging messages on Turbolinks events. */
  traceTurbolinks?: boolean;
  /** Turbo (the successor of Turbolinks) events will be registered, if set to true. */
  turbo?: boolean;
  /** Enable debug mode for detailed logging of React on Rails operations. */
  debugMode?: boolean;
  /** Log component registration details including timing and size information. */
  logComponentRegistration?: boolean;
  /**
   * React root error callbacks (`onRecoverableError`, `onCaughtError`, `onUncaughtError`)
   * applied to every React root created by React on Rails.
   * @see {RootErrorHandlers}
   */
  rootErrorHandlers?: RootErrorHandlers;
}

export interface ReactOnRails {
  /**
   * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
   * find you components for rendering.
   * @param components keys are component names, values are components
   */
  register(components: Record<string, RegisteredComponentValue>): void;
  /** @deprecated Use registerStoreGenerators instead */
  registerStore(stores: Record<string, StoreGenerator>): void;
  /**
   * Allows registration of store generators for legacy or advanced pages where multiple React roots
   * on one Rails view share a Redux store. Store generators receive props and railsContext, then
   * return a store. Note that the `setStore` API is different in that it's the actual store hydrated
   * with props.
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

export type WithAsyncProps<
  AsyncPropsType extends Record<string, unknown>,
  PropsType extends Record<string, unknown>,
> = PropsType & {
  getReactOnRailsAsyncProp: <PropName extends keyof AsyncPropsType>(
    propName: PropName,
  ) => Promise<AsyncPropsType[PropName]>;
};

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
   * Clears registered store generators. Used by internal tests and setup code that must reset global
   * registration state between runs.
   */
  clearStoreGenerators(): void;
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
   * @remarks
   * **Cleanup is the caller's responsibility.** Unlike the components React on Rails mounts itself
   * (which are unmounted automatically on Turbo/Turbolinks navigation and same-id node replacement),
   * a root created by this imperative API is **not** tracked internally. The returned root is handed
   * back to you, and you must call `unmount()` on it yourself — e.g. on a Turbo `turbo:before-render`
   * / Turbolinks `turbolinks:before-render` event, or in your framework's teardown hook — to avoid
   * leaking the root (and any subscriptions or timers it holds) across navigations. If you want
   * automatic cleanup instead, register a renderer function (the 3-argument render-function form) and
   * return a {@link RendererTeardownResult}; React on Rails tracks those mounts and runs the teardown for
   * you.
   *
   * @param name Name of your registered component
   * @param props Props to pass to your component
   * @param domNodeId HTML ID of the node the component will be rendered at
   * @param [hydrate=false] Pass truthy to update server rendered HTML. Default is falsy
   * @returns {Root|ReactComponent|ReactElement} Under React 18+: the created React root
   *   (see "What is a root?" in https://github.com/reactwg/react-18/discussions/5).
   *   Under React 16/17: Reference to your component's backing instance or `null` for stateless components.
   */
  render(
    name: string,
    props: Record<string, unknown>,
    domNodeId: string,
    hydrate?: boolean,
  ): RenderReturnType;
  /**
   * Get the component that you registered
   * @returns {name, component, renderFunction, isRenderer}
   */
  getComponent(name: string): RegisteredComponent<RegisteredComponentValue>;
  /**
   * Get the component that you registered, or wait for it to be registered
   * @returns {name, component, renderFunction, isRenderer}
   */
  getOrWaitForComponent(name: string): Promise<RegisteredComponent<RegisteredComponentValue>>;
  /**
   * Used by server rendering by Rails
   */
  serverRenderReactComponent(options: RenderParams): null | string | Promise<string>;
  /**
   * Used by Rails to select progressive streaming only when the installed React DOM server supports it.
   */
  isServerStreamingSupported(): boolean;
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
   * Prepares a rendering result in the length-prefixed wire format for transport to Ruby.
   * Used by the server_render_js Rails helper to format arbitrary JS evaluation results.
   */
  prepareRenderResult(
    html: string,
    consoleReplayScript: string,
    hasErrors: boolean,
    renderingError: RenderingError | null,
  ): string;
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
  registeredComponents(): Map<string, RegisteredComponent<RegisteredComponentValue>>;
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
  /**
   * Adds the getAsyncProp function to the component props object.
   * Uses getOrCreateAsyncPropsManager internally to handle race conditions
   * between initial render and update chunks.
   *
   * @param props - The component props to enhance
   * @param sharedExecutionContext - Map scoped to the current HTTP request
   * @returns An object containing the component props with getReactOnRailsAsyncProp added
   */
  addAsyncPropsCapabilityToComponentProps: <
    AsyncPropsType extends Record<string, unknown>,
    PropsType extends Record<string, unknown>,
  >(
    props: PropsType,
    sharedExecutionContext: Map<string, unknown>,
  ) => {
    props: WithAsyncProps<AsyncPropsType, PropsType>;
  };
  /**
   * Gets or creates an AsyncPropsManager from the shared execution context.
   * Implements lazy initialization to handle race conditions between
   * the initial render request and update chunks.
   *
   * @param sharedExecutionContext - Map scoped to the current HTTP request
   * @returns The AsyncPropsManager instance (existing or newly created)
   */
  getOrCreateAsyncPropsManager: (sharedExecutionContext: Map<string, unknown>) => AsyncPropsManager;
}

export type RenderStateHtml = FinalHtmlResult | Promise<FinalHtmlResult | ServerRenderResult>;

export type RenderState = {
  result: null | RenderStateHtml;
  clientProps?: Record<string, unknown>;
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
