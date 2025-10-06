// config/swc.config.js
// This file is merged with Shakapacker's default SWC configuration
// See: https://swc.rs/docs/configuration/compilation

module.exports = {
  jsc: {
    transform: {
      react: {
        runtime: 'automatic',
      },
    },
  },
};
