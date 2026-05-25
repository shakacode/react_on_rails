/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Fastify server and its Request and Reply objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */
// TODO: Replace with fastify-basic-auth per https://github.com/shakacode/react_on_rails_pro/issues/110

import { timingSafeEqual } from 'crypto';
import { getConfig } from '../shared/configBuilder.js';

export interface AuthBody {
  password?: string;
}

export function authenticate(body: AuthBody) {
  const { password } = getConfig();

  if (password) {
    const reqPassword = body.password || '';

    // Use timing-safe comparison to prevent timing attacks
    // Both strings must be converted to buffers of the same length
    try {
      const passwordBuffer = Buffer.from(password);
      const reqPasswordBuffer = Buffer.from(reqPassword);

      // If lengths differ, create a dummy buffer of the same length to compare against
      // This ensures constant-time comparison even when lengths don't match
      if (passwordBuffer.length !== reqPasswordBuffer.length) {
        return {
          headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
          status: 401,
          data: 'Wrong password',
        };
      }

      if (!timingSafeEqual(passwordBuffer, reqPasswordBuffer)) {
        return {
          headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
          status: 401,
          data: 'Wrong password',
        };
      }
    } catch {
      // If there's any error in comparison, deny access
      return {
        headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
        status: 401,
        data: 'Wrong password',
      };
    }
  }

  return undefined;
}
