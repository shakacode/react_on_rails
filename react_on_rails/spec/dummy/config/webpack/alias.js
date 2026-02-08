const { resolve } = require('path');

module.exports = {
  resolve: {
    alias: {
      Assets: resolve(__dirname, '..', '..', 'client', 'app', 'assets'),
      // Ensure a single copy of React across the pnpm workspace to prevent
      // "Invalid hook call" errors from duplicate React instances during SSR
      react: resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules', 'react'),
      'react-dom': resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules', 'react-dom'),
    },
  },
};
