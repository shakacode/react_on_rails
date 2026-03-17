import * as http2 from 'node:http2';
import { FastifyServerOptions } from 'fastify';
import { LevelWithSilent } from 'pino';
export interface Config {
    port: number;
    logLevel: LevelWithSilent;
    logHttpLevel: LevelWithSilent;
    fastifyServerOptions: FastifyServerOptions<http2.Http2Server>;
    serverBundleCachePath: string;
    bundlePath?: string;
    supportModules: boolean;
    additionalContext: Record<string, unknown> | null;
    workersCount: number;
    password: string | undefined;
    allWorkersRestartInterval: number | undefined;
    delayBetweenIndividualWorkerRestarts: number | undefined;
    gracefulWorkerRestartTimeout: number | undefined;
    maxDebugSnippetLength: number;
    honeybadgerApiKey?: string | null;
    sentryDsn?: string | null;
    sentryTracing?: boolean;
    sentryTracesSampleRate?: string | number;
    stubTimers: boolean;
    includeTimerPolyfills?: boolean;
    replayServerAsyncOperationLogs: boolean;
    maxVMPoolSize: number;
}
export declare function getConfig(): Config;
export declare function logSanitizedConfig(): void;
/**
 * Lazily create the config
 */
export declare function buildConfig(providedUserConfig?: Partial<Config>): Config;
//# sourceMappingURL=configBuilder.d.ts.map