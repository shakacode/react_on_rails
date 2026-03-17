import * as Sentry from '@sentry/node';
declare module '../shared/tracing.js' {
    interface UnitOfWorkOptions {
        sentry?: Parameters<typeof Sentry.startSpan>[0];
    }
}
export declare function init({ fastify, tracing }?: {
    fastify?: boolean | undefined;
    tracing?: boolean | undefined;
}): void;
//# sourceMappingURL=sentry.d.ts.map