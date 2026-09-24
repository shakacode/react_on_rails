// In JavaScript, when an escape sequence with a backslash (\) is followed by a character
// that isn't a recognized escape character, the backslash is ignored, and the character
// is treated as-is.
// This behavior allows us to use the backslash to escape characters that might be
// interpreted as HTML tags, preventing them from being processed by the HTML parser.
// For example, we can escape the comment tag <!-- as <\!-- and the script tag </script>
// as </\script>.
// This ensures that these tags are not prematurely closed or misinterpreted by the browser.
//
// BOTH replacements are required. Inside a <script> element, `</script` can end the
// element early, and `<!--` can switch the HTML parser into the "script data escaped"
// state, in which a subsequent `<script` makes `</script>` STOP ending the element —
// the script then swallows the rest of the document. See issue #5034.
//
// Only safe for scripts whose untrusted content lives inside JavaScript string literals
// (e.g. produced by JSON.stringify), which is true for every caller in this repo:
// the console replay (buildConsoleReplay) and Pro's RSC payload injection
// (injectRSCPayload's createScriptTag).
export default function escapeScript(script: string): string {
  return script.replace(/<!--/g, '<\\!--').replace(/<\/(script)/gi, '</\\$1');
}
