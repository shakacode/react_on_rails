// config/swc.config.js
// This file is merged with Shakapacker's default SWC configuration
// See: https://swc.rs/docs/configuration/compilation

module.exports = {
  jsc: {
    transform: {
      react: {
        runtime: 'automatic',
        development: process.env.NODE_ENV === 'development',
        refresh: process.env.NODE_ENV === 'development', // Enable Fast Refresh in development
      },
    },
  },
};
