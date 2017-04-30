import test from 'tape';

import scriptSanitizedVal from '../src/scriptSanitizedVal';

test('scriptSanitizedVal returns no </script if spaces, uppercase 1', (assert) => {
  assert.plan(1);
  const input = '[SERVER] This is a script:"</div>"</script> <script>alert(\'WTF\')</  SCRIPT >';
  const actual = scriptSanitizedVal(input);
  const expected = '[SERVER] This is a script:"</div>"(/script> <script>alert(\'WTF\')(/script >';
  assert.equals(actual, expected,
    'scriptSanitizedVal replaces closing script tags');
});

test('scriptSanitizedVal returns no </script> 2', (assert) => {
  assert.plan(1);
  const input = 'Script2:"</div>"</script xx> <script>alert(\'WTF2\')</script xx>';
  const actual = scriptSanitizedVal(input);
  const expected = 'Script2:"</div>"(/script xx> <script>alert(\'WTF2\')(/script xx>';
  assert.equals(actual, expected,
    'scriptSanitizedVal replaces closing script tags');
});

test('scriptSanitizedVal returns no </script> 3', (assert) => {
  assert.plan(1);
  const input = 'Script3:"</div>"</  SCRIPT xx> <script>alert(\'WTF3\')</script xx>';
  const actual = scriptSanitizedVal(input);
  const expected = 'Script3:"</div>"(/script xx> <script>alert(\'WTF3\')(/script xx>';
  assert.equals(actual, expected,
    'scriptSanitizedVal replaces closing script tags');
});

test('scriptSanitizedVal returns no </script> 4', (assert) => {
  assert.plan(1);
  const input = 'Script4"</div>"</script <script>alert(\'WTF4\')</script>';
  const actual = scriptSanitizedVal(input);
  const expected = 'Script4"</div>"(/script <script>alert(\'WTF4\')(/script>';
  assert.equals(actual, expected,
    'scriptSanitizedVal replaces closing script tags');
});

test('scriptSanitizedVal returns no </script> 5', (assert) => {
  assert.plan(1);
  const input = 'Script5:"</div>"</ script> <script>alert(\'WTF5\')</script>';
  const actual = scriptSanitizedVal(input);
  const expected = 'Script5:"</div>"(/script> <script>alert(\'WTF5\')(/script>';
  assert.equals(actual, expected,
    'scriptSanitizedVal replaces closing script tags');
});
