/// <reference types="react/experimental" />
const throwRailsContextMissingEntries = (missingEntries) => {
  throw new Error(
    `Rails context does not have server side ${missingEntries}.\n\n` +
      'Please ensure:\n' +
      '1. You are using a compatible version of react_on_rails_pro\n' +
      '2. Server components support is enabled by setting:\n' +
      '   ReactOnRailsPro.configuration.enable_rsc_support = true',
  );
};
export const assertRailsContextWithServerComponentMetadata = (context) => {
  if (
    !context ||
    !('reactClientManifestFileName' in context) ||
    !('reactServerClientManifestFileName' in context)
  ) {
    throwRailsContextMissingEntries(
      'server side RSC payload parameters, reactClientManifestFileName, and reactServerClientManifestFileName',
    );
  }
};
export const assertRailsContextWithServerStreamingCapabilities = (context) => {
  assertRailsContextWithServerComponentMetadata(context);
  if (!('getRSCPayloadStream' in context) || !('addPostSSRHook' in context)) {
    throwRailsContextMissingEntries('getRSCPayloadStream and addPostSSRHook functions');
  }
};
//# sourceMappingURL=index.js.map
