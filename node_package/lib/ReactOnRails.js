"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var ClientStartup = __importStar(require("./clientStartup"));
var handleError_1 = __importDefault(require("./handleError"));
var ComponentRegistry_1 = __importDefault(require("./ComponentRegistry"));
var StoreRegistry_1 = __importDefault(require("./StoreRegistry"));
var serverRenderReactComponent_1 = __importDefault(require("./serverRenderReactComponent"));
var buildConsoleReplay_1 = __importDefault(require("./buildConsoleReplay"));
var createReactOutput_1 = __importDefault(require("./createReactOutput"));
var Authenticity_1 = __importDefault(require("./Authenticity"));
var context_1 = __importDefault(require("./context"));
var reactHydrateOrRender_1 = __importDefault(require("./reactHydrateOrRender"));
var ctx = (0, context_1.default)();
if (ctx === undefined) {
    throw new Error("The context (usually Window or NodeJS's Global) is undefined.");
}
var DEFAULT_OPTIONS = {
    traceTurbolinks: false,
    turbo: false,
};
ctx.ReactOnRails = {
    options: {},
    /**
     * Main entry point to using the react-on-rails npm package. This is how Rails will be able to
     * find you components for rendering.
     * @param components (key is component name, value is component)
     */
    register: function (components) {
        ComponentRegistry_1.default.register(components);
    },
    /**
     * Allows registration of store generators to be used by multiple react components on one Rails
     * view. store generators are functions that take one arg, props, and return a store. Note that
     * the setStore API is different in that it's the actual store hydrated with props.
     * @param stores (keys are store names, values are the store generators)
     */
    registerStore: function (stores) {
        if (!stores) {
            throw new Error('Called ReactOnRails.registerStores with a null or undefined, rather than ' +
                'an Object with keys being the store names and the values are the store generators.');
        }
        StoreRegistry_1.default.register(stores);
    },
    /**
     * Allows retrieval of the store by name. This store will be hydrated by any Rails form props.
     * Pass optional param throwIfMissing = false if you want to use this call to get back null if the
     * store with name is not registered.
     * @param name
     * @param throwIfMissing Defaults to true. Set to false to have this call return undefined if
     *        there is no store with the given name.
     * @returns Redux Store, possibly hydrated
     */
    getStore: function (name, throwIfMissing) {
        if (throwIfMissing === void 0) { throwIfMissing = true; }
        return StoreRegistry_1.default.getStore(name, throwIfMissing);
    },
    /**
     * Renders or hydrates the react element passed. In case react version is >=18 will use the new api.
     * @param domNode
     * @param reactElement
     * @param hydrate if true will perform hydration, if false will render
     * @returns {Root|ReactComponent|ReactElement|null}
     */
    reactHydrateOrRender: function (domNode, reactElement, hydrate) {
        return (0, reactHydrateOrRender_1.default)(domNode, reactElement, hydrate);
    },
    /**
     * Set options for ReactOnRails, typically before you call ReactOnRails.register
     * Available Options:
     * `traceTurbolinks: true|false Gives you debugging messages on Turbolinks events
     * `turbo: true|false Turbo (the follower of Turbolinks) events will be registered, if set to true.
     */
    setOptions: function (newOptions) {
        if (typeof newOptions.traceTurbolinks !== 'undefined') {
            this.options.traceTurbolinks = newOptions.traceTurbolinks;
            // eslint-disable-next-line no-param-reassign
            delete newOptions.traceTurbolinks;
        }
        if (typeof newOptions.turbo !== 'undefined') {
            this.options.turbo = newOptions.turbo;
            // eslint-disable-next-line no-param-reassign
            delete newOptions.turbo;
        }
        if (Object.keys(newOptions).length > 0) {
            throw new Error("Invalid options passed to ReactOnRails.options: ".concat(JSON.stringify(newOptions)));
        }
    },
    /**
     * Allow directly calling the page loaded script in case the default events that trigger react
     * rendering are not sufficient, such as when loading JavaScript asynchronously with TurboLinks:
     * More details can be found here:
     * https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/turbolinks.md
     */
    reactOnRailsPageLoaded: function () {
        ClientStartup.reactOnRailsPageLoaded();
    },
    /**
     * Returns CSRF authenticity token inserted by Rails csrf_meta_tags
     * @returns String or null
     */
    authenticityToken: function () {
        return Authenticity_1.default.authenticityToken();
    },
    /**
     * Returns header with csrf authenticity token and XMLHttpRequest
     * @param {*} other headers
     * @returns {*} header
     */
    authenticityHeaders: function (otherHeaders) {
        if (otherHeaders === void 0) { otherHeaders = {}; }
        return Authenticity_1.default.authenticityHeaders(otherHeaders);
    },
    // /////////////////////////////////////////////////////////////////////////////
    // INTERNALLY USED APIs
    // /////////////////////////////////////////////////////////////////////////////
    /**
     * Retrieve an option by key.
     * @param key
     * @returns option value
     */
    option: function (key) {
        return this.options[key];
    },
    /**
     * Allows retrieval of the store generator by name. This is used internally by ReactOnRails after
     * a rails form loads to prepare stores.
     * @param name
     * @returns Redux Store generator function
     */
    getStoreGenerator: function (name) {
        return StoreRegistry_1.default.getStoreGenerator(name);
    },
    /**
     * Allows saving the store populated by Rails form props. Used internally by ReactOnRails.
     * @param name
     * @returns Redux Store, possibly hydrated
     */
    setStore: function (name, store) {
        return StoreRegistry_1.default.setStore(name, store);
    },
    /**
     * Clears hydratedStores to avoid accidental usage of wrong store hydrated in previous/parallel
     * request.
     */
    clearHydratedStores: function () {
        StoreRegistry_1.default.clearHydratedStores();
    },
    /**
     * @example
     * ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
     *
     * Does this:
     * ```js
     * ReactDOM.render(React.createElement(HelloWorldApp, {name: "Stranger"}),
     *   document.getElementById('app'))
     * ```
     * under React 16/17 and
     * ```js
     * const root = ReactDOMClient.createRoot(document.getElementById('app'))
     * root.render(React.createElement(HelloWorldApp, {name: "Stranger"}))
     * return root
     * ```
     * under React 18+.
     *
     * @param name Name of your registered component
     * @param props Props to pass to your component
     * @param domNodeId
     * @param hydrate Pass truthy to update server rendered html. Default is falsy
     * @returns {Root|ReactComponent|ReactElement} Under React 18+: the created React root
     *   (see "What is a root?" in https://github.com/reactwg/react-18/discussions/5).
     *   Under React 16/17: Reference to your component's backing instance or `null` for stateless components.
     */
    render: function (name, props, domNodeId, hydrate) {
        var componentObj = ComponentRegistry_1.default.get(name);
        var reactElement = (0, createReactOutput_1.default)({ componentObj: componentObj, props: props, domNodeId: domNodeId });
        return (0, reactHydrateOrRender_1.default)(document.getElementById(domNodeId), reactElement, hydrate);
    },
    /**
     * Get the component that you registered
     * @param name
     * @returns {name, component, renderFunction, isRenderer}
     */
    getComponent: function (name) {
        return ComponentRegistry_1.default.get(name);
    },
    /**
     * Used by server rendering by Rails
     * @param options
     */
    serverRenderReactComponent: function (options) {
        return (0, serverRenderReactComponent_1.default)(options);
    },
    /**
     * Used by Rails to catch errors in rendering
     * @param options
     */
    handleError: function (options) {
        return (0, handleError_1.default)(options);
    },
    /**
     * Used by Rails server rendering to replay console messages.
     */
    buildConsoleReplay: function () {
        return (0, buildConsoleReplay_1.default)();
    },
    /**
     * Get an Object containing all registered components. Useful for debugging.
     * @returns {*}
     */
    registeredComponents: function () {
        return ComponentRegistry_1.default.components();
    },
    /**
     * Get an Object containing all registered store generators. Useful for debugging.
     * @returns {*}
     */
    storeGenerators: function () {
        return StoreRegistry_1.default.storeGenerators();
    },
    /**
     * Get an Object containing all hydrated stores. Useful for debugging.
     * @returns {*}
     */
    stores: function () {
        return StoreRegistry_1.default.stores();
    },
    resetOptions: function () {
        this.options = Object.assign({}, DEFAULT_OPTIONS);
    },
};
ctx.ReactOnRails.resetOptions();
ClientStartup.clientStartup(ctx);
exports.default = ctx.ReactOnRails;
