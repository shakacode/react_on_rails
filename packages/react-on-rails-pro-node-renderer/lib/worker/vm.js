"use strict";
/**
 * Manages the virtual machine for rendering code in isolated context.
 * @module worker/vm
 */
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
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.VMContextNotFoundError = void 0;
exports.hasVMContextForBundle = hasVMContextForBundle;
exports.getVMContext = getVMContext;
exports.buildExecutionContext = buildExecutionContext;
exports.resetVM = resetVM;
exports.removeVM = removeVM;
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const vm_1 = __importDefault(require("vm"));
const module_1 = __importDefault(require("module"));
const cluster_1 = __importDefault(require("cluster"));
const web_1 = require("stream/web");
const util_1 = require("util");
const sharedConsoleHistory_js_1 = __importDefault(require("../shared/sharedConsoleHistory.js"));
const log_js_1 = __importDefault(require("../shared/log.js"));
const configBuilder_js_1 = require("../shared/configBuilder.js");
const utils_js_1 = require("../shared/utils.js");
const errorReporter = __importStar(require("../shared/errorReporter.js"));
const readFileAsync = (0, util_1.promisify)(fs_1.default.readFile);
const writeFileAsync = (0, util_1.promisify)(fs_1.default.writeFile);
// Store contexts by their bundle file paths
const vmContexts = new Map();
// Track VM creation promises to handle concurrent buildVM requests
const vmCreationPromises = new Map();
/**
 * Returns all bundle paths that have a VM context
 * @internal Used in tests
 */
function hasVMContextForBundle(bundlePath) {
    return vmContexts.has(bundlePath);
}
/**
 * Get a specific VM context by bundle path
 */
function getVMContext(bundlePath) {
    return vmContexts.get(bundlePath);
}
const extendContext = (contextObject, additionalContext) => {
    if (log_js_1.default.level === 'debug') {
        log_js_1.default.debug(`Adding ${Object.keys(additionalContext).join(', ')} to context object.`);
    }
    Object.assign(contextObject, additionalContext);
};
// Helper function to manage VM pool size
function manageVMPoolSize() {
    const { maxVMPoolSize } = (0, configBuilder_js_1.getConfig)();
    if (vmContexts.size <= maxVMPoolSize) {
        return;
    }
    const sortedEntries = Array.from(vmContexts.entries()).sort(([, a], [, b]) => a.lastUsed - b.lastUsed);
    while (sortedEntries.length > maxVMPoolSize) {
        const oldestPath = sortedEntries.shift()?.[0];
        if (oldestPath) {
            vmContexts.delete(oldestPath);
            log_js_1.default.debug(`Removed VM for bundle ${oldestPath} due to pool size limit (max: ${maxVMPoolSize})`);
        }
    }
}
class VMContextNotFoundError extends Error {
    constructor(bundleFilePath) {
        super(`VMContext not found for bundle: ${bundleFilePath}`);
        this.name = 'VMContextNotFoundError';
    }
}
exports.VMContextNotFoundError = VMContextNotFoundError;
async function buildVM(filePath) {
    // Return existing promise if VM is already being created
    const existingVmCreationPromise = vmCreationPromises.get(filePath);
    if (existingVmCreationPromise) {
        return existingVmCreationPromise;
    }
    // Check if VM for this bundle already exists
    const vmContext = vmContexts.get(filePath);
    if (vmContext) {
        // Update last used time when accessing existing VM
        vmContext.lastUsed = Date.now();
        return vmContext;
    }
    // Create a new promise for this VM creation
    const vmCreationPromise = (async () => {
        try {
            const { supportModules, stubTimers, additionalContext } = (0, configBuilder_js_1.getConfig)();
            const additionalContextIsObject = additionalContext !== null && additionalContext.constructor === Object;
            const sharedConsoleHistory = new sharedConsoleHistory_js_1.default();
            const contextObject = { sharedConsoleHistory };
            if (supportModules) {
                // IMPORTANT: When adding anything to this object, update:
                // 1. docs/node-renderer/js-configuration.md
                // 2. packages/node-renderer/src/shared/configBuilder.ts
                extendContext(contextObject, {
                    Buffer,
                    TextDecoder,
                    TextEncoder: util_1.TextEncoder,
                    URLSearchParams,
                    ReadableStream: web_1.ReadableStream,
                    process,
                    setTimeout,
                    setInterval,
                    setImmediate,
                    clearTimeout,
                    clearInterval,
                    clearImmediate,
                    queueMicrotask,
                });
            }
            if (additionalContextIsObject) {
                extendContext(contextObject, additionalContext);
            }
            const context = vm_1.default.createContext(contextObject);
            // Create explicit reference to global context, just in case (some libs can use it):
            vm_1.default.runInContext('global = this', context);
            // Reimplement console methods for replaying on the client:
            vm_1.default.runInContext(`
      console = {
        get history() {
          return sharedConsoleHistory.getConsoleHistory();
        },
        set history(value) {
          // Do nothing. It's just for the backward compatibility.
        },
      };
      ['error', 'log', 'info', 'warn'].forEach(function (level) {
        console[level] = function () {
          var argArray = Array.prototype.slice.call(arguments);
          if (argArray.length > 0) {
            argArray[0] = '[SERVER] ' + argArray[0];
          }
          sharedConsoleHistory.addToConsoleHistory({level: level, arguments: argArray});
        };
      });`, context);
            // Define global getStackTrace() function:
            vm_1.default.runInContext(`
      function getStackTrace() {
        var stack;
        try {
          throw new Error('');
        }
        catch (error) {
          stack = error.stack || '';
        }
        stack = stack.split('\\n').map(function (line) { return line.trim(); });
        return stack.splice(stack[0] == 'Error' ? 2 : 1);
      }`, context);
            if (stubTimers) {
                // Define timer polyfills:
                vm_1.default.runInContext(`function setInterval() {}`, context);
                vm_1.default.runInContext(`function setTimeout() {}`, context);
                vm_1.default.runInContext(`function setImmediate() {}`, context);
                vm_1.default.runInContext(`function clearTimeout() {}`, context);
                vm_1.default.runInContext(`function clearInterval() {}`, context);
                vm_1.default.runInContext(`function clearImmediate() {}`, context);
                vm_1.default.runInContext(`function queueMicrotask() {}`, context);
            }
            // Run bundle code in created context:
            const bundleContents = await readFileAsync(filePath, 'utf8');
            // If node-specific code is provided then it must be wrapped into a module wrapper. The bundle
            // may need the `require` function, which is not available when running in vm unless passed in.
            if (additionalContextIsObject || supportModules) {
                vm_1.default.runInContext(module_1.default.wrap(bundleContents), context)(exports, require, module, filePath, path_1.default.dirname(filePath));
            }
            else {
                vm_1.default.runInContext(bundleContents, context);
            }
            // Only now, after VM is fully initialized, store the context
            const newVmContext = {
                context,
                sharedConsoleHistory,
                lastUsed: Date.now(),
            };
            vmContexts.set(filePath, newVmContext);
            // Manage pool size after adding new VM
            manageVMPoolSize();
            // isWorker check is required for JS unit testing:
            if (cluster_1.default.isWorker && cluster_1.default.worker !== undefined) {
                log_js_1.default.debug(`Built VM for worker #${cluster_1.default.worker.id} with bundle ${filePath}`);
            }
            if (log_js_1.default.level === 'debug') {
                log_js_1.default.debug('Required objects now in VM sandbox context: %s', vm_1.default.runInContext('global.ReactOnRails', context) !== undefined);
                log_js_1.default.debug('Required objects should not leak to the global context (true means OK): %s', !!global.ReactOnRails);
            }
            return newVmContext;
        }
        catch (error) {
            log_js_1.default.error({ error }, 'Caught Error when creating context in buildVM');
            errorReporter.error(error);
            throw error;
        }
        finally {
            // Always remove the promise from the map when done
            vmCreationPromises.delete(filePath);
        }
    })();
    // Store the promise
    vmCreationPromises.set(filePath, vmCreationPromise);
    return vmCreationPromise;
}
async function getOrBuildVMContext(bundleFilePath, buildVmsIfNeeded) {
    const vmContext = getVMContext(bundleFilePath);
    if (vmContext) {
        return vmContext;
    }
    const vmCreationPromise = vmCreationPromises.get(bundleFilePath);
    if (vmCreationPromise) {
        return vmCreationPromise;
    }
    if (buildVmsIfNeeded) {
        return buildVM(bundleFilePath);
    }
    throw new VMContextNotFoundError(bundleFilePath);
}
/**
 * Builds an ExecutionContext that manages VM execution for a set of bundles.
 *
 * The ExecutionContext includes a `sharedExecutionContext` Map that enables safe data sharing
 * between the initial render request and subsequent update chunks (for incremental rendering).
 *
 * CRITICAL SECURITY DESIGN:
 * - sharedExecutionContext is created ONCE per ExecutionContext (per HTTP request)
 * - It is NOT a global variable - each request gets its own isolated Map
 * - This prevents data leakage between concurrent rendering requests from different users
 * - The Map is passed to the VM context only during code execution, then immediately removed
 *
 * @see handleIncrementalRenderRequest.ts for how update chunks access the same context
 */
async function buildExecutionContext(bundlePaths, buildVmsIfNeeded) {
    const mapBundleFilePathToVMContext = new Map();
    await Promise.all(bundlePaths.map(async (bundleFilePath) => {
        const vmContext = await getOrBuildVMContext(bundleFilePath, buildVmsIfNeeded);
        vmContext.lastUsed = Date.now();
        mapBundleFilePathToVMContext.set(bundleFilePath, vmContext);
    }));
    // This Map persists for the lifetime of this ExecutionContext (one HTTP request).
    // It allows data to be shared between the initial render and subsequent update chunks.
    // Example: asyncPropsManager is stored here during initial render and accessed by update chunks.
    const sharedExecutionContext = new Map();
    const runInVM = async (renderingRequest, bundleFilePath, vmCluster) => {
        try {
            const { serverBundleCachePath } = (0, configBuilder_js_1.getConfig)();
            const vmContext = mapBundleFilePathToVMContext.get(bundleFilePath);
            if (!vmContext) {
                throw new VMContextNotFoundError(bundleFilePath);
            }
            // Update last used timestamp
            vmContext.lastUsed = Date.now();
            const { context, sharedConsoleHistory } = vmContext;
            if (log_js_1.default.level === 'debug') {
                // worker is nullable in the primary process
                const workerId = vmCluster?.worker?.id;
                log_js_1.default.debug(`worker ${workerId ? `${workerId} ` : ''}received render request for bundle ${bundleFilePath} with code
  ${(0, utils_js_1.smartTrim)(renderingRequest)}`);
                const debugOutputPathCode = path_1.default.join(serverBundleCachePath, 'code.js');
                log_js_1.default.debug(`Full code executed written to: ${debugOutputPathCode}`);
                await writeFileAsync(debugOutputPathCode, renderingRequest);
            }
            // Execute the rendering request in the VM context.
            // We temporarily inject sharedExecutionContext into the VM's global scope
            // so that code can store/retrieve data (e.g., asyncPropsManager).
            // IMPORTANT: We clean up immediately after execution to prevent the VM context
            // (which may be reused by other requests) from retaining references to this request's data.
            let result = sharedConsoleHistory.trackConsoleHistoryInRenderRequest(() => {
                context.renderingRequest = renderingRequest;
                context.sharedExecutionContext = sharedExecutionContext;
                context.runOnOtherBundle = (bundleTimestamp, newRenderingRequest) => {
                    const otherBundleFilePath = (0, utils_js_1.getRequestBundleFilePath)(bundleTimestamp);
                    return runInVM(newRenderingRequest, otherBundleFilePath, vmCluster);
                };
                try {
                    return vm_1.default.runInContext(renderingRequest, context);
                }
                finally {
                    // Clean up references immediately after execution.
                    // Note: sharedExecutionContext itself is NOT cleared here - it persists
                    // for the lifetime of this ExecutionContext so that update chunks can access it.
                    // We only remove the VM context's reference to prevent cross-request data access.
                    context.renderingRequest = undefined;
                    context.sharedExecutionContext = undefined;
                    context.runOnOtherBundle = undefined;
                }
            });
            if ((0, utils_js_1.isReadableStream)(result)) {
                const newStreamAfterHandlingError = (0, utils_js_1.handleStreamError)(result, (error) => {
                    const msg = (0, utils_js_1.formatExceptionMessage)(renderingRequest, error, 'Error in a rendering stream');
                    errorReporter.message(msg);
                });
                return newStreamAfterHandlingError;
            }
            if (typeof result !== 'string') {
                const objectResult = await result;
                result = JSON.stringify(objectResult);
            }
            if (log_js_1.default.level === 'debug' && result) {
                log_js_1.default.debug(`result from JS:
  ${(0, utils_js_1.smartTrim)(result)}`);
                const debugOutputPathResult = path_1.default.join(serverBundleCachePath, 'result.json');
                log_js_1.default.debug(`Wrote result to file: ${debugOutputPathResult}`);
                await writeFileAsync(debugOutputPathResult, result);
            }
            return result;
        }
        catch (exception) {
            const exceptionMessage = (0, utils_js_1.formatExceptionMessage)(renderingRequest, exception);
            log_js_1.default.debug('Caught exception in rendering request: %s', exceptionMessage);
            return Promise.resolve({ exceptionMessage });
        }
    };
    return {
        getVMContext: (bundleFilePath) => mapBundleFilePathToVMContext.get(bundleFilePath),
        runInVM,
    };
}
/** @internal Used in tests */
function resetVM() {
    // Clear all VM contexts
    vmContexts.clear();
}
// Optional: Add a method to remove a specific VM if needed
/**
 * @public TODO: Remove the line below when this function is actually used
 */
function removeVM(bundlePath) {
    vmContexts.delete(bundlePath);
}
//# sourceMappingURL=vm.js.map