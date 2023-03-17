"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var react_1 = __importDefault(require("react"));
var server_1 = __importDefault(require("react-dom/server"));
function handleRenderFunctionIssue(options) {
    var e = options.e, name = options.name;
    var msg = '';
    if (name) {
        var lastLine = 'A Render-Function takes a single arg of props (and the location for react-router) ' +
            'and returns a ReactElement.';
        var shouldBeRenderFunctionError = "ERROR: ReactOnRails is incorrectly detecting Render-Function to be false. The React\ncomponent '".concat(name, "' seems to be a Render-Function.\n").concat(lastLine);
        var reMatchShouldBeGeneratorError = /Can't add property context, object is not extensible/;
        if (reMatchShouldBeGeneratorError.test(e.message)) {
            msg += "".concat(shouldBeRenderFunctionError, "\n\n");
            console.error(shouldBeRenderFunctionError);
        }
        shouldBeRenderFunctionError =
            "ERROR: ReactOnRails is incorrectly detecting renderFunction to be true, but the React\ncomponent '".concat(name, "' is not a Render-Function.\n").concat(lastLine);
        var reMatchShouldNotBeGeneratorError = /Cannot call a class as a function/;
        if (reMatchShouldNotBeGeneratorError.test(e.message)) {
            msg += "".concat(shouldBeRenderFunctionError, "\n\n");
            console.error(shouldBeRenderFunctionError);
        }
    }
    return msg;
}
var handleError = function (options) {
    var e = options.e, jsCode = options.jsCode, serverSide = options.serverSide;
    console.error('Exception in rendering!');
    var msg = handleRenderFunctionIssue(options);
    if (jsCode) {
        console.error("JS code was: ".concat(jsCode));
    }
    if (e.fileName) {
        console.error("location: ".concat(e.fileName, ":").concat(e.lineNumber));
    }
    console.error("message: ".concat(e.message));
    console.error("stack: ".concat(e.stack));
    if (serverSide) {
        msg += "Exception in rendering!\n".concat(e.fileName ? "\nlocation: ".concat(e.fileName, ":").concat(e.lineNumber) : '', "\nMessage: ").concat(e.message, "\n\n").concat(e.stack);
        var reactElement = react_1.default.createElement('pre', null, msg);
        return server_1.default.renderToString(reactElement);
    }
    return "undefined";
};
exports.default = handleError;
