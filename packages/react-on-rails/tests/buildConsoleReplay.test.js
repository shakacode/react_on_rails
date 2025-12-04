import buildConsoleReplay, { consoleReplay } from '../src/buildConsoleReplay.ts';

describe('consoleReplay', () => {
  it('does not throw an exception if no console.history object', () => {
    expect(() => consoleReplay()).not.toThrow(/Error/);
  });

  it('returns empty string if no console.history object', () => {
    const actual = consoleReplay();
    const expected = '';
    expect(actual).toEqual(expected);
  });

  it('returns empty string if console.history is empty', () => {
    console.history = [];
    const actual = consoleReplay();
    const expected = '';
    expect(actual).toEqual(expected);
  });

  it('replays multiple history messages', () => {
    console.history = [
      { arguments: ['a', 'b'], level: 'log' },
      { arguments: ['c', 'd'], level: 'warn' },
    ];
    const actual = consoleReplay();
    const expected = 'console.log.apply(console, ["a","b"]);\nconsole.warn.apply(console, ["c","d"]);';
    expect(actual).toEqual(expected);
  });

  it('replays converts console param objects to JSON', () => {
    console.history = [
      { arguments: ['some message', { a: 1, b: 2 }], level: 'log' },
      { arguments: ['other message', { c: 3, d: 4 }], level: 'warn' },
    ];
    const actual = consoleReplay();

    const expected = `console.log.apply(console, ["some message","{\\"a\\":1,\\"b\\":2}"]);
console.warn.apply(console, ["other message","{\\"c\\":3,\\"d\\":4}"]);`;
    expect(actual).toEqual(expected);
  });

  it('replays converts script tag inside of object string to be safe', () => {
    console.history = [
      {
        arguments: [
          "some message </script><script>alert('WTF')</script>",
          { a: "Wow</script><script>alert('WTF')</script>", b: 2 },
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
  });

  it('buildConsoleReplay adds nonce attribute when provided', () => {
    console.history = [{ arguments: ['test message'], level: 'log' }];
    const actual = buildConsoleReplay(undefined, 0, 'abc123');

    expect(actual).toContain('nonce="abc123"');
    expect(actual).toContain('<script id="consoleReplayLog" nonce="abc123">');
    expect(actual).toContain('console.log.apply(console, ["test message"]);');
  });

  it('buildConsoleReplay returns empty string when no console messages', () => {
    console.history = [];
    const actual = buildConsoleReplay(undefined, 0, 'abc123');

    expect(actual).toEqual('');
  });

  it('consoleReplay returns only JavaScript without script tags', () => {
    console.history = [
      { arguments: ['message 1'], level: 'log' },
      { arguments: ['message 2'], level: 'error' },
    ];
    const actual = consoleReplay();

    // Should not contain script tags
    expect(actual).not.toContain('<script');
    expect(actual).not.toContain('</script>');

    // Should contain the JavaScript code
    expect(actual).toContain('console.log.apply(console, ["message 1"]);');
    expect(actual).toContain('console.error.apply(console, ["message 2"]);');
  });

  it('buildConsoleReplay sanitizes nonce to prevent XSS', () => {
    console.history = [{ arguments: ['test'], level: 'log' }];
    // Attempt attribute injection attack
    const maliciousNonce = 'abc123" onload="alert(1)';
    const actual = buildConsoleReplay(undefined, 0, maliciousNonce);

    // Should strip dangerous characters (quotes, parens, spaces)
    // = is kept as it's valid in base64, but the quotes are stripped making it harmless
    expect(actual).toContain('nonce="abc123onload=alert1"');
    // Should NOT contain quotes that would close the attribute
    expect(actual).not.toContain('nonce="abc123"');
    expect(actual).not.toContain('alert(1)');
    // Verify the dangerous parts (quotes and parens) are removed
    expect(actual).not.toMatch(/nonce="[^"]*"[^>]*onload=/);
  });

  it('consoleReplay skips specified number of messages', () => {
    console.history = [
      { arguments: ['skip 1'], level: 'log' },
      { arguments: ['skip 2'], level: 'log' },
      { arguments: ['keep 1'], level: 'log' },
      { arguments: ['keep 2'], level: 'warn' },
    ];
    const actual = consoleReplay(undefined, 2); // Skip first 2 messages

    // Should not contain skipped messages
    expect(actual).not.toContain('skip 1');
    expect(actual).not.toContain('skip 2');

    // Should contain kept messages
    expect(actual).toContain('console.log.apply(console, ["keep 1"]);');
    expect(actual).toContain('console.warn.apply(console, ["keep 2"]);');
  });

  it('consoleReplay uses custom console history when provided', () => {
    console.history = [{ arguments: ['ignored'], level: 'log' }];
    const customHistory = [
      { arguments: ['custom message 1'], level: 'warn' },
      { arguments: ['custom message 2'], level: 'error' },
    ];
    const actual = consoleReplay(customHistory);

    // Should not contain global console.history
    expect(actual).not.toContain('ignored');

    // Should contain custom history
    expect(actual).toContain('console.warn.apply(console, ["custom message 1"]);');
    expect(actual).toContain('console.error.apply(console, ["custom message 2"]);');
  });

  it('consoleReplay combines numberOfMessagesToSkip with custom history', () => {
    const customHistory = [
      { arguments: ['skip this'], level: 'log' },
      { arguments: ['keep this'], level: 'warn' },
    ];
    const actual = consoleReplay(customHistory, 1);

    // Should skip first message
    expect(actual).not.toContain('skip this');

    // Should keep second message
    expect(actual).toContain('console.warn.apply(console, ["keep this"]);');
  });
});
