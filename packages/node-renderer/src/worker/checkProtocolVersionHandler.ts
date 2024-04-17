/**
 * Logic for checking protocol version.
 * @module worker/checkProtocVersionHandler
 */
import type { Request } from 'express';
import packageJson from '../shared/packageJson';

export = function checkProtocolVersion(req: Request) {
  const reqProtocolVersion = (req.body as { protocolVersion?: string }).protocolVersion;
  if (reqProtocolVersion !== packageJson.protocolVersion) {
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 412,
      data: `Unsupported renderer protocol version ${
        reqProtocolVersion
          ? `request protocol ${reqProtocolVersion}`
          : `MISSING with body ${JSON.stringify(req.body)}`
      } does not
match installed renderer protocol ${packageJson.protocolVersion} for version ${packageJson.version}.
Update either the renderer or the Rails server`,
    };
  }

  return undefined;
};
