import test from 'tape';

import buildConsoleReplay, { consoleReplay } from '../src/buildConsoleReplay';

test('consoleReplay does not crash if no console.history object', (assert) => {
  assert.plan(1);
  assert.doesNotThrow(() => consoleReplay(), /Error/,
    'consoleReplay should not throw an exception if no console.history object');
});

test('consoleReplay returns empty string if no console.history object', (assert) => {
  assert.plan(1);
  const actual = consoleReplay();
  const expected = '';
  assert.equals(actual, expected,
    'consoleReplay should return an empty string if no console.history');
});

test('consoleReplay does not crash if no console.history.length is 0', (assert) => {
  assert.plan(1);
  console.history = [];
  assert.doesNotThrow(() => consoleReplay(), /Error/,
    'consoleReplay should not throw an exception if console.history.length is zero');
});

test('consoleReplay returns empty string if no console.history object', (assert) => {
  assert.plan(1);
  console.history = [];
  const actual = consoleReplay();
  const expected = '';
  assert.equals(actual, expected,
    'consoleReplay should return an empty string if console.history is an empty array');
});

test('consoleReplay replays multiple history messages', (assert) => {
  assert.plan(1);
  console.history = [
    { arguments: ['a', 'b'], level: 'log' },
    { arguments: ['c', 'd'], level: 'warn' },
  ];
  const actual = consoleReplay();
  const expected =
      'console.log.apply(console, ["a","b"]);\nconsole.warn.apply(console, ["c","d"]);';
  assert.equals(actual, expected,
    'Unexpected value for console replay history');
});

test('consoleReplay replays converts console param objects to JSON', (assert) => {
  assert.plan(1);
  console.history = [
    { arguments: ['some message', { a: 1, b: 2 }], level: 'log' },
    { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
  ];
  const actual = consoleReplay();

  const expected = `console.log.apply(console, ["some message","{\\"a\\":1,\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);`;
  assert.equals(actual, expected, 'Unexpected value for console replay history');
});

test('consoleReplay replays converts script tag inside of object string to be safe ', (assert) => {
  assert.plan(1);
  console.history = [
    { arguments: ['some message </script><script>alert(\'WTF\')</script>',
      { a: 'Wow</script><script>alert(\'WTF\')</script>', b: 2 }],
      level: 'log',
    },
    { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
  ];
  const actual = consoleReplay();

  const expected = `console.log.apply(console, ["some message (/script><script>alert('WTF')\
(/script>","{\\"a\\":\\"Wow(/script><script>alert('WTF')(/script>\\",\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);`;

  assert.equals(actual, expected, 'Unexpected value for console replay history');
});

test('buildConsoleReplay wraps console replay in a script tag', (assert) => {
  assert.plan(1);
  console.history = [
    { arguments: ['some message', { a: 1, b: 2 }], level: 'log' },
    { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
  ];
  const actual = buildConsoleReplay();

  const expected = `
<script id="consoleReplayLog">
console.log.apply(console, ["some message","{\\"a\\":1,\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);
</script>`;

  assert.equals(actual, expected, 'Unexpected value for console replay history');
});
