export = function requireOptional(path: string): unknown {
  try {
    // eslint-disable-next-line import/no-dynamic-require, global-require
    return require(path);
  } catch (e) {
    if ((e as { code?: string }).code === 'MODULE_NOT_FOUND') {
      return null;
    }

    throw e;
  }
};
