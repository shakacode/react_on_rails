const fs = require('fs');
const path = require('path');

const rspackConfigPath = path.resolve(__dirname, '../config/rspack/rspack.config.js');
const shakapackerBinPath = path.resolve(__dirname, '../bin/shakapacker');
const clientConfigPath = path.resolve(__dirname, '../config/webpack/clientWebpackConfig.js');
const serverConfigPath = path.resolve(__dirname, '../config/webpack/serverWebpackConfig.js');
const rscConfigPath = path.resolve(__dirname, '../config/webpack/rscWebpackConfig.js');

afterEach(() => {
  jest.resetModules();
  jest.clearAllMocks();
});

describe('Pro dummy RSC rspack config', () => {
  it('provides a rspack entrypoint that delegates to the shared build config', () => {
    expect(fs.existsSync(rspackConfigPath)).toBe(true);

    const source = fs.readFileSync(rspackConfigPath, 'utf8');
    expect(source).toMatch(/SHAKAPACKER_ASSETS_BUNDLER/);
    expect(source).toMatch(/webpack\.config/);
  });

  it('uses the Shakapacker runner that selects webpack or rspack at runtime', () => {
    const source = fs.readFileSync(shakapackerBinPath, 'utf8');

    expect(source).toContain('require "shakapacker/runner"');
    expect(source).toContain('Shakapacker::Runner.run(ARGV)');
    expect(source).not.toContain('shakapacker/webpack_runner');
    expect(source).not.toContain('Shakapacker::WebpackRunner.run(ARGV)');
  });

  it('selects the native RSC manifest plugin when Shakapacker runs under rspack', () => {
    const clientSource = fs.readFileSync(clientConfigPath, 'utf8');
    const serverSource = fs.readFileSync(serverConfigPath, 'utf8');

    [clientSource, serverSource].forEach((source) => {
      expect(source).toContain("config.assets_bundler === 'rspack'");
      expect(source).toContain("require('react-on-rails-rsc/RspackPlugin').RSCRspackPlugin");
      expect(source).toContain("require('react-on-rails-rsc/WebpackPlugin').RSCWebpackPlugin");
      expect(source).toContain('RSCManifestPlugin');
    });
    expect(serverSource).toContain("require('@rspack/core')");
    expect(serverSource).toContain("require('webpack')");
  });

  it('keeps Node-only modules out of the browser bundle fallback set', () => {
    const clientSource = fs.readFileSync(clientConfigPath, 'utf8');

    expect(clientSource).toContain('fs: false');
    expect(clientSource).toContain('module: false');
    expect(clientSource).toContain('path: false');
    expect(clientSource).toContain('stream: false');
  });

  it('wraps function-shaped JavaScript loader rules once for the RSC loader', () => {
    jest.doMock('shakapacker', () => ({
      config: {
        assets_bundler: 'rspack',
        source_entry_path: 'packs',
        source_path: 'client/app',
      },
    }));

    const functionRule = {
      use() {
        return [{ loader: 'babel-loader', options: { caller: { ssr: true } } }];
      },
    };
    const serverConfig = {
      entry: { 'server-bundle': './server-bundle.js' },
      module: { rules: [functionRule] },
      output: {},
      plugins: [],
      resolve: { alias: {} },
    };
    const configureServer = jest.fn(() => serverConfig);
    const extractLoader = (rule, loaderName) =>
      Array.isArray(rule.use)
        ? rule.use.find((item) => {
            const testValue = typeof item === 'string' ? item : (item?.loader ?? '');
            return testValue.includes(loaderName);
          })
        : null;

    jest.doMock(serverConfigPath, () => ({
      default: configureServer,
      extractLoader,
    }));

    // eslint-disable-next-line global-require, import/no-dynamic-require
    const configureRsc = require(rscConfigPath);
    const firstConfig = configureRsc();
    const wrappedUse = firstConfig.module.rules[0].use;
    const firstUseResult = wrappedUse({});

    configureRsc();
    const secondUseResult = firstConfig.module.rules[0].use({});

    expect(configureServer).toHaveBeenCalledWith(true);
    expect(wrappedUse.name).toBe('rscLoaderWrapper');
    expect(firstUseResult).toEqual([
      { loader: 'babel-loader', options: { caller: { ssr: true } } },
      { loader: 'react-on-rails-rsc/RspackLoader' },
    ]);
    expect(secondUseResult).toEqual(firstUseResult);
  });
});
