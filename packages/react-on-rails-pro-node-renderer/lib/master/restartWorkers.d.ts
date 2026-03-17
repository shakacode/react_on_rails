/**
 * Perform all workers restart with provided delay
 * @module master/restartWorkers
 */
declare module 'cluster' {
    interface Worker {
        isScheduledRestart?: boolean;
    }
}
export default function restartWorkers(delayBetweenIndividualWorkerRestarts: number, gracefulWorkerRestartTimeout: number | undefined): Promise<void>;
//# sourceMappingURL=restartWorkers.d.ts.map