/**
 * Formats a message if the `traceTurbolinks` option is enabled.
 * Multiple arguments can be passed like to `console.log`,
 * except format specifiers aren't substituted (because it isn't used as the first argument).
 */
export function debugTurbolinks(...msg) {
  if (!window) {
    return;
  }
  if (globalThis.ReactOnRails?.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}
export function turbolinksInstalled() {
  return typeof Turbolinks !== 'undefined';
}
export function turboInstalled() {
  return globalThis.ReactOnRails?.option('turbo') === true;
}
export function turbolinksVersion5() {
  return typeof Turbolinks.controller !== 'undefined';
}
export function turbolinksSupported() {
  return Turbolinks.supported;
}
