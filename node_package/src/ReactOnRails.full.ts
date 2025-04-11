if (typeof window !== 'undefined') {
  console.log(
    'Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 (Requires creating a free account)',
  );
}

export * from './ReactOnRails.client';
export { default as handleError } from './handleError';
export { default as serverRenderReactComponent } from './serverRenderReactComponent';
