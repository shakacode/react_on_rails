/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Fastify server and its Request and Reply objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */
// TODO: Replace with fastify-basic-auth per https://github.com/shakacode/react_on_rails_pro/issues/110

import type { FastifyRequest } from './types.js';
import { getConfig } from '../shared/configBuilder.js';

export default function authenticate(req: FastifyRequest) {
  const { password } = getConfig();

  if (password && password !== (req.body as { password?: string }).password) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 401,
      data: 'Wrong password',
    };
  }

  return undefined;
}
