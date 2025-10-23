export function isServerRenderHash(testValue) {
  return !!(testValue.renderedHtml || testValue.redirectLocation || testValue.routeError || testValue.error);
}
export function isPromise(testValue) {
  return !!testValue?.then;
}
