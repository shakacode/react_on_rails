/// <reference types="react/experimental" />
const throwRailsContextMissingEntries = (missingEntries) => {
    throw new Error(`Rails context does not have server side ${missingEntries}.\n\n` +
        'This is either a configuration issue or a bug:\n' +
        '1. Ensure you are using a compatible version of react_on_rails_pro\n' +
        '2. Ensure server components support is enabled:\n' +
        '   ReactOnRailsPro.configuration.enable_rsc_support = true\n\n' +
        'If the above are correct, please report at https://github.com/shakacode/react_on_rails/issues');
};
export const assertRailsContextWithServerComponentMetadata = (context) => {
    if (!context ||
        !('reactClientManifestFileName' in context) ||
        !('reactServerClientManifestFileName' in context)) {
        throwRailsContextMissingEntries('server side RSC payload parameters, reactClientManifestFileName, and reactServerClientManifestFileName');
    }
};
export const assertRailsContextWithServerStreamingCapabilities = (context) => {
    assertRailsContextWithServerComponentMetadata(context);
    if (!('getRSCPayloadStream' in context) || !('addPostSSRHook' in context)) {
        throwRailsContextMissingEntries('getRSCPayloadStream and addPostSSRHook functions');
    }
};
// Note: Global type declaration for ReactOnRails is in context.ts
// to avoid circular dependencies with ReactOnRailsInternal
//# sourceMappingURL=index.js.map