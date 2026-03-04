import path from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';
import webpack from 'webpack';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');

// Resolve the actual react package location (may be hoisted in pnpm workspace)
const reactDir = path.dirname(require.resolve('react/package.json'));

export default {
  mode: 'production',
  target: 'node',
  entry: { 'rsc-bundle': path.resolve(rootDir, 'src/entry-rsc.tsx') },
  output: {
    path: path.resolve(rootDir, 'dist/rsc'),
    filename: 'rsc-bundle.cjs',
    libraryTarget: 'commonjs2',
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.jsx'],
    conditionNames: ['react-server', '...'],
    alias: {
      'react/jsx-runtime': path.resolve(reactDir, 'jsx-runtime.react-server.js'),
      'react/jsx-dev-runtime': path.resolve(reactDir, 'jsx-dev-runtime.react-server.js'),
      'react$': path.resolve(reactDir, 'react.react-server.js'),
      'react-dom/server': false,
    },
  },
  module: {
    rules: [
      {
        test: /\.(tsx?|jsx?)$/,
        exclude: /node_modules/,
        use: [
          {
            loader: 'babel-loader',
            options: {
              presets: [
                ['@babel/preset-env', { targets: { node: 'current' }, modules: false }],
                ['@babel/preset-react', { runtime: 'automatic' }],
                '@babel/preset-typescript',
              ],
            },
          },
          {
            loader: 'react-on-rails-rsc/WebpackLoader',
          },
        ],
      },
    ],
  },
  optimization: { minimize: false },
  plugins: [new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })],
};
