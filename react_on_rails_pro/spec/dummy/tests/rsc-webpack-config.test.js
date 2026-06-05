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
});
