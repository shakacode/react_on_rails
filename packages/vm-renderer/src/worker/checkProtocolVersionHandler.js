/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */
import semver from 'semver';

import packageJson from '../shared/packageJson';

module.exports = function checkProtocolVersion(req) {
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
