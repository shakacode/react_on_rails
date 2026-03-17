export declare function unlock(lockfileName: string): Promise<void>;
type LockResult = {
    lockfileName: string;
} & ({
    wasLockAcquired: true;
    errorMessage: null;
} | {
    wasLockAcquired: false;
    errorMessage: Error;
});
export declare function lock(filename: string): Promise<LockResult>;
export {};
//# sourceMappingURL=locks.d.ts.map