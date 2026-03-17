import { CaptureContext, TransactionContext } from '@sentry/types';
declare module '../shared/tracing.js' {
    interface TracingContext {
        sentry6?: CaptureContext;
    }
    interface UnitOfWorkOptions {
        sentry6?: TransactionContext;
    }
}
export declare function init({ tracing }?: {
    tracing?: boolean | undefined;
}): void;
//# sourceMappingURL=sentry6.d.ts.map