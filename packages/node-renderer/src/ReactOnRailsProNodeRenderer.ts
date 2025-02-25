import cluster from 'cluster';
import { version as fastifyVersion } from 'fastify/package.json';
import { Config } from './shared/configBuilder';
import log from './shared/log';
import { majorVersion } from './shared/utils';

export async function reactOnRailsProNodeRenderer(config: Partial<Config> = {}) {
  const fastify5Supported = majorVersion(process.versions.node) >= 20;
  const fastify5OrNewer = majorVersion(fastifyVersion) >= 5;
  if (fastify5OrNewer && !fastify5Supported) {
    log.error(
      `Node.js version ${process.versions.node} is not supported by Fastify ${fastifyVersion}.
Please either use Node.js v20 or higher or downgrade Fastify by setting the following resolutions in your package.json:
{
  "@fastify/formbody": "^7.4.0",
  "@fastify/multipart": "^8.3.1",
  "fastify": "^4.29.0",
}`,
    );
    process.exit(1);
  } else if (!fastify5OrNewer && fastify5Supported) {
    log.warn(
      `Fastify 5+ supports Node.js ${process.versions.node}, but the current version of Fastify is ${fastifyVersion}.
You have probably forced an older version of Fastify by adding resolutions for it
and for "@fastify/..." dependencies in your package.json. Consider removing them.`,
    );
  }

  /* eslint-disable global-require,@typescript-eslint/no-var-requires --
   * Using normal `import` fails before the check above.
   */
  if (cluster.isPrimary) {
    (require('./master') as typeof import('./master'))(config);
  } else {
    await (require('./worker') as typeof import('./worker')).default(config).ready();
  }
  /* eslint-enable global-require,@typescript-eslint/no-var-requires */
}
