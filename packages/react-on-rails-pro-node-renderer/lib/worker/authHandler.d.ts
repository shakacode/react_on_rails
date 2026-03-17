/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Fastify server and its Request and Reply objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */
export interface AuthBody {
    password?: string;
}
export declare function authenticate(body: AuthBody): {
    headers: {
        'Cache-Control': string;
    };
    status: number;
    data: string;
} | undefined;
//# sourceMappingURL=authHandler.d.ts.map