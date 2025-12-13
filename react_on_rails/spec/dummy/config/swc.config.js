/* eslint-disable global-require */
let env;
try {
  ({ env } = require('shakapacker'));
} catch (error) {
  console.error('Failed to load shakapacker:', error.message);
  console.error('Make sure shakapacker is installed: pnpm add shakapacker');
  process.exit(1);
}
/* eslint-enable global-require */

const customConfig = {
  options: {
    jsc: {
      parser: {
        syntax: 'ecmascript',
        jsx: true,
        dynamicImport: true,
      },
      transform: {
        react: {
          runtime: 'automatic',
          development: env.isDevelopment,
          refresh: env.isDevelopment && env.runningWebpackDevServer,
          useBuiltins: true,
        },
      },
      // Keep class names for better debugging and compatibility
      keepClassNames: true,
    },
    env: {
      targets: '> 0.25%, not dead',
    },
  },
};

module.exports = customConfig;
