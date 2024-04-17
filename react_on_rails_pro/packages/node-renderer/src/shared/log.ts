import winston = require('winston');

const { combine, splat, colorize, label, printf } = winston.format;

const myFormat = printf((info) => `[${info.label as string}] ${info.level}: ${info.message}`);

const transports = [
  new winston.transports.Console({
    handleExceptions: true,
  }),
];

export default winston.createLogger({
  transports,
  format: combine(label({ label: 'RORP' }), splat(), colorize(), myFormat),
  exitOnError: false,
});

export function configureLogger(theLogger: winston.Logger, logLevel: string | undefined) {
  theLogger.configure({
    level: logLevel,
    transports,
    format: combine(label({ label: 'RORP' }), splat(), colorize(), myFormat),
    exitOnError: false,
  });
}
