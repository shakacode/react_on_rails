"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.init = init;
const js_1 = __importDefault(require("@honeybadger-io/js"));
const api_js_1 = require("./api.js");
function init({ fastify = false } = {}) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (0, api_js_1.addNotifier)((msg) => js_1.default.notify(msg));
    if (fastify) {
        if ('requestHandler' in js_1.default && 'withRequest' in js_1.default) {
            // https://docs.honeybadger.io/lib/javascript/integration/node/#fastify
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            (0, api_js_1.configureFastify)((app) => {
                app.addHook('preHandler', js_1.default.requestHandler);
                // Better than setErrorHandler in the above documentation
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                app.addHook('onError', (request, _reply, error, done) => {
                    js_1.default.withRequest(request, () => {
                        js_1.default.notify(error);
                    });
                    done();
                });
            });
        }
        else {
            (0, api_js_1.message)("Your Honeybadger version doesn't support Fastify integration, please upgrade it");
        }
    }
}
//# sourceMappingURL=honeybadger.js.map