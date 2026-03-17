/**
 * Entry point for worker process that handles requests.
 * @module worker
 */
import { Config } from './shared/configBuilder.js';
import type { FastifyInstance } from './worker/types.js';
import { Asset } from './shared/utils.js';
declare module '@fastify/multipart' {
    interface MultipartFile {
        value: Asset;
    }
}
declare module 'fastify' {
    interface FastifyRequest {
        uploadDir: string;
    }
}
export type FastifyConfigFunction = (app: FastifyInstance) => void;
/**
 * Configures Fastify instance before starting the server.
 * @param configFunction The configuring function. Normally it will be something like `(app) => { app.register(...); }`
 *  or `(app) => { app.addHook(...); }` to report data from Fastify to an external service.
 *  Note that we call `await app.ready()` in our code, so you don't need to `await` the results.
 */
export declare function configureFastify(configFunction: FastifyConfigFunction): void;
export declare const disableHttp2: () => void;
export default function run(config: Partial<Config>): import("fastify").FastifyInstance<import("http2").Http2Server<typeof import("http").IncomingMessage, typeof import("http").ServerResponse, typeof import("http2").Http2ServerRequest, typeof import("http2").Http2ServerResponse>, import("http2").Http2ServerRequest, import("http2").Http2ServerResponse<import("http2").Http2ServerRequest>, import("fastify").FastifyBaseLogger, import("fastify").FastifyTypeProviderDefault> & PromiseLike<import("fastify").FastifyInstance<import("http2").Http2Server<typeof import("http").IncomingMessage, typeof import("http").ServerResponse, typeof import("http2").Http2ServerRequest, typeof import("http2").Http2ServerResponse>, import("http2").Http2ServerRequest, import("http2").Http2ServerResponse<import("http2").Http2ServerRequest>, import("fastify").FastifyBaseLogger, import("fastify").FastifyTypeProviderDefault>> & {
    __linterBrands: "SafePromiseLike";
};
//# sourceMappingURL=worker.d.ts.map