import type { RenderCodeResult } from '../worker/vm.js';
type ConsoleMessage = {
    level: 'error' | 'log' | 'info' | 'warn';
    arguments: unknown[];
};
declare class SharedConsoleHistory {
    private asyncLocalStorageIfEnabled;
    private isRunningSyncOperation;
    private syncHistory;
    constructor();
    getConsoleHistory(): ConsoleMessage[];
    addToConsoleHistory(message: ConsoleMessage): void;
    replayConsoleLogsAfterRender(result: RenderCodeResult, customConsoleHistory?: ConsoleMessage[]): RenderCodeResult;
    trackConsoleHistoryInRenderRequest(renderRequestFunction: () => RenderCodeResult): RenderCodeResult;
}
export default SharedConsoleHistory;
//# sourceMappingURL=sharedConsoleHistory.d.ts.map