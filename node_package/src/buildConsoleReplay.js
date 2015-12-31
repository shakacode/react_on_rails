import RenderUtils from './RenderUtils';

export function consoleReplay() {
  // console.history is a global polyfill used in server rendering.
  const history = console.history;
  if (!history || history.length === 0) {
    return '';
  }

  const lines = history.map(msg => {
    const stringifiedList = msg.arguments.map(arg => {
      try {
        return (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
      } catch (e) {
        return `${e.message}: ${arg}`;
      }
    });

    return 'console.' + msg.level + '.apply(console, ' +
      JSON.stringify(stringifiedList) + ');';
  });

  return lines.join('\n');
}

export default function buildConsoleReplay() {
  return RenderUtils.wrapInScriptTags(consoleReplay());
}
