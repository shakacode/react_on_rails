// The real return type is `typeof import(path) | null`, which can't be specified in TS.
// Usually the result should be cast to that type.
// An exception is `@sentry/tracing` where we usually just check the module exists.
export = function requireOptional(path: string): unknown {
  try {
    // eslint-disable-next-line import/no-dynamic-require, global-require -- unavoidable dynamic require
    return require(path);
  } catch (e) {
    if ((e as { code?: string }).code === 'MODULE_NOT_FOUND') {
      return null;
    }

    throw e;
  }
};
