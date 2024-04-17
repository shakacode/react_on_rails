// Inspiration from https://github.com/Abazhenov/express-async-handler/blob/master/index.js
const asyncUtil = <F extends (...args: any[]) => any>(fn: F) =>
  function asyncUtilWrap(...args: Parameters<F>) {
    const fnReturn = fn(...args);
    const next = args[args.length - 1];
    return Promise.resolve(fnReturn).catch(next);
  };

export = asyncUtil;
