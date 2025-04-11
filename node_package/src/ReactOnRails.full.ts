if (typeof window !== 'undefined') {
  // warn to include a collapsed stack trace
  console.warn(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account). Click this for the stack trace.',
  );
}

export * from './ReactOnRails.client.ts';
export { default as handleError } from './handleError.ts';
export { default as serverRenderReactComponent } from './serverRenderReactComponent.ts';
