/**
 * Isolates logic for checking gem version. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/checkGemVersionHandler
 */

'use strict';

const path = require('path');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

/**
 *
 */
module.exports = function checkGemVersion(req) {
  if (packageJson.version !== req.body.gemVersion) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: 'Renderer version does not match gem version',
    };
  }

  return undefined;
};
