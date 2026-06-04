const packageJson = require('../package.json');

describe('package scripts', () => {
  it.each(['build:client', 'build:server'])(
    '%s refreshes generated RSC refs without deleting production webpack output',
    (scriptName) => {
      const script = packageJson.scripts[scriptName];

      expect(script).toMatch(/^rm -rf ssr-generated && /);
      expect(script).not.toContain('public/webpack/production');
      expect(script).toContain('bin/shakapacker-precompile-hook');
    },
  );
});
