/**
 * @jest-environment node
 */

import { createRequire } from 'module';

const nodeRequire = createRequire(__filename);
const path = nodeRequire('path');
const { Volume, createFsFromVolume } = nodeRequire('memfs');
const webpack = nodeRequire('webpack');
const { RSCWebpackPlugin } = nodeRequire('react-on-rails-rsc/WebpackPlugin');

const packageRoot = path.resolve(__dirname, '..');
const workspaceRoot = path.resolve(packageRoot, '../..');
const proSrcRoot = path.join(packageRoot, 'src');
const reactOnRailsSrcRoot = path.join(workspaceRoot, 'packages/react-on-rails/src');
const outputPath = '/webpack-output';

const swcLoader = nodeRequire.resolve('swc-loader');
const getReactServerComponentStub = path.join(
  __dirname,
  'fixtures/rsc-manifest/getReactServerComponent.client.stub.ts',
);

const runWebpack = () => {
  const volume = new Volume();
  const outputFileSystem = createFsFromVolume(volume);
  outputFileSystem.join = path.join.bind(path);

  const compiler = webpack({
    mode: 'development',
    target: 'web',
    context: packageRoot,
    entry: {
      client: path.join(proSrcRoot, 'wrapServerComponentRenderer/client.tsx'),
    },
    output: {
      filename: '[name].js',
      path: outputPath,
    },
    resolve: {
      alias: {
        'react-on-rails/@internal/rendererTeardown$': path.join(reactOnRailsSrcRoot, 'rendererTeardown.ts'),
        'react-on-rails/isRenderFunction$': path.join(reactOnRailsSrcRoot, 'isRenderFunction.ts'),
        'react-on-rails/reactApis$': path.join(reactOnRailsSrcRoot, 'reactApis.cts'),
        'react-on-rails/types$': path.join(reactOnRailsSrcRoot, 'types/index.ts'),
      },
      extensions: ['.tsx', '.ts', '.cts', '.jsx', '.js', '.cjs'],
    },
    module: {
      rules: [
        {
          test: /\.[cm]?[jt]sx?$/,
          exclude: /node_modules/,
          use: {
            loader: swcLoader,
            options: {
              jsc: {
                parser: {
                  syntax: 'typescript',
                  tsx: true,
                },
                transform: {
                  react: {
                    runtime: 'automatic',
                  },
                },
                target: 'es2022',
              },
            },
          },
        },
      ],
    },
    plugins: [
      new webpack.NormalModuleReplacementPlugin(/getReactServerComponent\.client\.ts$/, (resource) => {
        resource.request = getReactServerComponentStub;
      }),
      new RSCWebpackPlugin({
        isServer: false,
        clientReferences: [],
      }),
    ],
    optimization: {
      minimize: false,
    },
  });

  compiler.outputFileSystem = outputFileSystem;

  return new Promise((resolve, reject) => {
    compiler.run((error, stats) => {
      compiler.close((closeError) => {
        if (error || closeError) {
          reject(error || closeError);
          return;
        }

        resolve({
          volume,
          stats: stats.toJson({
            all: false,
            assets: true,
            errors: true,
            warnings: true,
          }),
        });
      });
    });
  });
};

describe('wrapServerComponentRenderer client manifest emission', () => {
  it('keeps the RSC client runtime visible to RSCWebpackPlugin', async () => {
    const { stats, volume } = await runWebpack();

    expect(stats.errors).toEqual([]);
    expect(stats.warnings).not.toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          message: expect.stringContaining('Client runtime at react-on-rails-rsc/client was not found'),
        }),
      ]),
    );
    expect(volume.existsSync(path.join(outputPath, 'react-client-manifest.json'))).toBe(true);
  });
});
