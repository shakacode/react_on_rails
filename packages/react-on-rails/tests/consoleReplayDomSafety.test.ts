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
import buildConsoleReplay, { consoleReplay } from '../src/buildConsoleReplay.ts';

function parsePageWithReplay(loggedString: string) {
  const history: NonNullable<(typeof console)['history']> = [{ arguments: [loggedString], level: 'log' }];
  const replay = buildConsoleReplay(history);
  const doc = new DOMParser().parseFromString(
    `<!doctype html><html><body>${replay}<div id="after">AFTER</div></body></html>`,
    'text/html',
  );
  return { doc, code: consoleReplay(history) };
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
    const { doc, code } = parsePageWithReplay(logged);
    const after = doc.getElementById('after');
    const replayScript = doc.getElementById('consoleReplayLog');

    // The page survived: the element after the replay script is a real element.
    expect(after).not.toBeNull();
    expect(after?.textContent).toBe('AFTER');

    // And it was not consumed as script text.
    expect(replayScript).not.toBeNull();
    expect(replayScript?.textContent).not.toContain('AFTER');

    // The script element holds the COMPLETE replay code: a regression on the
    // `</script` half would close the element early and truncate its text,
    // which the swallow assertions above cannot see on their own.
    expect(replayScript?.textContent?.trim()).toBe(code);
  });
});
