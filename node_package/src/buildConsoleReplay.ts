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
      let val: string | undefined;
      try {
        // eslint-disable-next-line no-nested-ternary
        val = typeof arg === 'string' ? arg :
          arg instanceof String ? String(arg) :
            JSON.stringify(arg);
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
