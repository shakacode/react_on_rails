const fs = require('fs');
const path = require('path');

const rscWebpackConfigPath = path.resolve(__dirname, '../config/webpack/rscWebpackConfig.js');

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
});
