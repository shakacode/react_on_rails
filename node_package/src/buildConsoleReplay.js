import RenderUtils from './RenderUtils';
import scriptSanitizedVal from './scriptSanitizedVal';

export function consoleReplay() {
  // console.history is a global polyfill used in server rendering.
  const history = console.history;
  if (!history || history.length === 0) {
    return '';
  }

  const lines = history.map(msg => {
    const stringifiedList = msg.arguments.map(arg => {
      let val;
      try {
        val = (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
      } catch (e) {
        val = `${e.message}: ${arg}`;
      }

      return scriptSanitizedVal(val);
    });

    return `console.${msg.level}.apply(console, ${JSON.stringify(stringifiedList)});`;
  });

  return lines.join('\n');
}

export default function buildConsoleReplay() {
  return RenderUtils.wrapInScriptTags(consoleReplay());
}
