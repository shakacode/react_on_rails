const customFetch = (...args: Parameters<typeof fetch>) => {
  const res = fetch(...args);
  return res;
};

export { customFetch as fetch };

export const createRSCPayloadKey = (componentName: string, componentProps: unknown, domNodeId?: string) => {
  return `${componentName}-${JSON.stringify(componentProps)}${domNodeId ? `-${domNodeId}` : ''}`;
};

export const wrapInNewPromise = <T>(promise: Promise<T>) => {
  return new Promise<T>((resolve, reject) => {
    void promise.then(resolve);
    void promise.catch(reject);
  });
};

export const extractErrorMessage = (error: unknown): string => {
  return error instanceof Error ? error.message : String(error);
};
