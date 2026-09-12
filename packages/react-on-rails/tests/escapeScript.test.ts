import escapeScript from '../src/escapeScript.ts';

describe('escapeScript', () => {
  test.each([
    ['<!--', '<\\!--'], // comment opener neutralized (issue #5034)
    ['</script>', '</\\script>'], // closing tag neutralized
    ['</SCRIPT>', '</\\SCRIPT>'], // case-insensitive
    ['</script xx>', '</\\script xx>'], // prefix match, attributes after the tag name
    ['<script>', '<script>'], // bare opener is harmless without <!-- — untouched
    ['</ script>', '</ script>'], // not an end tag per the HTML spec (space after </) — untouched
    ['<!--<script>', '<\\!--<script>'], // the #5034 page-swallowing combination
    ['a<!--b</script>c', 'a<\\!--b</\\script>c'],
  ])('escapes %j to %j', (input, expected) => {
    expect(escapeScript(input)).toBe(expected);
  });

  it('is idempotent (safe to apply twice, e.g. core console replay then Pro streaming)', () => {
    const once = escapeScript('x<!--<script></script>y');
    expect(escapeScript(once)).toBe(once);
  });

  it('is lossless: the running script sees the original text', () => {
    const nasty = 'oops <!--<script></script> tail';
    // What the browser does after HTML parsing: evaluate the escaped code as JavaScript.
    // eslint-disable-next-line no-new-func -- evaluating generated code is the point of the test
    const roundTripped = new Function(`return ${escapeScript(JSON.stringify(nasty))}`)() as string;
    expect(roundTripped).toBe(nasty);
  });
});
