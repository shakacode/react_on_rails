import { reactOnRailsContext } from './context';

declare global {
  namespace Turbolinks {
    interface TurbolinksStatic {
      controller?: unknown;
    }
  }
}

export function debugTurbolinks(...msg: string[]): void {
  if (!window) {
    return;
  }

  const context = reactOnRailsContext();
  if (context.ReactOnRails && context.ReactOnRails.option('traceTurbolinks')) {
    console.log('TURBO:', ...msg);
  }
}

export function turbolinksInstalled(): boolean {
  return (typeof Turbolinks !== 'undefined');
}

export function turboInstalled() {
  const context = reactOnRailsContext();
  if (context.ReactOnRails) {
    return context.ReactOnRails.option('turbo') === true;
  }
  return false;
}

export function turbolinksVersion5(): boolean {
  return (typeof Turbolinks.controller !== 'undefined');
}

export function turbolinksSupported(): boolean {
  return Turbolinks.supported;
}
