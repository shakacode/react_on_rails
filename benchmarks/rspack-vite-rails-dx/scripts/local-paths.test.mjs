import assert from 'node:assert/strict';
import test from 'node:test';
import { assertNoLocalPaths, redactLocalPaths } from './local-paths.mjs';

test('redacts common local-user paths', () => {
  assert.equal(redactLocalPaths('/Users/example/project/file.js'), '<LOCAL_PATH>');
  assert.throws(() => assertNoLocalPaths({ log: '/home/example/project' }), /unredacted/);
});

test('allows repository-relative paths and public URLs', () => {
  assert.doesNotThrow(() =>
    assertNoLocalPaths({
      file: 'starters/rspack/Gemfile',
      issue: 'https://github.com/shakacode/react_on_rails/issues/4600',
    }),
  );
});
