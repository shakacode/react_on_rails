"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.reactRender = exports.reactHydrate = void 0;
var react_dom_1 = __importDefault(require("react-dom"));
var reactApis_1 = require("./reactApis");
// TODO: once React dependency is updated to >= 18, we can remove this and just
// import ReactDOM from 'react-dom/client';
// eslint-disable-next-line @typescript-eslint/no-explicit-any
var reactDomClient;
if (reactApis_1.supportsRootApi) {
    // This will never throw an exception, but it's the way to tell Webpack the dependency is optional
    // https://github.com/webpack/webpack/issues/339#issuecomment-47739112
    // Unfortunately, it only converts the error to a warning.
    try {
        // eslint-disable-next-line global-require,import/no-unresolved
        reactDomClient = require('react-dom/client');
    }
    catch (e) {
        // We should never get here, but if we do, we'll just use the default ReactDOM
        // and live with the warning.
        reactDomClient = react_dom_1.default;
    }
}
exports.reactHydrate = reactApis_1.supportsRootApi ?
    reactDomClient.hydrateRoot :
    function (domNode, reactElement) { return react_dom_1.default.hydrate(reactElement, domNode); };
function reactRender(domNode, reactElement) {
    if (reactApis_1.supportsRootApi) {
        var root = reactDomClient.createRoot(domNode);
        root.render(reactElement);
        return root;
    }
    // eslint-disable-next-line react/no-render-return-value
    return react_dom_1.default.render(reactElement, domNode);
}
exports.reactRender = reactRender;
function reactHydrateOrRender(domNode, reactElement, hydrate) {
    return hydrate ? (0, exports.reactHydrate)(domNode, reactElement) : reactRender(domNode, reactElement);
}
exports.default = reactHydrateOrRender;
