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
import { onPageLoaded, onPageUnloaded } from '../pageLifecycle.js';
import { getRailsContext } from '../context.js';

export default class CallbackRegistry {
  constructor(registryType) {
    this.registeredItems = new Map();
    this.waitingPromises = new Map();
    this.notUsedItems = new Set();
    this.timeoutEventsInitialized = false;
    this.timedout = false;
    this.registryType = registryType;
  }

  initializeTimeoutEvents() {
    if (this.timeoutEventsInitialized) return;
    this.timeoutEventsInitialized = true;
    let timeoutId;
    const triggerTimeout = () => {
      this.timedout = true;
      this.waitingPromises.forEach((waitingPromiseInfo, itemName) => {
        waitingPromiseInfo.reject(this.createNotFoundError(itemName));
      });
      this.notUsedItems.forEach((itemName) => {
        console.warn(
          `Warning: ${this.registryType} '${itemName}' was registered but never used. This may indicate unused code that can be removed.`,
        );
      });
    };
    onPageLoaded(() => {
      const registryTimeout = getRailsContext()?.componentRegistryTimeout;
      if (!registryTimeout) return;
      timeoutId = setTimeout(triggerTimeout, registryTimeout);
    });
    onPageUnloaded(() => {
      this.waitingPromises.clear();
      this.timedout = false;
      clearTimeout(timeoutId);
    });
  }

  set(name, item) {
    this.registeredItems.set(name, item);
    if (this.timedout) return;
    const waitingPromiseInfo = this.waitingPromises.get(name);
    if (waitingPromiseInfo) {
      waitingPromiseInfo.resolve(item);
      this.waitingPromises.delete(name);
    } else {
      this.notUsedItems.add(name);
    }
  }

  get(name) {
    const item = this.registeredItems.get(name);
    if (!item) {
      throw this.createNotFoundError(name);
    }
    this.notUsedItems.delete(name);
    return item;
  }

  has(name) {
    return this.registeredItems.has(name);
  }

  clear() {
    this.registeredItems.clear();
    this.notUsedItems.clear();
  }

  getAll() {
    return new Map(this.registeredItems);
  }

  async getOrWaitForItem(name) {
    this.initializeTimeoutEvents();
    try {
      return this.get(name);
    } catch (error) {
      if (this.timedout) {
        throw error;
      }
      const existingWaitingPromiseInfo = this.waitingPromises.get(name);
      if (existingWaitingPromiseInfo) {
        return existingWaitingPromiseInfo.promise;
      }
      let promiseResolve = () => {};
      let promiseReject = () => {};
      const promise = new Promise((resolve, reject) => {
        promiseResolve = resolve;
        promiseReject = reject;
      });
      this.waitingPromises.set(name, { resolve: promiseResolve, reject: promiseReject, promise });
      return promise;
    }
  }

  createNotFoundError(itemName) {
    const keys = Array.from(this.registeredItems.keys()).join(', ');
    return new Error(
      `Could not find ${this.registryType} registered with name ${itemName}. ` +
        `Registered ${this.registryType} names include [ ${keys} ]. ` +
        `Maybe you forgot to register the ${this.registryType}?`,
    );
  }
}
