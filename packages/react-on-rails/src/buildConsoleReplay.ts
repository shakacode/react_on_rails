import { wrapInScriptTags } from './RenderUtils.ts';
import scriptSanitizedVal from './scriptSanitizedVal.ts';

declare global {
  interface Console {
    history?: {
      arguments: Array<string | Record<string, string>>;
      level: 'error' | 'log' | 'debug';
    }[];
  }
}

/**
 * Returns the console replay JavaScript code without wrapping it in script tags.
 * This is useful when you want to wrap the code in script tags yourself (e.g., with a CSP nonce).
 * @internal Exported for tests and for Ruby helper to wrap with nonce
 */
export function consoleReplay(
  customConsoleHistory: (typeof console)['history'] | undefined = undefined,
  numberOfMessagesToSkip = 0,
): string {
  // console.history is a global polyfill used in server rendering.
  const consoleHistory = customConsoleHistory ?? console.history;

  if (!Array.isArray(consoleHistory)) {
    return '';
  }

  const lines = consoleHistory.slice(numberOfMessagesToSkip).map((msg) => {
    const stringifiedList = msg.arguments.map((arg) => {
      let val: string;
      try {
        if (typeof arg === 'string') {
          val = arg;
        } else if (arg instanceof String) {
          val = String(arg);
        } else {
          val = JSON.stringify(arg);
        }
        if (val === undefined) {
          val = 'undefined';
        }
      } catch (e) {
        // eslint-disable-next-line @typescript-eslint/no-base-to-string -- if we here, JSON.stringify didn't work
        val = `${(e as Error).message}: ${arg}`;
      }

      return scriptSanitizedVal(val);
    });

    return `console.${msg.level}.apply(console, ${JSON.stringify(stringifiedList)});`;
  });

  return lines.join('\n');
}

export default function buildConsoleReplay(
  customConsoleHistory: (typeof console)['history'] | undefined = undefined,
  numberOfMessagesToSkip = 0,
  nonce?: string,
): string {
  const consoleReplayJS = consoleReplay(customConsoleHistory, numberOfMessagesToSkip);
  if (consoleReplayJS.length === 0) {
    return '';
  }
  return wrapInScriptTags('consoleReplayLog', consoleReplayJS, nonce);
}
