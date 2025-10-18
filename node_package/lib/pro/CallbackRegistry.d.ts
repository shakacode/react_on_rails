export default class CallbackRegistry<T> {
  private readonly registryType;

  private registeredItems;

  private waitingPromises;

  private notUsedItems;

  private timeoutEventsInitialized;

  private timedout;

  constructor(registryType: string);

  private initializeTimeoutEvents;

  set(name: string, item: T): void;

  get(name: string): T;

  has(name: string): boolean;

  clear(): void;

  getAll(): Map<string, T>;

  getOrWaitForItem(name: string): Promise<T>;

  private createNotFoundError;
}
