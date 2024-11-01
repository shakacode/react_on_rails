import { AsyncLocalStorage } from 'async_hooks';
import { getConfig } from './configBuilder';
import log from './log';
import { isPromise } from './utils';

type ConsoleMessage = { level: 'error' | 'log' | 'info' | 'warn'; arguments: unknown[] };

function replayConsoleOnRenderer(consoleHistory: ConsoleMessage[]) {
  if (log.level !== 'debug') return;

  consoleHistory.forEach((msg) => {
    const stringifiedList = msg.arguments.map((arg) => {
      let val;
      try {
        val = typeof arg === 'string' || arg instanceof String ? arg : JSON.stringify(arg);
      } catch (e) {
        val = `${(e as Error).message}: ${arg}`;
      }

      return val;
    });

    log.debug(stringifiedList.join(' '));
  });
}

// AsyncLocalStorage is available in Node.js 12.17.0 and later versions
const canUseAsyncLocalStorage = (): boolean =>
  typeof AsyncLocalStorage !== 'undefined' && getConfig().replayServerAsyncOperationLogs;

class SharedConsoleHistory {
  private asyncLocalStorageIfEnabled: AsyncLocalStorage<{ consoleHistory: ConsoleMessage[] }> | undefined;
  private isRunningSyncOperation: boolean;
  private syncHistory: ConsoleMessage[];

  constructor() {
    if (canUseAsyncLocalStorage()) {
      this.asyncLocalStorageIfEnabled = new AsyncLocalStorage();
    }
    this.isRunningSyncOperation = false;
    this.syncHistory = [];
  }

  getConsoleHistory(): ConsoleMessage[] {
    if (this.asyncLocalStorageIfEnabled) {
      return this.asyncLocalStorageIfEnabled.getStore()?.consoleHistory ?? [];
    }
    // If console history is not safely stored in AsyncLocalStorage,
    // then return it only in sync operations (to avoid data leakage)
    return this.isRunningSyncOperation ? this.syncHistory : [];
  }

  addToConsoleHistory(message: ConsoleMessage): void {
    if (this.asyncLocalStorageIfEnabled) {
      this.asyncLocalStorageIfEnabled.getStore()?.consoleHistory.push(message);
    } else {
      this.syncHistory.push(message);
    }
  }

  replayConsoleLogsAfterRender(
    result: string | Promise<string>,
    customConsoleHistory?: ConsoleMessage[],
  ): string | Promise<string> {
    const replayLogs = (value: string) => {
      const consoleHistory = customConsoleHistory ?? this.syncHistory;
      replayConsoleOnRenderer(consoleHistory);
      return value;
    };

    return isPromise(result) ? result.then(replayLogs) : replayLogs(result);
  }

  trackConsoleHistoryInRenderRequest(
    renderRequestFunction: () => string | Promise<string>,
  ): string | Promise<string> {
    this.isRunningSyncOperation = true;
    let result: string | Promise<string>;

    try {
      if (this.asyncLocalStorageIfEnabled) {
        const storage = { consoleHistory: [] };
        result = this.asyncLocalStorageIfEnabled.run(storage, renderRequestFunction);
        return this.replayConsoleLogsAfterRender(result, storage.consoleHistory);
      }
      this.syncHistory = [];
      result = renderRequestFunction();
      return this.replayConsoleLogsAfterRender(result);
    } finally {
      this.isRunningSyncOperation = false;
      this.syncHistory = [];
    }
  }
}

export default SharedConsoleHistory;
