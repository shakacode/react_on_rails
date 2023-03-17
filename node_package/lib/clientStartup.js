"use strict";
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.clientStartup = exports.reactOnRailsPageLoaded = void 0;
var react_dom_1 = __importDefault(require("react-dom"));
var createReactOutput_1 = __importDefault(require("./createReactOutput"));
var isServerRenderResult_1 = require("./isServerRenderResult");
var reactHydrateOrRender_1 = __importDefault(require("./reactHydrateOrRender"));
var reactApis_1 = require("./reactApis");
var REACT_ON_RAILS_STORE_ATTRIBUTE = 'data-js-react-on-rails-store';
function findContext() {
    if (typeof window.ReactOnRails !== 'undefined') {
        return window;
    }
    else if (typeof ReactOnRails !== 'undefined') {
        return global;
    }
    throw new Error("ReactOnRails is undefined in both global and window namespaces.\n  ");
}
function debugTurbolinks() {
    var msg = [];
    for (var _i = 0; _i < arguments.length; _i++) {
        msg[_i] = arguments[_i];
    }
    if (!window) {
        return;
    }
    var context = findContext();
    if (context.ReactOnRails && context.ReactOnRails.option('traceTurbolinks')) {
        console.log.apply(console, __spreadArray(['TURBO:'], msg, false));
    }
}
function turbolinksInstalled() {
    return (typeof Turbolinks !== 'undefined');
}
function turboInstalled() {
    var context = findContext();
    if (context.ReactOnRails) {
        return context.ReactOnRails.option('turbo') === true;
    }
    return false;
}
function reactOnRailsHtmlElements() {
    return document.getElementsByClassName('js-react-on-rails-component');
}
function initializeStore(el, context, railsContext) {
    var name = el.getAttribute(REACT_ON_RAILS_STORE_ATTRIBUTE) || '';
    var props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
    var storeGenerator = context.ReactOnRails.getStoreGenerator(name);
    var store = storeGenerator(props, railsContext);
    context.ReactOnRails.setStore(name, store);
}
function forEachStore(context, railsContext) {
    var els = document.querySelectorAll("[".concat(REACT_ON_RAILS_STORE_ATTRIBUTE, "]"));
    for (var i = 0; i < els.length; i += 1) {
        initializeStore(els[i], context, railsContext);
    }
}
function turbolinksVersion5() {
    return (typeof Turbolinks.controller !== 'undefined');
}
function turbolinksSupported() {
    return Turbolinks.supported;
}
function delegateToRenderer(componentObj, props, railsContext, domNodeId, trace) {
    var name = componentObj.name, component = componentObj.component, isRenderer = componentObj.isRenderer;
    if (isRenderer) {
        if (trace) {
            console.log("DELEGATING TO RENDERER ".concat(name, " for dom node with id: ").concat(domNodeId, " with props, railsContext:"), props, railsContext);
        }
        component(props, railsContext, domNodeId);
        return true;
    }
    return false;
}
function domNodeIdForEl(el) {
    return el.getAttribute('data-dom-id') || '';
}
/**
 * Used for client rendering by ReactOnRails. Either calls ReactDOM.hydrate, ReactDOM.render, or
 * delegates to a renderer registered by the user.
 */
function render(el, context, railsContext) {
    // This must match lib/react_on_rails/helper.rb
    var name = el.getAttribute('data-component-name') || '';
    var domNodeId = domNodeIdForEl(el);
    var props = (el.textContent !== null) ? JSON.parse(el.textContent) : {};
    var trace = el.getAttribute('data-trace') === 'true';
    try {
        var domNode = document.getElementById(domNodeId);
        if (domNode) {
            var componentObj = context.ReactOnRails.getComponent(name);
            if (delegateToRenderer(componentObj, props, railsContext, domNodeId, trace)) {
                return;
            }
            // Hydrate if available and was server rendered
            // @ts-expect-error potentially present if React 18 or greater
            var shouldHydrate = !!(react_dom_1.default.hydrate || react_dom_1.default.hydrateRoot) && !!domNode.innerHTML;
            var reactElementOrRouterResult = (0, createReactOutput_1.default)({
                componentObj: componentObj,
                props: props,
                domNodeId: domNodeId,
                trace: trace,
                railsContext: railsContext,
                shouldHydrate: shouldHydrate,
            });
            if ((0, isServerRenderResult_1.isServerRenderHash)(reactElementOrRouterResult)) {
                throw new Error("You returned a server side type of react-router error: ".concat(JSON.stringify(reactElementOrRouterResult), "\nYou should return a React.Component always for the client side entry point."));
            }
            else {
                var rootOrElement = (0, reactHydrateOrRender_1.default)(domNode, reactElementOrRouterResult, shouldHydrate);
                if (reactApis_1.supportsRootApi) {
                    context.roots.push(rootOrElement);
                }
            }
        }
    }
    catch (e) {
        e.message = "ReactOnRails encountered an error while rendering component: ".concat(name, ".\n") +
            "Original message: ".concat(e.message);
        throw e;
    }
}
function forEachReactOnRailsComponentRender(context, railsContext) {
    var els = reactOnRailsHtmlElements();
    for (var i = 0; i < els.length; i += 1) {
        render(els[i], context, railsContext);
    }
}
function parseRailsContext() {
    var el = document.getElementById('js-react-on-rails-context');
    if (!el) {
        // The HTML page will not have an element with ID 'js-react-on-rails-context' if there are no
        // react on rails components
        return null;
    }
    if (!el.textContent) {
        throw new Error('The HTML element with ID \'js-react-on-rails-context\' has no textContent');
    }
    return JSON.parse(el.textContent);
}
function reactOnRailsPageLoaded() {
    debugTurbolinks('reactOnRailsPageLoaded');
    var railsContext = parseRailsContext();
    // If no react on rails components
    if (!railsContext)
        return;
    var context = findContext();
    if (reactApis_1.supportsRootApi) {
        context.roots = [];
    }
    forEachStore(context, railsContext);
    forEachReactOnRailsComponentRender(context, railsContext);
}
exports.reactOnRailsPageLoaded = reactOnRailsPageLoaded;
function unmount(el) {
    var domNodeId = domNodeIdForEl(el);
    var domNode = document.getElementById(domNodeId);
    if (domNode === null) {
        return;
    }
    try {
        react_dom_1.default.unmountComponentAtNode(domNode);
    }
    catch (e) {
        console.info("Caught error calling unmountComponentAtNode: ".concat(e.message, " for domNode"), domNode, e);
    }
}
function reactOnRailsPageUnloaded() {
    debugTurbolinks('reactOnRailsPageUnloaded');
    if (reactApis_1.supportsRootApi) {
        var roots = findContext().roots;
        // If no react on rails components
        if (!roots)
            return;
        for (var _i = 0, roots_1 = roots; _i < roots_1.length; _i++) {
            var root = roots_1[_i];
            root.unmount();
        }
    }
    else {
        var els = reactOnRailsHtmlElements();
        for (var i = 0; i < els.length; i += 1) {
            unmount(els[i]);
        }
    }
}
function renderInit() {
    // Install listeners when running on the client (browser).
    // We must do this check for turbolinks AFTER the document is loaded because we load the
    // Webpack bundles first.
    if ((!turbolinksInstalled() || !turbolinksSupported()) && !turboInstalled()) {
        debugTurbolinks('NOT USING TURBOLINKS: calling reactOnRailsPageLoaded');
        reactOnRailsPageLoaded();
        return;
    }
    if (turboInstalled()) {
        debugTurbolinks('USING TURBO: document added event listeners ' +
            'turbo:before-render and turbo:render.');
        document.addEventListener('turbo:before-render', reactOnRailsPageUnloaded);
        document.addEventListener('turbo:render', reactOnRailsPageLoaded);
        reactOnRailsPageLoaded();
    }
    else if (turbolinksVersion5()) {
        debugTurbolinks('USING TURBOLINKS 5: document added event listeners ' +
            'turbolinks:before-render and turbolinks:render.');
        document.addEventListener('turbolinks:before-render', reactOnRailsPageUnloaded);
        document.addEventListener('turbolinks:render', reactOnRailsPageLoaded);
        reactOnRailsPageLoaded();
    }
    else {
        debugTurbolinks('USING TURBOLINKS 2: document added event listeners page:before-unload and ' +
            'page:change.');
        document.addEventListener('page:before-unload', reactOnRailsPageUnloaded);
        document.addEventListener('page:change', reactOnRailsPageLoaded);
    }
}
function isWindow(context) {
    return context.document !== undefined;
}
function clientStartup(context) {
    // Check if server rendering
    if (!isWindow(context)) {
        return;
    }
    var document = context.document;
    // Tried with a file local variable, but the install handler gets called twice.
    // eslint-disable-next-line no-underscore-dangle
    if (context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
        return;
    }
    // eslint-disable-next-line no-underscore-dangle, no-param-reassign
    context.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;
    debugTurbolinks('Adding DOMContentLoaded event to install event listeners.');
    // So  long as the document is not loading, we can assume:
    // The document has finished loading and the document has been parsed
    // but sub-resources such as images, stylesheets and frames are still loading.
    // If lazy asynch loading is used, such as with loadable-components, then the init
    // function will install some handler that will properly know when to do hyrdation.
    if (document.readyState !== 'loading') {
        window.setTimeout(renderInit);
    }
    else {
        document.addEventListener('DOMContentLoaded', renderInit);
    }
}
exports.clientStartup = clientStartup;
