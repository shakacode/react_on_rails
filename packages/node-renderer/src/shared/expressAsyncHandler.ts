import type { NextFunction, Request, Response } from 'express';
import type { RouteParameters } from 'express-serve-static-core';

type AsyncHandler<Route extends string = string> = (
  req: Request<RouteParameters<Route>>,
  res: Response,
  next: NextFunction,
) => Promise<void>;

// Inspiration from https://github.com/Abazhenov/express-async-handler/blob/master/index.js
const asyncUtil = <Route extends string = string>(fn: AsyncHandler<Route>): AsyncHandler<Route> =>
  function asyncUtilWrap(req, res, next) {
    const fnReturn = fn(req, res, next);
    // eslint-disable-next-line @typescript-eslint/use-unknown-in-catch-callback-variable -- unavoidable due to Express types
    return Promise.resolve(fnReturn).catch(next);
  };

export = asyncUtil;
