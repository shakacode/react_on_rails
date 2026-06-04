/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

/* eslint-disable max-classes-per-file */

import type { ReactElement } from 'react';
import type {
  RailsContext,
  RegisteredComponent,
  RendererResult,
  RendererTeardown,
  Root,
} from 'react-on-rails/types';

import { getRailsContext, resetRailsContext } from 'react-on-rails/context';
import createReactOutput from 'react-on-rails/createReactOutput';
import { isServerRenderHash } from 'react-on-rails/isServerRenderResult';
import { supportsHydrate, supportsRootApi, unmountComponentAtNode } from 'react-on-rails/reactApis';
import reactHydrateOrRender from 'react-on-rails/reactHydrateOrRender';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import { maybeWrapWithDefaultRSCProviderWithStatus } from './defaultRSCProviderRegistry.ts';
import handleRecoverableError from './handleRecoverableError.client.ts';

import * as StoreRegistry from './StoreRegistry.ts';
import * as ComponentRegistry from './ComponentRegistry.ts';

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';

/**
 * Invokes a renderer teardown, swallowing async rejections so a failing teardown cannot produce an
 * unhandled promise rejection. Synchronous throws propagate to the caller's try/catch.
 *
 * Intentionally duplicated from the OSS `react-on-rails` ClientRenderer rather than imported: it is a
 * tiny self-contained helper that the OSS module does not export, so duplicating keeps the Pro client
 * renderer decoupled from OSS internals (no reliance on a non-public export) instead of widening the
 * OSS public API just to share it.
 */
function invokeRendererTeardown(teardown: RendererTeardown | undefined, domNodeId: string): void {
  if (!teardown) return;
  const maybePromise = teardown();
  if (maybePromise && typeof maybePromise.then === 'function') {
    // Detect a thenable with `.then` (Promises/A+) but swallow the rejection via
    // `Promise.resolve(...).catch(...)`: a non-native thenable may lack `.catch`, so calling it
    // directly could itself throw or leave the rejection unhandled. This keeps a failing async
    // teardown from surfacing as an unhandled promise rejection.
    Promise.resolve(maybePromise).catch((error: unknown) => {
      console.error(`Error in renderer teardown for dom node "${domNodeId}":`, error);
    });
  }
}

// The 3-argument renderer call signature. A renderer owns its own mount and returns a RendererResult
// (nothing, a teardown, or a promise resolving to one). Casting the registered component to this
// precise type — rather than the public `RenderFunction`, which unifies the renderer and server
// render-function shapes by arity — narrows the awaited result to `void | RendererTeardown` without
// a value-level cast.
type RendererFunction = (
  props?: Record<string, unknown>,
  railsContext?: RailsContext,
  domNodeId?: string,
) => RendererResult;

type DelegationResult = { delegated: false } | { delegated: true; teardown?: RendererTeardown };

async function delegateToRenderer(
  componentObj: RegisteredComponent,
  props: Record<string, unknown>,
  railsContext: RailsContext,
  domNodeId: string,
  trace: boolean,
): Promise<DelegationResult> {
  const { name, component, isRenderer } = componentObj;

  if (isRenderer) {
    if (trace) {
      console.log(
        `DELEGATING TO RENDERER ${name} for dom node with id: ${domNodeId} with props, railsContext:`,
        props,
        railsContext,
      );
    }

    // The renderer owns its own mount and may return a teardown callback so we can clean it up on
    // unmount (Turbo/Turbolinks navigation). `result` is `void | RendererTeardown`, so a `function`
    // check narrows to the teardown with no cast.
    const result = await (component as RendererFunction)(props, railsContext, domNodeId);
    return {
      delegated: true,
      teardown: typeof result === 'function' ? result : undefined,
    };
  }

  return { delegated: false };
}

const getDomId = (domIdOrElement: string | Element): string =>
  typeof domIdOrElement === 'string' ? domIdOrElement : domIdOrElement.getAttribute('data-dom-id') || '';

const getSsrIdentifierPrefix = (el: Element): string | undefined =>
  el.getAttribute('data-ssr-identifier-prefix') || undefined;

class ComponentRenderer {
  private domNodeId: string;

  private ssrIdentifierPrefix?: string;

  private state: 'unmounted' | 'rendering' | 'rendered';

  private root?: Root;

  // Set when this mount was delegated to a renderer function that returned a teardown callback.
  private rendererTeardown?: RendererTeardown;

  private renderPromise?: Promise<void>;

  constructor(domIdOrElement: string | Element) {
    const domId = getDomId(domIdOrElement);
    this.domNodeId = domId;
    this.state = 'rendering';
    const el =
      typeof domIdOrElement === 'string'
        ? document.querySelector(`[data-dom-id="${CSS.escape(domId)}"]`)
        : domIdOrElement;
    if (!el) return;

    this.ssrIdentifierPrefix = getSsrIdentifierPrefix(el);

    const storeDependencies = el.getAttribute('data-store-dependencies');
    const storeDependenciesArray = storeDependencies ? (JSON.parse(storeDependencies) as string[]) : [];

    const railsContext = getRailsContext();
    if (!railsContext) return;

    // Wait for all store dependencies to be loaded
    this.renderPromise = Promise.all(
      storeDependenciesArray.map((storeName) => StoreRegistry.getOrWaitForStore(storeName)),
    ).then(() => {
      if (this.state === 'unmounted') return Promise.resolve();
      return this.render(el, railsContext);
    });
  }

  hasStartedRendering(): boolean {
    return this.renderPromise !== undefined;
  }

  /**
   * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
   * delegates to a renderer registered by the user.
   */
  private async render(el: Element, railsContext: RailsContext): Promise<void> {
    // This must match lib/react_on_rails/helper.rb
    const name = el.getAttribute('data-component-name') || '';
    const { domNodeId } = this;
    const props = el.textContent !== null ? (JSON.parse(el.textContent) as Record<string, unknown>) : {};
    const trace = el.getAttribute('data-trace') === 'true';

    try {
      const domNode = document.getElementById(domNodeId);
      if (domNode) {
        const componentObj = await ComponentRegistry.getOrWaitForComponent(name);
        if (this.state === 'unmounted') {
          return;
        }

        const delegation = await delegateToRenderer(componentObj, props, railsContext, domNodeId, trace);
        if (delegation.delegated) {
          // @ts-expect-error The state can change while awaiting delegateToRenderer
          if (this.state === 'unmounted') {
            // unmount() ran while the renderer was resolving and could not see the teardown yet, so
            // run it now to avoid leaking the renderer's mount. Guard it like unmount() does (below)
            // so a synchronously-throwing teardown is logged here rather than escaping to render()'s
            // outer catch, which would rethrow it as a misleading "encountered an error while
            // rendering" rejection even though the component is already unmounted.
            try {
              invokeRendererTeardown(delegation.teardown, domNodeId);
            } catch (teardownError: unknown) {
              const error = teardownError instanceof Error ? teardownError : new Error('Unknown error');
              console.error(`Error in renderer teardown for dom node "${domNodeId}":`, error);
            }
          } else {
            this.rendererTeardown = delegation.teardown;
            this.state = 'rendered';
          }
          return;
        }
        // @ts-expect-error The state can change while awaiting delegateToRenderer
        if (this.state === 'unmounted') {
          return;
        }

        // Hydrate if available and was server rendered
        const shouldHydrate = supportsHydrate && !!domNode.innerHTML;

        const reactElementOrRouterResult = createReactOutput({
          componentObj,
          props,
          domNodeId,
          trace,
          railsContext,
          shouldHydrate,
        });

        if (isServerRenderHash(reactElementOrRouterResult)) {
          throw new Error(`\
You returned a server side type of react-router error: ${JSON.stringify(reactElementOrRouterResult)}
You should return a React.Component always for the client side entry point.`);
        } else {
          const { reactElement, wrappedByDefaultRSCProvider } = maybeWrapWithDefaultRSCProviderWithStatus(
            reactElementOrRouterResult as ReactElement,
            railsContext,
            domNodeId,
          );
          let renderOptions: Parameters<typeof reactHydrateOrRender>[3];
          if (wrappedByDefaultRSCProvider) {
            renderOptions = shouldHydrate
              ? {
                  ...(this.ssrIdentifierPrefix ? { identifierPrefix: this.ssrIdentifierPrefix } : {}),
                  onRecoverableError: handleRecoverableError,
                }
              : { identifierPrefix: domNodeId };
          }
          const rootOrElement = reactHydrateOrRender(domNode, reactElement, shouldHydrate, renderOptions);
          this.state = 'rendered';
          if (supportsRootApi) {
            this.root = rootOrElement as Root;
          }
        }
      }
    } catch (e: unknown) {
      const error = e instanceof Error ? e : new Error(e?.toString() ?? 'Unknown error');
      console.error(error.message);
      error.message = `ReactOnRails encountered an error while rendering component: ${name}. See above error message.`;
      throw error;
    }
  }

  unmount(): void {
    if (this.state === 'rendering') {
      this.state = 'unmounted';
      return;
    }
    this.state = 'unmounted';

    if (this.rendererTeardown) {
      // This mount was owned by a renderer function; run its teardown instead of unmounting a
      // React root we never created.
      const { rendererTeardown } = this;
      this.rendererTeardown = undefined;
      try {
        invokeRendererTeardown(rendererTeardown, this.domNodeId);
      } catch (e: unknown) {
        const error = e instanceof Error ? e : new Error('Unknown error');
        console.error(`Error in renderer teardown for dom node "${this.domNodeId}":`, error);
      }
      return;
    }

    if (supportsRootApi) {
      this.root?.unmount();
      this.root = undefined;
    } else {
      const domNode = document.getElementById(this.domNodeId);
      if (!domNode) {
        return;
      }

      try {
        unmountComponentAtNode(domNode);
      } catch (e: unknown) {
        const error = e instanceof Error ? e : new Error('Unknown error');
        // A thrown error here means the component tree did not unmount cleanly — that is a
        // teardown failure, not informational chatter, and most log collectors / default
        // browser-console filters drop `info`. Use `console.error` to match the other caught
        // errors in this file.
        console.error(
          `Caught error calling unmountComponentAtNode: ${error.message} for domNode`,
          domNode,
          error,
        );
      }
    }
  }

  waitUntilRendered(): Promise<void> {
    if (this.state === 'rendering' && this.renderPromise) {
      return this.renderPromise;
    }
    return Promise.resolve();
  }
}

class StoreRenderer {
  private hydratePromise?: Promise<void>;

  private state: 'unmounted' | 'hydrating' | 'hydrated';

  constructor(storeDataElement: Element) {
    this.state = 'hydrating';
    const railsContext = getRailsContext();
    if (!railsContext) {
      return;
    }

    const name = storeDataElement.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
    const props =
      storeDataElement.textContent !== null
        ? (JSON.parse(storeDataElement.textContent) as Record<string, unknown>)
        : {};
    this.hydratePromise = this.hydrate(railsContext, name, props);
  }

  private async hydrate(railsContext: RailsContext, name: string, props: Record<string, unknown>) {
    const storeGenerator = await StoreRegistry.getOrWaitForStoreGenerator(name);
    if (this.state === 'unmounted') {
      return;
    }

    const store = storeGenerator(props, railsContext);
    StoreRegistry.setStore(name, store);
    this.state = 'hydrated';
  }

  hasStartedHydrating(): boolean {
    return this.hydratePromise !== undefined;
  }

  waitUntilHydrated(): Promise<void> {
    if (this.state === 'hydrating' && this.hydratePromise) {
      return this.hydratePromise;
    }
    return Promise.resolve();
  }

  unmount(): void {
    this.state = 'unmounted';
  }
}

const renderedRoots = new Map<string, ComponentRenderer>();

export function renderOrHydrateComponent(domIdOrElement: string | Element) {
  const domId = getDomId(domIdOrElement);
  debugTurbolinks('renderOrHydrateComponent', domId);
  let root = renderedRoots.get(domId);
  if (!root) {
    const newRoot = new ComponentRenderer(domIdOrElement);
    if (!newRoot.hasStartedRendering()) {
      return Promise.resolve();
    }
    root = newRoot;
    renderedRoots.set(domId, root);
  }
  return root.waitUntilRendered();
}

async function forAllElementsAsync(
  selector: string,
  callback: (el: Element) => Promise<void>,
): Promise<void> {
  const els = document.querySelectorAll(selector);
  await Promise.all(Array.from(els).map(callback));
}

/**
 * Filters elements to only include those with a nextSibling.
 *
 * This is used to prevent a race condition during HTML streaming where
 * the props script element exists in the DOM but its content is incomplete.
 *
 * Why checking for ANY nextSibling works:
 * - During HTML streaming, the browser parses incrementally
 * - A script element's content is everything between <script> and </script>
 * - The browser cannot parse ANY content after a script until </script> is found
 * - Therefore, if nextSibling exists (even whitespace or comments), the closing
 *   tag was parsed and the content is guaranteed to be complete
 *
 * Elements without a nextSibling will be hydrated via inline scripts as streaming completes (Pro),
 * or on DOMContentLoaded (non-Pro).
 *
 * See: https://github.com/shakacode/react_on_rails/issues/2283
 */
async function forAllCompleteElementsAsync(
  selector: string,
  callback: (el: Element) => Promise<void>,
): Promise<void> {
  const els = document.querySelectorAll(selector);
  const completeEls = Array.from(els).filter((el) => el.nextSibling !== null);
  await Promise.all(completeEls.map(callback));
}

// For Pro streaming pages: hydrate all components whose markup has been fully streamed
// (identified by having a nextSibling). On non-streaming pages this matches ALL components,
// but ClientSideRenderer memoizes by DOM node id so the later DOMContentLoaded sweep is a no-op.
export const renderOrHydrateCompleteComponents = () =>
  forAllCompleteElementsAsync('.js-react-on-rails-component', renderOrHydrateComponent);

export const renderOrHydrateAllComponents = () =>
  forAllElementsAsync('.js-react-on-rails-component', renderOrHydrateComponent);

function unmountAllComponents(): void {
  renderedRoots.forEach((root) => root.unmount());
  renderedRoots.clear();
  resetRailsContext();
}

const storeRenderers = new Map<string, StoreRenderer>();

export async function hydrateStore(storeNameOrElement: string | Element) {
  const storeName =
    typeof storeNameOrElement === 'string'
      ? storeNameOrElement
      : storeNameOrElement.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
  let storeRenderer = storeRenderers.get(storeName);
  if (!storeRenderer) {
    const storeDataElement =
      typeof storeNameOrElement === 'string'
        ? document.querySelector(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}="${CSS.escape(storeNameOrElement)}"]`)
        : storeNameOrElement;
    if (!storeDataElement) {
      return;
    }

    const newStoreRenderer = new StoreRenderer(storeDataElement);
    if (!newStoreRenderer.hasStartedHydrating()) {
      return;
    }
    storeRenderer = newStoreRenderer;
    storeRenderers.set(storeName, storeRenderer);
  }
  await storeRenderer.waitUntilHydrated();
}

export const hydrateCompleteStores = () =>
  forAllCompleteElementsAsync(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`, hydrateStore);

export const hydrateAllStores = () =>
  forAllElementsAsync(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}]`, hydrateStore);

function unmountAllStores(): void {
  storeRenderers.forEach((storeRenderer) => storeRenderer.unmount());
  storeRenderers.clear();
}

export function unmountAll(): void {
  unmountAllComponents();
  unmountAllStores();
}
