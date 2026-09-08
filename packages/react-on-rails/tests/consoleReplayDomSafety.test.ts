/**
 * Regression tests for issue #5034 asserting observable browser behavior rather than
 * the escaped string shape: after the console-replay <script> is parsed, the elements
 * that follow it on the page must still exist.
 *
 * Inside a <script> element, `</script` can end the element early, and `<!--` switches
 * the HTML parser into a state where a subsequent `<script` makes `</script>` stop
 * ending the element — the script then swallows the rest of the document. jsdom's
 * parser implements those states, so these tests fail against an escaping scheme that
 * misses either sequence.
 */
import buildConsoleReplay from '../src/buildConsoleReplay.ts';

function parsePageWithReplay(loggedString: string) {
  const replay = buildConsoleReplay([{ arguments: [loggedString], level: 'log' }]);
  return new DOMParser().parseFromString(
    `<!doctype html><html><body>${replay}<div id="after">AFTER</div></body></html>`,
    'text/html',
  );
}

describe('console replay script does not swallow the rest of the document', () => {
  test.each([
    'hello world',
    'bye </script> tail',
    'oops <!--<script> tail', // swallowed the page before the #5034 fix
    '<!--',
    '<script>',
    '<!--<script></script>-->',
    'combo </script> and <!--<script> in one message',
  ])('a following element still parses when logging %j', (logged) => {
    const doc = parsePageWithReplay(logged);
    const after = doc.getElementById('after');
    const replayScript = doc.getElementById('consoleReplayLog');

    // The page survived: the element after the replay script is a real element.
    expect(after).not.toBeNull();
    expect(after?.textContent).toBe('AFTER');

    // And it was not consumed as script text.
    expect(replayScript).not.toBeNull();
    expect(replayScript?.textContent).not.toContain('AFTER');
  });
});
