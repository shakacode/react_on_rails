"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureReactUseAvailable = exports.unmountComponentAtNode = exports.reactHydrate = exports.supportsHydrate = exports.supportsRootApi = void 0;
exports.reactRender = reactRender;
/* eslint-disable global-require,@typescript-eslint/no-require-imports */
const React = require("react");
const ReactDOM = require("react-dom");
const reactMajorVersion = Number(ReactDOM.version?.split('.')[0]) || 16;
// TODO: once we require React 18, we can remove this and inline everything guarded by it.
exports.supportsRootApi = reactMajorVersion >= 18;
exports.supportsHydrate = exports.supportsRootApi || 'hydrate' in ReactDOM;
// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
let reactDomClient;
if (exports.supportsRootApi) {
    // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
    // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
    // Unfortunately, it only converts the error to a warning.
    try {
        reactDomClient = require('react-dom/client');
    }
    catch (_e) {
        // We should never get here, but if we do, we'll just use the default ReactDOM
        // and live with the warning.
        reactDomClient = ReactDOM;
    }
}
/* eslint-disable @typescript-eslint/no-deprecated,@typescript-eslint/no-non-null-assertion,react/no-deprecated --
 * while we need to support React 16
 */
exports.reactHydrate = exports.supportsRootApi
    ? reactDomClient.hydrateRoot
    : (domNode, reactElement) => ReactDOM.hydrate(reactElement, domNode);
function reactRender(domNode, reactElement) {
    if (exports.supportsRootApi) {
        const root = reactDomClient.createRoot(domNode);
        root.render(reactElement);
        return root;
    }
    // eslint-disable-next-line react/no-render-return-value
    return ReactDOM.render(reactElement, domNode);
}
exports.unmountComponentAtNode = exports.supportsRootApi
    ? // not used if we use root API
        () => false
    : ReactDOM.unmountComponentAtNode;
const ensureReactUseAvailable = () => {
    if (!('use' in React) || typeof React.use !== 'function') {
        throw new Error('React.use is not defined. Please ensure you are using React 19 to use server components.');
    }
};
exports.ensureReactUseAvailable = ensureReactUseAvailable;
//# sourceMappingURL=reactApis.cjs.map