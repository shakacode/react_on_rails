const fs = require('fs');
const path = require('path');

const rspackConfigPath = path.resolve(__dirname, '../config/rspack/rspack.config.js');
const shakapackerBinPath = path.resolve(__dirname, '../bin/shakapacker');
const clientConfigPath = path.resolve(__dirname, '../config/webpack/clientWebpackConfig.js');
const serverConfigPath = path.resolve(__dirname, '../config/webpack/serverWebpackConfig.js');

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
});
