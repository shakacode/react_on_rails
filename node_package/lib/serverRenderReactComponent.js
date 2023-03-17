"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var server_1 = __importDefault(require("react-dom/server"));
var ComponentRegistry_1 = __importDefault(require("./ComponentRegistry"));
var createReactOutput_1 = __importDefault(require("./createReactOutput"));
var isServerRenderResult_1 = require("./isServerRenderResult");
var buildConsoleReplay_1 = __importDefault(require("./buildConsoleReplay"));
var handleError_1 = __importDefault(require("./handleError"));
function serverRenderReactComponent(options) {
    var _this = this;
    var name = options.name, domNodeId = options.domNodeId, trace = options.trace, props = options.props, railsContext = options.railsContext, renderingReturnsPromises = options.renderingReturnsPromises, throwJsErrors = options.throwJsErrors;
    var renderResult = null;
    var hasErrors = false;
    var renderingError = null;
    try {
        var componentObj = ComponentRegistry_1.default.get(name);
        if (componentObj.isRenderer) {
            throw new Error("Detected a renderer while server rendering component '".concat(name, "'. See https://github.com/shakacode/react_on_rails#renderer-functions"));
        }
        var reactRenderingResult_1 = (0, createReactOutput_1.default)({
            componentObj: componentObj,
            domNodeId: domNodeId,
            trace: trace,
            props: props,
            railsContext: railsContext,
        });
        var processServerRenderHash = function () {
            // We let the client side handle any redirect
            // Set hasErrors in case we want to throw a Rails exception
            hasErrors = !!reactRenderingResult_1.routeError;
            if (hasErrors) {
                console.error("React Router ERROR: ".concat(JSON.stringify(reactRenderingResult_1.routeError)));
            }
            if (reactRenderingResult_1.redirectLocation) {
                if (trace) {
                    var redirectLocation = reactRenderingResult_1.redirectLocation;
                    var redirectPath = redirectLocation.pathname + redirectLocation.search;
                    console.log("  ROUTER REDIRECT: ".concat(name, " to dom node with id: ").concat(domNodeId, ", redirect to ").concat(redirectPath));
                }
                // For redirects on server rendering, we can't stop Rails from returning the same result.
                // Possibly, someday, we could have the rails server redirect.
                return '';
            }
            return reactRenderingResult_1.renderedHtml;
        };
        var processPromise = function () {
            if (!renderingReturnsPromises) {
                console.error('Your render function returned a Promise, which is only supported by a node renderer, not ExecJS.');
            }
            return reactRenderingResult_1;
        };
        var processReactElement = function () {
            try {
                return server_1.default.renderToString(reactRenderingResult_1);
            }
            catch (error) {
                console.error("Invalid call to renderToString. Possibly you have a renderFunction, a function that already\ncalls renderToString, that takes one parameter. You need to add an extra unused parameter to identify this function\nas a renderFunction and not a simple React Function Component.");
                throw error;
            }
        };
        if ((0, isServerRenderResult_1.isServerRenderHash)(reactRenderingResult_1)) {
            renderResult = processServerRenderHash();
        }
        else if ((0, isServerRenderResult_1.isPromise)(reactRenderingResult_1)) {
            renderResult = processPromise();
        }
        else {
            renderResult = processReactElement();
        }
    }
    catch (e) {
        if (throwJsErrors) {
            throw e;
        }
        hasErrors = true;
        renderResult = (0, handleError_1.default)({
            e: e,
            name: name,
            serverSide: true,
        });
        renderingError = e;
    }
    var consoleReplayScript = (0, buildConsoleReplay_1.default)();
    var addRenderingErrors = function (resultObject, renderError) {
        resultObject.renderingError = {
            message: renderError.message,
            stack: renderError.stack,
        };
    };
    if (renderingReturnsPromises) {
        var resolveRenderResult = function () { return __awaiter(_this, void 0, void 0, function () {
            var promiseResult, e_1;
            var _a;
            return __generator(this, function (_b) {
                switch (_b.label) {
                    case 0:
                        _b.trys.push([0, 2, , 3]);
                        _a = {};
                        return [4 /*yield*/, renderResult];
                    case 1:
                        promiseResult = (_a.html = _b.sent(),
                            _a.consoleReplayScript = consoleReplayScript,
                            _a.hasErrors = hasErrors,
                            _a);
                        return [3 /*break*/, 3];
                    case 2:
                        e_1 = _b.sent();
                        if (throwJsErrors) {
                            throw e_1;
                        }
                        promiseResult = {
                            html: (0, handleError_1.default)({
                                e: e_1,
                                name: name,
                                serverSide: true,
                            }),
                            consoleReplayScript: consoleReplayScript,
                            hasErrors: true,
                        };
                        renderingError = e_1;
                        return [3 /*break*/, 3];
                    case 3:
                        if (renderingError !== null) {
                            addRenderingErrors(promiseResult, renderingError);
                        }
                        return [2 /*return*/, promiseResult];
                }
            });
        }); };
        return resolveRenderResult();
    }
    var result = {
        html: renderResult,
        consoleReplayScript: consoleReplayScript,
        hasErrors: hasErrors,
    };
    if (renderingError) {
        addRenderingErrors(result, renderingError);
    }
    return JSON.stringify(result);
}
exports.default = serverRenderReactComponent;
