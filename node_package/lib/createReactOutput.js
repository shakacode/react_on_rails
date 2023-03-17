"use strict";
/* eslint-disable react/prop-types */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var react_1 = __importDefault(require("react"));
var isServerRenderResult_1 = require("./isServerRenderResult");
/**
 * Logic to either call the renderFunction or call React.createElement to get the
 * React.Component
 * @param options
 * @param options.componentObj
 * @param options.props
 * @param options.domNodeId
 * @param options.trace
 * @param options.location
 * @returns {ReactElement}
 */
function createReactOutput(_a) {
    var componentObj = _a.componentObj, props = _a.props, railsContext = _a.railsContext, domNodeId = _a.domNodeId, trace = _a.trace, shouldHydrate = _a.shouldHydrate;
    var name = componentObj.name, component = componentObj.component, renderFunction = componentObj.renderFunction;
    if (trace) {
        if (railsContext && railsContext.serverSide) {
            console.log("RENDERED ".concat(name, " to dom node with id: ").concat(domNodeId));
        }
        else if (shouldHydrate) {
            console.log("HYDRATED ".concat(name, " in dom node with id: ").concat(domNodeId, " using props, railsContext:"), props, railsContext);
        }
        else {
            console.log("RENDERED ".concat(name, " to dom node with id: ").concat(domNodeId, " with props, railsContext:"), props, railsContext);
        }
    }
    if (renderFunction) {
        // Let's invoke the function to get the result
        if (trace) {
            console.log("".concat(name, " is a renderFunction"));
        }
        var renderFunctionResult = component(props, railsContext);
        if ((0, isServerRenderResult_1.isServerRenderHash)(renderFunctionResult)) {
            // We just return at this point, because calling function knows how to handle this case and
            // we can't call React.createElement with this type of Object.
            return renderFunctionResult;
        }
        if ((0, isServerRenderResult_1.isPromise)(renderFunctionResult)) {
            // We just return at this point, because calling function knows how to handle this case and
            // we can't call React.createElement with this type of Object.
            return renderFunctionResult;
        }
        if (react_1.default.isValidElement(renderFunctionResult)) {
            // If already a ReactElement, then just return it.
            console.error("Warning: ReactOnRails: Your registered render-function (ReactOnRails.register) for ".concat(name, "\nincorrectly returned a React Element (JSX). Instead, return a React Function Component by\nwrapping your JSX in a function. ReactOnRails v13 will throw error on this, as React Hooks do not\nwork if you return JSX. Update by wrapping the result JSX of ").concat(name, " in a fat arrow function."));
            return renderFunctionResult;
        }
        // If a component, then wrap in an element
        var reactComponent = renderFunctionResult;
        return react_1.default.createElement(reactComponent, props);
    }
    // else
    return react_1.default.createElement(component, props);
}
exports.default = createReactOutput;
