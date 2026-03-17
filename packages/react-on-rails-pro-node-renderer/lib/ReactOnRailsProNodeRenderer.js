"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.reactOnRailsProNodeRenderer = reactOnRailsProNodeRenderer;
const cluster_1 = __importDefault(require("cluster"));
const package_json_1 = __importDefault(require("fastify/package.json"));
const configBuilder_js_1 = require("./shared/configBuilder.js");
const { version: fastifyVersion } = package_json_1.default;
const log_js_1 = __importDefault(require("./shared/log.js"));
const utils_js_1 = require("./shared/utils.js");
async function reactOnRailsProNodeRenderer(config = {}) {
    const fastify5Supported = (0, utils_js_1.majorVersion)(process.versions.node) >= 20;
    const fastify5OrNewer = (0, utils_js_1.majorVersion)(fastifyVersion) >= 5;
    if (fastify5OrNewer && !fastify5Supported) {
        log_js_1.default.error(`Node.js version ${process.versions.node} is not supported by Fastify ${fastifyVersion}.
Please either use Node.js v20 or higher or downgrade Fastify by setting the following resolutions in your package.json:
{
  "@fastify/formbody": "^7.4.0",
  "@fastify/multipart": "^8.3.1",
  "fastify": "^4.29.0",
}`);
        process.exit(1);
    }
    else if (!fastify5OrNewer && fastify5Supported) {
        log_js_1.default.warn(`Fastify 5+ supports Node.js ${process.versions.node}, but the current version of Fastify is ${fastifyVersion}.
You have probably forced an older version of Fastify by adding resolutions for it
and for "@fastify/..." dependencies in your package.json. Consider removing them.`);
    }
    const { workersCount } = (0, configBuilder_js_1.buildConfig)(config);
    /* eslint-disable global-require,@typescript-eslint/no-require-imports --
     * Using normal `import` fails before the check above.
     */
    const isSingleProcessMode = workersCount === 0;
    if (isSingleProcessMode || cluster_1.default.isWorker) {
        if (isSingleProcessMode) {
            log_js_1.default.info('Running renderer in single process mode (workersCount: 0)');
        }
        const worker = require('./worker.js');
        await worker.default(config).ready();
    }
    else {
        const master = require('./master.js');
        master.default(config);
    }
    /* eslint-enable global-require,@typescript-eslint/no-require-imports */
}
//# sourceMappingURL=ReactOnRailsProNodeRenderer.js.map