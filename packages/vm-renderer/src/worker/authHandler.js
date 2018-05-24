/**
 * Isolates logic for request authentication. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/authHandler
 */


const { getConfig } = require('../shared/configBuilder');

/**
 *
 */
module.exports = function authenticate(req) {
  const { password } = getConfig();

  if (password && password !== req.body.password) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 401,
      data: 'Wrong password',
    };
  }

  return undefined;
};
