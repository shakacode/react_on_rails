import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  entry: ['node_package/src/ReactOnRails.ts!', 'node_package/src/ReactOnRails.node.ts!'],
  project: ['node_package/src/**/*.[jt]s!', 'node_package/tests/**/*.[jt]s'],
  ignoreBinaries: [
    // not detected in production mode
    'nps',
    'node_package/scripts/.*',
  ],
  ignoreDependencies: [
    // Not detected because turbolinks itself is not used?
    '@types/turbolinks',
    // used in package-scripts.yml
    'concurrently',
  ],
  babel: {
    config: ['node_package/babel.config.js', 'package.json'],
  },
};

export default config;
