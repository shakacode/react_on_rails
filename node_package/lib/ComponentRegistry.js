"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var isRenderFunction_1 = __importDefault(require("./isRenderFunction"));
var registeredComponents = new Map();
exports.default = {
    /**
     * @param components { component1: component1, component2: component2, etc. }
     */
    register: function (components) {
        Object.keys(components).forEach(function (name) {
            if (registeredComponents.has(name)) {
                console.warn('Called register for component that is already registered', name);
            }
            var component = components[name];
            if (!component) {
                throw new Error("Called register with null component named ".concat(name));
            }
            var renderFunction = (0, isRenderFunction_1.default)(component);
            var isRenderer = renderFunction && component.length === 3;
            registeredComponents.set(name, {
                name: name,
                component: component,
                renderFunction: renderFunction,
                isRenderer: isRenderer,
            });
        });
    },
    /**
     * @param name
     * @returns { name, component, isRenderFunction, isRenderer }
     */
    get: function (name) {
        if (registeredComponents.has(name)) {
            return registeredComponents.get(name);
        }
        var keys = Array.from(registeredComponents.keys()).join(', ');
        throw new Error("Could not find component registered with name ".concat(name, ". Registered component names include [ ").concat(keys, " ]. Maybe you forgot to register the component?"));
    },
    /**
     * Get a Map containing all registered components. Useful for debugging.
     * @returns Map where key is the component name and values are the
     * { name, component, renderFunction, isRenderer}
     */
    components: function () {
        return registeredComponents;
    },
};
