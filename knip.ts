import type { KnipConfig } from 'knip';

const config: KnipConfig = {
  // ! at the end means files are used in production
  entry: ['node_package/src/ReactOnRails.ts!', 'node_package/src/ReactOnRails.node.ts!'],
  project: ['node_package/src/**/*.[jt]s!', 'node_package/tests/**/*.[jt]s'],
  ignoreBinaries: [
    // Knip fails to detect it's declared in devDependencies
    'nps',
    // local scripts
    'node_package/scripts/.*',
  ],
  ignoreDependencies: [
    // Required for TypeScript compilation, but we don't depend on Turbolinks itself.
    '@types/turbolinks',
    // used in package-scripts.yml
    'concurrently',
    // The Knip ESLint plugin fails to detect it's transitively required by a config,
    // though we don't actually use its rules anywhere.
    'eslint-plugin-jsx-a11y',
  ],
  babel: {
    config: ['node_package/babel.config.js', 'package.json'],
  },
};

export default config;
