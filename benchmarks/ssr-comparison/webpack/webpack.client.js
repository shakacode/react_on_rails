import path from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');

export default {
  mode: 'production',
  target: 'web',
  entry: {
    client: [
      'react-on-rails-rsc/client',
      path.resolve(rootDir, 'src/entry-traditional.tsx'),
    ],
  },
  output: {
    path: path.resolve(rootDir, 'dist/rsc/client'),
    filename: '[name].js',
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
  optimization: { minimize: false },
  plugins: [
    new RSCWebpackPlugin({
      isServer: false,
      clientReferences: [
        { directory: path.resolve(rootDir, 'src'), recursive: true, include: /\.(tsx|ts)$/ },
      ],
      clientManifestFilename: '../react-client-manifest.json',
    }),
  ],
};
