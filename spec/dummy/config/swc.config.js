// config/swc.config.js
// This file is merged with Shakapacker's default SWC configuration
// See: https://swc.rs/docs/configuration/compilation

module.exports = {
  jsc: {
    transform: {
      react: {
        runtime: 'automatic',
        development: process.env.NODE_ENV === 'development',
        // Only enable Fast Refresh when using webpack-dev-server (bin/dev)
        // Not needed for static builds (bin/shakapacker)
        refresh: !!process.env.WEBPACK_SERVE,
      },
    },
  },
};
