/**
 * Request prechecks logic that is independent of the HTTP server framework.
 * @module worker/requestPrechecks
 */
import type { ResponseResult } from '../shared/utils';
import { checkProtocolVersion, type RequestBody } from './checkProtocolVersionHandler';
import { authenticate, type AuthBody } from './authHandler';

export interface RequestPrechecksBody extends RequestBody, AuthBody {
  [key: string]: unknown;
}

export function performRequestPrechecks(body: RequestPrechecksBody): ResponseResult | undefined {
  // Check protocol version
  const protocolVersionCheckingResult = checkProtocolVersion(body);
  if (typeof protocolVersionCheckingResult === 'object') {
    return protocolVersionCheckingResult;
  }

  // Authenticate Ruby client
  const authResult = authenticate(body);
  if (typeof authResult === 'object') {
    return authResult;
  }

  return undefined;
}
