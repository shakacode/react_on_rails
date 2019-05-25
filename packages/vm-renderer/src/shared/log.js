const winston = require('winston');

const { format, transports } = winston;

const { combine, splat, colorize, label, printf } = format;

const myFormat = printf(info => `[${info.label}] ${info.level}: ${info.message}`);

// https://stackoverflow.com/questions/54047173/mixed-default-and-named-exports-in-node-with-es5-syntax
/* eslint-disable-next-line no-multi-assign */
const logger = (module.exports = winston.createLogger({
  transports: [new transports.Console()],
  format: combine(label({ label: 'ROR-VM' }), splat(), colorize(), myFormat),
}));

logger.configureLogger = function configureLogger(theLogger, logLevel) {
  theLogger.configure({
    level: logLevel,
    transports: [new transports.Console()],
    format: combine(label({ label: 'ROR-VM' }), splat(), colorize(), myFormat),
  });
};
