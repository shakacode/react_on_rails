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

/**
 * Controller for a single async prop promise.
 * Holds the promise and its resolve/reject functions so they can be called
 * when the prop value arrives from Rails via an update chunk.
 */
type PromiseController = {
  promise: Promise<unknown>;
  resolve: (propValue: unknown) => void;
  reject: (reason: unknown) => void;
  resolved: boolean;
};

/**
 * Manages async props for incremental server-side rendering.
 *
 * DESIGN PRINCIPLES:
 *
 * 1. PROMISE CACHING: Same promise is returned for multiple getProp() calls.
 *    This is CRITICAL for React's rendering model - if we returned new promises,
 *    React would create infinite render loops or flicker as each render would
 *    get a different promise object.
 *
 * 2. ORDER INDEPENDENCE: Props can be set before or after they're requested.
 *    - If getProp() is called first: Creates promise, suspends, later setProp() resolves it
 *    - If setProp() is called first: Creates resolved promise, getProp() returns immediately
 *
 * 3. STREAM LIFECYCLE: endStream() rejects all unresolved props.
 *    This handles the case where the HTTP request closes before all props arrive,
 *    allowing React to show error boundaries instead of hanging forever.
 *
 * USAGE FLOW:
 * 1. ServerRenderingJsCode calls addAsyncPropsCapabilityToComponentProps()
 * 2. Component calls getReactOnRailsAsyncProp("propName") → getProp() returns promise
 * 3. React suspends on the promise
 * 4. Rails sends update chunk → setProp("propName", value) → promise resolves
 * 5. React resumes rendering with the value
 *
 * @example
 * // Inside a React Server Component
 * async function MyComponent({ getReactOnRailsAsyncProp }) {
 *   const users = await getReactOnRailsAsyncProp('users');
 *   return <UserList users={users} />;
 * }
 */
class AsyncPropsManager {
  private isClosed: boolean = false;

  private propNameToPromiseController = new Map<string, PromiseController>();

  /**
   * Gets the promise for an async prop. Returns the SAME promise on repeated calls.
   *
   * IMPORTANT: This is not an async function intentionally.
   * Returning the same Promise object on every call is required for React's
   * concurrent rendering - new promises would cause re-renders.
   */
  getProp(propName: string) {
    const promiseController = this.getOrCreatePromiseController(propName);
    if (!promiseController) {
      return Promise.reject(AsyncPropsManager.getNoPropFoundError(propName));
    }

    return promiseController.promise;
  }

  setProp(propName: string, propValue: unknown) {
    const promiseController = this.getOrCreatePromiseController(propName);
    if (!promiseController) {
      throw new Error(`Can't set the async prop "${propName}" because the stream is already closed`);
    }

    promiseController.resolve(propValue);
    promiseController.resolved = true;
  }

  endStream() {
    if (this.isClosed) {
      return;
    }

    this.isClosed = true;
    this.propNameToPromiseController.forEach((promiseController, propName) => {
      if (!promiseController.resolved) {
        promiseController.reject(AsyncPropsManager.getNoPropFoundError(propName));
      }
    });
  }

  private getOrCreatePromiseController(propName: string) {
    const promiseController = this.propNameToPromiseController.get(propName);
    if (promiseController) {
      return promiseController;
    }

    if (this.isClosed) {
      return undefined;
    }

    const partialPromiseController = {
      resolved: false,
    };

    let resolvePromise: PromiseController['resolve'] = () => {};
    let rejectPromise: PromiseController['reject'] = () => {};
    const promise = new Promise((resolve, reject) => {
      resolvePromise = resolve;
      rejectPromise = reject;
    });

    const newPromiseController = Object.assign(partialPromiseController, {
      promise,
      resolve: resolvePromise,
      reject: rejectPromise,
    });
    this.propNameToPromiseController.set(propName, newPromiseController);
    return newPromiseController;
  }

  private static getNoPropFoundError(propName: string) {
    return new Error(
      `The async prop "${propName}" is not received. Ensure to send the async prop from ruby side`,
    );
  }
}

export default AsyncPropsManager;
