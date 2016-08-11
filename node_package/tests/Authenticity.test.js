import test from 'tape';
import ReactOnRails from '../src/ReactOnRails.js';

test('authenticityToken and authenticityHeaders', (assert) => {
  assert.plan(4);

  assert.ok(typeof ReactOnRails.authenticityToken == 'function',
    'authenticityToken function exists in ReactOnRails API');

  assert.ok(typeof ReactOnRails.authenticityHeaders == 'function',
    'authenticityHeaders function exists in ReactOnRails API');

  const testToken = 'TEST_CSRF_TOKEN';

  var meta = document.createElement('meta');
  meta.name = 'csrf-token';
  meta.content = testToken;
  document.head.appendChild(meta);

  var realToken = ReactOnRails.authenticityToken();

  assert.equal(realToken, testToken,
    'authenticityToken can read Rails CSRF token from <meta>');

  var realHeader = ReactOnRails.authenticityHeaders();

  assert.deepEqual(realHeader, { 'X-CSRF-Token': testToken, 'X-Requested-With': 'XMLHttpRequest' },
    'authenticityHeaders returns valid header with CFRS token'
  );
});
