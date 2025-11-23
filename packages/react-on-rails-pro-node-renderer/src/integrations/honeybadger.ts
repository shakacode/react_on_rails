import Honeybadger from '@honeybadger-io/js';
import { addNotifier, configureFastify, message } from './api.js';

export function init({ fastify = false } = {}) {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  addNotifier((msg: any) => Honeybadger.notify(msg));

  if (fastify) {
    if ('requestHandler' in Honeybadger && 'withRequest' in Honeybadger) {
      // https://docs.honeybadger.io/lib/javascript/integration/node/#fastify
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      configureFastify((app: any) => {
        app.addHook('preHandler', Honeybadger.requestHandler);

        // Better than setErrorHandler in the above documentation
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        app.addHook('onError', (request: any, _reply: any, error: any, done: () => void) => {
          Honeybadger.withRequest(request, () => {
            Honeybadger.notify(error);
          });
          done();
        });
      });
    } else {
      message("Your Honeybadger version doesn't support Fastify integration, please upgrade it");
    }
  }
}
