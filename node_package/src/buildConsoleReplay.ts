import RenderUtils from './RenderUtils';
import scriptSanitizedVal from './scriptSanitizedVal';

/* eslint-disable @typescript-eslint/no-explicit-any */

declare global {
  interface Console {
    history?: {
      arguments: Array<string | Record<string, string>>; level: "error" | "log" | "debug";
    }[];
  }
}

export function consoleReplay(): string {
  // console.history is a global polyfill used in server rendering.
  // Must use Array.isArray instead of instanceof Array the history array is defined outside the vm if node renderer is used.
  // In this case, the Array prototype used to define the array is not the same as the one in the global scope inside the vm.
  // $FlowFixMe
  if (!(Array.isArray(console.history))) {
    return '';
  }

  const lines = console.history.map(msg => {
    const stringifiedList = msg.arguments.map(arg => {
      let val;
      try {
        val = (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
        if (val === undefined) {
          val = 'undefined';
        }
      } catch (e: any) {
        val = `${e.message}: ${arg}`;
      }

      return scriptSanitizedVal(val as string);
    });

    return `console.${msg.level}.apply(console, ${JSON.stringify(stringifiedList)});`;
  });

  return lines.join('\n');
}

export default function buildConsoleReplay(): string {
  return RenderUtils.wrapInScriptTags('consoleReplayLog', consoleReplay());
}
