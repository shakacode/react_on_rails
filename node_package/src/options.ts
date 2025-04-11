import type { ReactOnRailsOptions } from './types/index.ts';

const DEFAULT_OPTIONS = {
  traceTurbolinks: false,
  turbo: false,
};

let options: ReactOnRailsOptions = {};

export function setOptions(newOptions: Partial<ReactOnRailsOptions>): void {
  if (typeof newOptions.traceTurbolinks !== 'undefined') {
    options.traceTurbolinks = newOptions.traceTurbolinks;

    // eslint-disable-next-line no-param-reassign
    delete newOptions.traceTurbolinks;
  }

  if (typeof newOptions.turbo !== 'undefined') {
    options.turbo = newOptions.turbo;

    // eslint-disable-next-line no-param-reassign
    delete newOptions.turbo;
  }

  if (Object.keys(newOptions).length > 0) {
    throw new Error(`Invalid options passed to ReactOnRails.options: ${JSON.stringify(newOptions)}`);
  }
}

export function option<K extends keyof ReactOnRailsOptions>(key: K): ReactOnRailsOptions[K] | undefined {
  return options[key];
}

export function resetOptions(): void {
  options = { ...DEFAULT_OPTIONS };
}
