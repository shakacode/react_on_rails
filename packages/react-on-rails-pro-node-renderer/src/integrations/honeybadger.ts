import * as Honeybadger from '@honeybadger-io/js';
import { addNotifier, configureFastify, message } from './api';

export function init({ fastify = false } = {}) {
  addNotifier((msg) => Honeybadger.notify(msg));

  if (fastify) {
    if ('requestHandler' in Honeybadger && 'withRequest' in Honeybadger) {
      // https://docs.honeybadger.io/lib/javascript/integration/node/#fastify
      configureFastify((app) => {
        // @ts-expect-error Slight type mismatch, but it should work
        app.addHook('preHandler', Honeybadger.requestHandler);

        // Better than setErrorHandler in the above documentation
        app.addHook('onError', (request, _reply, error, done) => {
          // @ts-expect-error Slight type mismatch, but it should work
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
