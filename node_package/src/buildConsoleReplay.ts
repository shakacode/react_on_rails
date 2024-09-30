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

export function consoleReplay(customConsoleHistory: typeof console['history'] | undefined = undefined): string {
  // console.history is a global polyfill used in server rendering.
  const consoleHistory = customConsoleHistory ?? console.history;

  // $FlowFixMe
  if (!(Array.isArray(consoleHistory))) {
    return '';
  }

  const lines = consoleHistory.map(msg => {
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

export default function buildConsoleReplay(customConsoleHistory: typeof console['history'] | undefined = undefined): string {
  return RenderUtils.wrapInScriptTags('consoleReplayLog', consoleReplay(customConsoleHistory));
}
