/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */

'use strict';

const path = require('path');
const semver = require('semver');

// eslint-disable-next-line import/no-dynamic-require
const packageJson = require(path.join(__dirname, '/../../../package.json'));

module.exports = function checkProtocolVersion(req) {
  // TODO: old style gem version comparison, remove after not needed
  if (semver.lt(req.body.gemVersion, '0.5.4')) return undefined;

  if (
    req.body.protocolVersion === undefined ||
    semver.gt(req.body.protocolVersion, packageJson.protocolVersion)
  ) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: 'Unsupported renderer protocol version, please update your gem to current.',
    };
  }

  return undefined;
};
