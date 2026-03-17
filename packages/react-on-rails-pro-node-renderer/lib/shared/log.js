"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sharedLoggerOptions = void 0;
const pino_1 = __importDefault(require("pino"));
let pretty = false;
if (process.env.NODE_ENV === 'development' || process.env.NODE_ENV === 'test') {
    try {
        // eslint-disable-next-line global-require,@typescript-eslint/no-require-imports
        require('pino-pretty');
        pretty = true;
    }
    catch (_e) {
        console.log('pino-pretty not found in development, using the default pino log settings');
    }
}
exports.sharedLoggerOptions = {
    // Omit pid and hostname
    base: undefined,
    formatters: {
        level: (label) => ({ level: label }),
    },
    transport: pretty
        ? {
            target: 'pino-pretty',
            options: {
                colorize: true,
                // [2024-12-01 12:18:53.092 +0300] INFO (RORP):
                // or
                // INFO [2024-12-01 12:18:53.092 +0300] (RORP):
                levelFirst: false,
                // Show UTC time in CI and local time on developers' machines
                translateTime: process.env.CI ? true : 'SYS:standard',
                // See https://github.com/pinojs/pino-pretty?tab=readme-ov-file#usage-with-jest
                sync: process.env.NODE_ENV === 'test',
            },
        }
        : undefined,
};
// TODO: ideally we want a way to pass arbitrary logger options or even a logger object from config like Fastify,
//  but the current design doesn't allow this.
const log = (0, pino_1.default)({
    name: 'RORP',
    ...exports.sharedLoggerOptions,
});
exports.default = log;
process.on('uncaughtExceptionMonitor', (err, origin) => {
    // fatal ensures the logging is flushed before exit.
    log.fatal({
        msg: origin === 'uncaughtException' ? 'Uncaught exception' : 'Unhandled promise rejection',
        err,
    });
});
//# sourceMappingURL=log.js.map