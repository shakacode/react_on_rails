/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */
// TODO: Replace with express-basic-auth per https://github.com/shakacode/react_on_rails_pro/issues/110

import type { Request } from 'express';
import { getConfig } from '../shared/configBuilder';

/**
 *
 */
export = function authenticate(req: Request) {
  const { password } = getConfig();

  if (password && password !== (req.body as { password?: string }).password) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 401,
      data: 'Wrong password',
    };
  }

  return undefined;
};
