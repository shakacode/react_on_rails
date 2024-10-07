import RenderUtils from './RenderUtils';
import scriptSanitizedVal from './scriptSanitizedVal';

declare global {
  interface Console {
    history?: {
      arguments: Array<string | Record<string, string>>; level: "error" | "log" | "debug";
    }[];
  }
}

export function consoleReplay(): string {
  // console.history is a global polyfill used in server rendering.
  if (!(console.history instanceof Array)) {
    return '';
  }

  const lines = console.history.map(msg => {
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

export default function buildConsoleReplay(): string {
  return RenderUtils.wrapInScriptTags('consoleReplayLog', consoleReplay());
}
