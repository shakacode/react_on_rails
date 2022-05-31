/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */
const packageJson = require('../shared/packageJson');

module.exports = function checkProtocolVersion(req) {
  if (req.body.protocolVersion !== packageJson.protocolVersion) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: `Unsupported renderer protocol version ${
        req.body.protocolVersion
          ? `request protocol ${req.body.protocolVersion}`
          : `MISSING with body ${req.body}`
      } does not
match installed renderer protocol ${packageJson.protocolVersion} for version ${packageJson.version}.
Update either the renderer or the Rails server`,
    };
  }

  return undefined;
};
