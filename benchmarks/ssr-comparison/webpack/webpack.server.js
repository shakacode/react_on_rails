import path from 'path';
import { fileURLToPath } from 'url';
import webpack from 'webpack';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '..');

// Plugin that exposes __webpack_require__ on globalThis inside the webpack runtime
class ExposeWebpackRequirePlugin {
  apply(compiler) {
    compiler.hooks.compilation.tap('ExposeWebpackRequirePlugin', (compilation) => {
      compilation.hooks.additionalTreeRuntimeRequirements.tap(
        'ExposeWebpackRequirePlugin',
        (chunk) => {
          compilation.addRuntimeModule(chunk, new ExposeWebpackRequireRuntimeModule());
        }
      );
    });
  }
}

class ExposeWebpackRequireRuntimeModule extends webpack.RuntimeModule {
  constructor() {
    super('expose __webpack_require__');
  }
  generate() {
    return 'globalThis.__webpack_require__ = __webpack_require__;';
  }
}

export default {
  mode: 'production',
  target: 'node',
  entry: {
    'server-bundle': [
      'react-on-rails-rsc/client',
      path.resolve(rootDir, 'src/entry-traditional.tsx'),
    ],
  },
  output: {
    path: path.resolve(rootDir, 'dist/rsc'),
    filename: 'server-bundle.cjs',
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
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),
    new ExposeWebpackRequirePlugin(),
    new RSCWebpackPlugin({
      isServer: true,
      clientReferences: [
        { directory: path.resolve(rootDir, 'src'), recursive: true, include: /\.(tsx|ts)$/ },
      ],
      clientManifestFilename: 'react-server-client-manifest.json',
    }),
  ],
};
