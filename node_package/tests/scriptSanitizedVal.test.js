import test from 'tape';
import scriptSanitizedVal, { consoleReplay } from '../src/scriptSanitizedVal';

test('scriptSanitizedVal returns no </script>', (assert) => {
  assert.plan(1);
  const input = '[SERVER] This is a script:\"</div>\"</script> <script>alert(\'WTF\')</  SCRIPT >';
  const actual = scriptSanitizedVal(input);
  const expected = '[SERVER] This is a script:\"</div>\"(/script) <script>alert(\'WTF\')(/script)';;
  assert.equals(actual, expected,
    'consoleReplay should return an empty string if no console.history');
});
