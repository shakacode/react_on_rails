declare module 'react-server-dom-webpack/client' {
  export const createFromFetch: (promise: Promise<Response>) => Promise<unknown>;

  export const createFromReadableStream: (stream: ReadableStream) => Promise<unknown>;
}
