import winston, { format, transports } from 'winston';

const {
  combine, splat, colorize, label, printf,
} = format;

const myFormat = printf((info) => `[${info.label}] ${info.level}: ${info.message}`);

const logger = winston.createLogger({
  transports: [
    new transports.Console(),
  ],
  format: combine(
    label({ label: 'ROR-VM' }),
    splat(),
    colorize(),
    myFormat,
  ),
});

export function configureLogger(theLogger, logLevel) {
  theLogger.configure({
    level: logLevel,
    transports: [
      new transports.Console(),
    ],
    format: combine(
      label({ label: 'ROR-VM' }),
      splat(),
      colorize(),
      myFormat,
    ),
  });
}

export default logger;
