import path from 'path';
import { fileURLToPath } from 'url';
import webpack from 'webpack';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');

export default {
  mode: 'production',
  target: 'node',
  entry: { 'server-bundle-suspense': path.resolve(rootDir, 'src/entry-suspense.tsx') },
  output: {
    path: path.resolve(rootDir, 'dist/traditional'),
    filename: 'server-bundle-suspense.cjs',
    libraryTarget: 'commonjs2',
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js', '.jsx'],
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
        ],
      },
    ],
  },
  externals: {
    react: 'commonjs2 react',
    'react/jsx-runtime': 'commonjs2 react/jsx-runtime',
    'react/jsx-dev-runtime': 'commonjs2 react/jsx-dev-runtime',
    'react-dom': 'commonjs2 react-dom',
    'react-dom/server': 'commonjs2 react-dom/server',
  },
  optimization: { minimize: false },
  plugins: [new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })],
};
