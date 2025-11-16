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
import type { RailsContext, RegisteredComponent, RenderFunction, Root } from 'react-on-rails/types';

import { getRailsContext, resetRailsContext } from 'react-on-rails/context';
import createReactOutput from 'react-on-rails/createReactOutput';
import { isServerRenderHash } from 'react-on-rails/isServerRenderResult';
import { supportsHydrate, supportsRootApi, unmountComponentAtNode } from 'react-on-rails/reactApis';
import reactHydrateOrRender from 'react-on-rails/reactHydrateOrRender';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import { onPageLoaded } from 'react-on-rails/pageLifecycle';
import * as StoreRegistry from './StoreRegistry.ts';
import * as ComponentRegistry from './ComponentRegistry.ts';

const REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';
const IMMEDIATE_HYDRATION_PRO_WARNING =
  "[REACT ON RAILS] The 'immediate_hydration' feature requires a React on Rails Pro license. " +
  'Please visit https://shakacode.com/react-on-rails-pro to get a license.';

async function delegateToRenderer(
  componentObj: RegisteredComponent,
  props: Record<string, unknown>,
  railsContext: RailsContext,
  domNodeId: string,
  trace: boolean,
): Promise<boolean> {
  const { name, component, isRenderer } = componentObj;

  if (isRenderer) {
    if (trace) {
      console.log(
        `DELEGATING TO RENDERER ${name} for dom node with id: ${domNodeId} with props, railsContext:`,
        props,
        railsContext,
      );
    }

    await (component as RenderFunction)(props, railsContext, domNodeId);
    return true;
  }

  return false;
}

const getDomId = (domIdOrElement: string | Element): string =>
  typeof domIdOrElement === 'string' ? domIdOrElement : domIdOrElement.getAttribute('data-dom-id') || '';
class ComponentRenderer {
  private domNodeId: string;

  private state: 'unmounted' | 'rendering' | 'rendered';

  private root?: Root;

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

  /**
   * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
   * delegates to a renderer registered by the user.
   */
  private async render(el: Element, railsContext: RailsContext): Promise<void> {
    const isImmediateHydrationRequested = el.getAttribute('data-immediate-hydration') === 'true';
    const hasProLicense = railsContext.rorPro;

    // Handle immediate_hydration feature usage without Pro license
    if (isImmediateHydrationRequested && !hasProLicense) {
      console.warn(IMMEDIATE_HYDRATION_PRO_WARNING);

      // Fallback to standard behavior: wait for page load before hydrating
      if (document.readyState === 'loading') {
        await new Promise<void>((resolve) => {
          onPageLoaded(resolve);
        });
      }
    }

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

        if (
          (await delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) ||
          // @ts-expect-error The state can change while awaiting delegateToRenderer
          this.state === 'unmounted'
        ) {
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
          const rootOrElement = reactHydrateOrRender(
            domNode,
            reactElementOrRouterResult as ReactElement,
            shouldHydrate,
          );
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
        console.info(
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
    root = new ComponentRenderer(domIdOrElement);
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

export const renderOrHydrateImmediateHydratedComponents = () =>
  forAllElementsAsync(
    '.js-react-on-rails-component[data-immediate-hydration="true"]',
    renderOrHydrateComponent,
  );

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

    storeRenderer = new StoreRenderer(storeDataElement);
    storeRenderers.set(storeName, storeRenderer);
  }
  await storeRenderer.waitUntilHydrated();
}

export const hydrateImmediateHydratedStores = () =>
  forAllElementsAsync(`[${REACT_ON_RAILS_STORE_ATTRIBUTE}][data-immediate-hydration="true"]`, hydrateStore);

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
