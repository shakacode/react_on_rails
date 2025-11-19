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

type PromiseController = {
  promise: Promise<unknown>;
  resolve: (propValue: unknown) => void;
  reject: (reason: unknown) => void;
  resolved: boolean;
};

class AsyncPropsManager {
  private isClosed: boolean = false;

  private propNameToPromiseController = new Map<string, PromiseController>();

  // The function is not converted to an async function to ensure that:
  // The function returns the same promise on successful scenario, so it can be used inside async react component
  // Or with the `use` hook without causing an infinite loop or flicks during rendering
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
      `The async prop "${propName}" is not received. Esnure to send the async prop from ruby side`,
    );
  }
}

export default AsyncPropsManager;
