export const consistentKeysReplacer = <T>(key: string, value: T): T | Record<string, T> => {
  if (value instanceof Object && !(value instanceof Array)) {
    const sortedObject: Record<string, T> = Object.keys(value)
      .sort()
      .reduce((sorted: Record<string, T>, currentKey: string) => {
        const keyValue = (value as Record<string, T>)[currentKey];
        sorted[currentKey] = keyValue;
        return sorted;
      }, {});
    return sortedObject;
  }
  return value;
};
