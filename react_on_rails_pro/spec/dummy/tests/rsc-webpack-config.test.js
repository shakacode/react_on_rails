const fs = require('fs');
const path = require('path');

const rscWebpackConfigPath = path.resolve(__dirname, '../config/webpack/rscWebpackConfig.js');
const rscWebpackConfig = require('../config/webpack/rscWebpackConfig');

describe('rscWebpackConfig discovery build contract', () => {
  const source = fs.readFileSync(rscWebpackConfigPath, 'utf8');

  it('lazy-loads the discovery plugin with the same actionable hint as the generator template', () => {
    expect(source).not.toContain(
      "const { RSCReferenceDiscoveryPlugin } = require('react-on-rails-rsc/RSCReferenceDiscoveryPlugin');",
    );
    expect(source).toContain('const rscReferenceDiscoveryPlugin = () => {');
    expect(source).toContain('Missing react-on-rails-rsc/RSCReferenceDiscoveryPlugin');
    expect(source).toContain('Run bin/shakapacker-precompile-hook before bin/shakapacker.');
  });

  it('honors the explicit registration entry path for discovery builds', () => {
    expect(source).toContain('process.env.REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH');
    expect(source).toContain('defaultServerComponentRegistrationEntry');
    expect(source).toContain('validServerComponentRegistrationEntry');
    expect(source).toContain('basename(entryPath) !== expectedServerComponentRegistrationEntry');
    expect(source).toContain('statSync(entryPath).isFile()');
    expect(source).toContain('excludedRegistrationEntryPathComponents');
    expect(source).toContain('return configuredEntry;');
  });

  it('keeps generated React server alias cleanup guards in the RSC config source', () => {
    expect(source).toContain("delete rscAliases['react-dom/server'];");
    expect(source).toContain("delete rscAliases['react-dom/server$'];");
    expect(source).toContain('const resolveReactServerEntry = (entryFilename) =>');
    expect(source).toContain('existsSync(entryPath)');
  });

  it('pins React server imports to one package instance for React.cache dispatcher sharing', () => {
    const config = rscWebpackConfig();
    const aliases = config.resolve.alias;

    expect(config.resolve.conditionNames).toContain('react-server');
    expect(aliases.react).toBeUndefined();
    expect(aliases.react$).toMatch(/react[\\/]react\.react-server\.js$/);
    expect(aliases['react/jsx-runtime$']).toMatch(/react[\\/]jsx-runtime\.react-server\.js$/);
    expect(aliases['react/jsx-dev-runtime$']).toMatch(/react[\\/]jsx-dev-runtime\.react-server\.js$/);
    expect(aliases['react-dom/server']).toBe(false);
  });
});
