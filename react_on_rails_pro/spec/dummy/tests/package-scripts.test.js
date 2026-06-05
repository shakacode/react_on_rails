const packageJson = require('../package.json');

describe('package scripts', () => {
  it.each([
    ['build:client', /^rm -rf ssr-generated && /],
    ['build:server', /^rm -rf ssr-generated && /],
    ['build:dev', /^rm -rf public\/webpack\/development ssr-generated && /],
    ['build:test', /^rm -rf public\/webpack\/test ssr-generated && /],
    ['build:dev:watch', /^rm -rf public\/webpack\/development ssr-generated && /],
  ])('%s refreshes generated RSC refs from a clean manifest state', (scriptName, cleanCommandPattern) => {
    const script = packageJson.scripts[scriptName];

    expect(script).toMatch(cleanCommandPattern);
    expect(script).not.toContain('public/webpack/production');
    expect(script).toContain('bin/shakapacker-precompile-hook');
  });
});
