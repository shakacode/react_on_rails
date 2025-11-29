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

import { ItemRegistrationCallback } from 'react-on-rails/types';
import { onPageLoaded, onPageUnloaded } from 'react-on-rails/pageLifecycle';
import { getRailsContext } from './railsContext.ts';

/**
 * Represents information about a registered item including its value,
 * promise details for pending registrations, and usage status
 */
type WaitingPromiseInfo<T> = {
  resolve: ItemRegistrationCallback<T>;
  reject: (error: Error) => void;
  promise: Promise<T>;
};

export default class CallbackRegistry<T> {
  private readonly registryType: string;

  private registeredItems = new Map<string, T>();

  private waitingPromises = new Map<string, WaitingPromiseInfo<T>>();

  private notUsedItems = new Set<string>();

  private timeoutEventsInitialized = false;

  private timedout = false;

  constructor(registryType: string) {
    this.registryType = registryType;
  }

  private initializeTimeoutEvents() {
    if (this.timeoutEventsInitialized) return;
    this.timeoutEventsInitialized = true;

    let timeoutId: NodeJS.Timeout;
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

  set(name: string, item: T): void {
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

  get(name: string): T {
    const item = this.registeredItems.get(name);
    if (!item) {
      throw this.createNotFoundError(name);
    }
    this.notUsedItems.delete(name);
    return item;
  }

  has(name: string): boolean {
    return this.registeredItems.has(name);
  }

  clear(): void {
    this.registeredItems.clear();
    this.notUsedItems.clear();
  }

  getAll(): Map<string, T> {
    return new Map(this.registeredItems);
  }

  async getOrWaitForItem(name: string): Promise<T> {
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

      let promiseResolve: (value: T | PromiseLike<T>) => void = () => {};
      let promiseReject: (reason?: unknown) => void = () => {};
      const promise = new Promise<T>((resolve, reject) => {
        promiseResolve = resolve;
        promiseReject = reject;
      });
      this.waitingPromises.set(name, { resolve: promiseResolve, reject: promiseReject, promise });
      return promise;
    }
  }

  private createNotFoundError(itemName: string): Error {
    const keys = Array.from(this.registeredItems.keys()).join(', ');
    return new Error(
      `Could not find ${this.registryType} registered with name ${itemName}. ` +
        `Registered ${this.registryType} names include [ ${keys} ]. ` +
        `Maybe you forgot to register the ${this.registryType}?`,
    );
  }
}
