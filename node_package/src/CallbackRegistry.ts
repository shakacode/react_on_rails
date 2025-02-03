import { ItemRegistrationCallback } from "./types";
import { onPageLoaded, onPageUnloaded } from "./pageLifecycle";
import { getContextAndRailsContext } from "./context";

export default class CallbackRegistry<T> {
  private readonly registryType: string;
  private registeredItems = new Map<string, T>();
  private callbacks = new Map<string, Array<{
    resolve: ItemRegistrationCallback<T>;
    reject: (error: Error) => void;
  }>>();

  private timoutEventsInitialized = false;
  private timedout = false;

  constructor(registryType: string) {
    this.registryType = registryType;
    this.initializeTimeoutEvents();
  }

  private initializeTimeoutEvents() {
    if (!this.timoutEventsInitialized) {
      this.timoutEventsInitialized = true;
    }

    let timeoutId: NodeJS.Timeout;
    const triggerTimeout = () => {
      this.timedout = true;
      this.callbacks.forEach((itemCallbacks, itemName) => {
        itemCallbacks.forEach((callback) => {
          callback.reject(this.createNotFoundError(itemName));
        });
      });
    };

    onPageLoaded(() => {
      const registryTimeout = getContextAndRailsContext().railsContext?.componentRegistryTimeout;
      if (!registryTimeout) return;

      timeoutId = setTimeout(triggerTimeout, registryTimeout);
    });

    onPageUnloaded(() => {
      this.callbacks.clear();
      this.timedout = false;
      clearTimeout(timeoutId);
    });
  }

  set(name: string, item: T): void {
    this.registeredItems.set(name, item);
    
    const callbacks = this.callbacks.get(name) || [];
    callbacks.forEach(callback => callback.resolve(item));
    this.callbacks.delete(name);
  }

  get(name: string): T {
    const item = this.registeredItems.get(name);
    if (item !== undefined) return item;

    throw this.createNotFoundError(name);
  }

  has(name: string): boolean {
    return this.registeredItems.has(name);
  }

  clear(): void {
    this.registeredItems.clear();
  }

  getAll(): Map<string, T> {
    return this.registeredItems;
  }

  getOrWaitForItem(name: string): Promise<T> {
    return new Promise((resolve, reject) => {
      try {
        resolve(this.get(name));
      } catch(error) {
        if (this.timedout) {
          throw error;
        }

        const itemCallbacks = this.callbacks.get(name) || [];
        itemCallbacks.push({ resolve, reject });
        this.callbacks.set(name, itemCallbacks);
      }
    });
  }

  private createNotFoundError(itemName: string): Error {
    const keys = Array.from(this.registeredItems.keys()).join(', ');
    return new Error(
      `Could not find ${this.registryType} registered with name ${itemName}. ` +
      `Registered ${this.registryType} names include [ ${keys} ]. ` +
      `Maybe you forgot to register the ${this.registryType}?`
    );
  }
}
