export const consistentKeysReplacer = (_key: string, value: unknown) => {
  if (value instanceof Object && !(value instanceof Array)) {
    const sortedKeys = Object.keys(value).sort();
    const sortedObject = Object.fromEntries(
      sortedKeys.map((key) => [key, (value as Record<string, unknown>)[key]]),
    );
    return sortedObject;
  }
  return value;
};
