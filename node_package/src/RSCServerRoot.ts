// import * as React from 'react';
// import { createFromNodeStream } from 'react-on-rails-rsc/client.node';
// import transformRSCStream from './transformRSCNodeStreamAndReplayConsoleLogs';
// import loadJsonFile from './loadJsonFile';

// if (!('use' in React && typeof React.use === 'function')) {
//   throw new Error('React.use is not defined. Please ensure you are using React 18 with experimental features enabled or React 19+ to use server components.');
// }

// const { use } = React;

// export type RSCServerRootProps = {
//   getRscPromise: NodeJS.ReadableStream,
//   reactClientManifestFileName: string,
//   reactServerManifestFileName: string,
// }

// const createFromFetch = (stream: NodeJS.ReadableStream, ssrManifest: Record<string, unknown>) => {
//   const transformedStream = transformRSCStream(stream);
//   return createFromNodeStream(transformedStream, ssrManifest);
// }

// const createSSRManifest = (reactServerManifestFileName: string, reactClientManifestFileName: string) => {
//   const reactServerManifest = loadJsonFile(reactServerManifestFileName);
//   const reactClientManifest = loadJsonFile(reactClientManifestFileName);

//   const ssrManifest = {
//     moduleLoading: {
//       prefix: "/webpack/development/",
//       crossOrigin: null,
//     },
//     moduleMap: {} as Record<string, unknown>,
//   };

//   Object.entries(reactClientManifest).forEach(([aboluteFileUrl, clientFileBundlingInfo]) => {
//     const serverFileBundlingInfo = reactServerManifest[aboluteFileUrl];
//     ssrManifest.moduleMap[(clientFileBundlingInfo as { id: string }).id] = {
//       '*': {
//         id: (serverFileBundlingInfo as { id: string }).id,
//         chunks: (serverFileBundlingInfo as { chunks: string[] }).chunks,
//         name: '*',
//       }
//     };
//   });

//   return ssrManifest;
// }

// const RSCServerRoot = ({
//   getRscPromise,
//   reactClientManifestFileName,
//   reactServerManifestFileName,
// }: RSCServerRootProps) => {
//   const ssrManifest = createSSRManifest(reactServerManifestFileName, reactClientManifestFileName);
//   return use(createFromFetch(getRscPromise, ssrManifest));
// };

// export default RSCServerRoot;
