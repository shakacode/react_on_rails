const { env } = require('shakapacker');

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
