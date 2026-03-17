/**
 * Request prechecks logic that is independent of the HTTP server framework.
 * @module worker/requestPrechecks
 */
import type { ResponseResult } from '../shared/utils';
import { type RequestBody } from './checkProtocolVersionHandler';
import { type AuthBody } from './authHandler';
export interface RequestPrechecksBody extends RequestBody, AuthBody {
    [key: string]: unknown;
}
export declare function performRequestPrechecks(body: RequestPrechecksBody): ResponseResult | undefined;
//# sourceMappingURL=requestPrechecks.d.ts.map