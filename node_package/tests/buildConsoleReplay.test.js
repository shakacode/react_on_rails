import buildConsoleReplay, { consoleReplay } from '../src/buildConsoleReplay';

describe('consoleReplay', () => {
  expect.assertions(8);
  it('does not throw an exception if no console.history object', () => {
    expect.assertions(1);
    expect(() => consoleReplay()).not.toThrow(/Error/);
  });

  it('returns empty string if no console.history object', () => {
    expect.assertions(1);
    const actual = consoleReplay();
    const expected = '';
    expect(actual).toEqual(expected);
  });

  it('does not throw an exception if console.history.length is zero', () => {
    expect.assertions(1);
    console.history = [];
    expect(() => consoleReplay()).not.toThrow(/Error/);
  });

  it('returns empty string if no console.history object', () => {
    expect.assertions(1);
    console.history = [];
    const actual = consoleReplay();
    const expected = '';
    expect(actual).toEqual(expected);
  });

  it('replays multiple history messages', () => {
    expect.assertions(1);
    console.history = [
      { arguments: ['a', 'b'], level: 'log' },
      { arguments: ['c', 'd'], level: 'warn' },
    ];
    const actual = consoleReplay();
    const expected =
        'console.log.apply(console, ["a","b"]);\nconsole.warn.apply(console, ["c","d"]);';
    expect(actual).toEqual(expected);
  });

  it('replays converts console param objects to JSON', () => {
    expect.assertions(1);
    console.history = [
      { arguments: ['some message', { a: 1, b: 2 }], level: 'log' },
      { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
    ];
    const actual = consoleReplay();

    const expected = `console.log.apply(console, ["some message","{\\"a\\":1,\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);`;
    expect(actual).toEqual(expected);
  });

  it('replays converts script tag inside of object string to be safe ', () => {
    expect.assertions(1);
    console.history = [
      {
        arguments: [
          'some message </script><script>alert(\'WTF\')</script>',
          { a: 'Wow</script><script>alert(\'WTF\')</script>', b: 2 },
        ],
        level: 'log',
      },
      { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
    ];
    const actual = consoleReplay();

    const expected = `console.log.apply(console, ["some message (/script><script>alert('WTF')\
(/script>","{\\"a\\":\\"Wow(/script><script>alert('WTF')(/script>\\",\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);`;

    expect(actual).toEqual(expected);
  });

  it('buildConsoleReplay wraps console replay in a script tag', () => {
    expect.assertions(1);
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

    expect(actual).toEqual(expected);
  })
})
