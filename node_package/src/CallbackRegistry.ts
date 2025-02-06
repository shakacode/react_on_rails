import { ItemRegistrationCallback } from "./types";
import { onPageLoaded, onPageUnloaded } from "./pageLifecycle";
import { getContextAndRailsContext } from "./context";

/**
 * Represents information about a registered item including its value,
 * promise details for pending registrations, and usage status
 */
type ItemInfo<T> = {
  item: T | null;
  waitingPromiseInfo?: {
    resolve: ItemRegistrationCallback<T>;
    reject: (error: Error) => void;
    promise: Promise<T>;
  },
  isUsed: boolean;
}

export default class CallbackRegistry<T> {
  private readonly registryType: string;
  private registeredItems = new Map<string, ItemInfo<T>>();

  private timeoutEventsInitialized = false;
  private timedout = false;

  constructor(registryType: string) {
    this.registryType = registryType;
  }

  private initializeTimeoutEvents() {
    if (!this.timeoutEventsInitialized) {
      this.timeoutEventsInitialized = true;
    }

    let timeoutId: NodeJS.Timeout;
    const triggerTimeout = () => {
      this.timedout = true;
      this.registeredItems.forEach((itemInfo, itemName) => {
        if (itemInfo.waitingPromiseInfo) {
          itemInfo.waitingPromiseInfo.reject(this.createNotFoundError(itemName));
          // eslint-disable-next-line no-param-reassign
          itemInfo.waitingPromiseInfo = undefined;
        } else if (!itemInfo.isUsed) {
          console.warn(`Warning: ${this.registryType} '${itemName}' was registered but never used. This may indicate unused code that can be removed.`);
        }
      });
    };

    onPageLoaded(() => {
      const registryTimeout = getContextAndRailsContext().railsContext?.componentRegistryTimeout;
      if (!registryTimeout) return;

      timeoutId = setTimeout(triggerTimeout, registryTimeout);
    });

    onPageUnloaded(() => {
      this.registeredItems.forEach((itemInfo) => {
        // eslint-disable-next-line no-param-reassign
        itemInfo.waitingPromiseInfo = undefined;
      });
      this.timedout = false;
      clearTimeout(timeoutId);
    });
  }

  set(name: string, item: T): void {
    const { waitingPromiseInfo } = this.registeredItems.get(name) ?? {};
    this.registeredItems.set(name, { item, isUsed: !!waitingPromiseInfo });

    if (waitingPromiseInfo) {
      waitingPromiseInfo.resolve(item);
    }
  }

  get(name: string): T {
    const itemInfo = this.registeredItems.get(name);
    if (!itemInfo?.item) {
      throw this.createNotFoundError(name);
    }
    itemInfo.isUsed = true;
    return itemInfo.item;
  }

  has(name: string): boolean {
    return !!this.registeredItems.get(name)?.item;
  }

  clear(): void {
    this.registeredItems.clear();
  }

  getAll(): Map<string, T> {
    const components = new Map<string, T>();
    this.registeredItems.forEach((itemInfo, name) => {
      if (!itemInfo.item) return;
      components.set(name, itemInfo.item);
    });
    return components;
  }

  getOrWaitForItem(name: string): Promise<T> {
    this.initializeTimeoutEvents();
    const existingInfo = this.registeredItems.get(name);
    
    // Return existing promise if there's already a waiting promise
    if (existingInfo?.waitingPromiseInfo) {
      return existingInfo.waitingPromiseInfo.promise;
    }

    let waitingPromiseInfo: ItemInfo<T>['waitingPromiseInfo'];
    const getItemPromise = new Promise<T>((resolve, reject) => {
      try {
        const item = this.get(name);
        resolve(item);
      } catch(error) {
        if (this.timedout) {
          reject(error);
          return;
        }

        this.registeredItems.set(name, {
          item: null,
          waitingPromiseInfo: waitingPromiseInfo = {
            resolve,
            reject,
            promise: getItemPromise,
          },
          isUsed: true,
        });
      }
    });
    if (waitingPromiseInfo) {
      waitingPromiseInfo.promise = getItemPromise;
    }

    return getItemPromise;
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
