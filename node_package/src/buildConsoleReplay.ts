import RenderUtils from './RenderUtils';
import scriptSanitizedVal from './scriptSanitizedVal';

declare global {
  interface Console {
    history?: {
      arguments: Array<string | Record<string, string>>; level: "error" | "log" | "debug";
    }[];
  }
}

export function consoleReplay(customConsoleHistory: typeof console['history'] | undefined = undefined, skipFirstNumberOfMessages: number = 0): string {
  // console.history is a global polyfill used in server rendering.
  const consoleHistory = customConsoleHistory ?? console.history;

  if (!(Array.isArray(consoleHistory))) {
    return '';
  }

  const lines = consoleHistory.slice(skipFirstNumberOfMessages).map(msg => {
    const stringifiedList = msg.arguments.map(arg => {
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
        val = `${(e as Error).message}: ${arg}`;
      }

      return scriptSanitizedVal(val);
    });

    return `console.${msg.level}.apply(console, ${JSON.stringify(stringifiedList)});`;
  });

  return lines.join('\n');
}

export default function buildConsoleReplay(customConsoleHistory: typeof console['history'] | undefined = undefined, skipFirstNumberOfMessages: number = 0): string {
  return RenderUtils.wrapInScriptTags('consoleReplayLog', consoleReplay(customConsoleHistory, skipFirstNumberOfMessages));
}
