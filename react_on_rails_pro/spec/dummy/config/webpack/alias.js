const { resolve } = require('path');

const rootNodeModules = resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules');

module.exports = {
  resolve: {
    alias: {
      Assets: resolve(__dirname, '..', '..', 'client', 'app', 'assets'),
      // Ensure a single copy of React across the pnpm workspace to prevent
      // "Invalid hook call" errors from duplicate React instances during SSR
      react: resolve(rootNodeModules, 'react'),
      'react/jsx-runtime': resolve(rootNodeModules, 'react', 'jsx-runtime'),
      'react/jsx-dev-runtime': resolve(rootNodeModules, 'react', 'jsx-dev-runtime'),
      'react-dom': resolve(rootNodeModules, 'react-dom'),
      'react-dom/client': resolve(rootNodeModules, 'react-dom', 'client'),
      'react-dom/server': resolve(rootNodeModules, 'react-dom', 'server'),
    },
  },
};
