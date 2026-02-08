const { resolve } = require('path');

module.exports = {
  resolve: {
    alias: {
      Assets: resolve(__dirname, '..', '..', 'client', 'app', 'assets'),
      // Ensure a single copy of React across the pnpm workspace to prevent
      // "Invalid hook call" errors from duplicate React instances during SSR
      react: resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules', 'react'),
      'react/jsx-runtime': resolve(
        __dirname,
        '..',
        '..',
        '..',
        '..',
        '..',
        'node_modules',
        'react',
        'jsx-runtime',
      ),
      'react/jsx-dev-runtime': resolve(
        __dirname,
        '..',
        '..',
        '..',
        '..',
        '..',
        'node_modules',
        'react',
        'jsx-dev-runtime',
      ),
      'react-dom': resolve(__dirname, '..', '..', '..', '..', '..', 'node_modules', 'react-dom'),
      'react-dom/client': resolve(
        __dirname,
        '..',
        '..',
        '..',
        '..',
        '..',
        'node_modules',
        'react-dom',
        'client',
      ),
      'react-dom/server': resolve(
        __dirname,
        '..',
        '..',
        '..',
        '..',
        '..',
        'node_modules',
        'react-dom',
        'server',
      ),
    },
  },
};
