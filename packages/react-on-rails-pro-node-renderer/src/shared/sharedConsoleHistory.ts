import { AsyncLocalStorage } from 'async_hooks';
import { getConfig } from './configBuilder.js';
import log from './log.js';
import { isPromise, isReadableStream } from './utils.js';
import type { RenderCodeResult } from '../worker/vm.js';

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
    result: RenderCodeResult,
    customConsoleHistory?: ConsoleMessage[],
  ): RenderCodeResult {
    const replayLogs = (value: string) => {
      const consoleHistory = customConsoleHistory ?? this.syncHistory;
      replayConsoleOnRenderer(consoleHistory);
      return value;
    };

    // TODO: replay console logs for readable streams
    if (isReadableStream(result)) {
      return result;
    }
    if (isPromise(result)) {
      return result.then(replayLogs);
    }
    return replayLogs(result);
  }

  trackConsoleHistoryInRenderRequest(renderRequestFunction: () => RenderCodeResult): RenderCodeResult {
    this.isRunningSyncOperation = true;
    let result: RenderCodeResult;

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
