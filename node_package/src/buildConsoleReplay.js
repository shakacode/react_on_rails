import RenderUtils from './RenderUtils';

export default function buildConsoleReplay() {
  let consoleReplay = '';

  const history = console.history;

  if (history && history.length > 0) {
    history.forEach(msg => {
      const stringifiedList = msg.arguments.map(arg => {
        try {
          return (typeof arg === 'string' || arg instanceof String) ? arg : JSON.stringify(arg);
        } catch (e) {
          return `${e.message}: ${arg}`;
        }
      });
      consoleReplay += '\nconsole.' + msg.level + '.apply(console, ' +
       JSON.stringify(stringifiedList) + ');';
    });
  }

  return RenderUtils.wrapInScriptTags(consoleReplay);
}
