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
  // $FlowFixMe
  if (!(console.history instanceof Array)) {
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
