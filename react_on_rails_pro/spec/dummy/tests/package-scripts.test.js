const packageJson = require('../package.json');

describe('package scripts', () => {
  it.each([
    ['build:client', 'public/webpack/production'],
    ['build:server', 'public/webpack/production'],
  ])(
    '%s cleans production webpack output and ssr-generated before discovery',
    (scriptName, webpackOutput) => {
      const script = packageJson.scripts[scriptName];

      expect(script).toMatch(new RegExp(`^rm -rf ${webpackOutput} ssr-generated && `));
      expect(script).toContain('bin/shakapacker-precompile-hook');
    },
  );
});
