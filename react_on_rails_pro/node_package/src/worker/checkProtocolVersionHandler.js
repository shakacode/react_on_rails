/**
 * Isolates logic for checking protocol version. We don't want this module to know about
 * Express server and its req and res objects. This allows to test module in isolation
 * and without async calls.
 * @module worker/checkGemVersionHandler
 */

'use strict';

const path = require('path');
const versionCompare = require('./versionCompare');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

module.exports = function checkProtocolVersion(req) {
  // old style gem version comparison
  if (versionCompare(req.body.gemVersion, '0.5.2') <= 0) return undefined;

  if (
    req.body.protocolVersion === undefined ||
    versionCompare(req.body.protocolVersion, packageJson.protocolVersion) > 0
  ) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: 'Unsupported renderer protocol version, please update your gem to current.',
    };
  }

  return undefined;
};
