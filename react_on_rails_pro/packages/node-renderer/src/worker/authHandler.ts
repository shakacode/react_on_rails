/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Fastify server and its Request and Reply objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */
// TODO: Replace with fastify-basic-auth per https://github.com/shakacode/react_on_rails_pro/issues/110

import { getConfig } from '../shared/configBuilder';

export interface AuthBody {
  password?: string;
}

export function authenticate(body: AuthBody) {
  const { password } = getConfig();

  if (password && password !== body.password) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 401,
      data: 'Wrong password',
    };
  }

  return undefined;
}
